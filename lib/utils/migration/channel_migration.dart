// lib/utils/migration/channel_migration.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChannelMigration {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check if migration is needed
  Future<bool> needsMigration() async {
    try {
      debugPrint('🔍 Checking if migration is needed...');
      
      final snapshot = await _firestore
          .collection('channels')
          .where('isActive', isEqualTo: true)
          .limit(5)
          .get();

      if (snapshot.docs.isEmpty) {
        debugPrint('✅ No channels found - migration not needed');
        return false;
      }

      for (final doc in snapshot.docs) {
        if (!doc.data().containsKey('lastPostAt')) {
          debugPrint('⚠️ Found channel without lastPostAt - migration needed');
          return true;
        }
      }
      
      debugPrint('✅ All channels have lastPostAt - migration not needed');
      return false;
    } catch (e) {
      debugPrint('❌ Error checking migration status: $e');
      return true; // Run migration to be safe
    }
  }

  /// Run the migration
  Future<bool> runMigration() async {
    try {
      debugPrint('🚀 Starting lastPostAt migration...');
      
      // Get all active channels
      final channelsSnapshot = await _firestore
          .collection('channels')
          .where('isActive', isEqualTo: true)
          .get();

      final totalChannels = channelsSnapshot.docs.length;
      debugPrint('📊 Found $totalChannels channels to process');

      if (totalChannels == 0) {
        debugPrint('✅ No channels to migrate');
        return true;
      }

      int updatedCount = 0;
      int skippedCount = 0;

      for (int i = 0; i < channelsSnapshot.docs.length; i++) {
        final channelDoc = channelsSnapshot.docs[i];
        final channelId = channelDoc.id;
        final channelData = channelDoc.data();
        
        debugPrint('🔄 Processing channel $channelId (${i + 1}/$totalChannels)');
        
        // Skip if lastPostAt already exists
        if (channelData.containsKey('lastPostAt')) {
          debugPrint('⏭️ Channel $channelId already has lastPostAt');
          skippedCount++;
          continue;
        }

        try {
          // Find the most recent video for this channel
          final videosSnapshot = await _firestore
              .collection('channelVideos')
              .where('channelId', isEqualTo: channelId)
              .where('isActive', isEqualTo: true)
              .orderBy('createdAt', descending: true)
              .limit(1)
              .get();

          Timestamp? lastPostAt;
          
          if (videosSnapshot.docs.isNotEmpty) {
            lastPostAt = videosSnapshot.docs.first.data()['createdAt'];
            debugPrint('📹 Channel $channelId: Found ${videosSnapshot.docs.length} videos, using latest timestamp');
          } else {
            lastPostAt = null;
            debugPrint('📭 Channel $channelId: No videos found, setting lastPostAt to null');
          }

          // Update the channel
          await _firestore
              .collection('channels')
              .doc(channelId)
              .update({'lastPostAt': lastPostAt});

          updatedCount++;
          debugPrint('✅ Updated channel $channelId ($updatedCount/$totalChannels)');

        } catch (e) {
          debugPrint('❌ Failed to update channel $channelId: $e');
          // Continue with other channels
        }
      }

      debugPrint('🎉 Migration completed!');
      debugPrint('📈 Summary: $updatedCount updated, $skippedCount skipped, $totalChannels total');
      
      return true;

    } catch (e) {
      debugPrint('💥 Migration failed: $e');
      return false;
    }
  }

  /// Main migration method - checks and runs if needed
  Future<bool> migrateIfNeeded() async {
    try {
      final needsMig = await needsMigration();
      
      if (!needsMig) {
        debugPrint('✨ Migration not needed');
        return true;
      }

      debugPrint('🔧 Running migration...');
      return await runMigration();
      
    } catch (e) {
      debugPrint('💥 Migration process failed: $e');
      return false;
    }
  }
}