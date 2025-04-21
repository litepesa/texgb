import 'package:flutter/material.dart';

class FeedLoadingIndicator extends StatelessWidget {
  const FeedLoadingIndicator({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated loading indicator
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          
          // Loading text
          const Text(
            'Loading statuses...',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}