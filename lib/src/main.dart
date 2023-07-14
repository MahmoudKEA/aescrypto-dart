import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import 'core/core.dart';
import 'models.dart';
import 'utils.dart';

class AESCrypto {
  AESCrypto({required String key, AESMode mode = AESMode.cbc}) {
    _storage = SecretStringStorage();
    _mode = mode;
    setKey(key);
  }

  late SecretStringStorage _storage;
  late AESMode _mode;

  late ProgressState state;
  late ProgressCallback callback;

  Uint8List get _key => secureKey(_storage.read('key')!);

  void setKey(String key) {
    _storage.write(key: 'key', value: key, overwrite: true);
  }

  void setMode(AESMode mode) {
    _mode = mode;
  }

  Future<Uint8List> encryptText({
    required String plainText,
    bool hasSignature = false,
    bool hasKey = false,
  }) async {
    final Uint8List key = _key;
    final Cipher cipher = newCipher(key, _mode);
    final Uint8List data = await encrypt<String>(cipher, plainText);

    return dataEncoder(key, cipher.iv, hasSignature, hasKey, data);
  }

  Future<String> decryptText({
    required Uint8List bytes,
    bool hasSignature = false,
    bool hasKey = false,
  }) async {
    final Uint8List key = _key;
    final DataDecoder data = dataDecoder(key, bytes, hasSignature, hasKey);
    final Cipher cipher = newCipher(key, _mode, iv: data.iv);

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
      forEncrypt: true,
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
      forEncrypt: false,
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
    final String outputPath = await outputPathHandler(path, forEncrypt: true);
    await fileExistsChecker(outputPath, ignoreFileExists);

    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    final MemoryFileSystem srcFile = MemoryFileSystem(
      bytes: data,
      mode: MemoryFileSystemMode.readOnly,
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
      mode: MemoryFileSystemMode.readAndWrite,
    );
    Uint8List outputBytes = Uint8List(0);

    await decryptFileCore(
      _key,
      _mode,
      state,
      callback,
      srcFile,
      outputFile,
      hasKey,
      onOutputCallback: (bytes) => outputBytes = bytes,
    );

    return outputBytes;
  }
}
