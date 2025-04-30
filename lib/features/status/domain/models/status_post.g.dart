// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'status_post.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StatusPost _$StatusPostFromJson(Map<String, dynamic> json) => _StatusPost(
      id: json['id'] as String,
      authorId: json['authorId'] as String,
      authorName: json['authorName'] as String,
      authorImage: json['authorImage'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      content: json['content'] as String,
      media: (json['media'] as List<dynamic>)
          .map((e) => StatusMedia.fromJson(e as Map<String, dynamic>))
          .toList(),
      privacy: StatusPrivacy.fromJson(json['privacy'] as Map<String, dynamic>),
      comments: (json['comments'] as List<dynamic>)
          .map((e) => StatusComment.fromJson(e as Map<String, dynamic>))
          .toList(),
      reactions: (json['reactions'] as List<dynamic>)
          .map((e) => StatusReaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      viewerIds:
          (json['viewerIds'] as List<dynamic>).map((e) => e as String).toList(),
      viewCount: (json['viewCount'] as num).toInt(),
      isEdited: json['isEdited'] as bool? ?? false,
      location: json['location'] as String?,
      linkUrl: json['linkUrl'] as String?,
      linkPreviewImage: json['linkPreviewImage'] as String?,
      linkPreviewTitle: json['linkPreviewTitle'] as String?,
      linkPreviewDescription: json['linkPreviewDescription'] as String?,
      shareSource: json['shareSource'] as String?,
      shareSourcePostId: json['shareSourcePostId'] as String?,
    );

Map<String, dynamic> _$StatusPostToJson(_StatusPost instance) =>
    <String, dynamic>{
      'id': instance.id,
      'authorId': instance.authorId,
      'authorName': instance.authorName,
      'authorImage': instance.authorImage,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
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
