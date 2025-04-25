import 'package:flutter/material.dart';

/// Modern color system for the application with WhatsApp-inspired palette
class ModernColors {
  // Primary brand colors
  static const primaryGreen = Color(0xFF00A884);  // WhatsApp green for dark mode
  static const primaryTeal = Color(0xFF008069);   // WhatsApp green for light mode
  static const accentBlue = Color(0xFF53BDEB);    // Accent blue for dark mode
  static const accentTealBlue = Color(0xFF027EB5); // Accent blue for light mode

  // Semantic colors
  static const success = Color(0xFF00A884);      // Success actions/states
  static const warning = Color(0xFFFFA000);      // Warning actions/states
  static const error = Color(0xFFE55252);        // Error actions/states
  static const info = Color(0xFF53BDEB);         // Information actions/states

  // Light theme colors
  static const lightBackground = Colors.white;
  static const lightSurface = Colors.white;
  static const lightSurfaceVariant = Color(0xFFF0F2F5);  // Light chat background
  static const lightAppBar = Color(0xFFF6F6F6);          // Light app bar
  static const lightBorder = Color(0xFFE4E4E4);          // Light dividers/borders
  static const lightText = Color(0xFF111B21);            // Light primary text
  static const lightTextSecondary = Color(0xFF667781);   // Light secondary text
  static const lightTextTertiary = Color(0xFF8696A0);    // Light tertiary text
  static const lightDivider = Color(0xFFE4E4E4);         // Light dividers
  static const lightChatBackground = Color(0xFFECE5DD);  // Light chat background with subtle pattern
  static const lightSenderBubble = Color(0xFFE1FFC7);    // Light green sender bubble
  static const lightReceiverBubble = Colors.white;       // Light receiver bubble
  static const lightSystemMessage = Color(0xFFFFF3C2);   // Light system message
  static const lightInputBackground = Color(0xFFF0F2F5); // Light input background

  // Dark theme colors
  static const darkBackground = Color(0xFF111B21);       // Dark background
  static const darkSurfaceVariant = Color(0xFF202C33);   // Dark surface variant
  static const darkSurface = Color(0xFF1F2C34);          // Dark surface
  static const darkAppBar = Color(0xFF1F2C34);           // Dark app bar
  static const darkBorder = Color(0xFF252D32);           // Dark dividers/borders
  static const darkText = Color(0xFFE9EDEF);             // Dark primary text
  static const darkTextSecondary = Color(0xFF8696A0);    // Dark secondary text
  static const darkTextTertiary = Color(0xFF8D989F);     // Dark tertiary text
  static const darkDivider = Color(0xFF252D32);          // Dark dividers
  static const darkChatBackground = Color(0xFF0B141A);   // Dark chat background
  static const darkSenderBubble = Color(0xFF005C4B);     // Dark green sender bubble
  static const darkReceiverBubble = Color(0xFF202C33);   // Dark receiver bubble
  static const darkSystemMessage = Color(0xFF182229);    // Dark system message
  static const darkInputBackground = Color(0xFF2A3942);  // Dark input background

  // UI element colors
  static const gradient1 = [Color(0xFF00A884), Color(0xFF008069)];  // Green gradient
  static const gradient2 = [Color(0xFF53BDEB), Color(0xFF027EB5)];  // Blue gradient

  // State colors for interactive elements
  static const rippleLight = Color(0x1F000000);  // 12% black
  static const rippleDark = Color(0x1FFFFFFF);   // 12% white
  
  // Overlay colors
  static const overlayLight = Color(0xB3FFFFFF);  // 70% white
  static const overlayDark = Color(0xB3111B21);   // 70% dark background
}