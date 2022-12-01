import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import '../models.dart';

Cipher newCipher(
  Uint8List key,
  AESMode mode, {
  IV? iv,
  String? padding = 'PKCS7',
}) {
  iv ??= IV.fromSecureRandom(16);

  final Encrypter cipher = Encrypter(
    AES(Key(key), mode: mode, padding: padding),
  );
  return Cipher(encrypter: cipher, iv: iv);
}
