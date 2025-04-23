import 'package:flutter/material.dart';

/// Modern color system for the application
class ModernColors {
  // Primary brand colors
  static const primaryBlue = Color(0xFF3B82F6);     // Modern vibrant blue
  static const primaryPurple = Color(0xFF8B5CF6);   // Secondary accent
  static const primaryEmerald = Color(0xFF10B981);  // Success state

  // Semantic colors
  static const success = Color(0xFF10B981);         // Success actions/states
  static const warning = Color(0xFFF59E0B);         // Warning actions/states
  static const error = Color(0xFFEF4444);           // Error actions/states
  static const info = Color(0xFF3B82F6);            // Information actions/states

  // Light theme colors
  static const lightBackground = Color(0xFFF8F9FA);
  static const lightSurface = Colors.white;
  static const lightSurfaceVariant = Color(0xFFF3F4F6);
  static const lightAppBar = Colors.white;
  static const lightBorder = Color(0xFFE5E7EB);
  static const lightText = Color(0xFF111827);
  static const lightTextSecondary = Color(0xFF6B7280);
  static const lightTextTertiary = Color(0xFF9CA3AF);
  static const lightDivider = Color(0xFFE5E7EB);
  static const lightChatBackground = Color(0xFFF3F4F6);
  static const lightSenderBubble = Color(0xFFECFDF5);  // Light emerald background
  static const lightReceiverBubble = Colors.white;
  static const lightSystemMessage = Color(0xFFF3F4F6);
  static const lightInputBackground = Color(0xFFF9FAFB);

  // Dark theme colors
  static const darkBackground = Color(0xFF111827);
  static const darkSurfaceVariant = Color(0xFF1F2937);
  static const darkSurface = Color(0xFF1A1E2A);
  static const darkAppBar = Color(0xFF1F2937);
  static const darkBorder = Color(0xFF374151);
  static const darkText = Color(0xFFF9FAFB);
  static const darkTextSecondary = Color(0xFFD1D5DB);
  static const darkTextTertiary = Color(0xFF9CA3AF);
  static const darkDivider = Color(0xFF374151);
  static const darkChatBackground = Color(0xFF111827);
  static const darkSenderBubble = Color(0xFF064E3B);  // Dark emerald background
  static const darkReceiverBubble = Color(0xFF1F2937);
  static const darkSystemMessage = Color(0xFF1F2937);
  static const darkInputBackground = Color(0xFF1F2937);

  // True black mode (OLED-friendly)
  static const trueBlackBackground = Colors.black;
  static const trueBlackSurface = Color(0xFF121212);

  // UI element colors
  static const gradient1 = [Color(0xFF3B82F6), Color(0xFF8B5CF6)];  // Blue to purple
  static const gradient2 = [Color(0xFF10B981), Color(0xFF3B82F6)];  // Emerald to blue

  // State colors for interactive elements
  static const rippleLight = Color(0x1F000000);  // 12% black
  static const rippleDark = Color(0x1FFFFFFF);   // 12% white
  
  // Overlay colors
  static const overlayLight = Color(0xB3FFFFFF);  // 70% white
  static const overlayDark = Color(0xB3111827);   // 70% dark background
}