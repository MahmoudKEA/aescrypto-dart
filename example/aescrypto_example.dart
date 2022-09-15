import 'dart:typed_data';

import 'package:aescrypto/aescrypto.dart';
import 'package:encrypt/encrypt.dart';

void main() async {
  AESCrypto cipher = AESCrypto(key: '123456789', mode: AESMode.cbc);

  // Encrypt text
  Uint8List bytes = await cipher.encryptText(plainText: 'plainText');

  // Decrypt text
  String plainText = await cipher.decryptText(bytes: bytes);

  // Encrypt a file
  String outputPathEnc = await cipher.encryptFile(
    path: 'path/to/file.txt', // target file (Required)
    directory: 'output/folder', // putput dir (Default at same srcDir)
    hasKey: true, // include hash key into the file to check when decrypting
    ignoreFileExists: true, // warns or overwrite if file already exists
    removeAfterComplete: true, // remove source file when complete
    progressCallback: (value) {}, // progress rate callback
  );

  // Decrypt a file
  String outputPathDec = await cipher.decryptFile(path: 'path/to/file.txt.aes');

  // Encrypt from memory to file
  String outputPathToEnc = await cipher.encryptToFile(
    data: bytes,
    path: 'path/to/file.txt',
  );

  // Decrypt from file to memory
  Uint8List data = await cipher.decryptFromFile(path: 'path/to/file.txt.aes');
}
