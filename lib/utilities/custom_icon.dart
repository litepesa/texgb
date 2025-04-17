import 'dart:ui';

import 'package:flutter/material.dart';
import 'dart:math' as math;

class CustomIcon extends StatefulWidget {
  const CustomIcon({super.key});

  @override
  State<CustomIcon> createState() => _CustomIconState();
}

class _CustomIconState extends State<CustomIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _rotationAnimation = Tween<double>(begin: 0, end: 45 * math.pi / 180).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack)
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut)
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Remove the GestureDetector that's conflicting with BottomNavigationBar
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Trigger animation when this tab becomes selected
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (ModalRoute.of(context)?.isCurrent ?? false) {
            // Check if we're in a BottomNavigationBar
            if (context.findAncestorWidgetOfExactType<BottomNavigationBar>() != null) {
              // Get the current selected index
              final bottomNavBar = context.findAncestorWidgetOfExactType<BottomNavigationBar>();
              // If this is the currently selected item
              if (bottomNavBar?.currentIndex == 2) { // Assuming this is at index 2
                _controller.forward();
              } else {
                _controller.reverse();
              }
            }
          }
        });
        
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 1,
                  offset: const Offset(0, 5),
                ),
              ],
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFF6E9),
                  Color(0xFFF3F1F5),
                ],
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Orb effect background
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        const Color(0xFF32E0C4).withOpacity(0.15),
                        const Color(0xFFFA2D6C).withOpacity(0.15),
                      ],
                      radius: 0.8,
                    ),
                  ),
                ),
                
                // Color orbs floating on edges
                ...List.generate(5, (index) {
                  final angle = (index * (2 * math.pi / 5)) + (_controller.value * math.pi / 2);
                  final radius = 20.0;
                  final x = radius * math.cos(angle);
                  final y = radius * math.sin(angle);
                  
                  final colors = [
                    const Color(0xFFF8485E),
                    const Color(0xFF3BACB6),
                    const Color(0xFF7B2CBF),
                    const Color(0xFFFFBB55),
                    const Color(0xFF06FF00),
                  ];
                  
                  return Transform.translate(
                    offset: Offset(x, y),
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors[index],
                        boxShadow: [
                          BoxShadow(
                            color: colors[index].withOpacity(0.5),
                            blurRadius: 8,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                
                // Frosted glass effect for the button
                ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(15),
                        color: Colors.white.withOpacity(0.5),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: Transform.rotate(
                        angle: _rotationAnimation.value,
                        child: Icon(
                          Icons.add,
                          color: Color.lerp(
                            const Color(0xFF3BACB6),
                            const Color(0xFFF8485E),
                            _controller.value,
                          ),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}