import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

class MemoryFileSystem extends RandomAccessFile {
  MemoryFileSystem({
    Uint8List? readOnlyData,
    bool removeDataWhenClose = true,
  }) {
    _readableData = readOnlyData;
    _removeDataWhenClose = removeDataWhenClose;
    _length = readOnlyData?.length ?? 0;
  }

  late Uint8List? _readableData;
  List<int> _writableData = [];
  int _length = 0;
  int _position = 0;
  bool _isClosed = false;
  late bool _removeDataWhenClose;

  bool get isReadOnly => _readableData != null;

  Future<void> forceClose() async {
    forceCloseSync();
  }

  void forceCloseSync() {
    if (_isClosed) return;

    _removeDataWhenClose = true;
    closeSync();
  }

  @override
  Future<void> close() async {
    closeSync();
  }

  @override
  void closeSync() {
    _accessibility();
    _isClosed = true;

    if (_removeDataWhenClose) {
      _readableData = isReadOnly ? Uint8List(0) : null;
      _writableData.clear();
      _length = 0;
      _position = 0;
    }
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
      return (_readableData ?? _writableData)[_position++];
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

    Iterable<int> result = [];

    if (_position < _length) {
      final int pos = min(_length, _position + count);
      result = (_readableData ?? _writableData).getRange(_position, pos);
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
    _writableData = _writableData.take(length).toList();
    _length = length;
  }

  @override
  Future<RandomAccessFile> writeByte(int value) async {
    writeByteSync(value);
    return this;
  }

  @override
  int writeByteSync(int value) {
    _accessibility(writable: true);
    _writableData.add(value);
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
    _writableData += buffer;
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
    final List<int> data = encoding.encode(string);
    _writableData += data;
    _length += data.length;
  }

  void _accessibility({bool writable = false}) {
    if (writable && isReadOnly) {
      throw Exception("Permission denied, memory is read-only");
    }

    if (_isClosed && (writable || _removeDataWhenClose)) {
      throw Exception("Unable to access, file is closed");
    }
  }
}
