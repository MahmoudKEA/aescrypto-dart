import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';
import 'package:collection/collection.dart';

import '../utils.dart';
import 'core.dart';

Uint8List dataBuilder(
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

IV dataChecker(
  Uint8List key,
  List<int> data,
  bool hasSignature,
  bool hasKey,
) {
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

  return iv;
}
