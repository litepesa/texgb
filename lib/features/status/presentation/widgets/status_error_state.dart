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
    
    // Customize error message based on failure type
    if (failure is NetworkFailure) {
      errorMessage = 'Network error. Please check your internet connection and try again.';
    } else if (failure is ServerFailure) {
      errorMessage = 'Server error. Our team is working on fixing the issue.';
    } else if (failure is PermissionDeniedFailure) {
      errorMessage = 'You don\'t have permission to access this content.';
    } else if (failure is NotFoundFailure) {
      errorMessage = 'The content you\'re looking for doesn\'t exist or has been removed.';
    }
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.red[400],
            ),
            const SizedBox(height: 24),
            Text(
              'Oops! Something Went Wrong',
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