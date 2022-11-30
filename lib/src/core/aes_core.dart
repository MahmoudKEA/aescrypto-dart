import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import '../models.dart';
import '../utils.dart';
import 'core.dart';

CipherModel getCipherModel(
  Uint8List key,
  AESMode mode, {
  IV? iv,
  String? padding = 'PKCS7',
}) {
  iv ??= IV.fromSecureRandom(16);

  final Encrypter cipher = Encrypter(
    AES(Key(key), mode: mode, padding: padding),
  );
  return CipherModel(encrypter: cipher, iv: iv);
}

Future<void> encryptFileCore(
  Uint8List key,
  AESMode mode,
  ProgressState state,
  ProgressCallback callback,
  RandomAccessFile srcFile,
  RandomAccessFile outputFile,
  bool hasKey,
) async {
  final CipherModel cipher = getCipherModel(key, mode, padding: null);

  final int size = await srcFile.length();
  await outputFile.writeFrom(sizePacked(size));
  await outputFile.writeFrom(dataBuilder(key, cipher.iv, true, hasKey));

  while (state.isRunning) {
    Uint8List chunk = await srcFile.read(chunkSize);
    final int chunkLength = chunk.length;

    if (chunkLength == 0) {
      state.stop();
      continue;
    } else if (chunkLength % blockSize != 0) {
      final int padSize = blockSize - chunkLength % blockSize;
      chunk = Uint8List.fromList(chunk + List.filled(padSize, padSize));
    }

    await outputFile.writeFrom(
      cipher.encrypter.encryptBytes(chunk.toList(), iv: cipher.iv).bytes,
    );

    callback.update(chunkLength, size);
  }

  await outputFile.close();
  await srcFile.close();

  // Delete the output file if the process is killed
  if (state.isKilled && outputFile.path.isNotEmpty) {
    await File(outputFile.path).delete();
  }
}

Future<void> decryptFileCore(
  Uint8List key,
  AESMode mode,
  ProgressState state,
  ProgressCallback callback,
  RandomAccessFile srcFile,
  RandomAccessFile outputFile,
  bool hasKey,
) async {
  final int size = sizeUnpacked(await srcFile.read(packedLength));

  final Uint8List metadata = await srcFile.read(
    signatureAES.length + (hasKey ? keyLength : 0) + ivLength,
  );
  final IV iv = dataChecker(key, metadata.toList(), true, hasKey);

  final CipherModel cipher = getCipherModel(key, mode, iv: iv, padding: null);

  while (state.isRunning) {
    final Uint8List chunk = await srcFile.read(chunkSize);
    final int chunkLength = chunk.length;

    if (chunkLength == 0) {
      state.stop();
      continue;
    }

    await outputFile.writeFrom(
      cipher.encrypter.decryptBytes(Encrypted(chunk), iv: cipher.iv),
    );

    callback.update(chunkLength, size);
  }

  if (state.isCompleted) {
    await outputFile.truncate(size);
  }

  await outputFile.close();
  await srcFile.close();

  // Delete the output file if the process is killed
  if (state.isKilled && outputFile.path.isNotEmpty) {
    await File(outputFile.path).delete();
  }
}
