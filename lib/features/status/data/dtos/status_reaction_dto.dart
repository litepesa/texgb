import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/status_reaction.dart';

part 'status_reaction_dto.freezed.dart';
part 'status_reaction_dto.g.dart';

@freezed
class StatusReactionDTO with _$StatusReactionDTO {
  const factory StatusReactionDTO({
    required String id,
    required String postId,
    required String userId,
    required String userName,
    required String userImage,
    @JsonKey(fromJson: _reactionTypeFromJson, toJson: _reactionTypeToJson)
    required ReactionType type,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) 
    required DateTime createdAt,
  }) = _StatusReactionDTO;

  factory StatusReactionDTO.fromJson(Map<String, dynamic> json) => _$StatusReactionDTOFromJson(json);

  factory StatusReactionDTO.fromDomain(StatusReaction domain) {
    return StatusReactionDTO(
      id: domain.id,
      postId: domain.postId,
      userId: domain.userId,
      userName: domain.userName,
      userImage: domain.userImage,
      type: domain.type,
      createdAt: domain.createdAt,
    );
  }

  StatusReaction toDomain() {
    return StatusReaction(
      id: id,
      postId: postId,
      userId: userId,
      userName: userName,
      userImage: userImage,
      type: type,
      createdAt: createdAt,
    );
  }
}

// Helper methods for DateTime conversion
DateTime _dateTimeFromJson(dynamic timestamp) {
  if (timestamp is Timestamp) {
    return timestamp.toDate();
  } else if (timestamp is String) {
    return DateTime.parse(timestamp);
  }
  return DateTime.now();
}

String _dateTimeToJson(DateTime dateTime) {
  return dateTime.toIso8601String();
}

// Helper methods for ReactionType conversion
ReactionType _reactionTypeFromJson(String value) {
  return ReactionType.values.firstWhere(
    (e) => e.toString().split('.').last == value,
    orElse: () => ReactionType.like,
  );
}

String _reactionTypeToJson(ReactionType type) {
  return type.toString().split('.').last;
}