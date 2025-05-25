import 'dart:io';
import 'package:flutter/material.dart';

class EditedMediaModel {
  final File originalFile;
  final File? processedFile;
  final List<TextOverlay> textOverlays;
  final List<StickerOverlay> stickerOverlays;
  final AudioTrack? audioTrack;
  final String? filterType;
  final double beautyLevel;
  final double brightness;
  final double contrast;
  final double saturation;

  EditedMediaModel({
    required this.originalFile,
    this.processedFile,
    required this.textOverlays,
    required this.stickerOverlays,
    this.audioTrack,
    this.filterType,
    required this.beautyLevel,
    required this.brightness,
    required this.contrast,
    required this.saturation,
  });

  bool get hasEdits =>
      textOverlays.isNotEmpty ||
      stickerOverlays.isNotEmpty ||
      audioTrack != null ||
      filterType != null ||
      beautyLevel > 0 ||
      brightness != 0 ||
      contrast != 1 ||
      saturation != 1;

  EditedMediaModel copyWith({
    File? originalFile,
    File? processedFile,
    List<TextOverlay>? textOverlays,
    List<StickerOverlay>? stickerOverlays,
    AudioTrack? audioTrack,
    String? filterType,
    double? beautyLevel,
    double? brightness,
    double? contrast,
    double? saturation,
  }) {
    return EditedMediaModel(
      originalFile: originalFile ?? this.originalFile,
      processedFile: processedFile ?? this.processedFile,
      textOverlays: textOverlays ?? List.from(this.textOverlays),
      stickerOverlays: stickerOverlays ?? List.from(this.stickerOverlays),
      audioTrack: audioTrack ?? this.audioTrack,
      filterType: filterType ?? this.filterType,
      beautyLevel: beautyLevel ?? this.beautyLevel,
      brightness: brightness ?? this.brightness,
      contrast: contrast ?? this.contrast,
      saturation: saturation ?? this.saturation,
    );
  }
}

class TextOverlay {
  final String text;
  final TextStyle style;
  final Offset position;
  final double rotation;
  final double scale;
  final Duration? startTime;
  final Duration? endTime;
  final TextAnimation? animation;

  TextOverlay({
    required this.text,
    required this.style,
    required this.position,
    this.rotation = 0,
    this.scale = 1,
    this.startTime,
    this.endTime,
    this.animation,
  });

  TextOverlay copyWith({
    String? text,
    TextStyle? style,
    Offset? position,
    double? rotation,
    double? scale,
    Duration? startTime,
    Duration? endTime,
    TextAnimation? animation,
  }) {
    return TextOverlay(
      text: text ?? this.text,
      style: style ?? this.style,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      animation: animation ?? this.animation,
    );
  }
}

class StickerOverlay {
  final String stickerPath;
  final Offset position;
  final double rotation;
  final double scale;
  final Duration? startTime;
  final Duration? endTime;
  final StickerAnimation? animation;

  StickerOverlay({
    required this.stickerPath,
    required this.position,
    this.rotation = 0,
    this.scale = 1,
    this.startTime,
    this.endTime,
    this.animation,
  });

  StickerOverlay copyWith({
    String? stickerPath,
    Offset? position,
    double? rotation,
    double? scale,
    Duration? startTime,
    Duration? endTime,
    StickerAnimation? animation,
  }) {
    return StickerOverlay(
      stickerPath: stickerPath ?? this.stickerPath,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      scale: scale ?? this.scale,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      animation: animation ?? this.animation,
    );
  }
}

class AudioTrack {
  final String name;
  final String path;
  final Duration duration;
  final double volume;
  final Duration startOffset;

  AudioTrack({
    required this.name,
    required this.path,
    required this.duration,
    this.volume = 0.5,
    this.startOffset = Duration.zero,
  });

  AudioTrack copyWith({
    String? name,
    String? path,
    Duration? duration,
    double? volume,
    Duration? startOffset,
  }) {
    return AudioTrack(
      name: name ?? this.name,
      path: path ?? this.path,
      duration: duration ?? this.duration,
      volume: volume ?? this.volume,
      startOffset: startOffset ?? this.startOffset,
    );
  }
}

enum TextAnimation {
  fadeIn,
  slideIn,
  bounce,
  typewriter,
  scale,
  rotate,
}

enum StickerAnimation {
  fadeIn,
  bounce,
  rotate,
  scale,
  shake,
}