// ===============================
// Status Reaction Models
// Multiple emoji reactions (better than WhatsApp)
// ===============================

class StatusReaction {
  final String id;
  final String statusId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String emoji;
  final DateTime createdAt;

  const StatusReaction({
    required this.id,
    required this.statusId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.emoji,
    required this.createdAt,
  });

  factory StatusReaction.fromJson(Map<String, dynamic> json) {
    return StatusReaction(
      id: json['id'] as String,
      statusId: json['statusId'] as String? ?? json['status_id'] as String,
      userId: json['userId'] as String? ?? json['user_id'] as String,
      userName: json['userName'] as String? ?? json['user_name'] as String,
      userAvatar: json['userAvatar'] as String? ?? json['user_avatar'] as String,
      emoji: json['emoji'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String? ?? json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'statusId': statusId,
      'userId': userId,
      'userName': userName,
      'userAvatar': userAvatar,
      'emoji': emoji,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

// ===============================
// Available Reaction Emojis
// ===============================

class StatusReactionEmojis {
  StatusReactionEmojis._();

  static const List<String> quick = [
    '❤️', // Love
    '😂', // Laughing
    '😮', // Surprised
    '😢', // Sad
    '🔥', // Fire
    '👏', // Clapping
  ];

  static const List<String> all = [
    // Love & Hearts
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🤎', '🖤', '🤍', '💗',
    '💖', '💝', '💘', '💕',

    // Faces - Happy
    '😀', '😃', '😄', '😁', '😆', '😅', '🤣', '😂', '🙂', '🙃',
    '😉', '😊', '😇', '🥰', '😍', '🤩', '😘', '😗', '😚', '😙',

    // Faces - Surprised/Shocked
    '😮', '😯', '😲', '😳', '🤯', '😱',

    // Faces - Sad/Crying
    '😢', '😥', '😭', '😿',

    // Faces - Thinking
    '🤔', '🤨', '🧐',

    // Gestures
    '👍', '👎', '👏', '🙌', '👋', '🤝', '🙏', '💪', '✌️', '🤞',
    '🤟', '🤘', '👌', '🤌', '👈', '👉', '👆', '👇', '☝️',

    // Symbols
    '💯', '🔥', '⭐', '✨', '💫', '⚡', '💥', '💢', '💦', '💨',
    '🎉', '🎊', '🎈', '🎁', '🏆', '🥇', '🥈', '🥉',

    // Other
    '👀', '💀', '👻', '💩', '🤡', '👽', '🤖', '🎯', '💎', '🌟',
  ];

  static String getLabel(String emoji) {
    switch (emoji) {
      case '❤️':
        return 'Love';
      case '😂':
        return 'Haha';
      case '😮':
        return 'Wow';
      case '😢':
        return 'Sad';
      case '🔥':
        return 'Fire';
      case '👏':
        return 'Clap';
      case '👍':
        return 'Like';
      case '💯':
        return '100';
      case '🎉':
        return 'Party';
      case '💪':
        return 'Strong';
      default:
        return emoji;
    }
  }
}

// ===============================
// Reaction Summary (for display)
// ===============================

class ReactionSummary {
  final String emoji;
  final int count;
  final bool reactedByMe;

  const ReactionSummary({
    required this.emoji,
    required this.count,
    this.reactedByMe = false,
  });

  static List<ReactionSummary> fromReactions(
    List<StatusReaction> reactions,
    String currentUserId,
  ) {
    final Map<String, int> emojiCounts = {};
    final Set<String> myReactions = {};

    for (final reaction in reactions) {
      emojiCounts[reaction.emoji] = (emojiCounts[reaction.emoji] ?? 0) + 1;
      if (reaction.userId == currentUserId) {
        myReactions.add(reaction.emoji);
      }
    }

    return emojiCounts.entries
        .map((entry) => ReactionSummary(
              emoji: entry.key,
              count: entry.value,
              reactedByMe: myReactions.contains(entry.key),
            ))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count)); // Sort by count descending
  }
}
