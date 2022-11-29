import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import '../utils.dart';
import 'core.dart';

Uint8List metadataBuilder(
  Uint8List key,
  IV iv,
  bool hasSignature,
  bool hasKey,
) {
  return Uint8List.fromList([
    if (hasSignature) ...signatureAES,
    if (hasKey) ...secureKey(key),
    ...iv.bytes,
  ]);
}

IV metadataChecker(
  Uint8List key,
  List<int> data,
  bool hasSignature,
  bool hasKey,
) {
  if (hasSignature) {
    if (data.take(signatureAES.length).join() != signatureAES.join()) {
      throw Exception("signature doesn't match");
    }
    data.removeRange(0, signatureAES.length);
  }

  if (hasKey) {
    if (data.take(keyLength).join() != secureKey(key).join()) {
      throw Exception("the key doesn't match");
    }
    data.removeRange(0, keyLength);
  }

  final Uint8List iv = Uint8List.fromList(data.take(ivLength).toList());
  data.removeRange(0, ivLength);

  return IV(iv);
}
