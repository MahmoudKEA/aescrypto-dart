import 'dart:io';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import '../models.dart';
import '../utils.dart';
import 'core.dart';

Future<void> encryptFileCore(
  Uint8List key,
  AESMode mode,
  ProgressState state,
  ProgressCallback callback,
  RandomAccessFile srcFile,
  RandomAccessFile outputFile,
  bool hasKey,
) async {
  final Cipher cipher = newCipher(key, mode, padding: null);

  final int size = await srcFile.length();
  await outputFile.writeFrom(sizePacked(size));
  await outputFile.writeFrom(dataEncoder(key, cipher.iv, true, hasKey));

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
      await encrypt<Uint8List>(cipher, chunk),
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
  final DataDecoder dataDecoded = dataDeocder(key, metadata, true, hasKey);

  final Cipher cipher = newCipher(key, mode, iv: dataDecoded.iv, padding: null);

  while (state.isRunning) {
    final Uint8List chunk = await srcFile.read(chunkSize);
    final int chunkLength = chunk.length;

    if (chunkLength == 0) {
      state.stop();
      continue;
    }

    await outputFile.writeFrom(
      await decrypt<List<int>>(cipher, chunk),
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
