// lib/features/videos/widgets/video_state_indicator.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

/// Widget for showing video loading, error, and other states
class VideoStateIndicator extends StatelessWidget {
  final VideoState state;
  final String? errorMessage;
  final VoidCallback? onRetry;
  final double? progress;
  final bool showBackground;
  final Color backgroundColor;
  final Color foregroundColor;
  
  const VideoStateIndicator({
    super.key,
    required this.state,
    this.errorMessage,
    this.onRetry,
    this.progress,
    this.showBackground = true,
    this.backgroundColor = Colors.black54,
    this.foregroundColor = Colors.white,
  });
  
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      color: showBackground ? backgroundColor : Colors.transparent,
      child: Center(
        child: _buildStateContent(),
      ),
    );
  }
  
  Widget _buildStateContent() {
    switch (state) {
      case VideoState.loading:
        return _buildLoadingIndicator();
      case VideoState.error:
        return _buildErrorIndicator();
      case VideoState.empty:
        return _buildEmptyIndicator();
      case VideoState.networkError:
        return _buildNetworkErrorIndicator();
      case VideoState.formatError:
        return _buildFormatErrorIndicator();
      case VideoState.retrying:
        return _buildRetryingIndicator();
      case VideoState.paused:
        return _buildPausedIndicator();
      case VideoState.buffering:
        return _buildBufferingIndicator();
    }
  }
  
  Widget _buildLoadingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (progress != null && progress! > 0)
          _buildProgressIndicator()
        else
          _buildSpinningIndicator(),
        const SizedBox(height: 16),
        Text(
          'Loading video...',
          style: TextStyle(
            color: foregroundColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildErrorIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.error_outline,
          color: Colors.red[300],
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Video Error',
          style: TextStyle(
            color: foregroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        if (errorMessage != null) ...[
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              errorMessage!,
              style: TextStyle(
                color: foregroundColor.withOpacity(0.8),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          _buildRetryButton(),
        ],
      ],
    );
  }
  
  Widget _buildNetworkErrorIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.wifi_off,
          color: Colors.orange[300],
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Network Error',
          style: TextStyle(
            color: foregroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your internet connection',
          style: TextStyle(
            color: foregroundColor.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          _buildRetryButton(),
        ],
      ],
    );
  }
  
  Widget _buildFormatErrorIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.video_file,
          color: Colors.amber[300],
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Video Format Error',
          style: TextStyle(
            color: foregroundColor,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'This video format is not supported',
          style: TextStyle(
            color: foregroundColor.withOpacity(0.8),
            fontSize: 14,
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.videocam_off_outlined,
          color: foregroundColor.withOpacity(0.6),
          size: 64,
        ),
        const SizedBox(height: 16),
        Text(
          'No Video',
          style: TextStyle(
            color: foregroundColor.withOpacity(0.8),
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildRetryingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSpinningIndicator(),
        const SizedBox(height: 16),
        Text(
          'Retrying...',
          style: TextStyle(
            color: foregroundColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPausedIndicator() {
    return Icon(
      CupertinoIcons.play_circle,
      color: foregroundColor.withOpacity(0.8),
      size: 64,
    );
  }
  
  Widget _buildBufferingIndicator() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildSpinningIndicator(),
        const SizedBox(height: 16),
        Text(
          'Buffering...',
          style: TextStyle(
            color: foregroundColor,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgressIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        value: progress,
        color: foregroundColor,
        backgroundColor: foregroundColor.withOpacity(0.3),
        strokeWidth: 3,
      ),
    );
  }
  
  Widget _buildSpinningIndicator() {
    return SizedBox(
      width: 32,
      height: 32,
      child: CircularProgressIndicator(
        color: foregroundColor,
        strokeWidth: 3,
      ),
    );
  }
  
  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh, size: 18),
      label: const Text('Retry'),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.black,
        backgroundColor: foregroundColor,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        minimumSize: const Size(0, 36),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
    );
  }
}

/// Different states a video can be in
enum VideoState {
  loading,
  error,
  empty,
  networkError,
  formatError,
  retrying,
  paused,
  buffering,
}

/// Factory methods for common video states
extension VideoStateIndicatorFactory on VideoStateIndicator {
  static VideoStateIndicator loading({
    double? progress,
    bool showBackground = true,
  }) {
    return VideoStateIndicator(
      state: VideoState.loading,
      progress: progress,
      showBackground: showBackground,
    );
  }
  
  static VideoStateIndicator error({
    required String message,
    VoidCallback? onRetry,
    bool showBackground = true,
  }) {
    return VideoStateIndicator(
      state: VideoState.error,
      errorMessage: message,
      onRetry: onRetry,
      showBackground: showBackground,
    );
  }
  
  static VideoStateIndicator networkError({
    VoidCallback? onRetry,
    bool showBackground = true,
  }) {
    return VideoStateIndicator(
      state: VideoState.networkError,
      onRetry: onRetry,
      showBackground: showBackground,
    );
  }
  
  static VideoStateIndicator formatError({
    bool showBackground = true,
  }) {
    return VideoStateIndicator(
      state: VideoState.formatError,
      showBackground: showBackground,
    );
  }
  
  static VideoStateIndicator empty({
    bool showBackground = false,
  }) {
    return VideoStateIndicator(
      state: VideoState.empty,
      showBackground: showBackground,
    );
  }
  
  static VideoStateIndicator retrying({
    bool showBackground = true,
  }) {
    return VideoStateIndicator(
      state: VideoState.retrying,
      showBackground: showBackground,
    );
  }
  
  static VideoStateIndicator paused({
    bool showBackground = false,
  }) {
    return VideoStateIndicator(
      state: VideoState.paused,
      showBackground: showBackground,
    );
  }
  
  static VideoStateIndicator buffering({
    bool showBackground = false,
  }) {
    return VideoStateIndicator(
      state: VideoState.buffering,
      showBackground: showBackground,
    );
  }
}