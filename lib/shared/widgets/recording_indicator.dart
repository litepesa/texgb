part of 'bottom_chat_field.dart';

class RecordingIndicator extends StatelessWidget {
  final double recordingPosition;
  final int recordingDuration;
  final Color accentColor;
  final Color? backgroundColor;
  final Color? textColor;
  final Color? secondaryTextColor;
  final Function(DragUpdateDetails) onDragUpdate;
  final Function(DragEndDetails) onDragEnd;
  final VoidCallback onStopRecording;
  final String Function(int) formatDuration;

  const RecordingIndicator({
    super.key,
    required this.recordingPosition,
    required this.recordingDuration,
    required this.accentColor,
    required this.backgroundColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.onDragUpdate,
    required this.onDragEnd,
    required this.onStopRecording,
    required this.formatDuration,
  });

  @override
  Widget build(BuildContext context) {
    final cancelOpacity = recordingPosition < -50 ? (recordingPosition / -150).clamp(0.0, 1.0) : 0.0;
    final cancelColor = Colors.red.withOpacity(cancelOpacity * 0.3);
    
    return GestureDetector(
      onHorizontalDragUpdate: onDragUpdate,
      onHorizontalDragEnd: onDragEnd,
      child: Container(
        color: backgroundColor,
        padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.2),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(seconds: 2),
                    builder: (context, value, child) {
                      return Container(
                        width: 30 + (value * 10),
                        height: 30 + (value * 10),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.3 * (1 - value)),
                          shape: BoxShape.circle,
                        ),
                      );
                    },
                  ),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Text(
                        'Recording',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        formatDuration(recordingDuration),
                        style: TextStyle(
                          fontSize: 14,
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Transform.translate(
                    offset: Offset(recordingPosition, 0),
                    child: Row(
                      children: [
                        Icon(
                          Icons.arrow_back,
                          size: 14,
                          color: recordingPosition < -50 ? Colors.red : secondaryTextColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          "Slide left to cancel",
                          style: TextStyle(
                            fontSize: 12,
                            color: recordingPosition < -50 ? Colors.red : secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            GestureDetector(
              onTap: onStopRecording,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: accentColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}