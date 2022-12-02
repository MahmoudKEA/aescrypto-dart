import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:collection/collection.dart';

import '../utils.dart';
import 'core.dart';

class DataDecoder {
  DataDecoder(this.data, this.iv);

  final List<int> data;
  final IV iv;
}

Uint8List dataEncoder(
  Uint8List key,
  IV iv,
  bool hasSignature,
  bool hasKey, [
  Uint8List? data,
]) {
  return Uint8List.fromList([
    if (hasSignature) ...signatureAES,
    if (hasKey) ...secureKey(key),
    ...iv.bytes,
    if (data != null) ...data,
  ]);
}

DataDecoder dataDeocder(
  Uint8List key,
  Uint8List bytes,
  bool hasSignature,
  bool hasKey,
) {
  final List<int> data = bytes.toList();

  if (hasSignature) {
    if (!data.take(signatureAES.length).toList().equals(signatureAES)) {
      throw Exception("signature doesn't match");
    }
    data.removeRange(0, signatureAES.length);
  }

  if (hasKey) {
    if (!data.take(keyLength).toList().equals(secureKey(key))) {
      throw Exception("the key doesn't match");
    }
    data.removeRange(0, keyLength);
  }

  final IV iv = IV(Uint8List.fromList(data.take(ivLength).toList()));
  data.removeRange(0, ivLength);

  return DataDecoder(data, iv);
}
