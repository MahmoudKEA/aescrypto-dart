import 'dart:typed_data';

import 'package:aescrypto/src/core/constants.dart';
import 'package:aescrypto/src/utils.dart';
import 'package:encrypt/encrypt.dart';

Uint8List metadataBuilder(
  Uint8List key,
  IV iv,
  bool hasSignature,
  bool hasKey,
) {
  return Uint8List.fromList([
    if (hasSignature) ...signatureAES,
    if (hasKey) ...createKeySync(key),
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
    if (data.take(keyLength).join() != createKeySync(key).join()) {
      throw Exception("the key doesn't match");
    }
    data.removeRange(0, keyLength);
  }

  Uint8List iv = Uint8List.fromList(data.take(ivLength).toList());
  data.removeRange(0, ivLength);

  return IV(iv);
}
