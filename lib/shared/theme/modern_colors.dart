import 'package:flutter/material.dart';

/// WhatsApp Messenger color system - synced from whatsapp_messenger repository
class ModernColors {
  // Primary brand colors (from WhatsApp Messenger)
  static const primaryGreen = Color(0xFF00A884);  // WhatsApp green dark
  static const primaryTeal = Color(0xFF008069);   // WhatsApp green light
  static const accentBlue = Color(0xFF53BDEB);    // WhatsApp blue dark
  static const accentTealBlue = Color(0xFF027EB5); // WhatsApp blue light

  // Semantic colors
  static const success = Color(0xFF00A884);      // Success actions/states
  static const warning = Color(0xFFFFA000);      // Warning actions/states
  static const error = Color(0xFFE55252);        // Error actions/states
  static const info = Color(0xFF53BDEB);         // Information actions/states

  // Light theme colors (from WhatsApp Messenger)
  static const lightBackground = Color(0xFFFFFFFF);    // White background
  static const lightSurface = Color(0xFFFFFFFF);       // White surface
  static const lightSurfaceVariant = Color(0xFFF7F8FA); // Light grey variant
  static const lightAppBar = Color(0xFF008069);        // Green app bar
  static const lightBorder = Color(0xFFE0E0E0);        // Light border
  static const lightText = Color(0xFF000000);          // Black text
  static const lightTextSecondary = Color(0xFF667781); // Grey text (WhatsApp grey light)
  static const lightTextTertiary = Color(0xFF8696A0);  // Lighter grey text
  static const lightDivider = Color(0xFFE0E0E0);       // Divider color
  static const lightChatBackground = Color(0xFFEFE7DE); // Chat doodle background
  static const lightSenderBubble = Color(0xFFE7FFDB);  // Light green sender bubble
  static const lightReceiverBubble = Color(0xFFFFFFFF); // White receiver bubble
  static const lightSystemMessage = Color(0xFFFFEECC); // Yellow system message
  static const lightInputBackground = Color(0xFFFFFFFF); // White input background

  // Dark theme colors (from WhatsApp Messenger)
  static const darkBackground = Color(0xFF111B21);       // WhatsApp dark background
  static const darkSurfaceVariant = Color(0xFF1F2C34);   // Dark surface variant
  static const darkSurface = Color(0xFF202C33);          // WhatsApp grey background
  static const darkAppBar = Color(0xFF202C33);           // Dark app bar
  static const darkBorder = Color(0xFF2A3942);           // Dark border
  static const darkText = Colors.white;                  // Pure white for text
  static const darkTextSecondary = Color(0xFF8696A0);    // WhatsApp grey dark
  static const darkTextTertiary = Color(0xFF667781);     // Darker grey text
  static const darkDivider = Color(0xFF2A3942);          // Dark dividers
  static const darkChatBackground = Color(0xFF081419);   // Dark chat background
  static const darkSenderBubble = Color(0xFF005C4B);     // Dark green sender bubble
  static const darkReceiverBubble = Color(0xFF202C33);   // Dark receiver bubble
  static const darkSystemMessage = Color(0xFF222E35);    // Dark system message
  static const darkInputBackground = Color(0xFF202C33);  // Dark input background

  // UI element colors
  static const gradient1 = [Color(0xFF00A884), Color(0xFF005C4B)];  // WhatsApp green gradient
  static const gradient2 = [Color(0xFF53BDEB), Color(0xFF027EB5)];  // Blue gradient

  // Light theme gradients
  static const lightGradient1 = [Color(0xFF008069), Color(0xFF00A884)]; // Light green gradient

  // State colors for interactive elements
  static const rippleLight = Color(0x1F000000);  // 12% black ripple for light theme
  static const rippleDark = Color(0x1FFFFFFF);   // 12% white ripple for dark theme

  // Overlay colors
  static const overlayLight = Color(0xB3FFFFFF);  // Light overlay
  static const overlayDark = Color(0xB3111B21);   // Dark overlay
}