import 'package:flutter/material.dart';

/// Custom theme for Channels feature - completely independent of app theme
/// Inspired by Facebook's clean, modern design with light background
class ChannelsTheme {
  // Core Colors
  static const Color black = Color(0xFF000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightGray = Color(0xFFF0F2F5); // Facebook background
  static const Color tiktokPink = Color(0xFFFE2C55);
  static const Color tiktokCyan = Color(0xFF25F4EE);
  static const Color facebookBlue = Color(0xFF1877F2);

  // Derived Colors
  static const Color textPrimary = black;
  static const Color textSecondary = Color(0xFF65676B); // Facebook gray text
  static const Color textTertiary = Color(0xFF8A8D91); // Lighter gray
  static const Color divider = Color(0xFFDDE1E6);
  static const Color cardBackground = white;
  static const Color screenBackground = lightGray;
  static const Color hoverColor = Color(0xFFF2F3F5);

  // Status Colors
  static const Color success = Color(0xFF31A24C);
  static const Color warning = Color(0xFFF7B928);
  static const Color error = Color(0xFFE4294B);

  // Channel Type Colors
  static const Color publicChannelColor = facebookBlue;
  static const Color privateChannelColor = Color(0xFF5851DB); // Purple
  static const Color premiumChannelColor = tiktokPink;

  // Shadows
  static List<BoxShadow> cardShadow = [
    BoxShadow(
      color: black.withOpacity(0.08),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> hoverShadow = [
    BoxShadow(
      color: black.withOpacity(0.12),
      blurRadius: 12,
      offset: const Offset(0, 4),
    ),
  ];

  // Border Radius
  static const double cardRadius = 8.0;
  static const double buttonRadius = 6.0;
  static const double inputRadius = 8.0;
  static const double avatarRadius = 8.0;

  // Spacing
  static const double spacingXs = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 12.0;
  static const double spacingL = 16.0;
  static const double spacingXl = 24.0;
  static const double spacingXxl = 32.0;

  // Typography
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.2,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: textPrimary,
    height: 1.25,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: textPrimary,
    height: 1.3,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: textPrimary,
    height: 1.4,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: textSecondary,
    height: 1.4,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.3,
  );

  static const TextStyle caption = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: textTertiary,
    height: 1.3,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: white,
    height: 1.2,
  );

  // Button Styles
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: facebookBlue,
    foregroundColor: white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    textStyle: buttonText,
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: hoverColor,
    foregroundColor: textPrimary,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    textStyle: buttonText.copyWith(color: textPrimary),
  );

  static ButtonStyle accentButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: tiktokPink,
    foregroundColor: white,
    elevation: 0,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    textStyle: buttonText,
  );

  static ButtonStyle outlinedButtonStyle = OutlinedButton.styleFrom(
    foregroundColor: facebookBlue,
    side: const BorderSide(color: facebookBlue, width: 1),
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(buttonRadius),
    ),
    textStyle: buttonText.copyWith(color: facebookBlue),
  );

  // Input Decoration
  static InputDecoration inputDecoration({
    String? hintText,
    String? labelText,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      labelText: labelText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: hoverColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: facebookBlue, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(inputRadius),
        borderSide: const BorderSide(color: error, width: 1),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      hintStyle: bodyMedium.copyWith(color: textTertiary),
      labelStyle: bodyMedium.copyWith(color: textSecondary),
    );
  }

  // Card Decoration
  static BoxDecoration cardDecoration({
    Color? color,
    List<BoxShadow>? boxShadow,
    Border? border,
  }) {
    return BoxDecoration(
      color: color ?? cardBackground,
      borderRadius: BorderRadius.circular(cardRadius),
      boxShadow: boxShadow ?? cardShadow,
      border: border,
    );
  }

  // Avatar Decoration
  static BoxDecoration avatarDecoration({
    Color? color,
    ImageProvider? image,
  }) {
    return BoxDecoration(
      color: color ?? hoverColor,
      borderRadius: BorderRadius.circular(avatarRadius),
      image: image != null
          ? DecorationImage(
              image: image,
              fit: BoxFit.cover,
            )
          : null,
    );
  }

  // Channel Type Badge
  static Widget channelTypeBadge(String type) {
    Color bgColor;
    Color textColor = white;
    String label;

    switch (type.toLowerCase()) {
      case 'public':
        bgColor = publicChannelColor;
        label = 'Public';
        break;
      case 'private':
        bgColor = privateChannelColor;
        label = 'Private';
        break;
      case 'premium':
        bgColor = premiumChannelColor;
        label = 'Premium';
        break;
      default:
        bgColor = textSecondary;
        label = type;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: caption.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // Verified Badge
  static Widget verifiedBadge({double size = 16}) {
    return Container(
      width: size,
      height: size,
      decoration: const BoxDecoration(
        color: facebookBlue,
        shape: BoxShape.circle,
      ),
      child: Icon(
        Icons.check,
        color: white,
        size: size * 0.7,
      ),
    );
  }

  // Engagement Button (like, comment, share)
  static Widget engagementButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    bool isActive = false,
    Color? activeColor,
  }) {
    final color = isActive ? (activeColor ?? tiktokPink) : textSecondary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(buttonRadius),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 6),
            Text(
              label,
              style: bodySmall.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Shimmer Loading Effect
  static Widget shimmerCard({double? width, double? height}) {
    return Container(
      width: width,
      height: height ?? 100,
      decoration: BoxDecoration(
        color: hoverColor,
        borderRadius: BorderRadius.circular(cardRadius),
      ),
    );
  }

  // Divider
  static Widget get dividerWidget => Container(
        height: 1,
        color: divider,
      );

  // Spacing Helpers
  static Widget verticalSpacing(double height) => SizedBox(height: height);
  static Widget horizontalSpacing(double width) => SizedBox(width: width);
}
