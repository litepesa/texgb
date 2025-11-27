import 'package:flutter/material.dart';

/// Modern color system for the application with updated light and dark mode colors
class ModernColors {
  // Primary brand colors
  static const primaryGreen = Color(0xFF25D366);  // Dark theme green (unchanged)
  static const primaryTeal = Color(0xFF25D366);   // Updated light theme green with the same green as dark mode
  static const accentBlue = Color(0xFF53BDEB);    // Accent blue for dark mode (unchanged)
  static const accentTealBlue = Color(0xFF056062); // Updated accent blue for light mode

  // Semantic colors
  static const success = Color(0xFF25D366);      // Success actions/states (unchanged)
  static const warning = Color(0xFFFFA000);      // Warning actions/states (unchanged)
  static const error = Color(0xFFE55252);        // Error actions/states (unchanged)
  static const info = Color(0xFF53BDEB);         // Information actions/states (unchanged)

  // Group-specific semantic colors (replacing hardcoded colors)
  static const groupAdmin = Color(0xFF53BDEB);    // Admin role badge/actions (blue)
  static const groupModerator = Color(0xFFFFA000); // Moderator role (orange)
  static const groupDanger = Color(0xFFE55252);   // Delete/remove actions (red)
  static const groupSuccess = Color(0xFF25D366);  // Add/success actions (green)
  static const groupMedia = Color(0xFF9C27B0);    // Media actions (purple)

  // Light theme colors - Updated with your specified colors
  static const lightBackground = Color(0xFF131C21);    // Main background
  static const lightSurface = Color(0xFF1F2C34);       // Surface color
  static const lightSurfaceVariant = Color(0xFF252D31); // Surface variant 
  static const lightAppBar = Color(0xFF1F2C34);        // App bar color
  static const lightBorder = Color(0xFF323739);        // Border color
  static const lightText = Color(0xFFF1F1F2);          // Light text color
  static const lightTextSecondary = Colors.grey;       // Secondary text
  static const lightTextTertiary = Color(0xFF8A8A8A); // Tertiary text
  static const lightDivider = Color(0xFF323739);       // Divider color
  static const lightChatBackground = Color(0xFF131C21); // Chat background
  static const lightSenderBubble = Color(0xFF056062);  // Sender bubble
  static const lightReceiverBubble = Color(0xFF1F2C34); // Receiver bubble
  static const lightSystemMessage = Color(0xFF252D31); // System message background
  static const lightInputBackground = Color(0xFF252D31); // Input background

  // Dark theme colors - Unchanged as requested
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
  static const gradient1 = [Color(0xFF25D366), Color(0xFF066C38)];  // Green gradient for dark theme (unchanged)
  static const gradient2 = [Color(0xFF53BDEB), Color(0xFF027EB5)];  // Blue gradient (unchanged)
  
  // Light theme gradients - Updated for better visibility
  static const lightGradient1 = [Color(0xFF25D366), Color(0xFF056062)]; // Updated green gradient for light theme
  
  // State colors for interactive elements
  static const rippleLight = Color(0x1FFFFFFF);  // Changed to white ripple for dark backgrounds
  static const rippleDark = Color(0x1FFFFFFF);   // 12% white (unchanged)
  
  // Overlay colors
  static const overlayLight = Color(0xB3131C21);  // Updated overlay for light theme
  static const overlayDark = Color(0xB330302E);   // 70% dark background - unchanged
}