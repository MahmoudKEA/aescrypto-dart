import 'dart:convert';
import 'dart:typed_data';

import 'package:aescrypto/src/core/memory_file_system.dart';
import 'package:test/test.dart';

const debugging = true;
void printDebug(String message) {
  if (debugging) print(message);
}

void main() {
  const String plainText = "plainText";
  final Uint8List textBytes = utf8.encoder.convert("plainText");

  group("ReadOnly Group:", () {
    final MemoryFileSystem file = MemoryFileSystem(
      bytes: textBytes,
      mode: MemoryFileSystemMode.readOnly,
    );

    test("Test initial values", () async {
      String path = file.path;
      MemoryFileSystemMode mode = file.mode;
      int length = await file.length();
      int position = await file.position();

      printDebug("""
      path: $path
      mode: $mode
      length: $length
      position: $position
      """);

      expect(path, isEmpty);
      expect(mode, equals(MemoryFileSystemMode.readOnly));
      expect(length, equals(textBytes.length));
      expect(position, isZero);
    });

    test("Test (setPosition)", () async {
      int safePosition = textBytes.length - 3;
      await file.setPosition(safePosition);
      int positionInSafePosition = await file.position();
      await file.setPosition(0);
      int positionReset = await file.position();

      printDebug("""
      positionInSafePosition: $positionInSafePosition
      positionReset: $positionReset
      """);

      expect(positionInSafePosition, equals(safePosition));
      expect(positionReset, isZero);
      expect(
        () async => await file.setPosition(textBytes.length + 1),
        throwsException,
      );
    });

    test("Test (readByte)", () async {
      int readByte = await file.readByte();
      int position = await file.position();

      printDebug("""
      readByte: $readByte
      position: $position
      """);

      expect(readByte, equals(textBytes[0]));
      expect(position, equals(1));
    });

    test("Test (read)", () async {
      int length = textBytes.length;
      Uint8List read = await file.read(length);
      int position = await file.position();

      printDebug("""
      read: $read
      position: $position
      """);

      expect(read, equals(textBytes.getRange(1, length)));
      expect(position, equals(length));
    });

    test("Test (read & readByte) with max position", () async {
      int length = textBytes.length;
      int readByte = await file.readByte();
      Uint8List read = await file.read(length);
      int position = await file.position();

      printDebug("""
      readByte: $readByte
      read: $read
      position: $position
      """);

      expect(readByte, equals(-1));
      expect(read, isEmpty);
      expect(position, equals(length));
    });

    test("Test write methods that haven't permission to access", () async {
      int length = textBytes.length;

      expect(() async => await file.flush(), throwsException);
      expect(() async => await file.lock(), throwsException);
      expect(() async => await file.unlock(), throwsException);
      expect(() async => await file.truncate(length), throwsException);
      expect(() async => await file.writeByte(textBytes[0]), throwsException);
      expect(() async => await file.writeFrom(textBytes), throwsException);
      expect(() async => await file.writeString(plainText), throwsException);
    });

    test("Test (close)", () async {
      await file.close();

      expect(() async => await file.length(), throwsException);
      expect(() async => await file.position(), throwsException);
      expect(() async => await file.readByte(), throwsException);
      expect(() async => await file.read(textBytes.length), throwsException);
    });
  });

  group("WriteOnly Group:", () {
    final MemoryFileSystem file = MemoryFileSystem(
      mode: MemoryFileSystemMode.writeOnly,
    );

    test("Test initial values", () async {
      String path = file.path;
      MemoryFileSystemMode mode = file.mode;
      int length = await file.length();
      int position = await file.position();

      printDebug("""
      path: $path
      mode: $mode
      length: $length
      position: $position
      """);

      expect(path, isEmpty);
      expect(mode, equals(MemoryFileSystemMode.writeOnly));
      expect(length, isZero);
      expect(position, isZero);
    });

    test("Test (writeByte)", () async {
      int byte = textBytes[0];
      await file.writeByte(byte);
      int length = await file.length();

      printDebug("""
      length: $length
      """);

      expect(length, equals(1));
    });

    test("Test (writeFrom)", () async {
      int length = textBytes.length;
      List<int> bytes = textBytes.getRange(1, textBytes.length).toList();
      await file.writeFrom(bytes);
      int writeLength = await file.length();

      printDebug("""
      writeLength: $writeLength
      """);

      expect(writeLength, equals(length));
    });

    test("Test (writeString)", () async {
      int length = textBytes.length;
      await file.writeString(plainText);
      int writeLength = await file.length();

      printDebug("""
      writeLength: $writeLength
      """);

      expect(writeLength, equals(length * 2));
    });

    test("Test (truncate)", () async {
      int length = textBytes.length;
      await file.truncate(length);
      await file.setPosition(0);
      int writeLength = await file.length();

      printDebug("""
      writeLength: $writeLength
      """);

      expect(writeLength, equals(length));
    });

    test("Test read methods that haven't permission to access", () async {
      int length = textBytes.length;

      expect(() async => await file.readByte(), throwsException);
      expect(() async => await file.read(length), throwsException);
    });
  });

  group("Read and write Group:", () {
    final MemoryFileSystem file = MemoryFileSystem(
      mode: MemoryFileSystemMode.readAndWrite,
    );

    test("Test initial values", () async {
      String path = file.path;
      MemoryFileSystemMode mode = file.mode;
      int length = await file.length();
      int position = await file.position();

      printDebug("""
      path: $path
      mode: $mode
      length: $length
      position: $position
      """);

      expect(path, isEmpty);
      expect(mode, equals(MemoryFileSystemMode.readAndWrite));
      expect(length, isZero);
      expect(position, isZero);
    });

    test("Test (writeByte)", () async {
      int byte = textBytes[0];
      await file.writeByte(byte);
      int readByte = await file.readByte();
      int length = await file.length();

      printDebug("""
      readByte: $readByte
      length: $length
      """);

      expect(readByte, equals(byte));
      expect(length, equals(1));
    });

    test("Test (writeFrom)", () async {
      int length = textBytes.length;
      List<int> bytes = textBytes.getRange(1, textBytes.length).toList();
      await file.writeFrom(bytes);
      List<int> read = await file.read(length);
      int writeLength = await file.length();

      printDebug("""
      read: $read
      writeLength: $writeLength
      """);

      expect(read, equals(bytes));
      expect(writeLength, equals(length));
    });

    test("Test (writeString)", () async {
      int length = textBytes.length;
      await file.writeString(plainText);
      List<int> read = await file.read(length);
      int writeLength = await file.length();

      printDebug("""
      read: $read
      writeLength: $writeLength
      """);

      expect(read, equals(textBytes));
      expect(writeLength, equals(length * 2));
    });

    test("Test (truncate)", () async {
      int length = textBytes.length;
      await file.truncate(length);
      await file.setPosition(0);
      List<int> read = await file.read(length);
      int writeLength = await file.length();

      printDebug("""
      read: $read
      writeLength: $writeLength
      """);

      expect(read, equals(textBytes));
      expect(writeLength, equals(length));
    });
  });
}
