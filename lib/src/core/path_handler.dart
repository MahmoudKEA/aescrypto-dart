import 'dart:io';

import 'package:path/path.dart' as pathlib;

import '../utils.dart';
import 'core.dart';

Future<void> fileExistsChecker(String path, bool ignoreFileExists) async {
  if (!ignoreFileExists && await File(path).exists()) {
    throw FileSystemException("File already exists", path);
  }
}

Future<String> outputPathHandler(String path, {String? directory}) async {
  if (directory is String) {
    await Directory(directory).create(recursive: true);
    path = pathlib.join(directory, pathlib.basename(path));
  }

  return path.endsWith(outputFileExtension)
      ? removeAESExtension(path)
      : addAESExtension(path);
}
