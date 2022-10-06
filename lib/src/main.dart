import 'dart:io';
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
    _key = createKeySync(key);
    _mode = mode;
  }

  void setKey(String key) {
    _key = createKeySync(key);
  }

  void setMode(AESMode mode) {
    _mode = mode;
  }

  Future<Uint8List> encryptText({
    required String plainText,
    bool hasSignature = false,
    bool hasKey = false,
  }) {
    return Future(() {
      return encryptTextSync(
        plainText: plainText,
        hasSignature: hasSignature,
        hasKey: hasKey,
      );
    });
  }

  Uint8List encryptTextSync({
    required String plainText,
    bool hasSignature = false,
    bool hasKey = false,
  }) {
    CipherModel cipher = getCipherModel(_key, _mode);
    Uint8List metadata = metadataBuilder(_key, cipher.iv, hasSignature, hasKey);

    return Uint8List.fromList(
      metadata + cipher.encrypter.encrypt(plainText, iv: cipher.iv).bytes,
    );
  }

  Future<String> decryptText({
    required Uint8List bytes,
    bool hasSignature = false,
    bool hasKey = false,
  }) {
    return Future(() {
      return decryptTextSync(
        bytes: bytes,
        hasSignature: hasSignature,
        hasKey: hasKey,
      );
    });
  }

  String decryptTextSync({
    required Uint8List bytes,
    bool hasSignature = false,
    bool hasKey = false,
  }) {
    List<int> data = bytes.toList();

    IV iv = metadataChecker(_key, data, hasSignature, hasKey);
    CipherModel cipher = getCipherModel(_key, _mode, iv: iv);

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
  }) {
    return Future(() {
      return encryptFileSync(
        path: path,
        directory: directory,
        hasKey: hasKey,
        ignoreFileExists: ignoreFileExists,
        removeAfterComplete: removeAfterComplete,
        progressCallback: progressCallback,
      );
    });
  }

  String encryptFileSync({
    required String path,
    String? directory,
    bool hasKey = true,
    bool ignoreFileExists = false,
    bool removeAfterComplete = false,
    void Function(int value)? progressCallback,
  }) {
    String outputPath = outputPathHandler(path, directory: directory);
    fileExistsChecker(outputPath, ignoreFileExists);

    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    RandomAccessFile srcFile = File(path).openSync(
      mode: FileMode.read,
    );
    RandomAccessFile outputFile = File(outputPath).openSync(
      mode: FileMode.writeOnly,
    );

    encryptFileCore(_key, _mode, state, callback, srcFile, outputFile, hasKey);

    if (removeAfterComplete && state.isCompleted) {
      File(srcFile.path).deleteSync();
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
  }) {
    return Future(() {
      return decryptFileSync(
        path: path,
        directory: directory,
        hasKey: hasKey,
        ignoreFileExists: ignoreFileExists,
        removeAfterComplete: removeAfterComplete,
        progressCallback: progressCallback,
      );
    });
  }

  String decryptFileSync({
    required String path,
    String? directory,
    bool hasKey = true,
    bool ignoreFileExists = false,
    bool removeAfterComplete = false,
    void Function(int value)? progressCallback,
  }) {
    String outputPath = outputPathHandler(path, directory: directory);
    fileExistsChecker(outputPath, ignoreFileExists);

    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    RandomAccessFile srcFile = File(path).openSync(
      mode: FileMode.read,
    );
    RandomAccessFile outputFile = File(outputPath).openSync(
      mode: FileMode.writeOnly,
    );

    decryptFileCore(_key, _mode, state, callback, srcFile, outputFile, hasKey);

    if (removeAfterComplete && state.isCompleted) {
      File(srcFile.path).deleteSync();
    }

    return outputPath;
  }

  Future<String> encryptToFile({
    required Uint8List data,
    required String path,
    bool hasKey = true,
    bool ignoreFileExists = false,
    void Function(int value)? progressCallback,
  }) {
    return Future(() {
      return encryptToFileSync(
        data: data,
        path: path,
        hasKey: hasKey,
        ignoreFileExists: ignoreFileExists,
        progressCallback: progressCallback,
      );
    });
  }

  String encryptToFileSync({
    required Uint8List data,
    required String path,
    bool hasKey = true,
    bool ignoreFileExists = false,
    void Function(int value)? progressCallback,
  }) {
    String outputPath = outputPathHandler(path);
    fileExistsChecker(outputPath, ignoreFileExists);

    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    RandomAccessFile srcFile = MemoryFileSystem()..writeFromSync(data);
    RandomAccessFile outputFile = File(outputPath).openSync(
      mode: FileMode.writeOnly,
    );

    encryptFileCore(_key, _mode, state, callback, srcFile, outputFile, hasKey);

    return outputPath;
  }

  Future<Uint8List> decryptFromFile({
    required String path,
    bool hasKey = true,
    void Function(int value)? progressCallback,
  }) {
    return Future(() {
      return decryptFromFileSync(
        path: path,
        hasKey: hasKey,
        progressCallback: progressCallback,
      );
    });
  }

  Uint8List decryptFromFileSync({
    required String path,
    bool hasKey = true,
    void Function(int value)? progressCallback,
  }) {
    state = ProgressState();
    callback = ProgressCallback(progressCallback);

    RandomAccessFile srcFile = File(path).openSync(
      mode: FileMode.read,
    );
    RandomAccessFile outputFile = MemoryFileSystem();

    decryptFileCore(_key, _mode, state, callback, srcFile, outputFile, hasKey);

    // MemoryFileSystem still stores its data after closing it
    // inside decryptFileCore
    return outputFile.readSync(outputFile.lengthSync());
  }
}
