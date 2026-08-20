import 'dart:convert';
import 'package:crypto/crypto.dart';

import 'security_config.dart';

/// Handles cryptographic hashing of save data to detect external tampering.
class SaveIntegrityManager {
  final SecurityConfig _config;

  SaveIntegrityManager(this._config);

  /// Generates an HMAC SHA-256 hash for the given JSON string.
  String generateHash(String payload) {
    final key = utf8.encode(_config.localSaveSecretKey);
    final bytes = utf8.encode(payload);
    
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(bytes);
    
    return digest.toString();
  }

  /// Packages a raw JSON payload with its integrity hash and a timestamp.
  String packageSaveData(String payload) {
    final hash = generateHash(payload);
    final wrapper = {
      'payload': payload,
      'hash': hash,
      'timestamp': DateTime.now().toUtc().toIso8601String(),
    };
    return jsonEncode(wrapper);
  }

  /// Unpackages and verifies a save file. 
  /// Returns the original payload if valid.
  /// Throws an exception if the file is tampered with or corrupted.
  String extractAndVerify(String packagedJson) {
    try {
      final wrapper = jsonDecode(packagedJson) as Map<String, dynamic>;
      
      final payload = wrapper['payload'] as String?;
      final hash = wrapper['hash'] as String?;
      
      if (payload == null || hash == null) {
        throw const FormatException('Missing payload or hash in save file.');
      }

      final expectedHash = generateHash(payload);
      if (expectedHash != hash) {
        throw const FormatException('Save file integrity check failed! Hash mismatch.');
      }

      return payload;
    } catch (e) {
      // If it fails to parse as a wrapper, it might be an older unhashed save.
      // In a real migration, you'd try to parse it directly. 
      // For this robust implementation, we strictly require the wrapper.
      rethrow;
    }
  }
}
