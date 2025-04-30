// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_post_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusPostDTO _$StatusPostDTOFromJson(Map<String, dynamic> json) =>
    _StatusPostDTO(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorImage: json['authorImage'] as String,
      createdAt: _dateTimeFromJson(json['createdAt']),
      expiresAt: _dateTimeFromJson(json['expiresAt']),
      content: json['content'] as String,
      media: (json['media'] as List<dynamic>)
          .map((e) => StatusMediaDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      privacy:
          StatusPrivacyDTO.fromJson(json['privacy'] as Map<String, dynamic>),
      comments: (json['comments'] as List<dynamic>?)
              ?.map((e) => StatusCommentDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      reactions: (json['reactions'] as List<dynamic>?)
              ?.map(
                  (e) => StatusReactionDTO.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      viewerIds: (json['viewerIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      viewCount: (json['viewCount'] as num?)?.toInt() ?? 0,
      isEdited: json['isEdited'] as bool? ?? false,
      location: json['location'] as String?,
      linkUrl: json['linkUrl'] as String?,
      linkPreviewImage: json['linkPreviewImage'] as String?,
      linkPreviewTitle: json['linkPreviewTitle'] as String?,
      linkPreviewDescription: json['linkPreviewDescription'] as String?,
      shareSource: json['shareSource'] as String?,
      shareSourcePostId: json['shareSourcePostId'] as String?,
    );

Map<String, dynamic> _$StatusPostDTOToJson(_StatusPostDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorImage': instance.authorImage,
      'createdAt': _dateTimeToJson(instance.createdAt),
      'expiresAt': _dateTimeToJson(instance.expiresAt),
      'content': instance.content,
      'media': instance.media,
      'privacy': instance.privacy,
      'comments': instance.comments,
      'reactions': instance.reactions,
      'viewerIds': instance.viewerIds,
      'viewCount': instance.viewCount,
      'isEdited': instance.isEdited,
      'location': instance.location,
      'linkUrl': instance.linkUrl,
      'linkPreviewImage': instance.linkPreviewImage,
      'linkPreviewTitle': instance.linkPreviewTitle,
      'linkPreviewDescription': instance.linkPreviewDescription,
      'shareSource': instance.shareSource,
      'shareSourcePostId': instance.shareSourcePostId,
    };
