import 'dart:io';

import 'package:path/path.dart' as pathlib;

import '../utils.dart';

Future<void> fileExistsChecker(String path, bool ignoreFileExists) async {
  if (!ignoreFileExists && await File(path).exists()) {
    throw FileSystemException("File already exists", path);
  }
}

Future<String> outputPathHandler(
  String path, {
  String? directory,
  required bool forEncrypt,
}) async {
  if (directory != null) {
    await Directory(directory).create(recursive: true);
    path = pathlib.join(directory, pathlib.basename(path));
  }

  return forEncrypt ? addAESExtension(path) : removeAESExtension(path);
}
