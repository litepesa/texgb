import 'package:flutter/material.dart';

class CustomIcon extends StatefulWidget {
  const CustomIcon({super.key});

  @override
  State<CustomIcon> createState() => _CustomIconState();
}

class _CustomIconState extends State<CustomIcon> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
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
    // Get the current theme
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Define the WeChat green color
    const wechatGreen = Color(0xFF09BB07);
    
    // Use white for dark theme, green for light theme
    final iconColor = isDarkMode ? Colors.white : wechatGreen;
    
    // Define background color (black for dark, white for light)
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    
    return Container(
      // This container maintains the larger overall size (60x60) but doesn't show visually
      width: 60,
      height: 60,
      color: Colors.transparent, // Make it invisible
      child: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            // Trigger animation when this tab becomes selected
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (ModalRoute.of(context)?.isCurrent ?? false) {
                // Check if we're in a BottomNavigationBar
                if (context.findAncestorWidgetOfExactType<BottomNavigationBar>() != null) {
                  // Get the current selected index
                  final bottomNavBar = context.findAncestorWidgetOfExactType<BottomNavigationBar>();
                  // If this is the currently selected item (assuming index 2)
                  if (bottomNavBar?.currentIndex == 2) {
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
                // This is the actual visible icon - smaller than the parent container
                width: 44,
                height: 34,
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: iconColor,
                    width: 3.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: iconColor.withOpacity(0.3),
                      blurRadius: 8,
                      spreadRadius: isDarkMode ? 1 : 0,
                    ),
                  ],
                ),
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Horizontal line
                      Container(
                        width: 16,
                        height: 4.5,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: iconColor,
                        ),
                      ),
                      
                      // Vertical line
                      Container(
                        width: 4.5,
                        height: 16,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: iconColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}