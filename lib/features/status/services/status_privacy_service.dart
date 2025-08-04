// lib/features/status/services/status_privacy_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/enums/enums.dart';

class StatusPrivacyService {
  static const String _privacyTypeKey = 'status_privacy_type';
  static const String _allowedViewersKey = 'status_allowed_viewers';
  static const String _excludedViewersKey = 'status_excluded_viewers';
  static const String _mutedUsersKey = 'status_muted_users';
  static const String _lastSyncTimeKey = 'status_privacy_last_sync';

  // Singleton pattern
  static final StatusPrivacyService _instance = StatusPrivacyService._internal();
  factory StatusPrivacyService() => _instance;
  StatusPrivacyService._internal();

  SharedPreferences? _prefs;

  Future<void> _initPrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Save privacy settings locally
  Future<bool> savePrivacySettings({
    required StatusPrivacyType privacyType,
    required List<String> allowedViewers,
    required List<String> excludedViewers,
    required List<String> mutedUsers,
  }) async {
    try {
      await _initPrefs();
      
      // Save all settings atomically
      final batch = <String, dynamic>{
        _privacyTypeKey: privacyType.name,
        _allowedViewersKey: jsonEncode(allowedViewers),
        _excludedViewersKey: jsonEncode(excludedViewers),
        _mutedUsersKey: jsonEncode(mutedUsers),
        _lastSyncTimeKey: DateTime.now().millisecondsSinceEpoch,
      };

      // Save all at once to ensure consistency
      for (final entry in batch.entries) {
        if (entry.value is String) {
          await _prefs!.setString(entry.key, entry.value);
        } else if (entry.value is int) {
          await _prefs!.setInt(entry.key, entry.value);
        }
      }

      return true;
    } catch (e) {
      print('Error saving privacy settings: $e');
      return false;
    }
  }

  /// Load privacy settings from local storage
  Future<Map<String, dynamic>> loadPrivacySettings() async {
    try {
      await _initPrefs();

      final privacyTypeString = _prefs!.getString(_privacyTypeKey) ?? 'all_contacts';
      final allowedViewersJson = _prefs!.getString(_allowedViewersKey) ?? '[]';
      final excludedViewersJson = _prefs!.getString(_excludedViewersKey) ?? '[]';
      final mutedUsersJson = _prefs!.getString(_mutedUsersKey) ?? '[]';
      final lastSyncTime = _prefs!.getInt(_lastSyncTimeKey) ?? 0;

      return {
        'defaultPrivacy': privacyTypeString,
        'allowedViewers': jsonDecode(allowedViewersJson),
        'excludedViewers': jsonDecode(excludedViewersJson),
        'mutedUsers': jsonDecode(mutedUsersJson),
        'lastSyncTime': lastSyncTime,
      };
    } catch (e) {
      print('Error loading privacy settings: $e');
      // Return default settings on error
      return {
        'defaultPrivacy': 'all_contacts',
        'allowedViewers': <String>[],
        'excludedViewers': <String>[],
        'mutedUsers': <String>[],
        'lastSyncTime': 0,
      };
    }
  }

  /// Update only specific setting
  Future<bool> updatePrivacyType(StatusPrivacyType privacyType) async {
    try {
      await _initPrefs();
      await _prefs!.setString(_privacyTypeKey, privacyType.name);
      await _prefs!.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      print('Error updating privacy type: $e');
      return false;
    }
  }

  /// Update allowed viewers list
  Future<bool> updateAllowedViewers(List<String> allowedViewers) async {
    try {
      await _initPrefs();
      await _prefs!.setString(_allowedViewersKey, jsonEncode(allowedViewers));
      await _prefs!.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      print('Error updating allowed viewers: $e');
      return false;
    }
  }

  /// Update excluded viewers list
  Future<bool> updateExcludedViewers(List<String> excludedViewers) async {
    try {
      await _initPrefs();
      await _prefs!.setString(_excludedViewersKey, jsonEncode(excludedViewers));
      await _prefs!.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      print('Error updating excluded viewers: $e');
      return false;
    }
  }

  /// Update muted users list
  Future<bool> updateMutedUsers(List<String> mutedUsers) async {
    try {
      await _initPrefs();
      await _prefs!.setString(_mutedUsersKey, jsonEncode(mutedUsers));
      await _prefs!.setInt(_lastSyncTimeKey, DateTime.now().millisecondsSinceEpoch);
      return true;
    } catch (e) {
      print('Error updating muted users: $e');
      return false;
    }
  }

  /// Add user to muted list
  Future<bool> muteUser(String userId) async {
    try {
      final settings = await loadPrivacySettings();
      final mutedUsers = List<String>.from(settings['mutedUsers'] ?? []);
      
      if (!mutedUsers.contains(userId)) {
        mutedUsers.add(userId);
        return await updateMutedUsers(mutedUsers);
      }
      return true;
    } catch (e) {
      print('Error muting user: $e');
      return false;
    }
  }

  /// Remove user from muted list
  Future<bool> unmuteUser(String userId) async {
    try {
      final settings = await loadPrivacySettings();
      final mutedUsers = List<String>.from(settings['mutedUsers'] ?? []);
      
      if (mutedUsers.contains(userId)) {
        mutedUsers.remove(userId);
        return await updateMutedUsers(mutedUsers);
      }
      return true;
    } catch (e) {
      print('Error unmuting user: $e');
      return false;
    }
  }

  /// Clear all privacy settings (useful for logout)
  Future<bool> clearPrivacySettings() async {
    try {
      await _initPrefs();
      await _prefs!.remove(_privacyTypeKey);
      await _prefs!.remove(_allowedViewersKey);
      await _prefs!.remove(_excludedViewersKey);
      await _prefs!.remove(_mutedUsersKey);
      await _prefs!.remove(_lastSyncTimeKey);
      return true;
    } catch (e) {
      print('Error clearing privacy settings: $e');
      return false;
    }
  }

  /// Check if settings exist locally
  Future<bool> hasLocalSettings() async {
    try {
      await _initPrefs();
      return _prefs!.containsKey(_privacyTypeKey);
    } catch (e) {
      print('Error checking local settings: $e');
      return false;
    }
  }

  /// Get last sync time
  Future<DateTime?> getLastSyncTime() async {
    try {
      await _initPrefs();
      final timestamp = _prefs!.getInt(_lastSyncTimeKey);
      if (timestamp != null && timestamp > 0) {
        return DateTime.fromMillisecondsSinceEpoch(timestamp);
      }
      return null;
    } catch (e) {
      print('Error getting last sync time: $e');
      return null;
    }
  }

  /// Export settings for backup
  Future<Map<String, dynamic>?> exportSettings() async {
    try {
      final settings = await loadPrivacySettings();
      return {
        ...settings,
        'exportedAt': DateTime.now().toIso8601String(),
        'version': '1.0',
      };
    } catch (e) {
      print('Error exporting settings: $e');
      return null;
    }
  }

  /// Import settings from backup
  Future<bool> importSettings(Map<String, dynamic> settings) async {
    try {
      final privacyType = StatusPrivacyTypeExtension.fromString(
        settings['defaultPrivacy']?.toString() ?? 'all_contacts'
      );
      
      final allowedViewers = List<String>.from(settings['allowedViewers'] ?? []);
      final excludedViewers = List<String>.from(settings['excludedViewers'] ?? []);
      final mutedUsers = List<String>.from(settings['mutedUsers'] ?? []);

      return await savePrivacySettings(
        privacyType: privacyType,
        allowedViewers: allowedViewers,
        excludedViewers: excludedViewers,
        mutedUsers: mutedUsers,
      );
    } catch (e) {
      print('Error importing settings: $e');
      return false;
    }
  }
}