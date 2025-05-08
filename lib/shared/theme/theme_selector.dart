import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_manager.dart';
import '../theme/modern_colors.dart';

class ThemeSelector extends ConsumerWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeManagerNotifierProvider);
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Text(
              'Appearance',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
          
          _buildThemeOption(
            context,
            ref: ref,
            title: 'System',
            subtitle: 'Follow system settings',
            icon: Icons.brightness_auto,
            isSelected: themeState.currentTheme == ThemeOption.system,
            onTap: () => ref.read(themeManagerNotifierProvider.notifier).setTheme(ThemeOption.system),
          ),
          
          const SizedBox(height: 8),
          
          _buildThemeOption(
            context,
            ref: ref,
            title: 'Light',
            subtitle: 'Light appearance',
            icon: Icons.light_mode,
            isSelected: themeState.currentTheme == ThemeOption.light,
            onTap: () => ref.read(themeManagerNotifierProvider.notifier).setTheme(ThemeOption.light),
          ),
          
          const SizedBox(height: 8),
          
          _buildThemeOption(
            context,
            ref: ref,
            title: 'Dark',
            subtitle: 'Dark appearance',
            icon: Icons.dark_mode,
            isSelected: themeState.currentTheme == ThemeOption.dark,
            onTap: () => ref.read(themeManagerNotifierProvider.notifier).setTheme(ThemeOption.dark),
          ),
        ],
      ),
    );
  }
  
  Widget _buildThemeOption(
    BuildContext context, {
    required WidgetRef ref,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? 
        ModernColors.primaryGreen : // Use the updated green for dark mode
        ModernColors.primaryTeal;   // Use the teal for light mode
    
    return Material(
      color: isSelected 
          ? primaryColor.withOpacity(0.1)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isSelected ? primaryColor : theme.iconTheme.color,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: isSelected ? primaryColor : null,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: primaryColor,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A simple floating theme toggle button
class ThemeToggleButton extends ConsumerWidget {
  final double size;
  final EdgeInsets? padding;
  
  const ThemeToggleButton({
    super.key,
    this.size = 56,
    this.padding,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeManagerNotifierProvider);
    final isDark = themeState.isDarkMode;
    final primaryColor = isDark ? 
        ModernColors.primaryGreen : // Use the updated green for dark mode
        ModernColors.primaryTeal;   // Use the teal for light mode
    
    return Container(
      width: size,
      height: size,
      margin: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: primaryColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => ref.read(themeManagerNotifierProvider.notifier).toggleTheme(),
          customBorder: const CircleBorder(),
          child: Center(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: Icon(
                isDark ? Icons.light_mode : Icons.dark_mode,
                key: ValueKey<bool>(isDark),
                color: Colors.white,
                size: size * 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A theme selector bottom sheet
void showThemeSelector(BuildContext context) {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(24),
      ),
    ),
    builder: (context) => const ThemeSelector(),
  );
}