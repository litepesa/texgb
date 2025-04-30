import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../domain/models/status_post.dart';
import 'status_media_dto.dart';
import 'status_privacy_dto.dart';
import 'status_comment_dto.dart';
import 'status_reaction_dto.dart';

part 'status_post_dto.freezed.dart';
part 'status_post_dto.g.dart';

@freezed
class StatusPostDTO with _$StatusPostDTO {
  const factory StatusPostDTO({
    required String id,
    required String authorId,
    required String authorName,
    required String authorImage,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) 
    required DateTime createdAt,
    @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson) 
    required DateTime expiresAt,
    required String content,
    required List<StatusMediaDTO> media,
    required StatusPrivacyDTO privacy,
    @Default([]) List<StatusCommentDTO> comments,
    @Default([]) List<StatusReactionDTO> reactions,
    @Default([]) List<String> viewerIds,
    @Default(0) int viewCount,
    @Default(false) bool isEdited,
    String? location,
    String? linkUrl,
    String? linkPreviewImage,
    String? linkPreviewTitle,
    String? linkPreviewDescription,
    String? shareSource,
    String? shareSourcePostId,
  }) = _StatusPostDTO;

  factory StatusPostDTO.fromJson(Map<String, dynamic> json) => _$StatusPostDTOFromJson(json);

  factory StatusPostDTO.fromDomain(StatusPost domain) {
    return StatusPostDTO(
      id: domain.id,
      authorId: domain.authorId,
      authorName: domain.authorName,
      authorImage: domain.authorImage,
      createdAt: domain.createdAt,
      expiresAt: domain.expiresAt,
      content: domain.content,
      media: domain.media
          .map((media) => StatusMediaDTO.fromDomain(media))
          .toList(),
      privacy: StatusPrivacyDTO.fromDomain(domain.privacy),
      comments: domain.comments
          .map((comment) => StatusCommentDTO.fromDomain(comment))
          .toList(),
      reactions: domain.reactions
          .map((reaction) => StatusReactionDTO.fromDomain(reaction))
          .toList(),
      viewerIds: domain.viewerIds,
      viewCount: domain.viewCount,
      isEdited: domain.isEdited,
      location: domain.location,
      linkUrl: domain.linkUrl,
      linkPreviewImage: domain.linkPreviewImage,
      linkPreviewTitle: domain.linkPreviewTitle,
      linkPreviewDescription: domain.linkPreviewDescription,
      shareSource: domain.shareSource,
      shareSourcePostId: domain.shareSourcePostId,
    );
  }

  StatusPost toDomain() {
    return StatusPost(
      id: id,
      authorId: authorId,
      authorName: authorName,
      authorImage: authorImage,
      createdAt: createdAt,
      expiresAt: expiresAt,
      content: content,
      media: media.map((dto) => dto.toDomain()).toList(),
      privacy: privacy.toDomain(),
      comments: comments.map((dto) => dto.toDomain()).toList(),
      reactions: reactions.map((dto) => dto.toDomain()).toList(),
      viewerIds: viewerIds,
      viewCount: viewCount,
      isEdited: isEdited,
      location: location,
      linkUrl: linkUrl,
      linkPreviewImage: linkPreviewImage,
      linkPreviewTitle: linkPreviewTitle,
      linkPreviewDescription: linkPreviewDescription,
      shareSource: shareSource,
      shareSourcePostId: shareSourcePostId,
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