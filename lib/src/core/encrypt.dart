import 'dart:isolate';
import 'dart:typed_data';

import 'package:encrypt/encrypt.dart';

import '../../aescrypto.dart';

final ReceivePort _encryptReceivePort = ReceivePort();
SendPort? _encryptSendPort;

final ReceivePort _decryptReceivePort = ReceivePort();
SendPort? _decryptSendPort;

bool _isInitialized = false;

class SendData<O, I> {
  SendData(this.cipher, this.data, this.sendPort);

  final Cipher cipher;
  final I data;
  final SendPort sendPort;

  Type get input => I;

  Type get output => O;
}

class SendPorts {
  SendPorts(this.encryptPort, this.decryptPort);

  final SendPort encryptPort;
  final SendPort decryptPort;
}

Future<void> _initialize() async {
  await Isolate.spawn<SendPorts>(
    (ports) {
      final ReceivePort encryptPort = ReceivePort();
      ports.encryptPort.send(encryptPort.sendPort);
      encryptPort.listen((message) => _encryptListener(message));

      final ReceivePort decryptPort = ReceivePort();
      ports.decryptPort.send(decryptPort.sendPort);
      decryptPort.listen((message) => _decryptListener(message));
    },
    SendPorts(_encryptReceivePort.sendPort, _decryptReceivePort.sendPort),
  );

  _encryptSendPort = await _encryptReceivePort.first;
  _decryptSendPort = await _decryptReceivePort.first;
  _isInitialized = true;
}

void _encryptListener(SendData sendData) {
  try {
    sendData.sendPort.send(
      sendData.input == String
          ? sendData.cipher.encrypter
              .encrypt(sendData.data, iv: sendData.cipher.iv)
              .bytes
          : sendData.cipher.encrypter
              .encryptBytes(sendData.data, iv: sendData.cipher.iv)
              .bytes,
    );
  } catch (error, message) {
    sendData.sendPort.send(
      FormatException('${error.toString()} ${message.toString()}'),
    );
  }
}

Future<Uint8List> encrypt<T>(Cipher cipher, T data) async {
  if (!_isInitialized) await _initialize();

  final ReceivePort receivePort = ReceivePort();
  _encryptSendPort!.send(
    SendData<Uint8List, T>(cipher, data, receivePort.sendPort),
  );

  return receivePort.first.then<Uint8List>((result) {
    if (result is Exception) throw result;

    return result;
  });
}

void _decryptListener(SendData sendData) {
  try {
    sendData.sendPort.send(
      sendData.output == String
          ? sendData.cipher.encrypter
              .decrypt(Encrypted(sendData.data), iv: sendData.cipher.iv)
          : sendData.cipher.encrypter
              .decryptBytes(Encrypted(sendData.data), iv: sendData.cipher.iv),
    );
  } catch (error, message) {
    sendData.sendPort.send(
      FormatException('${error.toString()} ${message.toString()}'),
    );
  }
}

Future<T> decrypt<T>(Cipher cipher, Uint8List data) async {
  if (!_isInitialized) await _initialize();

  final ReceivePort receivePort = ReceivePort();
  _decryptSendPort!.send(
    SendData<T, Uint8List>(cipher, data, receivePort.sendPort),
  );

  return receivePort.first.then<T>((result) {
    if (result is Exception) throw result;

    return result;
  });
}
