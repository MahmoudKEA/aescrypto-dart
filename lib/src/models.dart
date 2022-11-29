import 'package:encrypt/encrypt.dart';

class CipherModel {
  final Encrypter encrypter;
  final IV iv;

  CipherModel({
    required this.encrypter,
    required this.iv,
  });
}
