import 'dart:convert';
import 'package:crypto/crypto.dart';

class ErrorFingerprint {
  final String hash;
  
  ErrorFingerprint(this.hash);

  factory ErrorFingerprint.generate(String type, String message, String module) {
    // Normalize message to prevent varying memory addresses/timestamps from breaking deduplication
    final normalizedMessage = message
        .replaceAll(RegExp(r'0x[a-fA-F0-9]+'), '<ADDR>')
        .replaceAll(RegExp(r'\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}.*'), '<TIME>');
        
    final raw = '$type:$module:$normalizedMessage';
    final hashBytes = sha256.convert(utf8.encode(raw));
    
    return ErrorFingerprint(hashBytes.toString());
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ErrorFingerprint &&
          runtimeType == other.runtimeType &&
          hash == other.hash;

  @override
  int get hashCode => hash.hashCode;
}
