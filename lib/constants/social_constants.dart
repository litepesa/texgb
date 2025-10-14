// lib/shared/constants/social_constants.dart
// Constants for Chat, Groups, and Status features

import 'package:flutter/material.dart';

// ===============================
// CHAT CONSTANTS
// ===============================
class ChatConstants {
  ChatConstants._();

  // Message limits
  static const int maxMessageLength = 4096; // Characters
  static const int maxCaptionLength = 1024; // For media messages
  
  // Media limits
  static const int maxImageSize = 16 * 1024 * 1024; // 16 MB
  static const int maxVideoSize = 100 * 1024 * 1024; // 100 MB
  static const int maxAudioSize = 16 * 1024 * 1024; // 16 MB
  static const int maxDocumentSize = 100 * 1024 * 1024; // 100 MB
  
  // Video limits
  static const int maxVideoDuration = 300; // 5 minutes in seconds
  
  // Audio limits
  static const int maxAudioDuration = 600; // 10 minutes in seconds
  
  // Message features
  static const int maxReplyDepth = 1; // Only one level of replies
  static const int maxForwardCount = 5; // Max messages to forward at once
  
  // Pagination
  static const int messagesPerPage = 50;
  static const int initialMessageLoad = 30;
  
  // Timeouts
  static const Duration messageSendTimeout = Duration(seconds: 30);
  static const Duration messageDeliveryTimeout = Duration(seconds: 60);
  
  // UI Settings
  static const double messageBubbleMaxWidth = 0.75; // 75% of screen width
  static const Duration messageAnimationDuration = Duration(milliseconds: 200);
  
  // Message types display names
  static const Map<String, String> messageTypeDisplayNames = {
    'text': 'Message',
    'image': '📷 Photo',
    'video': '🎥 Video',
    'audio': '🎤 Voice message',
    'document': '📄 Document',
    'location': '📍 Location',
    'contact': '👤 Contact',
    'sticker': '😊 Sticker',
    'gif': '🎬 GIF',
  };
}

// ===============================
// GROUP CONSTANTS
// ===============================
class GroupConstants {
  GroupConstants._();

  // Group limits
  static const int maxMembers = 1024; // WhatsApp limit
  static const int minMembers = 2; // At least 2 members (excluding creator)
  
  // Group info limits
  static const int maxGroupNameLength = 100;
  static const int maxGroupDescriptionLength = 512;
  
  // Media limits
  static const int maxGroupImageSize = 5 * 1024 * 1024; // 5 MB
  static const int maxGroupCoverImageSize = 10 * 1024 * 1024; // 10 MB
  
  // Admin/Moderator limits
  static const int maxAdmins = 50; // Maximum number of admins per group
  static const int maxModerators = 100; // Maximum number of moderators per group
  
  // Pagination
  static const int membersPerPage = 50;
  static const int groupsPerPage = 20;
  static const int postsPerPage = 20;
  
  // Group features
  static const int maxPendingRequests = 100; // Max pending join requests
  static const Duration joinRequestExpiration = Duration(days: 7);
  
  // UI Settings
  static const double groupImageSize = 120.0;
  static const double memberAvatarSize = 50.0;
  static const double groupCoverHeight = 200.0;
  
  // Group post limits (if groups have posts)
  static const int maxGroupPostLength = 5000;
  static const int maxGroupPostImages = 10;
}

// ===============================
// STATUS CONSTANTS
// ===============================
class StatusConstants {
  StatusConstants._();

  // Status limits
  static const int maxStatusDuration = 300; // 5 minutes in seconds (for video)
  static const int maxStatusFileSize = 100 * 1024 * 1024; // 100 MB
  
  // Image status limits
  static const int maxImageStatusSize = 16 * 1024 * 1024; // 16 MB
  
  // Video status limits
  static const int maxVideoStatusSize = 100 * 1024 * 1024; // 100 MB
  static const int maxVideoStatusDuration = 300; // 5 minutes in seconds
  
  // Text status limits
  static const int maxTextStatusLength = 700; // Characters
  
  // Caption limits
  static const int maxCaptionLength = 200; // For media status
  
  // Status expiration
  static const Duration statusExpiration = Duration(hours: 24);
  
  // Pagination
  static const int statusPerPage = 20;
  static const int maxStatusUpdatesPerDay = 50;
  
  // Privacy
  static const int maxSelectedContacts = 500; // For privacy settings
  
  // UI Settings
  static const double statusImageSize = 60.0;
  static const double statusRingWidth = 3.0;
  static const Duration statusTransitionDuration = Duration(milliseconds: 300);
  static const Duration statusDisplayDuration = Duration(seconds: 5); // Auto-advance
  
  // Text status backgrounds (hex colors)
  static const List<String> textStatusBackgrounds = [
    '#FF6B6B', // Red
    '#4ECDC4', // Teal
    '#45B7D1', // Blue
    '#FFA07A', // Light Salmon
    '#98D8C8', // Mint
    '#F7DC6F', // Yellow
    '#BB8FCE', // Purple
    '#85C1E2', // Light Blue
    '#F8B739', // Orange
    '#52B788', // Green
  ];
}

// ===============================
// COMMON SOCIAL CONSTANTS
// ===============================
class SocialConstants {
  SocialConstants._();

  // Common limits
  static const int maxUsernameLength = 50;
  static const int maxBioLength = 160;
  
  // Search
  static const int minSearchQueryLength = 2;
  static const int maxSearchResults = 50;
  static const Duration searchDebounce = Duration(milliseconds: 500);
  
  // Notifications
  static const Duration notificationDuration = Duration(seconds: 3);
  
  // Cache
  static const Duration cacheExpiration = Duration(hours: 1);
  static const int maxCachedChats = 100;
  static const int maxCachedStatuses = 200;
  
  // Network
  static const Duration apiTimeout = Duration(seconds: 30);
  static const int maxRetryAttempts = 3;
  
  // File types
  static const List<String> allowedImageExtensions = [
    'jpg', 'jpeg', 'png', 'gif', 'webp', 'heic'
  ];
  
  static const List<String> allowedVideoExtensions = [
    'mp4', 'mov', 'avi', 'mkv', 'webm', '3gp'
  ];
  
  static const List<String> allowedAudioExtensions = [
    'mp3', 'wav', 'aac', 'm4a', 'ogg', 'opus'
  ];
  
  static const List<String> allowedDocumentExtensions = [
    'pdf', 'doc', 'docx', 'xls', 'xlsx', 'ppt', 'pptx', 'txt', 'zip', 'rar'
  ];
}

// ===============================
// SCREEN ROUTES
// ===============================
class SocialRoutes {
  SocialRoutes._();

  // Chat routes
  static const String chatsTab = '/chats';
  static const String chatDetail = '/chat/detail';
  static const String chatInfo = '/chat/info';
  static const String chatMedia = '/chat/media';
  static const String chatSearch = '/chat/search';
  static const String newChat = '/chat/new';
  static const String selectContacts = '/chat/select-contacts';
  
  // Group routes
  static const String groupsTab = '/groups';
  static const String groupDetail = '/group/detail';
  static const String groupInfo = '/group/info';
  static const String groupMembers = '/group/members';
  static const String groupSettings = '/group/settings';
  static const String groupCreate = '/group/create';
  static const String groupEdit = '/group/edit';
  static const String groupInvite = '/group/invite';
  static const String groupRequests = '/group/requests';
  static const String groupPosts = '/group/posts';
  static const String groupPostDetail = '/group/post/detail';
  
  // Status routes
  static const String statusTab = '/status';
  static const String statusViewer = '/status/viewer';
  static const String statusCreate = '/status/create';
  static const String statusPrivacy = '/status/privacy';
  static const String myStatus = '/status/my';
  
  // Common routes
  static const String userProfile = '/user/profile';
  static const String mediaViewer = '/media/viewer';
  static const String mediaGallery = '/media/gallery';
  static const String contactsList = '/contacts/list';
  static const String blockList = '/settings/block-list';
  static const String privacy = '/settings/privacy';
}

// ===============================
// ERROR MESSAGES
// ===============================
class SocialErrorMessages {
  SocialErrorMessages._();

  // Chat errors
  static const String messageTooLong = 'Message is too long. Maximum ${ChatConstants.maxMessageLength} characters.';
  static const String mediaFileTooLarge = 'File is too large. Maximum size is ';
  static const String videoTooLong = 'Video is too long. Maximum ${ChatConstants.maxVideoDuration ~/ 60} minutes.';
  static const String audioTooLong = 'Audio is too long. Maximum ${ChatConstants.maxAudioDuration ~/ 60} minutes.';
  static const String messageSendFailed = 'Failed to send message. Please try again.';
  static const String invalidFileType = 'This file type is not supported.';
  
  // Group errors
  static const String groupNameTooLong = 'Group name is too long. Maximum ${GroupConstants.maxGroupNameLength} characters.';
  static const String groupDescriptionTooLong = 'Description is too long. Maximum ${GroupConstants.maxGroupDescriptionLength} characters.';
  static const String groupFull = 'This group has reached the maximum number of members (${GroupConstants.maxMembers}).';
  static const String notGroupAdmin = 'You need to be an admin to perform this action.';
  static const String notGroupModerator = 'You need to be a moderator or admin to perform this action.';
  static const String cannotLeaveAsOnlyAdmin = 'You cannot leave the group as the only admin. Please assign another admin first.';
  static const String groupCreateFailed = 'Failed to create group. Please try again.';
  
  // Status errors
  static const String statusTooLong = 'Status is too long. Maximum ${StatusConstants.maxVideoStatusDuration ~/ 60} minutes.';
  static const String statusFileTooLarge = 'Status file is too large. Maximum ${StatusConstants.maxStatusFileSize ~/ (1024 * 1024)} MB.';
  static const String textStatusTooLong = 'Text is too long. Maximum ${StatusConstants.maxTextStatusLength} characters.';
  static const String statusUploadFailed = 'Failed to upload status. Please try again.';
  static const String statusExpired = 'This status has expired.';
  static const String maxStatusReached = 'You have reached the maximum number of status updates for today.';
  
  // Common errors
  static const String networkError = 'Network error. Please check your connection.';
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String permissionDenied = 'Permission denied. Please grant the required permissions.';
  static const String userNotFound = 'User not found.';
  static const String unauthorized = 'You are not authorized to perform this action.';
}

// ===============================
// SUCCESS MESSAGES
// ===============================
class SocialSuccessMessages {
  SocialSuccessMessages._();

  // Chat messages
  static const String messageSent = 'Message sent';
  static const String messageDeleted = 'Message deleted';
  static const String messageStarred = 'Message starred';
  static const String messageUnstarred = 'Message unstarred';
  static const String chatMuted = 'Chat muted';
  static const String chatUnmuted = 'Chat unmuted';
  static const String chatArchived = 'Chat archived';
  static const String chatUnarchived = 'Chat unarchived';
  static const String chatDeleted = 'Chat deleted';
  static const String userBlocked = 'User blocked';
  static const String userUnblocked = 'User unblocked';
  
  // Group messages
  static const String groupCreated = 'Group created successfully';
  static const String groupUpdated = 'Group updated successfully';
  static const String groupDeleted = 'Group deleted';
  static const String memberAdded = 'Member added successfully';
  static const String memberRemoved = 'Member removed';
  static const String memberPromoted = 'Member promoted to admin';
  static const String memberDemoted = 'Member demoted';
  static const String groupLeft = 'You left the group';
  static const String joinRequestSent = 'Join request sent';
  static const String joinRequestAccepted = 'Join request accepted';
  static const String joinRequestRejected = 'Join request rejected';
  
  // Status messages
  static const String statusPosted = 'Status posted successfully';
  static const String statusDeleted = 'Status deleted';
  static const String statusMuted = 'Status updates muted';
  static const String statusUnmuted = 'Status updates unmuted';
  static const String privacyUpdated = 'Privacy settings updated';
}

// ===============================
// COLORS
// ===============================
class SocialColors {
  SocialColors._();

  // Status colors
  static const Color statusSeenColor = Color(0xFFBDBDBD); // Grey
  static const Color statusUnseenColor = Color(0xFF25D366); // WhatsApp green
  static const Color statusOwnColor = Color(0xFF128C7E); // Dark green
  
  // Chat colors
  static const Color sentMessageColor = Color(0xFFDCF8C6); // Light green
  static const Color receivedMessageColor = Color(0xFFFFFFFF); // White
  static const Color messageTimeColor = Color(0xFF667781); // Grey
  
  // Group colors
  static const Color adminBadgeColor = Color(0xFFFFC107); // Amber
  static const Color moderatorBadgeColor = Color(0xFF2196F3); // Blue
  static const Color onlineIndicatorColor = Color(0xFF4CAF50); // Green
  
  // Common colors
  static const Color primaryColor = Color(0xFF25D366); // WhatsApp green
  static const Color accentColor = Color(0xFF128C7E); // Dark green
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange
  static const Color successColor = Color(0xFF4CAF50); // Green
}

// ===============================
// ICONS
// ===============================
class SocialIcons {
  SocialIcons._();

  // Chat icons
  static const IconData chatIcon = Icons.chat_bubble_outline;
  static const IconData sendIcon = Icons.send;
  static const IconData attachIcon = Icons.attach_file;
  static const IconData cameraIcon = Icons.camera_alt;
  static const IconData micIcon = Icons.mic;
  static const IconData emojiIcon = Icons.emoji_emotions_outlined;
  
  // Group icons
  static const IconData groupIcon = Icons.group;
  static const IconData groupAddIcon = Icons.group_add;
  static const IconData adminIcon = Icons.admin_panel_settings;
  static const IconData moderatorIcon = Icons.verified_user;
  
  // Status icons
  static const IconData statusIcon = Icons.donut_large_rounded;
  static const IconData addStatusIcon = Icons.add_circle_outline;
  static const IconData myStatusIcon = Icons.account_circle;
  
  // Common icons
  static const IconData checkIcon = Icons.check;
  static const IconData doubleCheckIcon = Icons.done_all;
  static const IconData pendingIcon = Icons.access_time;
  static const IconData failedIcon = Icons.error_outline;
  static const IconData muteIcon = Icons.volume_off;
  static const IconData pinIcon = Icons.push_pin;
  static const IconData archiveIcon = Icons.archive;
  static const IconData blockIcon = Icons.block;
  static const IconData searchIcon = Icons.search;
  static const IconData moreIcon = Icons.more_vert;
}

// ===============================
// ANIMATION DURATIONS
// ===============================
class SocialAnimations {
  SocialAnimations._();

  static const Duration shortAnimation = Duration(milliseconds: 150);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Specific animations
  static const Duration messageSendAnimation = Duration(milliseconds: 200);
  static const Duration statusTransition = Duration(milliseconds: 300);
  static const Duration swipeAnimation = Duration(milliseconds: 250);
  static const Duration fadeAnimation = Duration(milliseconds: 200);
}