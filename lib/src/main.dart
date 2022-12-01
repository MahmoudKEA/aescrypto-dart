import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import 'core/core.dart';
import 'models.dart';
import 'utils.dart';

class AESCrypto {
  AESCrypto({required String key, AESMode mode = AESMode.cbc}) {
    _key = secureKey(key);
    _mode = mode;
  }

  late Uint8List _key;
  late AESMode _mode;

  late ProgressState state;
  late ProgressCallback callback;

  void setKey(String key) {
    _key = secureKey(key);
  }

  void setMode(AESMode mode) {
    _mode = mode;
  }

  Uint8List encryptText({
    required String plainText,
    bool hasSignature = false,
    bool hasKey = false,
  }) {
    final Cipher cipher = newCipher(_key, _mode);
    final Encrypted data = cipher.encrypter.encrypt(plainText, iv: cipher.iv);

    return dataBuilder(_key, cipher.iv, hasSignature, hasKey, data.bytes);
  }

  String decryptText({
    required Uint8List bytes,
    bool hasSignature = false,
    bool hasKey = false,
  }) {
    final List<int> data = bytes.toList();

    final IV iv = dataChecker(_key, data, hasSignature, hasKey);
    final Cipher cipher = newCipher(_key, _mode, iv: iv);

    return cipher.encrypter.decrypt(
      Encrypted(Uint8List.fromList(data)),
      iv: cipher.iv,
    );
  }

  Future<String> encryptFile({
    required String path,
    String? directory,
    bool hasKey = true,
    bool ignoreFileExists = false,
    bool removeAfterComplete = false,
    void Function(int value)? progressCallback,
  }) async {
    final String outputPath = await outputPathHandler(
      path,
      directory: directory,
    );
    await fileExistsChecker(outputPath, ignoreFileExists);

    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    final RandomAccessFile srcFile = await File(path).open(
      mode: FileMode.read,
    );
    final RandomAccessFile outputFile = await File(outputPath).open(
      mode: FileMode.writeOnly,
    );

    await encryptFileCore(
      _key,
      _mode,
      state,
      callback,
      srcFile,
      outputFile,
      hasKey,
    );

    if (removeAfterComplete && state.isCompleted) {
      await File(srcFile.path).delete();
    }

    return outputPath;
  }

  Future<String> decryptFile({
    required String path,
    String? directory,
    bool hasKey = true,
    bool ignoreFileExists = false,
    bool removeAfterComplete = false,
    void Function(int value)? progressCallback,
  }) async {
    final String outputPath = await outputPathHandler(
      path,
      directory: directory,
    );
    await fileExistsChecker(outputPath, ignoreFileExists);

    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    final RandomAccessFile srcFile = await File(path).open(
      mode: FileMode.read,
    );
    final RandomAccessFile outputFile = await File(outputPath).open(
      mode: FileMode.writeOnly,
    );

    await decryptFileCore(
      _key,
      _mode,
      state,
      callback,
      srcFile,
      outputFile,
      hasKey,
    );

    if (removeAfterComplete && state.isCompleted) {
      await File(srcFile.path).delete();
    }

    return outputPath;
  }

  Future<String> encryptToFile({
    required Uint8List data,
    required String path,
    bool hasKey = true,
    bool ignoreFileExists = false,
    void Function(int value)? progressCallback,
  }) async {
    final String outputPath = await outputPathHandler(path);
    await fileExistsChecker(outputPath, ignoreFileExists);

    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    final MemoryFileSystem srcFile = MemoryFileSystem();
    await srcFile.writeFrom(data);
    final RandomAccessFile outputFile = await File(outputPath).open(
      mode: FileMode.writeOnly,
    );

    await encryptFileCore(
      _key,
      _mode,
      state,
      callback,
      srcFile,
      outputFile,
      hasKey,
    );

    return outputPath;
  }

  Future<Uint8List> decryptFromFile({
    required String path,
    bool hasKey = true,
    void Function(int value)? progressCallback,
  }) async {
    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    final RandomAccessFile srcFile = await File(path).open(
      mode: FileMode.read,
    );
    final MemoryFileSystem outputFile = MemoryFileSystem(
      removeDataWhenClose: false,
    );

    await decryptFileCore(
      _key,
      _mode,
      state,
      callback,
      srcFile,
      outputFile,
      hasKey,
    );

    final Uint8List result = await outputFile.read(await outputFile.length());
    await outputFile.forceClose();

    return result;
  }
}
