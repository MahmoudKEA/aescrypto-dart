import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class MemoryFileSystem extends RandomAccessFile {
  List<int> _dataBytes = [];
  int _length = 0;
  int _position = 0;
  bool _isClosed = false;

  @override
  Future<void> close() async {
    closeSync();
  }

  @override
  void closeSync() {
    _accessibility();
    _dataBytes.clear();
    _length = 0;
    _position = 0;
    _isClosed = true;
  }

  @override
  Future<RandomAccessFile> flush() async {
    flushSync();
    return this;
  }

  @override
  void flushSync() {
    _accessibility();
  }

  @override
  Future<int> length() async {
    return lengthSync();
  }

  @override
  int lengthSync() {
    _accessibility();
    return _length;
  }

  @override
  Future<RandomAccessFile> lock([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) async {
    lockSync(mode, start, end);
    return this;
  }

  @override
  void lockSync([
    FileLock mode = FileLock.exclusive,
    int start = 0,
    int end = -1,
  ]) {
    _accessibility();
  }

  @override
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) async {
    unlockSync(start, end);
    return this;
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {
    _accessibility();
  }

  @override
  String get path => '';

  @override
  Future<int> position() async {
    return positionSync();
  }

  @override
  int positionSync() {
    _accessibility();
    return _position;
  }

  @override
  Future<RandomAccessFile> setPosition(int position) async {
    setPositionSync(position);
    return this;
  }

  @override
  void setPositionSync(int position) {
    _accessibility();
    _position = position;
  }

  @override
  Future<int> readByte() async {
    return readByteSync();
  }

  @override
  int readByteSync() {
    _accessibility();

    if (_position < _length) {
      return _dataBytes[_position++];
    }

    return -1;
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) async {
    return readIntoSync(buffer, start, end);
  }

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) {
    _accessibility();
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> read(int count) async {
    return readSync(count);
  }

  @override
  Uint8List readSync(int count) {
    _accessibility();
    List<int> result = [];

    if (_position < _length) {
      final int pos = min(_length, _position + count);
      result = _dataBytes.getRange(_position, pos).toList();
      _position = pos;
    }

    return Uint8List.fromList(result);
  }

  @override
  Future<RandomAccessFile> truncate(int length) async {
    truncateSync(length);
    return this;
  }

  @override
  void truncateSync(int length) {
    _accessibility();
    _dataBytes = _dataBytes.take(length).toList();
    _length = length;
  }

  @override
  Future<RandomAccessFile> writeByte(int value) async {
    writeByteSync(value);
    return this;
  }

  @override
  int writeByteSync(int value) {
    _accessibility();
    _dataBytes.add(value);
    _length++;

    return 1;
  }

  @override
  Future<RandomAccessFile> writeFrom(
    List<int> buffer, [
    int start = 0,
    int? end,
  ]) async {
    writeFromSync(buffer, start, end);
    return this;
  }

  @override
  void writeFromSync(List<int> buffer, [int start = 0, int? end]) {
    _accessibility();
    _dataBytes += buffer;
    _length += buffer.length;
  }

  @override
  Future<RandomAccessFile> writeString(
    String string, {
    Encoding encoding = utf8,
  }) async {
    writeStringSync(string, encoding: encoding);
    return this;
  }

  @override
  void writeStringSync(String string, {Encoding encoding = utf8}) {
    _accessibility();
    final List<int> data = encoding.encode(string);
    _dataBytes += data;
    _length += data.length;
  }

  void _accessibility() {
    if (_isClosed) {
      throw Exception("unable to access, file is closed");
    }
  }
}
