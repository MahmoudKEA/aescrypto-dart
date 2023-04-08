class ValueTypeError extends TypeError {
  ValueTypeError([this.message]);

  final String? message;

  @override
  String toString() {
    final String name = "TypeError";
    return (message != null) ? "$name: $message" : name;
  }
}

class InvalidKeyError extends Error {
  InvalidKeyError([this.message]);

  final String? message;

  @override
  String toString() {
    final String name = "InvalidKeyError";
    return (message != null) ? "$name: $message" : name;
  }
}
