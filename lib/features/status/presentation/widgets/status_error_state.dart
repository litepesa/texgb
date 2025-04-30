import 'package:flutter/material.dart';
import '../../core/failures.dart';

class StatusErrorState extends StatelessWidget {
  final Failure failure;
  final VoidCallback onRetry;
  
  const StatusErrorState({
    Key? key,
    required this.failure,
    required this.onRetry,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    String errorMessage = 'Something went wrong while loading status posts.';
    String title = 'Oops! Something Went Wrong';
    IconData icon = Icons.error_outline;
    Color iconColor = Colors.red[400]!;
    
    // Customize error message based on failure type
    if (failure is NetworkFailure) {
      title = 'Network Error';
      errorMessage = 'Please check your internet connection and try again.';
      icon = Icons.wifi_off;
      iconColor = Colors.orange;
    } else if (failure is ServerFailure) {
      title = 'Server Error';
      errorMessage = 'Our team is working on fixing the issue. Please try again later.';
      icon = Icons.cloud_off;
      iconColor = Colors.red[400]!;
    } else if (failure is PermissionDeniedFailure) {
      title = 'Permission Denied';
      errorMessage = 'You don\'t have permission to access this content.';
      icon = Icons.no_accounts;
      iconColor = Colors.red[400]!;
    } else if (failure is NotFoundFailure) {
      title = 'Content Not Found';
      errorMessage = 'The content you\'re looking for doesn\'t exist or has been removed.';
      icon = Icons.search_off;
      iconColor = Colors.grey;
    } else if (failure is MediaUploadFailure) {
      title = 'Media Upload Failed';
      errorMessage = 'There was a problem uploading your media. Please try again.';
      icon = Icons.broken_image;
      iconColor = Colors.orange;
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: iconColor,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}