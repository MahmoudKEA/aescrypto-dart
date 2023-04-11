import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart';

import 'core/core.dart';
import 'errors.dart';
import 'models.dart';

/// This signature by default is clean text and it's not secure,
/// Recommended to set the encrypted signature in your application
Uint8List signatureAES = utf8.encoder.convert("AESCrypto");

Future<String> getFileChecksum(String path, {Hash algorithm = sha256}) async {
  final RandomAccessFile srcFile = await File(path).open(mode: FileMode.read);

  final AccumulatorSink<Digest> output = AccumulatorSink<Digest>();
  final ByteConversionSink input = algorithm.startChunkedConversion(output);

  while (true) {
    final Uint8List chunk = await srcFile.read(chunkSize);
    final int chunkLength = chunk.length;
    if (chunkLength == 0) {
      input.close();
      break;
    }

    input.add(chunk);
  }

  return output.events.single.toString();
}

String getTextChecksumString(dynamic value, {Hash algorithm = sha256}) {
  if (value is String) {
    value = utf8.encoder.convert(value);
  } else if (value is! List<int>) {
    throw ValueTypeError(
      "Value must be String or List<int>, got ${value.runtimeType}",
    );
  }

  return algorithm.convert(value).toString();
}

Uint8List getTextChecksumBytes(dynamic value, {Hash algorithm = sha256}) {
  if (value is String) {
    value = utf8.encoder.convert(value);
  } else if (value is! List<int>) {
    throw ValueTypeError(
      "Value must be String or List<int>, got ${value.runtimeType}",
    );
  }

  return Uint8List.fromList(algorithm.convert(value).bytes);
}

Uint8List secureKey(dynamic key) {
  final String key512 = getTextChecksumString(key, algorithm: sha512);
  return getTextChecksumBytes(key512, algorithm: sha256);
}

String addAESExtension(String path) {
  return Uri.file(path + outputFileExtension).toFilePath();
}

String removeAESExtension(String path) {
  return Uri.file(
    path.endsWith(outputFileExtension)
        ? path.substring(0, path.length - outputFileExtension.length)
        : path,
  ).toFilePath();
}

class SecretStringStorage {
  SecretStringStorage() {
    final Random random = Random.secure();
    final Uint8List key = getTextChecksumBytes(
      List<int>.generate(30, (i) => random.nextInt(256)),
    );

    _cipher = newCipher(key, AESMode.cbc);
  }

  static final SecretStringStorage instance = SecretStringStorage();
  final Map<String, Uint8List> _values = {};
  late Cipher _cipher;

  Map<String, String>? readAll() {
    if (_values.isEmpty) return null;

    return _values.map<String, String>((k, v) => MapEntry(k, read(k)!));
  }

  String? read(String key) {
    final Uint8List? value = _values[key];

    if (value == null) return null;

    return _cipher.encrypter.decrypt(Encrypted(value), iv: _cipher.iv);
  }

  void write({
    required String key,
    required String value,
    bool overwrite = false,
  }) {
    if (!overwrite && _values[key] != null) {
      throw Exception("SecretStringStorage: The key already exists");
    }

    _values[key] = _cipher.encrypter.encrypt(value, iv: _cipher.iv).bytes;
  }

  bool remove(String key) {
    bool isValid = false;

    if (_values.remove(key) != null) {
      isValid = true;
    }

    return isValid;
  }

  void clear() {
    _values.clear();
  }
}
