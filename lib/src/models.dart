import 'package:encrypt/encrypt.dart';

class CipherModel {
  final Encrypter encrypter;
  final IV iv;

  CipherModel(this.encrypter, this.iv);
}
