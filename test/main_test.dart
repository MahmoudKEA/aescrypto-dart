import 'dart:io';
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
      Uint8List resultEncrypt = cipher.encryptText(plainText: plainText);
      String resultdecrypt = cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in CFB64 mode", () async {
      cipher.setMode(AESMode.cfb64);
      Uint8List resultEncrypt = cipher.encryptText(plainText: plainText);
      String resultdecrypt = cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in CTR mode", () async {
      cipher.setMode(AESMode.ctr);
      Uint8List resultEncrypt = cipher.encryptText(plainText: plainText);
      String resultdecrypt = cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in ECB mode", () async {
      cipher.setMode(AESMode.ecb);
      Uint8List resultEncrypt = cipher.encryptText(plainText: plainText);
      String resultdecrypt = cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in OFB64 mode", () async {
      cipher.setMode(AESMode.ofb64);
      Uint8List resultEncrypt = cipher.encryptText(plainText: plainText);
      String resultdecrypt = cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in OFB64GCTR mode", () async {
      cipher.setMode(AESMode.ofb64Gctr);
      Uint8List resultEncrypt = cipher.encryptText(plainText: plainText);
      String resultdecrypt = cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });

    test("Test (encryptText & decryptText) in SIC mode", () async {
      cipher.setMode(AESMode.sic);
      Uint8List resultEncrypt = cipher.encryptText(plainText: plainText);
      String resultdecrypt = cipher.decryptText(bytes: resultEncrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      resultdecrypt: $resultdecrypt
      """);

      expect(resultdecrypt, equals(plainText));
    });
  });

  group("File Encryption Group:", () {
    const String path = './test/data.txt';
    Uint8List data = File(path).readAsBytesSync();
    const String checksum =
        '93b9736fe1f6177e1932aa93e884119308a9259b8f29d8e8064110e544ce57f2';

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
      String fileDecryptChecksum = await getFileChecksum(resultdecrypt);

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
      String fileDecryptChecksum = getTextChecksumString(resultdecrypt);

      printDebug("""
      resultEncrypt: $resultEncrypt
      fileDecryptChecksum: $fileDecryptChecksum
      """);

      expect(resultdecrypt, equals(data));
    });
  });
}
