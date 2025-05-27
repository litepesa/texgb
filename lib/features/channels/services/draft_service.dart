// lib/features/channels/services/draft_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider/path_provider.dart';

class DraftService extends ChangeNotifier {
  static const String _draftsKey = 'channel_post_drafts';
  static const int _maxDrafts = 10;
  
  List<PostDraft> _drafts = [];
  PostDraft? _currentDraft;
  
  List<PostDraft> get drafts => _drafts;
  PostDraft? get currentDraft => _currentDraft;
  bool get hasDrafts => _drafts.isNotEmpty;

  /// Initialize the draft service
  Future<void> initialize() async {
    await _loadDrafts();
  }

  /// Create a new draft
  PostDraft createDraft() {
    final draft = PostDraft(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    _currentDraft = draft;
    notifyListeners();
    return draft;
  }

  /// Auto-save current draft
  Future<void> autoSaveDraft({
    String? caption,
    List<String>? tags,
    List<String>? mediaPaths,
    bool? isVideo,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentDraft == null) return;

    _currentDraft = _currentDraft!.copyWith(
      caption: caption,
      tags: tags,
      mediaPaths: mediaPaths,
      isVideo: isVideo,
      metadata: metadata,
      updatedAt: DateTime.now(),
    );

    await _saveDraft(_currentDraft!);
    notifyListeners();
  }

  /// Save a draft
  Future<void> _saveDraft(PostDraft draft) async {
    // Remove existing draft with same ID
    _drafts.removeWhere((d) => d.id == draft.id);
    
    // Add updated draft
    _drafts.insert(0, draft);
    
    // Limit number of drafts
    if (_drafts.length > _maxDrafts) {
      final removedDrafts = _drafts.sublist(_maxDrafts);
      _drafts = _drafts.take(_maxDrafts).toList();
      
      // Clean up media files from removed drafts
      for (final removedDraft in removedDrafts) {
        await _cleanupDraftMedia(removedDraft);
      }
    }
    
    await _persistDrafts();
  }

  /// Load a draft for editing
  void loadDraft(PostDraft draft) {
    _currentDraft = draft;
    notifyListeners();
  }

  /// Delete a draft
  Future<void> deleteDraft(String draftId) async {
    final draft = _drafts.firstWhere((d) => d.id == draftId);
    await _cleanupDraftMedia(draft);
    
    _drafts.removeWhere((d) => d.id == draftId);
    
    if (_currentDraft?.id == draftId) {
      _currentDraft = null;
    }
    
    await _persistDrafts();
    notifyListeners();
  }

  /// Complete current draft (after successful post)
  Future<void> completeDraft() async {
    if (_currentDraft != null) {
      await deleteDraft(_currentDraft!.id);
      _currentDraft = null;
    }
  }

  /// Clear current draft without saving
  void clearCurrentDraft() {
    _currentDraft = null;
    notifyListeners();
  }

  /// Load drafts from storage
  Future<void> _loadDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = prefs.getStringList(_draftsKey) ?? [];
      
      _drafts = draftsJson
          .map((json) => PostDraft.fromJson(jsonDecode(json)))
          .toList();
      
      // Sort by updated date (newest first)
      _drafts.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading drafts: $e');
      _drafts = [];
    }
  }

  /// Persist drafts to storage
  Future<void> _persistDrafts() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final draftsJson = _drafts
          .map((draft) => jsonEncode(draft.toJson()))
          .toList();
      
      await prefs.setStringList(_draftsKey, draftsJson);
    } catch (e) {
      debugPrint('Error persisting drafts: $e');
    }
  }

  /// Clean up media files associated with a draft
  Future<void> _cleanupDraftMedia(PostDraft draft) async {
    try {
      for (final mediaPath in draft.mediaPaths) {
        final file = File(mediaPath);
        if (await file.exists()) {
          await file.delete();
        }
      }
    } catch (e) {
      debugPrint('Error cleaning up draft media: $e');
    }
  }

  /// Copy media files to drafts directory
  Future<List<String>> copyMediaToDrafts(List<File> mediaFiles) async {
    final draftsDir = await _getDraftsDirectory();
    final copiedPaths = <String>[];
    
    for (int i = 0; i < mediaFiles.length; i++) {
      try {
        final originalFile = mediaFiles[i];
        final extension = originalFile.path.split('.').last;
        final newFileName = '${DateTime.now().millisecondsSinceEpoch}_$i.$extension';
        final newPath = '${draftsDir.path}/$newFileName';
        
        await originalFile.copy(newPath);
        copiedPaths.add(newPath);
      } catch (e) {
        debugPrint('Error copying media file: $e');
      }
    }
    
    return copiedPaths;
  }

  /// Get or create drafts directory
  Future<Directory> _getDraftsDirectory() async {
    final appDir = await getApplicationDocumentsDirectory();
    final draftsDir = Directory('${appDir.path}/drafts');
    
    if (!await draftsDir.exists()) {
      await draftsDir.create(recursive: true);
    }
    
    return draftsDir;
  }

  /// Clean up old drafts (older than 30 days)
  Future<void> cleanupOldDrafts() async {
    final cutoffDate = DateTime.now().subtract(const Duration(days: 30));
    final oldDrafts = _drafts.where((draft) => draft.updatedAt.isBefore(cutoffDate)).toList();
    
    for (final draft in oldDrafts) {
      await deleteDraft(draft.id);
    }
  }

  @override
  void dispose() {
    _persistDrafts();
    super.dispose();
  }
}

class PostDraft {
  final String id;
  final String caption;
  final List<String> tags;
  final List<String> mediaPaths;
  final bool isVideo;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime updatedAt;

  PostDraft({
    required this.id,
    this.caption = '',
    this.tags = const [],
    this.mediaPaths = const [],
    this.isVideo = false,
    this.metadata = const {},
    required this.createdAt,
    required this.updatedAt,
  });

  PostDraft copyWith({
    String? caption,
    List<String>? tags,
    List<String>? mediaPaths,
    bool? isVideo,
    Map<String, dynamic>? metadata,
    DateTime? updatedAt,
  }) {
    return PostDraft(
      id: id,
      caption: caption ?? this.caption,
      tags: tags ?? this.tags,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      isVideo: isVideo ?? this.isVideo,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'caption': caption,
      'tags': tags,
      'mediaPaths': mediaPaths,
      'isVideo': isVideo,
      'metadata': metadata,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory PostDraft.fromJson(Map<String, dynamic> json) {
    return PostDraft(
      id: json['id'],
      caption: json['caption'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      mediaPaths: List<String>.from(json['mediaPaths'] ?? []),
      isVideo: json['isVideo'] ?? false,
      metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(updatedAt);
    
    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  String get previewText {
    if (caption.isNotEmpty) {
      return caption.length > 50 ? '${caption.substring(0, 50)}...' : caption;
    } else if (tags.isNotEmpty) {
      return '#${tags.first}${tags.length > 1 ? ' +${tags.length - 1}' : ''}';
    } else {
      return 'Untitled draft';
    }
  }
}