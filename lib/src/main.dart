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

  Future<Uint8List> encryptText({
    required String plainText,
    bool hasSignature = false,
    bool hasKey = false,
  }) async {
    final Cipher cipher = newCipher(_key, _mode);
    final Uint8List data = await encrypt<String>(cipher, plainText);

    return dataEncoder(_key, cipher.iv, hasSignature, hasKey, data);
  }

  Future<String> decryptText({
    required Uint8List bytes,
    bool hasSignature = false,
    bool hasKey = false,
  }) async {
    final DataDecoder data = dataDeocder(_key, bytes, hasSignature, hasKey);
    final Cipher cipher = newCipher(_key, _mode, iv: data.iv);

    return decrypt<String>(cipher, Uint8List.fromList(data.data));
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

    final MemoryFileSystem srcFile = MemoryFileSystem(readOnlyData: data);
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
