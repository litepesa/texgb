import 'package:flutter/material.dart';

/// Modern color system for the application with updated light and dark mode colors
class ModernColors {
  // Primary brand colors
  static const primaryGreen = Color(0xFF25D366);  // Dark theme green
  static const primaryTeal = Color(0xFF1E9E1E);   // Updated light theme green for better visibility
  static const accentBlue = Color(0xFF53BDEB);    // Accent blue for dark mode
  static const accentTealBlue = Color(0xFF027EB5); // Accent blue for light mode

  // Semantic colors
  static const success = Color(0xFF25D366);      // Success actions/states
  static const warning = Color(0xFFFFA000);      // Warning actions/states
  static const error = Color(0xFFE55252);        // Error actions/states
  static const info = Color(0xFF53BDEB);         // Information actions/states

  // Light theme colors - Updated for better visibility
  static const lightBackground = Color(0xFFF8F7F2);  // Slightly darker off-white background
  static const lightSurface = Color(0xFFFFFFFF);     // Pure white surface for better contrast
  static const lightSurfaceVariant = Color(0xFFEAE9E3); // Darker chat background for better visibility
  static const lightAppBar = Color(0xFFFFFFFF);      // Pure white app bar
  static const lightBorder = Color(0xFFE8E8E8);      // Slightly darker borders for visibility
  static const lightText = Color(0xFF121212);        // Dark text for light mode
  static const lightTextSecondary = Color(0xFF303030); // Darker secondary text for better contrast
  static const lightTextTertiary = Color(0xFF555555);  // Darker tertiary text for better contrast
  static const lightDivider = Color(0xFFD8D8D8);     // Darker dividers for better visibility
  static const lightChatBackground = Color(0xFFF0EFE9); // Light chat background
  static const lightSenderBubble = Color(0xFFDCF8C6);  // Light green sender bubble
  static const lightReceiverBubble = Color(0xFFFFFFFF); // White receiver bubble
  static const lightSystemMessage = Color(0xFFEAE9E3);  // Darker system message for better visibility
  static const lightInputBackground = Color(0xFFEAE9E3); // Darker input background for better visibility

  // Dark theme colors - Unchanged to preserve dark mode
  static const darkBackground = Color(0xFF30302E);       // Dark background
  static const darkSurfaceVariant = Color(0xFF3A3A38);   // Dark surface variant
  static const darkSurface = Color(0xFF262624);          // Dark surface
  static const darkAppBar = Color(0xFF262624);           // Dark app bar
  static const darkBorder = Color(0xFF444442);           // Dark dividers/borders
  static const darkText = Colors.white;                  // Pure white for text
  static const darkTextSecondary = Color(0xFFBBBBBB);    // Dark secondary text
  static const darkTextTertiary = Color(0xFF999999);     // Dark tertiary text
  static const darkDivider = Color(0xFF444442);          // Dark dividers
  static const darkChatBackground = Color(0xFF30302E);   // Dark chat background
  static const darkSenderBubble = Color(0xFF066C38);     // Dark green sender bubble
  static const darkReceiverBubble = Color(0xFF262624);   // Dark receiver bubble
  static const darkSystemMessage = Color(0xFF3A3A38);    // Dark system message
  static const darkInputBackground = Color(0xFF3A3A38);  // Dark input background

  // UI element colors
  static const gradient1 = [Color(0xFF25D366), Color(0xFF066C38)];  // Green gradient for dark theme
  static const gradient2 = [Color(0xFF53BDEB), Color(0xFF027EB5)];  // Blue gradient
  
  // Light theme gradients - Updated for better visibility
  static const lightGradient1 = [Color(0xFF1E9E1E), Color(0xFF176D17)]; // Green gradient for light theme
  
  // State colors for interactive elements
  static const rippleLight = Color(0x1F000000);  // 12% black
  static const rippleDark = Color(0x1FFFFFFF);   // 12% white
  
  // Overlay colors
  static const overlayLight = Color(0xB3F8F7F2);  // 70% updated off-white
  static const overlayDark = Color(0xB330302E);   // 70% dark background - unchanged
}