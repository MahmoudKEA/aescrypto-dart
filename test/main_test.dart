import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:aescrypto/aescrypto.dart';
import 'package:encrypt/encrypt.dart';
import 'package:test/test.dart';

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  final AESCrypto cipher = AESCrypto(key: '123456789');

  group("Text Encryption Group:", () {
    const String plainText = "plainText";

    test("Test (encryptText & decryptText) in default CBC mode", () async {
      Uint8List resultEncrypt = await cipher.encryptText(plainText: plainText);
      String resultdecrypt = await cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in CFB64 mode", () async {
      cipher.setMode(AESMode.cfb64);
      Uint8List resultEncrypt = await cipher.encryptText(plainText: plainText);
      String resultdecrypt = await cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in CTR mode", () async {
      cipher.setMode(AESMode.ctr);
      Uint8List resultEncrypt = await cipher.encryptText(plainText: plainText);
      String resultdecrypt = await cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in ECB mode", () async {
      cipher.setMode(AESMode.ecb);
      Uint8List resultEncrypt = await cipher.encryptText(plainText: plainText);
      String resultdecrypt = await cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in OFB64 mode", () async {
      cipher.setMode(AESMode.ofb64);
      Uint8List resultEncrypt = await cipher.encryptText(plainText: plainText);
      String resultdecrypt = await cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in OFB64GCTR mode", () async {
      cipher.setMode(AESMode.ofb64Gctr);
      Uint8List resultEncrypt = await cipher.encryptText(plainText: plainText);
      String resultdecrypt = await cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in SIC mode", () async {
      cipher.setMode(AESMode.sic);
      Uint8List resultEncrypt = await cipher.encryptText(plainText: plainText);
      String resultdecrypt = await cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });
  });

  group("File Encryption Group:", () {
    const String path = './test/data.txt';
    Random random = Random();
    Uint8List data = Uint8List.fromList(
      List<int>.generate(100016, (i) => random.nextInt(256)),
    );
    late String checksum;

    setUpAll(() async {
      await File(path).writeAsBytes(data);
      checksum = await fileChecksum(path);
    });

    test("Test (encryptFile & decryptFile)", () async {
      String resultEncrypt = await cipher.encryptFile(
        path: path,
        ignoreFileExists: true,
        progressCallback: (value) => printDebug('Encrypt progress: $value'),
      );
      String resultdecrypt = await cipher.decryptFile(
        path: resultEncrypt,
        ignoreFileExists: true,
        progressCallback: (value) => printDebug('Decrypt progress: $value'),
      );
      String fileDecryptChecksum = await fileChecksum(resultdecrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      fileDecryptChecksum: $fileDecryptChecksum
      """);

      expect(checksum, equals(fileDecryptChecksum));
    });

    test("Test (encryptToFile & decryptFromFile)", () async {
      String resultEncrypt = await cipher.encryptToFile(
        data: data,
        path: path,
        ignoreFileExists: true,
        progressCallback: (value) => printDebug('Encrypt progress: $value'),
      );
      Uint8List resultdecrypt = await cipher.decryptFromFile(
        path: resultEncrypt,
        progressCallback: (value) => printDebug('Decrypt progress: $value'),
      );
      String fileDecryptChecksum = getHashString(resultdecrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      fileDecryptChecksum: $fileDecryptChecksum
      """);

      expect(resultdecrypt, equals(data));
    });
  });
}
