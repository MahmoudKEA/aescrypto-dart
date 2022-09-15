import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class MemoryFileSystem extends RandomAccessFile {
  List<int> _dataBytes = [];
  int _position = 0;
  bool _isClosed = false;

  @override
  Future<void> close() {
    return Future(() {
      return closeSync();
    });
  }

  @override
  void closeSync() {
    _isClosed = true;
  }

  @override
  Future<RandomAccessFile> flush() {
    return Future(() {
      flushSync();
      return this;
    });
  }

  @override
  void flushSync() {
    _accessibility();
  }

  @override
  Future<int> length() {
    return Future(() {
      return lengthSync();
    });
  }

  @override
  int lengthSync() {
    return _dataBytes.length;
  }

  @override
  Future<RandomAccessFile> lock(
      [FileLock mode = FileLock.exclusive, int start = 0, int end = -1]) {
    return Future(() {
      lockSync(mode, start, end);
      return this;
    });
  }

  @override
  void lockSync(
      [FileLock mode = FileLock.exclusive, int start = 0, int end = -1]) {
    _accessibility();
  }

  @override
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) {
    return Future(() {
      unlockSync(start, end);
      return this;
    });
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {
    _accessibility();
  }

  @override
  String get path => '';

  @override
  Future<int> position() {
    return Future(() {
      return positionSync();
    });
  }

  @override
  int positionSync() {
    return _position;
  }

  @override
  Future<RandomAccessFile> setPosition(int position) {
    return Future(() {
      setPosition(position);
      return this;
    });
  }

  @override
  void setPositionSync(int position) {
    _accessibility();
    _position = position;
  }

  @override
  Future<int> readByte() {
    return Future(() {
      return readByteSync();
    });
  }

  @override
  int readByteSync() {
    if (_position < _dataBytes.length) {
      return _dataBytes[_position++];
    }

    return -1;
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) {
    return Future(() {
      return readIntoSync(buffer, start, end);
    });
  }

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) {
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> read(int count) {
    return Future(() {
      return readSync(count);
    });
  }

  @override
  Uint8List readSync(int count) {
    int pos = min(_dataBytes.length, _position + count);
    List<int> result = [];

    if (_position < _dataBytes.length) {
      result = _dataBytes.getRange(_position, pos).toList();
      _position = pos;
    }

    return Uint8List.fromList(result);
  }

  @override
  Future<RandomAccessFile> truncate(int length) {
    return Future(() {
      truncateSync(length);
      return this;
    });
  }

  @override
  void truncateSync(int length) {
    _accessibility();
    _dataBytes = _dataBytes.take(length).toList();
  }

  @override
  Future<RandomAccessFile> writeByte(int value) {
    return Future(() {
      writeByteSync(value);
      return this;
    });
  }

  @override
  int writeByteSync(int value) {
    _accessibility();
    _dataBytes.add(value);

    return 1;
  }

  @override
  Future<RandomAccessFile> writeFrom(List<int> buffer,
      [int start = 0, int? end]) {
    return Future(() {
      writeFromSync(buffer, start, end);
      return this;
    });
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    _accessibility();
    _dataBytes += buffer;
  }

  @override
  Future<RandomAccessFile> writeString(String string,
      {Encoding encoding = utf8}) {
    return Future(() {
      writeStringSync(string, encoding: encoding);
      return this;
    });
  }

  @override
  void writeStringSync(String string, {Encoding encoding = utf8}) {
    _accessibility();
    _dataBytes += utf8.encode(string);
  }

  void _accessibility() {
    if (_isClosed) {
      throw Exception("unable to access, file is closed");
    }
  }
}
