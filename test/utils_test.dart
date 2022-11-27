import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:aescrypto/aescrypto.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';
import 'package:path/path.dart' as pathlib;

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  const String plainText = "plainText";
  final Uint8List textBytes = Uint8List.fromList(utf8.encode("plainText"));

  group("Checksum Group:", () {
    const String path = './test/data.txt';
    Random random = Random();
    File(path).writeAsBytesSync(
      List<int>.generate(100016, (i) => random.nextInt(256)),
    );

    test("Test (fileChecksum) in default sha256 algorithm", () async {
      String result = await fileChecksum(path);

      printDebug("""
      result: $result
      """);

      expect(result.length, equals(64));
    });

    test("Test (fileChecksum) in MD5 algorithm", () async {
      String result = await fileChecksum(path, algorithm: md5);

      printDebug("""
      result: $result
      """);

      expect(result.length, equals(32));
    });
  });

  group("Hash Group:", () {
    const String sha256String =
        '08a9b262078244cb990cb5746a7364bfd0b1ef95f8dd9ab61491edc050a1eb7e';
    const List<int> sha256Digest = [
      8,
      169,
      178,
      98,
      7,
      130,
      68,
      203,
      153,
      12,
      181,
      116,
      106,
      115,
      100,
      191,
      208,
      177,
      239,
      149,
      248,
      221,
      154,
      182,
      20,
      145,
      237,
      192,
      80,
      161,
      235,
      126
    ];

    test("Test (getHashString) by string/bytes value", () {
      String resultByString = getHashString(plainText);
      String resultByBytes = getHashString(textBytes);

      printDebug("""
      resultByString: $resultByString
      resultByBytes: $resultByBytes
      """);

      expect(resultByString, equals(sha256String));
      expect(resultByString, equals(resultByBytes));
    });

    test("Test (getHashBytes) by string/bytes value", () {
      Uint8List resultByString = getHashDigest(plainText);
      Uint8List resultByBytes = getHashDigest(textBytes);

      printDebug("""
      resultByString: $resultByString
      resultByBytes: $resultByBytes
      """);

      expect(resultByString, equals(sha256Digest));
      expect(resultByString, equals(resultByBytes));
    });

    test("Test (createKey)", () {
      const String key = '123456';
      const List<int> hashKey = [
        10,
        146,
        178,
        45,
        56,
        172,
        158,
        21,
        177,
        74,
        21,
        245,
        176,
        46,
        147,
        185,
        79,
        59,
        157,
        182,
        52,
        153,
        106,
        19,
        240,
        143,
        0,
        128,
        246,
        172,
        64,
        224
      ];
      Uint8List result = createKey(key);

      printDebug("""
      key: $key
      result: $result
      """);

      expect(result, equals(hashKey));
    });
  });

  group("Path Group:", () {
    String path = pathlib.prettyUri('./test/data.txt');

    test("Test (addAESExtension & removeAESExtension)", () {
      String resultWithExtension = addAESExtension(path);
      String resultWithoutExtension = removeAESExtension(resultWithExtension);

      printDebug("""
      resultWithExtension: $resultWithExtension
      resultWithoutExtension: $resultWithoutExtension
      """);

      expect(resultWithExtension, equals('$path.aes'));
      expect(resultWithoutExtension, equals(path));
    });
  });
}
