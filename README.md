# AESCrypto Library
#### This library is designed to encrypt & decrypt plain text and files with AES algorithm
- Designed by: Mahmoud Khalid

## Usage
### Initialize
```dart
import 'package:aescrypto/aescrypto.dart';
import 'package:encrypt/encrypt.dart';

AESCrypto cipher = AESCrypto(key: '123456789', mode: AESMode.cbc);

// Change key or AESMode
cipher.setKey('new password');
cipher.setMode(AESMode.cbc);
```

### Encrypt & decrypt plain text
```dart
// Encrypt text
Uint8List bytes = cipher.encryptText(plainText: 'plainText');

// Decrypt text
String plainText = cipher.decryptText(bytes: bytes);
```

### Encrypt & decrypt a file
```dart
// Encrypt a file
String outputPathEnc = await cipher.encryptFile(
    path: 'path/to/file.txt', // target file (Required)
    directory: 'output/folder', // output dir (Default at same srcDir)
    hasKey: true, // include hash key into the file to check when decrypting
    ignoreFileExists: true, // warns or overwrite if file already exists
    removeAfterComplete: true, // remove source file when complete
    progressCallback: (value) {}, // progress rate callback
);

// Decrypt a file
String outputPathDec = await cipher.decryptFile(path: 'path/to/file.txt.aes');
```

### Encrypt & decrypt between storage and memory
```dart
// Encrypt from memory to file
String outputPathToEnc = await cipher.encryptToFile(
    data: bytes,
    path: 'path/to/file.txt',
);

// Decrypt from file to memory
Uint8List data = await cipher.decryptFromFile(path: 'path/to/file.txt.aes');
```

### ProgressState & ProgressCallback controls
```dart
// Check state
cipher.state.isCompleted;
cipher.state.isKilled;
cipher.state.isRunning;

// Kill state
cipher.state.kill();

// Check progress
cipher.callback.sizeProgressed;
cipher.callback.value;
```

### Utils
```dart
// Default = 'AESCrypto'
signatureAES

// Get file checksum sha256
await getFileChecksum(String path, {Hash algorithm = sha256});

// Get sha256 of string/bytes as string
getTextChecksumString(dynamic value, {Hash algorithm = sha256});

// Get sha256 string/bytes as bytes
getTextChecksumBytes(dynamic value, {Hash algorithm = sha256});

// Create secure key of string/bytes
secureKey(dynamic key);

// Path with AES extension
addAESExtension(String path);

// Path without AES extension
removeAESExtension(String path);

// SecretStringStorage
// Add key
SecretStringStorage.instance.write(key: 'key', value: 'value');
// Read key
SecretStringStorage.instance.read('key');
// Read all keys
SecretStringStorage.instance.readAll();
// Remove key
SecretStringStorage.instance.remove('key');
// Remove all keys
SecretStringStorage.instance.clear();
```
