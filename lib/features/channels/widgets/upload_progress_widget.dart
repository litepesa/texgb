// lib/features/channels/widgets/upload_progress_widget.dart
import 'package:flutter/material.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/features/channels/services/post_creation_service.dart';

class UploadProgressWidget extends StatelessWidget {
  final PostCreationService service;
  final VoidCallback? onCancel;

  const UploadProgressWidget({
    Key? key,
    required this.service,
    this.onCancel,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: modernTheme.primaryColor!.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  service.isProcessing ? Icons.settings : Icons.cloud_upload,
                  color: modernTheme.primaryColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.isProcessing ? 'Processing' : 'Uploading',
                      style: TextStyle(
                        color: modernTheme.textColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      service.isProcessing 
                          ? service.processingStatus
                          : service.uploadStatus,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (service.canCancel && !service.isProcessing)
                IconButton(
                  onPressed: onCancel,
                  icon: Icon(
                    Icons.close,
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Progress bar
          Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(service.uploadProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (!service.isProcessing && service.uploadSpeed > 0)
                    Text(
                      service.uploadSpeedFormatted,
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Animated progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: service.isProcessing ? null : service.uploadProgress,
                  backgroundColor: modernTheme.surfaceColor,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    modernTheme.primaryColor!,
                  ),
                  minHeight: 8,
                ),
              ),
              
              if (!service.isProcessing && service.estimatedTimeRemaining.inSeconds > 0) ...[
                const SizedBox(height: 8),
                Text(
                  'About ${_formatDuration(service.estimatedTimeRemaining)} remaining',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ],
          ),
          
          // Additional info
          if (!service.isProcessing) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: modernTheme.primaryColor,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your post will be published once upload completes',
                      style: TextStyle(
                        color: modernTheme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class CompactUploadProgressWidget extends StatelessWidget {
  final PostCreationService service;
  final VoidCallback? onTap;

  const CompactUploadProgressWidget({
    Key? key,
    required this.service,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: modernTheme.primaryColor!.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modernTheme.primaryColor!.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            // Progress indicator
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                value: service.isProcessing ? null : service.uploadProgress,
                strokeWidth: 2,
                backgroundColor: modernTheme.primaryColor!.withOpacity(0.2),
                valueColor: AlwaysStoppedAnimation<Color>(
                  modernTheme.primaryColor!,
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Status text
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.isProcessing ? 'Processing...' : 'Uploading...',
                    style: TextStyle(
                      color: modernTheme.textColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    '${(service.uploadProgress * 100).toInt()}%',
                    style: TextStyle(
                      color: modernTheme.textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            
            // Tap to expand hint
            Icon(
              Icons.expand_less,
              color: modernTheme.textSecondaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}