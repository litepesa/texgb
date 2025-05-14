import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class StatusProgressBar extends StatefulWidget {
  final AnimationController? controller;
  final bool isPaused;
  final bool isActive;
  final bool isCompleted;

  const StatusProgressBar({
    Key? key,
    this.controller,
    this.isPaused = false,
    this.isActive = false,
    this.isCompleted = false,
  }) : super(key: key);

  @override
  State<StatusProgressBar> createState() => _StatusProgressBarState();
}

class _StatusProgressBarState extends State<StatusProgressBar> {
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animation = Tween(begin: 0.0, end: 1.0).animate(widget.controller ?? AnimationController(vsync: _DummyTickerProvider()));
    
    if (widget.controller != null) {
      widget.controller!.addListener(() {
        if (mounted) {
          setState(() {});
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      child: LinearProgressIndicator(
        value: widget.isCompleted 
            ? 1.0 
            : (widget.isActive ? _animation.value : 0.0),
        backgroundColor: Colors.white.withOpacity(0.3),
        valueColor: AlwaysStoppedAnimation<Color>(
          widget.isActive || widget.isCompleted
              ? Colors.white
              : Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }
}

// Dummy ticker provider to avoid errors when controller is null
class _DummyTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick, debugLabel: 'dummy');
  }
}