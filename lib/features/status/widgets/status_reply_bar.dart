import 'package:flutter/material.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/models/status_model.dart';

class StatusReplyBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final StatusModel currentStatus;
  final String thumbnailUrl;
  final bool isLoading; // Add this new property

  const StatusReplyBar({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.currentStatus,
    required this.thumbnailUrl,
    this.isLoading = false, // Default to false
  }) : super(key: key);

  @override
  State<StatusReplyBar> createState() => _StatusReplyBarState();
}

class _StatusReplyBarState extends State<StatusReplyBar> {
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateSendButton);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateSendButton);
    super.dispose();
  }

  void _updateSendButton() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) {
      setState(() {
        _hasText = hasText;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;
    
    return Container(
      padding: EdgeInsets.only(
        bottom: bottomPadding > 0 ? bottomPadding : 0,
      ),
      color: Colors.black,
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFF262626), // Instagram-style dark input background
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                // Text input field
                Expanded(
                  child: TextField(
                    controller: widget.controller,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Reply to ${widget.currentStatus.userName}...',
                      hintStyle: const TextStyle(
                        color: Color(0xFF8E8E8E), // Instagram grey
                        fontSize: 14,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.fromLTRB(20, 14, 14, 14),
                    ),
                    textCapitalization: TextCapitalization.sentences,
                    textAlignVertical: TextAlignVertical.center,
                    cursorColor: Colors.white,
                    minLines: 1,
                    maxLines: 1,
                    // Disable text input while loading
                    enabled: !widget.isLoading,
                  ),
                ),
                
                // Send button or loading indicator
                if (_hasText)
                  Padding(
                    padding: const EdgeInsets.only(right: 14.0),
                    child: widget.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF0095F6),
                              strokeWidth: 2,
                            ),
                          )
                        : Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onSend,
                              borderRadius: BorderRadius.circular(20),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Text(
                                  'Send',
                                  style: TextStyle(
                                    color: Color(0xFF0095F6), // Instagram blue
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ),
                          ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}