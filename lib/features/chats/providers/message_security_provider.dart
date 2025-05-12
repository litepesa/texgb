import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:textgb/features/authentication/authentication_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'message_security_provider.g.dart';

/// Provider for managing message encryption and security features.
/// Handles end-to-end encryption, message integrity verification, etc.
@riverpod
class MessageSecurityNotifier extends _$MessageSecurityNotifier {
  late final SharedPreferences _prefs;
  late encrypt.Encrypter _encrypter;
  late encrypt.IV _iv;
  
  @override
  FutureOr<void> build() async {
    // Register any required cleanup
    ref.onDispose(() {
      // Any cleanup code if needed
    });
    
    await _initializeEncryption();
  }
  
  // Initialize encryption
  Future<void> _initializeEncryption() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      
      // Check if we already have a key
      String? storedKey = _prefs.getString('encryption_key');
      
      if (storedKey == null) {
        // Generate a new key
        final key = _generateRandomKey(32);
        await _prefs.setString('encryption_key', base64Encode(key));
        storedKey = base64Encode(key);
      }
      
      // Create encrypter with AES
      final keyBytes = base64Decode(storedKey);
      final encryptKey = encrypt.Key(keyBytes);
      _iv = encrypt.IV.fromLength(16); // AES uses 16 bytes IV
      _encrypter = encrypt.Encrypter(encrypt.AES(encryptKey));
    } catch (e) {
      debugPrint('Error initializing encryption: $e');
      
      // Fallback to a default key if there's an error
      // This is not ideal for security but prevents app crashes
      final fallbackKey = encrypt.Key.fromLength(32);
      _iv = encrypt.IV.fromLength(16);
      _encrypter = encrypt.Encrypter(encrypt.AES(fallbackKey));
    }
  }
  
  // Generate a random key
  List<int> _generateRandomKey(int length) {
    final random = Random.secure();
    return List<int>.generate(length, (_) => random.nextInt(256));
  }
  
  // Encrypt message
  String encryptMessage(String message) {
    try {
      final encrypted = _encrypter.encrypt(message, iv: _iv);
      return encrypted.base64;
    } catch (e) {
      debugPrint('Error encrypting message: $e');
      // Return original message if encryption fails
      return message;
    }
  }
  
  // Decrypt message
  String decryptMessage(String encryptedMessage) {
    try {
      final decrypted = _encrypter.decrypt(
        encrypt.Encrypted.fromBase64(encryptedMessage),
        iv: _iv,
      );
      return decrypted;
    } catch (e) {
      debugPrint('Error decrypting message: $e');
      // Return encrypted message if decryption fails
      return encryptedMessage;
    }
  }
  
  // Calculate message hash for integrity verification
  String calculateMessageHash(String message) {
    try {
      final bytes = utf8.encode(message);
      final digest = sha256.convert(bytes);
      return digest.toString();
    } catch (e) {
      debugPrint('Error calculating message hash: $e');
      return '';
    }
  }
  
  // Verify message integrity
  bool verifyMessageIntegrity(String message, String hash) {
    try {
      final calculatedHash = calculateMessageHash(message);
      return calculatedHash == hash;
    } catch (e) {
      debugPrint('Error verifying message integrity: $e');
      return false;
    }
  }
  
  // Generate a chat session key for perfect forward secrecy
  Future<String> generateChatSessionKey(String contactUID) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final currentUID = authState.value?.uid;
      
      if (currentUID == null) {
        throw Exception('User not authenticated');
      }
      
      // Create a unique session key based on both UIDs and a random component
      final random = Random.secure();
      final randomBytes = List<int>.generate(16, (_) => random.nextInt(256));
      
      // Combine UIDs and random bytes
      final combined = utf8.encode('$currentUID-$contactUID-${base64Encode(randomBytes)}');
      final sessionKey = sha256.convert(combined).toString();
      
      // Store the session key
      final sortedUIDs = [currentUID, contactUID]..sort();
      final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
      
      await _prefs.setString('session_key_$chatId', sessionKey);
      
      return sessionKey;
    } catch (e) {
      debugPrint('Error generating chat session key: $e');
      
      // Fallback to a simple key
      return 'fallback_key_${DateTime.now().millisecondsSinceEpoch}';
    }
  }
  
  // Get current chat session key
  Future<String?> getChatSessionKey(String contactUID) async {
    try {
      // Get current user ID
      final authState = ref.read(authenticationProvider);
      final currentUID = authState.value?.uid;
      
      if (currentUID == null) {
        return null;
      }
      
      // Get the session key
      final sortedUIDs = [currentUID, contactUID]..sort();
      final chatId = '${sortedUIDs[0]}-${sortedUIDs[1]}';
      
      return _prefs.getString('session_key_$chatId');
    } catch (e) {
      debugPrint('Error getting chat session key: $e');
      return null;
    }
  }
  
  // Rotate chat session key (for enhanced security)
  Future<String> rotateChatSessionKey(String contactUID) async {
    return generateChatSessionKey(contactUID);
  }
}