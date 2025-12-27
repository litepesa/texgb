// ===============================
// Moments Privacy Service
// Client-side privacy checks and helpers
// ===============================

import 'package:textgb/features/moments/models/moment_model.dart';
import 'package:textgb/features/moments/models/moment_enums.dart';

class MomentsPrivacyService {
  /// Check if a moment should be visible to the current user
  /// Note: Server-side filtering is primary, this is for UI hints
  static bool canViewMoment({
    required MomentModel moment,
    required String currentUserId,
    required bool isMutualContact,
  }) {
    // Owner can always see their own moments
    if (moment.userId == currentUserId) {
      return true;
    }

    // Must be mutual contacts
    if (!isMutualContact) {
      return false;
    }

    // Check visibility settings
    switch (moment.visibility) {
      case MomentVisibility.private:
        return false;

      case MomentVisibility.custom:
        // Check whitelist
        if (moment.visibleTo.isNotEmpty) {
          return moment.visibleTo.contains(currentUserId);
        }
        // Check blacklist
        if (moment.hiddenFrom.isNotEmpty) {
          return !moment.hiddenFrom.contains(currentUserId);
        }
        return true;

      case MomentVisibility.all:
        return true;
    }
  }

  /// Check if current user can see a specific comment/like
  /// Based on WeChat's privacy bubble - only mutual friends see each other's interactions
  static bool canViewInteraction({
    required String interactionUserId,
    required String momentOwnerId,
    required String currentUserId,
    required List<String> mutualContactIds,
  }) {
    // Owner can see all interactions on their moments
    if (currentUserId == momentOwnerId) {
      return true;
    }

    // User can see their own interactions
    if (currentUserId == interactionUserId) {
      return true;
    }

    // Can only see if both viewer and interaction user are mutual contacts
    return mutualContactIds.contains(momentOwnerId) &&
        mutualContactIds.contains(interactionUserId);
  }

  /// Filter comments based on mutual contacts (privacy bubbles)
  static List<MomentCommentModel> filterVisibleComments({
    required List<MomentCommentModel> comments,
    required String currentUserId,
    required String momentOwnerId,
    required List<String> mutualContactIds,
  }) {
    return comments.where((comment) {
      return canViewInteraction(
        interactionUserId: comment.userId,
        momentOwnerId: momentOwnerId,
        currentUserId: currentUserId,
        mutualContactIds: mutualContactIds,
      );
    }).toList();
  }

  /// Filter likes based on mutual contacts
  static List<MomentLikerModel> filterVisibleLikes({
    required List<MomentLikerModel> likes,
    required String currentUserId,
    required String momentOwnerId,
    required List<String> mutualContactIds,
  }) {
    return likes.where((like) {
      return canViewInteraction(
        interactionUserId: like.userId,
        momentOwnerId: momentOwnerId,
        currentUserId: currentUserId,
        mutualContactIds: mutualContactIds,
      );
    }).toList();
  }

  /// Check if user can view a specific user's timeline
  static bool canViewTimeline({
    required String targetUserId,
    required String currentUserId,
    required bool isMutualContact,
    required MomentPrivacySettings? privacySettings,
  }) {
    // Own timeline is always visible
    if (targetUserId == currentUserId) {
      return true;
    }

    // Must be mutual contacts to see timeline
    if (!isMutualContact) {
      return false;
    }

    // Check if current user is in hiddenFrom list
    if (privacySettings != null &&
        privacySettings.hiddenFrom.contains(currentUserId)) {
      return false;
    }

    return true;
  }

  /// Check if moment passes timeline visibility time constraints
  static bool passesTimelineVisibility({
    required DateTime momentCreatedAt,
    required TimelineVisibility visibility,
  }) {
    final now = DateTime.now();
    final difference = now.difference(momentCreatedAt);

    switch (visibility) {
      case TimelineVisibility.lastThreeDays:
        return difference.inDays <= 3;
      case TimelineVisibility.lastSixMonths:
        return difference.inDays <= 180;
      case TimelineVisibility.all:
        return true;
    }
  }

  /// Get privacy description for UI
  static String getPrivacyDescription(MomentVisibility visibility, {
    int? visibleToCount,
    int? hiddenFromCount,
  }) {
    switch (visibility) {
      case MomentVisibility.all:
        return 'Visible to all contacts';
      case MomentVisibility.private:
        return 'Only visible to you';
      case MomentVisibility.custom:
        if (visibleToCount != null && visibleToCount > 0) {
          return 'Visible to $visibleToCount ${visibleToCount == 1 ? 'contact' : 'contacts'}';
        }
        if (hiddenFromCount != null && hiddenFromCount > 0) {
          return 'Hidden from $hiddenFromCount ${hiddenFromCount == 1 ? 'contact' : 'contacts'}';
        }
        return 'Custom privacy';
    }
  }

  /// Get timeline visibility description
  static String getTimelineVisibilityDescription(TimelineVisibility visibility) {
    switch (visibility) {
      case TimelineVisibility.all:
        return 'All moments visible';
      case TimelineVisibility.lastThreeDays:
        return 'Only last 3 days visible';
      case TimelineVisibility.lastSixMonths:
        return 'Only last 6 months visible';
    }
  }

  /// Validate privacy settings before sending to server
  static String? validatePrivacySettings({
    List<String>? visibleTo,
    List<String>? hiddenFrom,
  }) {
    if (visibleTo != null && visibleTo.length > 1000) {
      return 'Cannot select more than 1000 contacts';
    }
    if (hiddenFrom != null && hiddenFrom.length > 1000) {
      return 'Cannot hide from more than 1000 contacts';
    }
    if (visibleTo != null && hiddenFrom != null &&
        visibleTo.isNotEmpty && hiddenFrom.isNotEmpty) {
      return 'Cannot use both whitelist and blacklist simultaneously';
    }
    return null;
  }
}
