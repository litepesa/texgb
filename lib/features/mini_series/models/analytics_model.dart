// lib/features/mini_series/models/analytics_model.dart
class SeriesAnalyticsModel {
  final String seriesId;
  final int totalViews;
  final int totalLikes;
  final int totalComments;
  final int totalShares;
  final Map<String, int> viewsByEpisode;
  final Map<String, int> likesByEpisode;
  final Map<String, int> commentsByEpisode;
  final Map<String, int> viewsByDate; // Daily views
  final Map<String, int> viewsByCountry;
  final Map<String, int> viewsByAge;
  final Map<String, int> viewsByGender;
  final double averageWatchTime;
  final double retentionRate;
  final DateTime lastUpdated;

  const SeriesAnalyticsModel({
    required this.seriesId,
    this.totalViews = 0,
    this.totalLikes = 0,
    this.totalComments = 0,
    this.totalShares = 0,
    this.viewsByEpisode = const {},
    this.likesByEpisode = const {},
    this.commentsByEpisode = const {},
    this.viewsByDate = const {},
    this.viewsByCountry = const {},
    this.viewsByAge = const {},
    this.viewsByGender = const {},
    this.averageWatchTime = 0.0,
    this.retentionRate = 0.0,
    required this.lastUpdated,
  });

  factory SeriesAnalyticsModel.fromMap(Map<String, dynamic> map) {
    return SeriesAnalyticsModel(
      seriesId: map['seriesId']?.toString() ?? '',
      totalViews: map['totalViews']?.toInt() ?? 0,
      totalLikes: map['totalLikes']?.toInt() ?? 0,
      totalComments: map['totalComments']?.toInt() ?? 0,
      totalShares: map['totalShares']?.toInt() ?? 0,
      viewsByEpisode: Map<String, int>.from(map['viewsByEpisode'] ?? {}),
      likesByEpisode: Map<String, int>.from(map['likesByEpisode'] ?? {}),
      commentsByEpisode: Map<String, int>.from(map['commentsByEpisode'] ?? {}),
      viewsByDate: Map<String, int>.from(map['viewsByDate'] ?? {}),
      viewsByCountry: Map<String, int>.from(map['viewsByCountry'] ?? {}),
      viewsByAge: Map<String, int>.from(map['viewsByAge'] ?? {}),
      viewsByGender: Map<String, int>.from(map['viewsByGender'] ?? {}),
      averageWatchTime: map['averageWatchTime']?.toDouble() ?? 0.0,
      retentionRate: map['retentionRate']?.toDouble() ?? 0.0,
      lastUpdated: DateTime.fromMillisecondsSinceEpoch(
        int.tryParse(map['lastUpdated']?.toString() ?? '0') ?? 0,
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'seriesId': seriesId,
      'totalViews': totalViews,
      'totalLikes': totalLikes,
      'totalComments': totalComments,
      'totalShares': totalShares,
      'viewsByEpisode': viewsByEpisode,
      'likesByEpisode': likesByEpisode,
      'commentsByEpisode': commentsByEpisode,
      'viewsByDate': viewsByDate,
      'viewsByCountry': viewsByCountry,
      'viewsByAge': viewsByAge,
      'viewsByGender': viewsByGender,
      'averageWatchTime': averageWatchTime,
      'retentionRate': retentionRate,
      'lastUpdated': lastUpdated.millisecondsSinceEpoch.toString(),
    };
  }
}