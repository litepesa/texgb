import 'package:freezed_annotation/freezed_annotation.dart';

part 'status_reaction.freezed.dart';
part 'status_reaction.g.dart';

enum ReactionType {
  like,
  love,
  haha,
  wow,
  sad,
  angry
}

@freezed
class StatusReaction with _$StatusReaction {
  const factory StatusReaction({
    required String id,
    required String postId,
    required String userId,
    required String userName,
    required String userImage,
    required ReactionType type,
    required DateTime createdAt,
  }) = _StatusReaction;

  factory StatusReaction.fromJson(Map<String, dynamic> json) => _$StatusReactionFromJson(json);
  
  // Helper methods
  const StatusReaction._();
  
  // Get emoji representation of the reaction
  String get emoji {
    switch (type) {
      case ReactionType.like:
        return '👍';
      case ReactionType.love:
        return '❤️';
      case ReactionType.haha:
        return '😂';
      case ReactionType.wow:
        return '😮';
      case ReactionType.sad:
        return '😢';
      case ReactionType.angry:
        return '😠';
    }
  }
  
  // Get text description of the reaction
  String get description {
    switch (type) {
      case ReactionType.like:
        return 'like';
      case ReactionType.love:
        return 'love';
      case ReactionType.haha:
        return 'haha';
      case ReactionType.wow:
        return 'wow';
      case ReactionType.sad:
        return 'sad';
      case ReactionType.angry:
        return 'angry';
    }
  }
}