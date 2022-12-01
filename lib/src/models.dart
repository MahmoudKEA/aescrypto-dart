import 'package:encrypt/encrypt.dart';

class Cipher {
  final Encrypter encrypter;
  final IV iv;

  Cipher({
    required this.encrypter,
    required this.iv,
  });
}
