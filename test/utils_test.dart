import 'dart:convert';
import 'dart:typed_data';

import 'package:aescrypto/aescrypto.dart';
import 'package:crypto/crypto.dart';
import 'package:test/test.dart';

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  const String plainText = "plainText";
  final Uint8List textBytes = utf8.encoder.convert("plainText");

  group("Checksum Group:", () {
    const String path = './test/data.txt';

    test("Test (getFileChecksum) in default sha256 algorithm", () async {
      String result = await getFileChecksum(path);

      printDebug("""
      result: $result
      """);

      expect(
        result,
        equals(
          'be4a441c9a46ecfcb89c55fcf9923997dc9282f72f716cc7680673a0f078195c',
        ),
      );
    });

    test("Test (getFileChecksum) in MD5 algorithm", () async {
      String result = await getFileChecksum(path, algorithm: md5);

      printDebug("""
      result: $result
      """);

      expect(result, equals('d980b0be1be5d4dcca37b61d10bfbd03'));
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

    test("Test (getTextChecksumString) by string/bytes value", () {
      String resultByString = getTextChecksumString(plainText);
      String resultByBytes = getTextChecksumString(textBytes);

      printDebug("""
      resultByString: $resultByString
      resultByBytes: $resultByBytes
      """);

      expect(resultByString, equals(sha256String));
      expect(resultByString, equals(resultByBytes));
    });

    test("Test (getHashBytes) by string/bytes value", () {
      Uint8List resultByString = getTextChecksumBytes(plainText);
      Uint8List resultByBytes = getTextChecksumBytes(textBytes);

      printDebug("""
      resultByString: $resultByString
      resultByBytes: $resultByBytes
      """);

      expect(resultByString, equals(sha256Digest));
      expect(resultByString, equals(resultByBytes));
    });

    test("Test (secureKey)", () {
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
      Uint8List result = secureKey(key);

      printDebug("""
      key: $key
      result: $result
      """);

      expect(result, equals(hashKey));
    });
  });

  group("Path Group:", () {
    String path = Uri.file('./test/data.txt').toFilePath();

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

  group("SecretStringStorage Group:", () {
    SecretStringStorage storage = SecretStringStorage.instance;

    String key1 = '123';
    String key2 = '12345';
    String key3 = '1234567';
    String key4 = '123456789';

    test("Test (readAll) before store data", () {
      Map<String, String>? readAll = storage.readAll();

      printDebug("""
      readAll: $readAll
      """);

      expect(readAll, isNull);
    });

    test("Test (read & write)", () {
      storage.write(key: 'key1', value: key1);
      storage.write(key: 'key2', value: key2);
      storage.write(key: 'key3', value: key3);
      storage.write(key: 'key4', value: key4);

      String? readKey1 = storage.read('key1');
      String? readKey2 = storage.read('key2');
      String? readKey3 = storage.read('key3');
      String? readKey4 = storage.read('key4');
      String? readKey5 = storage.read('key5');

      printDebug("""
      readKey1: $readKey1
      readKey2: $readKey2
      readKey3: $readKey3
      readKey4: $readKey4
      readKey5: $readKey5
      """);

      expect(readKey1, equals(key1));
      expect(readKey2, equals(key2));
      expect(readKey3, equals(key3));
      expect(readKey4, equals(key4));
      expect(readKey5, isNull);
    });

    test("Test (readAll) after data stored", () {
      Map<String, String>? readAll = storage.readAll();

      printDebug("""
      readAll: $readAll
      """);

      expect(readAll?.length, equals(4));
    });

    test("Test (remove)", () {
      bool removeKey4 = storage.remove('key4');
      bool removeKey5 = storage.remove('key5');

      String? readKey4 = storage.read('key4');
      String? readKey5 = storage.read('key5');

      printDebug("""
      removeKey4: $removeKey4
      removeKey5: $removeKey5
      readKey4: $readKey4
      readKey5: $readKey5
      """);

      expect(removeKey4, isTrue);
      expect(removeKey5, isFalse);
      expect(readKey4, isNull);
      expect(readKey5, isNull);
    });

    test("Test (clear)", () {
      storage.clear();

      String? readKey1 = storage.read('key1');
      String? readKey2 = storage.read('key2');
      String? readKey3 = storage.read('key3');

      printDebug("""
      readKey1: $readKey1
      readKey2: $readKey2
      readKey3: $readKey3
      """);

      expect(readKey1, isNull);
      expect(readKey2, isNull);
      expect(readKey3, isNull);
    });
  });
}
