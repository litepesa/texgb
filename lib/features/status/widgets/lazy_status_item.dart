import 'package:flutter/material.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/status/widgets/status_feed_item.dart';
import 'package:textgb/models/status_model.dart';

class LazyStatusItem extends StatefulWidget {
  final StatusModel status;
  final bool isCurrentUser;
  final int currentIndex;
  final int index;
  final bool isVisible;

  const LazyStatusItem({
    Key? key,
    required this.status,
    required this.isCurrentUser,
    required this.currentIndex,
    required this.index,
    this.isVisible = true,
  }) : super(key: key);

  @override
  State<LazyStatusItem> createState() => _LazyStatusItemState();
}

class _LazyStatusItemState extends State<LazyStatusItem> {
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    
    // Immediately load text statuses (they're lightweight)
    if (widget.status.statusType == StatusType.text) {
      _isLoaded = true;
    }
    
    // For active status, load immediately regardless of type
    if (widget.currentIndex == widget.index) {
      _isLoaded = true;
    }
    
    // Add delay to initialize other statuses to improve performance
    if (!_isLoaded) {
      // Add small staggered delay based on index to prevent all loading at once
      Future.delayed(Duration(milliseconds: 100 * widget.index % 5), () {
        if (mounted) {
          setState(() {
            _isLoaded = true;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(LazyStatusItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // Load this status if it becomes active
    if (widget.currentIndex == widget.index && !_isLoaded) {
      setState(() {
        _isLoaded = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return a visibility detector to load when the status comes into view
    return _isLoaded
        ? StatusFeedItem(
            status: widget.status,
            isCurrentUser: widget.isCurrentUser,
            currentIndex: widget.currentIndex,
            index: widget.index,
            isVisible: widget.isVisible,
          )
        : _buildPlaceholder();
  }

  Widget _buildPlaceholder() {
    // Return a lightweight placeholder until content is loaded
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 50,
              height: 50,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Loading status...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}