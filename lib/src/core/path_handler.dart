import 'dart:io';

import 'package:path/path.dart' as pathlib;

import '../utils.dart';
import 'core.dart';

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
