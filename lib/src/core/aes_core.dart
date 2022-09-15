import 'dart:io';
import 'dart:typed_data';

import 'package:aescrypto/src/core/constants.dart';
import 'package:aescrypto/src/core/sizepack.dart';
import 'package:aescrypto/src/core/metadata.dart';
import 'package:aescrypto/src/core/progress_callback.dart';
import 'package:aescrypto/src/models.dart';
import 'package:aescrypto/src/utils.dart';
import 'package:encrypt/encrypt.dart';

CipherModel getCipherModel(
  Uint8List key,
  AESMode mode, {
  IV? iv,
  String? padding = 'PKCS7',
}) {
  iv ??= IV.fromSecureRandom(16);

  Encrypter cipher = Encrypter(AES(Key(key), mode: mode, padding: padding));
  return CipherModel(cipher, iv);
}

void encryptFileCore(
  Uint8List key,
  AESMode mode,
  ProgressState state,
  ProgressCallback callback,
  RandomAccessFile srcFile,
  RandomAccessFile outputFile,
  bool hasKey,
) {
  CipherModel cipher = getCipherModel(key, mode, padding: null);

  int size = srcFile.lengthSync();
  outputFile.writeFromSync(sizePacked(size));
  outputFile.writeFromSync(metadataBuilder(key, cipher.iv, true, hasKey));

  while (state.isRunning) {
    Uint8List chunk = srcFile.readSync(chunkSize);
    int chunkLength = chunk.length;

    if (chunkLength == 0) {
      state.stop();
      continue;
    } else if (chunkLength % blockSize != 0) {
      int padSize = blockSize - chunkLength % blockSize;
      chunk = Uint8List.fromList(chunk + List.filled(padSize, padSize));
    }

    outputFile.writeFromSync(
      cipher.encrypter.encryptBytes(chunk.toList(), iv: cipher.iv).bytes,
    );

    callback.updateSync(chunkLength, size);
  }

  outputFile.closeSync();
  srcFile.closeSync();

  // Delete the output file if the process is killed
  if (state.isKilled && outputFile.path.isNotEmpty) {
    File(outputFile.path).deleteSync();
  }
}

void decryptFileCore(
  Uint8List key,
  AESMode mode,
  ProgressState state,
  ProgressCallback callback,
  RandomAccessFile srcFile,
  RandomAccessFile outputFile,
  bool hasKey,
) {
  int size = sizeUnpacked(srcFile.readSync(packedLength));

  Uint8List metadata = srcFile.readSync(
    signatureAES.length + (hasKey ? keyLength : 0) + ivLength,
  );
  IV iv = metadataChecker(key, metadata.toList(), true, hasKey);

  CipherModel cipher = getCipherModel(key, mode, iv: iv, padding: null);

  while (state.isRunning) {
    Uint8List chunk = srcFile.readSync(chunkSize);
    int chunkLength = chunk.length;

    if (chunkLength == 0) {
      state.stop();
      continue;
    }

    outputFile.writeFromSync(
      cipher.encrypter.decryptBytes(Encrypted(chunk), iv: cipher.iv),
    );

    callback.updateSync(chunkLength, size);
  }

  state.isCompleted ? outputFile.truncateSync(size) : null;

  outputFile.closeSync();
  srcFile.closeSync();

  // Delete the output file if the process is killed
  if (state.isKilled && outputFile.path.isNotEmpty) {
    File(outputFile.path).deleteSync();
  }
}
