// lib/features/chat/models/moment_reaction_model.dart
// Updated for PostgreSQL Backend - No Firestore Dependencies

class MomentReactionModel {
  final String momentId;
  final String mediaUrl; // Video URL or first image URL
  final String? thumbnailUrl;
  final String authorName;
  final String authorImage;
  final String content; // Original moment content/caption
  final String reaction; // User's reaction text
  final String timestamp; // RFC3339 string format
  final String mediaType; // 'video' or 'image'

  const MomentReactionModel({
    required this.momentId,
    required this.mediaUrl,
    this.thumbnailUrl,
    required this.authorName,
    required this.authorImage,
    required this.content,
    required this.reaction,
    required this.timestamp,
    required this.mediaType,
  });

  factory MomentReactionModel.fromMap(Map<String, dynamic> map) {
    return MomentReactionModel(
      momentId: _parseString(map['momentId'] ?? map['moment_id']),
      mediaUrl: _parseString(map['mediaUrl'] ?? map['media_url']),
      thumbnailUrl: map['thumbnailUrl'] ?? map['thumbnail_url'],
      authorName: _parseString(map['authorName'] ?? map['author_name']),
      authorImage: _parseString(map['authorImage'] ?? map['author_image']),
      content: _parseString(map['content']),
      reaction: _parseString(map['reaction']),
      timestamp: _parseTimestamp(map['timestamp']),
      mediaType: _parseString(map['mediaType'] ?? map['media_type'] ?? 'image'),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'momentId': momentId,
      'mediaUrl': mediaUrl,
      'thumbnailUrl': thumbnailUrl,
      'authorName': authorName,
      'authorImage': authorImage,
      'content': content,
      'reaction': reaction,
      'timestamp': timestamp,
      'mediaType': mediaType,
    };
  }

  // Helper parsing methods
  static String _parseString(dynamic value) {
    if (value == null) return '';
    return value.toString().trim();
  }

  static String _parseTimestamp(dynamic value) {
    if (value == null) {
      return DateTime.now().toIso8601String();
    }
    
    if (value is String) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) {
        return DateTime.now().toIso8601String();
      }
      
      try {
        final dateTime = DateTime.parse(trimmed);
        return dateTime.toIso8601String();
      } catch (e) {
        return DateTime.now().toIso8601String();
      }
    }
    
    if (value is DateTime) {
      return value.toIso8601String();
    }
    
    // Handle Unix timestamp in milliseconds
    if (value is int) {
      try {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(value);
        return dateTime.toIso8601String();
      } catch (e) {
        return DateTime.now().toIso8601String();
      }
    }
    
    // Handle Unix timestamp in seconds (double)
    if (value is double) {
      try {
        final milliseconds = (value * 1000).round();
        final dateTime = DateTime.fromMillisecondsSinceEpoch(milliseconds);
        return dateTime.toIso8601String();
      } catch (e) {
        return DateTime.now().toIso8601String();
      }
    }
    
    return DateTime.now().toIso8601String();
  }

  MomentReactionModel copyWith({
    String? momentId,
    String? mediaUrl,
    String? thumbnailUrl,
    String? authorName,
    String? authorImage,
    String? content,
    String? reaction,
    String? timestamp,
    String? mediaType,
  }) {
    return MomentReactionModel(
      momentId: momentId ?? this.momentId,
      mediaUrl: mediaUrl ?? this.mediaUrl,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      authorName: authorName ?? this.authorName,
      authorImage: authorImage ?? this.authorImage,
      content: content ?? this.content,
      reaction: reaction ?? this.reaction,
      timestamp: timestamp ?? this.timestamp,
      mediaType: mediaType ?? this.mediaType,
    );
  }

  // Helper methods
  DateTime get timestampDateTime {
    try {
      return DateTime.parse(timestamp);
    } catch (e) {
      return DateTime.now();
    }
  }

  String get timeAgo {
    final now = DateTime.now();
    final reactionTime = timestampDateTime;
    final difference = now.difference(reactionTime);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  bool get isVideo => mediaType.toLowerCase() == 'video';
  
  bool get isImage => mediaType.toLowerCase() == 'image';

  String get displayMediaUrl => thumbnailUrl ?? mediaUrl;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MomentReactionModel &&
        other.momentId == momentId &&
        other.mediaUrl == mediaUrl &&
        other.thumbnailUrl == thumbnailUrl &&
        other.authorName == authorName &&
        other.authorImage == authorImage &&
        other.content == content &&
        other.reaction == reaction &&
        other.timestamp == timestamp &&
        other.mediaType == mediaType;
  }

  @override
  int get hashCode {
    return momentId.hashCode ^
        mediaUrl.hashCode ^
        thumbnailUrl.hashCode ^
        authorName.hashCode ^
        authorImage.hashCode ^
        content.hashCode ^
        reaction.hashCode ^
        timestamp.hashCode ^
        mediaType.hashCode;
  }

  @override
  String toString() {
    return 'MomentReactionModel(momentId: $momentId, authorName: $authorName, reaction: $reaction, mediaType: $mediaType)';
  }
}

// Extension for list operations
extension MomentReactionModelList on List<MomentReactionModel> {
  List<MomentReactionModel> sortByDate({bool descending = true}) {
    final sorted = List<MomentReactionModel>.from(this);
    sorted.sort((a, b) => descending 
        ? b.timestampDateTime.compareTo(a.timestampDateTime)
        : a.timestampDateTime.compareTo(b.timestampDateTime));
    return sorted;
  }
  
  List<MomentReactionModel> get videoReactions =>
      where((reaction) => reaction.isVideo).toList();
  
  List<MomentReactionModel> get imageReactions =>
      where((reaction) => reaction.isImage).toList();
  
  List<MomentReactionModel> filterByAuthor(String authorName) =>
      where((reaction) => 
          reaction.authorName.toLowerCase() == authorName.toLowerCase()).toList();
  
  List<MomentReactionModel> filterByMoment(String momentId) =>
      where((reaction) => reaction.momentId == momentId).toList();
}