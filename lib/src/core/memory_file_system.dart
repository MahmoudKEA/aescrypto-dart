import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

enum MemoryFileSystemMode { readOnly, writeOnly, readAndWrite }

class MemoryFileSystem implements RandomAccessFile {
  final MemoryFileSystemMode mode;
  late List<int> _bytes;
  int _length = 0;
  int _position = 0;
  bool _isClosed = false;

  MemoryFileSystem({
    Uint8List? bytes,
    this.mode = MemoryFileSystemMode.writeOnly,
  }) {
    _bytes = bytes ?? [];
    _length = bytes?.length ?? 0;
  }

  @override
  String get path => '';

  @override
  Future<void> close() async {
    closeSync();
  }

  @override
  void closeSync() {
    _accessibility();
    _bytes = [];
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
    _accessibility(writable: true);
    throw UnimplementedError();
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
    _accessibility(writable: true);
    throw UnimplementedError();
  }

  @override
  Future<RandomAccessFile> unlock([int start = 0, int end = -1]) async {
    unlockSync(start, end);
    return this;
  }

  @override
  void unlockSync([int start = 0, int end = -1]) {
    _accessibility(writable: true);
    throw UnimplementedError();
  }

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

    if (position > _length) {
      throw Exception("The position exceeds the length of the data");
    }

    _position = position;
  }

  @override
  Future<int> readByte() async {
    return readByteSync();
  }

  @override
  int readByteSync() {
    _accessibility(writable: false);

    if (_position < _length) {
      return _bytes[_position++];
    }

    return -1;
  }

  @override
  Future<int> readInto(List<int> buffer, [int start = 0, int? end]) async {
    return readIntoSync(buffer, start, end);
  }

  @override
  int readIntoSync(List<int> buffer, [int start = 0, int? end]) {
    _accessibility(writable: false);
    throw UnimplementedError();
  }

  @override
  Future<Uint8List> read(int count) async {
    return readSync(count);
  }

  @override
  Uint8List readSync(int count) {
    _accessibility(writable: false);

    Iterable<int> result = [];

    if (_position < _length) {
      final int pos = min(_length, _position + count);
      result = _bytes.getRange(_position, pos);
      _position = pos;
    }

    return Uint8List.fromList(result.toList());
  }

  @override
  Future<RandomAccessFile> truncate(int length) async {
    truncateSync(length);
    return this;
  }

  @override
  void truncateSync(int length) {
    _accessibility(writable: true);
    _bytes.removeRange(length, _length);
    _length = _bytes.length;
  }

  @override
  Future<RandomAccessFile> writeByte(int value) async {
    writeByteSync(value);
    return this;
  }

  @override
  int writeByteSync(int value) {
    _accessibility(writable: true);
    _bytes.add(value);
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
    _accessibility(writable: true);
    _bytes += buffer;
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
    _accessibility(writable: true);
    final List<int> bytes = encoding.encode(string);
    _bytes += bytes;
    _length += bytes.length;
  }

  void _accessibility({bool? writable}) {
    if (writable != null) {
      if (!writable && mode == MemoryFileSystemMode.writeOnly) {
        throw Exception("Permission denied, memory file in write-only mode");
      } else if (writable && mode == MemoryFileSystemMode.readOnly) {
        throw Exception("Permission denied, memory file in read-only mode");
      }
    }

    if (_isClosed) {
      throw Exception("Unable to access, memory file is closed");
    }
  }
}
