import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import 'core/core.dart';
import 'models.dart';
import 'utils.dart';

class AESCrypto {
  late Uint8List _key;
  late AESMode _mode;

  late ProgressState state;
  late ProgressCallback callback;

  AESCrypto({required String key, AESMode mode = AESMode.cbc}) {
    _key = createKey(key);
    _mode = mode;
  }

  void setKey(String key) {
    _key = createKey(key);
  }

  void setMode(AESMode mode) {
    _mode = mode;
  }

  Future<Uint8List> encryptText({
    required String plainText,
    bool hasSignature = false,
    bool hasKey = false,
  }) async {
    final ReceivePort receivePort = ReceivePort();

    Isolate.spawn<SendPort>(
      (sendPort) {
        final CipherModel cipher = getCipherModel(_key, _mode);
        final Uint8List metadata = metadataBuilder(
          _key,
          cipher.iv,
          hasSignature,
          hasKey,
        );

        final Uint8List cipherData = Uint8List.fromList(
          metadata + cipher.encrypter.encrypt(plainText, iv: cipher.iv).bytes,
        );

        sendPort.send(cipherData);
      },
      receivePort.sendPort,
    );

    return await receivePort.first;
  }

  Future<String> decryptText({
    required Uint8List bytes,
    bool hasSignature = false,
    bool hasKey = false,
  }) async {
    final ReceivePort receivePort = ReceivePort();

    Isolate.spawn<SendPort>(
      (sendPort) {
        final List<int> data = bytes.toList();

        final IV iv = metadataChecker(_key, data, hasSignature, hasKey);
        final CipherModel cipher = getCipherModel(_key, _mode, iv: iv);

        final String textData = cipher.encrypter.decrypt(
          Encrypted(Uint8List.fromList(data)),
          iv: cipher.iv,
        );

        sendPort.send(textData);
      },
      receivePort.sendPort,
    );

    return await receivePort.first;
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

    final RandomAccessFile srcFile = MemoryFileSystem();
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
    final RandomAccessFile outputFile = MemoryFileSystem();

    await decryptFileCore(
      _key,
      _mode,
      state,
      callback,
      srcFile,
      outputFile,
      hasKey,
    );

    // MemoryFileSystem still stores its data after closing it
    // inside decryptFileCore
    return await outputFile.read(await outputFile.length());
  }
}
