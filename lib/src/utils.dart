import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:convert/convert.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as pathlib;

import 'core/core.dart';

Uint8List signatureAES = Uint8List.fromList(utf8.encode("AESCrypto"));

Future<String> fileChecksum(String path, {Hash algorithm = sha256}) async {
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

String getHashString(dynamic value, {Hash algorithm = sha256}) {
  if (value is String) {
    value = utf8.encode(value);
  }
  return algorithm.convert(value).toString();
}

Uint8List getHashDigest(dynamic value, {Hash algorithm = sha256}) {
  if (value is String) {
    value = utf8.encode(value);
  }
  return Uint8List.fromList(algorithm.convert(value).bytes);
}

Uint8List secureKey(dynamic key) {
  final String key512 = getHashString(key, algorithm: sha256);
  return getHashDigest(key512, algorithm: sha256);
}

String addAESExtension(String path) {
  return pathlib.prettyUri(path + outputFileExtension);
}

String removeAESExtension(String path) {
  return pathlib.prettyUri(
    path.endsWith(outputFileExtension)
        ? path.substring(0, path.length - outputFileExtension.length)
        : path,
  );
}
