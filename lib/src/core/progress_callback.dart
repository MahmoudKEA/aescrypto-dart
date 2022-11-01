import 'dart:math';

class ProgressState {
  bool _isRunning = true;
  bool _isCompleted = false;
  bool _isKilled = false;

  bool get isRunning => _isRunning;
  bool get isCompleted => _isCompleted;
  bool get isKilled => _isKilled;

  void stop() {
    _isRunning = false;
    _isCompleted = true;
  }

  void kill() {
    _isRunning = false;
    _isKilled = true;
  }
}

class ProgressCallback {
  ProgressCallback(this._callback);

  final void Function(int value)? _callback;

  int sizeProgressed = 0;
  int value = 0;

  void update(int chunkSize, int size) {
    sizeProgressed += chunkSize;
    int currentValue = min((100.0 * sizeProgressed / size), 100.0).toInt();

    if (currentValue != value) {
      value = currentValue;

      if (_callback is Function) {
        _callback!(value);
      }
    }
  }
}
