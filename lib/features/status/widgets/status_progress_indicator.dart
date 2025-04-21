import 'package:flutter/material.dart';

class StatusProgressIndicator extends StatelessWidget {
  final double progress;
  
  const StatusProgressIndicator({
    Key? key,
    required this.progress,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4, // Increased from 3 for better visibility
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Added vertical margin
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2), // Increased for smoother look
        child: LinearProgressIndicator(
          value: progress.clamp(0.0, 1.0),
          backgroundColor: Colors.white.withOpacity(0.3),
          valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      ),
    );
  }
}