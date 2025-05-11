import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ModernBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;
  final Color backgroundColor;
  final Color selectedItemColor;
  final Color unselectedItemColor;
  final List<BottomNavigationBarItem> items;
  final double? elevation;
  final bool showLabels;

  const ModernBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.backgroundColor,
    required this.selectedItemColor,
    required this.unselectedItemColor,
    required this.items,
    this.elevation = 2.0,
    this.showLabels = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    final effectiveElevation = elevation ?? (isDarkMode ? 1.0 : 2.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          if (effectiveElevation > 0)
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: effectiveElevation * 2,
              offset: Offset(0, -effectiveElevation),
            ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(items.length, (index) {
          final item = items[index];
          final isSelected = index == currentIndex;
          
          return _NavItem(
            index: index,
            icon: item.icon,
            label: item.label ?? '',
            isSelected: isSelected,
            selectedColor: selectedItemColor,
            unselectedColor: unselectedItemColor,
            onTap: onTap,
            showLabel: showLabels,
          );
        }),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final int index;
  final Widget icon;
  final String label;
  final bool isSelected;
  final Color selectedColor;
  final Color unselectedColor;
  final Function(int) onTap;
  final bool showLabel;

  const _NavItem({
    required this.index,
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.selectedColor,
    required this.unselectedColor,
    required this.onTap,
    required this.showLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: isSelected,
      child: ExcludeSemantics(
        excluding: !showLabel,
        child: GestureDetector(
          onTap: () => onTap(index),
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Icon with animated background
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected 
                      ? selectedColor.withOpacity(0.2) 
                      : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: IconTheme(
                    data: IconThemeData(
                      color: isSelected ? selectedColor : unselectedColor,
                      size: 24,
                    ),
                    child: icon,
                  ),
                ),
                if (showLabel) ...[
                  const SizedBox(height: 4),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: TextStyle(
                      color: isSelected ? selectedColor : unselectedColor,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                      height: 1.1,
                    ),
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}