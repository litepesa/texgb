import 'package:textgb/constants.dart';

class ChannelModel {
  final String id;
  final String name;
  final String description;
  final String image;
  final String creatorUID;
  final bool isVerified;
  final List<String> subscribersUIDs;
  final List<String> adminUIDs;
  final String createdAt;
  final String lastPostAt;
  final Map<String, dynamic> settings;
  
  ChannelModel({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.creatorUID,
    required this.isVerified,
    required this.subscribersUIDs,
    required this.adminUIDs,
    required this.createdAt,
    required this.lastPostAt,
    required this.settings,
  });

  // Factory constructor to create ChannelModel from a Map
  factory ChannelModel.fromMap(Map<String, dynamic> map) {
    return ChannelModel(
      id: map[Constants.channelId] ?? '',
      name: map[Constants.channelName] ?? '',
      description: map[Constants.channelDescription] ?? '',
      image: map[Constants.channelImage] ?? '',
      creatorUID: map[Constants.creatorUID] ?? '',
      isVerified: map[Constants.isVerified] ?? false,
      subscribersUIDs: List<String>.from(map[Constants.subscribersUIDs] ?? []),
      adminUIDs: List<String>.from(map[Constants.adminUIDs] ?? []),
      createdAt: map[Constants.createdAt] ?? '',
      lastPostAt: map[Constants.lastPostAt] ?? '',
      settings: Map<String, dynamic>.from(map[Constants.channelSettings] ?? {}),
    );
  }

  // Method to convert ChannelModel to a Map
  Map<String, dynamic> toMap() {
    return {
      Constants.channelId: id,
      Constants.channelName: name,
      Constants.channelDescription: description,
      Constants.channelImage: image,
      Constants.creatorUID: creatorUID,
      Constants.isVerified: isVerified,
      Constants.subscribersUIDs: subscribersUIDs,
      Constants.adminUIDs: adminUIDs,
      Constants.createdAt: createdAt,
      Constants.lastPostAt: lastPostAt,
      Constants.channelSettings: settings,
    };
  }

  // Create a copy of ChannelModel with updated fields
  ChannelModel copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    String? creatorUID,
    bool? isVerified,
    List<String>? subscribersUIDs,
    List<String>? adminUIDs,
    String? createdAt,
    String? lastPostAt,
    Map<String, dynamic>? settings,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      creatorUID: creatorUID ?? this.creatorUID,
      isVerified: isVerified ?? this.isVerified,
      subscribersUIDs: subscribersUIDs ?? this.subscribersUIDs,
      adminUIDs: adminUIDs ?? this.adminUIDs,
      createdAt: createdAt ?? this.createdAt,
      lastPostAt: lastPostAt ?? this.lastPostAt,
      settings: settings ?? this.settings,
    );
  }
}