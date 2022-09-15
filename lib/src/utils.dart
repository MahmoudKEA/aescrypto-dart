import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:aescrypto/src/core/constants.dart';
import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as pathlib;

Uint8List signatureAES = Uint8List.fromList("AESCrypto".codeUnits);

Future<String> fileChecksum(String path, {Hash algorithm = sha256}) {
  return Future(() {
    return fileChecksumSync(path, algorithm: algorithm);
  });
}

String fileChecksumSync(String path, {Hash algorithm = sha256}) {
  RandomAccessFile srcFile = File(path).openSync(mode: FileMode.read);

  AccumulatorSink<Digest> output = AccumulatorSink<Digest>();
  ByteConversionSink input = algorithm.startChunkedConversion(output);

  while (true) {
    Uint8List chunk = srcFile.readSync(chunkSize);
    int chunkLength = chunk.length;
    if (chunkLength == 0) {
      input.close();
      break;
    }

    input.add(chunk);
  }

  return output.events.single.toString();
}

Future<String> getHashString(dynamic value, {Hash algorithm = sha256}) {
  return Future(() {
    return getHashStringSync(value, algorithm: algorithm);
  });
}

String getHashStringSync(dynamic value, {Hash algorithm = sha256}) {
  if (value is String) {
    value = utf8.encode(value);
  }
  return algorithm.convert(value).toString();
}

Future<Uint8List> getHashDigest(dynamic value, {Hash algorithm = sha256}) {
  return Future(() {
    return getHashDigestSync(value, algorithm: algorithm);
  });
}

Uint8List getHashDigestSync(dynamic value, {Hash algorithm = sha256}) {
  if (value is String) {
    value = utf8.encode(value);
  }
  return Uint8List.fromList(algorithm.convert(value).bytes);
}

Future<Uint8List> createKey(dynamic key) {
  return Future(() {
    return createKeySync(key);
  });
}

Uint8List createKeySync(dynamic key) {
  String key512 = getHashStringSync(key, algorithm: sha512);
  return getHashDigestSync(key512);
}

String addExtension(String path) {
  return pathlib.prettyUri(path + outputFileExtension);
}

String removeExtension(String path) {
  return pathlib.prettyUri(
    path.endsWith(outputFileExtension)
        ? path.substring(0, path.length - outputFileExtension.length)
        : path,
  );
}
