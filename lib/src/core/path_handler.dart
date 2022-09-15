import 'dart:io';

import 'package:aescrypto/src/core/constants.dart';
import 'package:aescrypto/src/utils.dart';
import 'package:path/path.dart' as pathlib;

void fileExistsChecker(String path, bool ignoreFileExists) {
  if (!ignoreFileExists && File(path).existsSync()) {
    throw FileSystemException("File already exists", path);
  }
}

String outputPathHandler(String path, {String? directory}) {
  if (directory is String) {
    Directory(directory).createSync(recursive: true);
    path = pathlib.join(directory, pathlib.basename(path));
  }

  return path.endsWith(outputFileExtension)
      ? removeExtension(path)
      : addExtension(path);
}
