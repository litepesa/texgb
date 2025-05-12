import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/chats/models/draft_message_model.dart';

/// Repository for handling message drafts.
/// Uses SharedPreferences to store drafts locally.
class DraftRepository {
  static const String _draftsKey = 'message_drafts';
  
  // Save a draft message
  Future<void> saveDraft(DraftMessageModel draft) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing drafts
      final Map<String, dynamic> drafts = await _getDraftsMap(prefs);
      
      // Add or update the draft for this contact
      drafts[draft.contactUID] = draft.toMap();
      
      // Save back to shared preferences
      await prefs.setString(_draftsKey, jsonEncode(drafts));
    } catch (e) {
      debugPrint('Error saving draft: $e');
    }
  }
  
  // Get a draft message for a specific contact
  Future<DraftMessageModel?> getDraft(String contactUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all drafts
      final Map<String, dynamic> drafts = await _getDraftsMap(prefs);
      
      // Check if there is a draft for this contact
      if (drafts.containsKey(contactUID)) {
        return DraftMessageModel.fromMap(
          Map<String, dynamic>.from(drafts[contactUID]),
        );
      }
      
      return null;
    } catch (e) {
      debugPrint('Error getting draft: $e');
      return null;
    }
  }
  
  // Delete a draft message for a specific contact
  Future<void> deleteDraft(String contactUID) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all drafts
      final Map<String, dynamic> drafts = await _getDraftsMap(prefs);
      
      // Remove the draft for this contact if it exists
      drafts.remove(contactUID);
      
      // Save back to shared preferences
      await prefs.setString(_draftsKey, jsonEncode(drafts));
    } catch (e) {
      debugPrint('Error deleting draft: $e');
    }
  }
  
  // Get all saved drafts
  Future<List<DraftMessageModel>> getAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get all drafts
      final Map<String, dynamic> drafts = await _getDraftsMap(prefs);
      
      // Convert to list of draft models
      return drafts.entries.map((entry) {
        return DraftMessageModel.fromMap(
          Map<String, dynamic>.from(entry.value),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error getting all drafts: $e');
      return [];
    }
  }
  
  // Clear all drafts
  Future<void> clearAllDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_draftsKey);
    } catch (e) {
      debugPrint('Error clearing all drafts: $e');
    }
  }
  
  // Helper method to get drafts map from shared preferences
  Future<Map<String, dynamic>> _getDraftsMap(SharedPreferences prefs) async {
    final String? draftsJson = prefs.getString(_draftsKey);
    
    if (draftsJson == null || draftsJson.isEmpty) {
      return {};
    }
    
    try {
      return Map<String, dynamic>.from(jsonDecode(draftsJson));
    } catch (e) {
      debugPrint('Error parsing drafts JSON: $e');
      return {};
    }
  }
  
  // Update a draft message with new content
  Future<void> updateDraftContent({
    required String contactUID,
    required String message,
  }) async {
    try {
      // Get existing draft
      final existingDraft = await getDraft(contactUID);
      
      if (existingDraft == null) {
        // Create new draft if none exists
        final newDraft = DraftMessageModel(
          contactUID: contactUID,
          message: message,
          messageType: MessageEnum.text,
          lastEdited: DateTime.now().millisecondsSinceEpoch,
        );
        
        await saveDraft(newDraft);
      } else {
        // Update existing draft
        final updatedDraft = existingDraft.copyWith(
          message: message,
          lastEdited: DateTime.now().millisecondsSinceEpoch,
        );
        
        await saveDraft(updatedDraft);
      }
    } catch (e) {
      debugPrint('Error updating draft content: $e');
    }
  }
  
  // Update draft reply data
  Future<void> updateDraftReply({
    required String contactUID,
    String? repliedMessage,
    String? repliedTo,
    MessageEnum? repliedMessageType,
  }) async {
    try {
      // Get existing draft
      final existingDraft = await getDraft(contactUID);
      
      if (existingDraft == null) {
        // Create new draft if none exists
        final newDraft = DraftMessageModel(
          contactUID: contactUID,
          message: '',
          messageType: MessageEnum.text,
          lastEdited: DateTime.now().millisecondsSinceEpoch,
          repliedMessage: repliedMessage,
          repliedTo: repliedTo,
          repliedMessageType: repliedMessageType,
        );
        
        await saveDraft(newDraft);
      } else {
        // Update existing draft
        final updatedDraft = existingDraft.copyWith(
          repliedMessage: repliedMessage,
          repliedTo: repliedTo,
          repliedMessageType: repliedMessageType,
          lastEdited: DateTime.now().millisecondsSinceEpoch,
        );
        
        await saveDraft(updatedDraft);
      }
    } catch (e) {
      debugPrint('Error updating draft reply: $e');
    }
  }
  
  // Update draft media attachment
  Future<void> updateDraftMedia({
    required String contactUID,
    required String mediaPath,
    required MessageEnum messageType,
    Map<String, dynamic>? attachmentData,
  }) async {
    try {
      // Get existing draft
      final existingDraft = await getDraft(contactUID);
      
      if (existingDraft == null) {
        // Create new draft if none exists
        final newDraft = DraftMessageModel(
          contactUID: contactUID,
          message: '',
          messageType: messageType,
          lastEdited: DateTime.now().millisecondsSinceEpoch,
          mediaPath: mediaPath,
          attachmentData: attachmentData,
        );
        
        await saveDraft(newDraft);
      } else {
        // Update existing draft
        final updatedDraft = existingDraft.copyWith(
          messageType: messageType,
          mediaPath: mediaPath,
          attachmentData: attachmentData,
          lastEdited: DateTime.now().millisecondsSinceEpoch,
        );
        
        await saveDraft(updatedDraft);
      }
    } catch (e) {
      debugPrint('Error updating draft media: $e');
    }
  }
  
  // Clear draft media attachment but keep text
  Future<void> clearDraftMedia(String contactUID) async {
    try {
      // Get existing draft
      final existingDraft = await getDraft(contactUID);
      
      if (existingDraft != null) {
        // Update existing draft to remove media
        final updatedDraft = existingDraft.copyWith(
          messageType: MessageEnum.text,
          mediaPath: null,
          attachmentData: null,
          lastEdited: DateTime.now().millisecondsSinceEpoch,
        );
        
        await saveDraft(updatedDraft);
      }
    } catch (e) {
      debugPrint('Error clearing draft media: $e');
    }
  }
}