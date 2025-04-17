import 'package:flutter/material.dart';

extension ExtendedTheme on BuildContext {
  WeChatThemeExtension get theme {
    return Theme.of(this).extension<WeChatThemeExtension>()!;
  }
}

class WeChatThemeExtension extends ThemeExtension<WeChatThemeExtension> {
  final Color? backgroundColor;
  final Color? appBarColor;
  final Color? chatBackgroundColor;
  final Color? senderBubbleColor;
  final Color? receiverBubbleColor;
  final Color? senderTextColor;
  final Color? receiverTextColor;
  final Color? greyColor;
  final Color? statusColor;
  final Color? accentColor;
  final Color? statusCircleColor;
  final Color? dividerColor;
  final Color? systemMessageColor;
  final Color? systemMessageTextColor;

  const WeChatThemeExtension({
    this.backgroundColor,
    this.appBarColor,
    this.chatBackgroundColor,
    this.senderBubbleColor,
    this.receiverBubbleColor,
    this.senderTextColor,
    this.receiverTextColor,
    this.greyColor,
    this.statusColor,
    this.accentColor,
    this.statusCircleColor,
    this.dividerColor,
    this.systemMessageColor,
    this.systemMessageTextColor,
  });

  static const lightMode = WeChatThemeExtension(
    backgroundColor: Color(0xFFF6F6F6),        // WeChat light background color
    appBarColor: Color(0xFFEDEDED),            // WeChat app bar color in light mode
    chatBackgroundColor: Color(0xFFF5F5F5),    // WeChat chat background
    senderBubbleColor: Color(0xFF95EC69),      // WeChat green bubble for sender
    receiverBubbleColor: Color(0xFFFFFFFF),    // White bubble for receiver
    senderTextColor: Color(0xFF000000),        // Black text for sender
    receiverTextColor: Color(0xFF000000),      // Black text for receiver
    greyColor: Color(0xFF8E8E93),              // Secondary text color
    statusColor: Color(0xFF8E8E93),            // Status text color
    accentColor: Color(0xFF07C160),            // WeChat primary green
    statusCircleColor: Color(0xFF07C160),      // Status circle color
    dividerColor: Color(0xFFDBDBDB),           // Light divider color
    systemMessageColor: Color(0xFFCECECE),     // System message background
    systemMessageTextColor: Color(0xFF454545), // System message text
  );

  static const darkMode = WeChatThemeExtension(
    backgroundColor: Color(0xFF1F1F1F),        // WeChat dark background
    appBarColor: Color(0xFF2C2C2C),            // WeChat app bar color in dark mode
    chatBackgroundColor: Color(0xFF1F1F1F),    // WeChat chat background in dark
    senderBubbleColor: Color(0xFF5B9E4D),      // Darker green bubble for dark mode
    receiverBubbleColor: Color(0xFF323232),    // Dark bubble for receiver
    senderTextColor: Color(0xFFFFFFFF),        // White text for sender in dark mode
    receiverTextColor: Color(0xFFFFFFFF),      // White text for receiver in dark mode
    greyColor: Color(0xFF8E8E93),              // Secondary text color
    statusColor: Color(0xFF8E8E93),            // Status text color
    accentColor: Color(0xFF07C160),            // WeChat primary green
    statusCircleColor: Color(0xFF07C160),      // Status circle color
    dividerColor: Color(0xFF3D3D3D),           // Dark divider color
    systemMessageColor: Color(0xFF3A3A3A),     // System message background
    systemMessageTextColor: Color(0xFFBBBBBB), // System message text
  );

  @override
  ThemeExtension<WeChatThemeExtension> copyWith({
    Color? backgroundColor,
    Color? appBarColor,
    Color? chatBackgroundColor,
    Color? senderBubbleColor,
    Color? receiverBubbleColor,
    Color? senderTextColor,
    Color? receiverTextColor,
    Color? greyColor,
    Color? statusColor,
    Color? accentColor,
    Color? statusCircleColor,
    Color? dividerColor,
    Color? systemMessageColor,
    Color? systemMessageTextColor,
  }) {
    return WeChatThemeExtension(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      appBarColor: appBarColor ?? this.appBarColor,
      chatBackgroundColor: chatBackgroundColor ?? this.chatBackgroundColor,
      senderBubbleColor: senderBubbleColor ?? this.senderBubbleColor,
      receiverBubbleColor: receiverBubbleColor ?? this.receiverBubbleColor,
      senderTextColor: senderTextColor ?? this.senderTextColor,
      receiverTextColor: receiverTextColor ?? this.receiverTextColor,
      greyColor: greyColor ?? this.greyColor,
      statusColor: statusColor ?? this.statusColor,
      accentColor: accentColor ?? this.accentColor,
      statusCircleColor: statusCircleColor ?? this.statusCircleColor,
      dividerColor: dividerColor ?? this.dividerColor,
      systemMessageColor: systemMessageColor ?? this.systemMessageColor,
      systemMessageTextColor: systemMessageTextColor ?? this.systemMessageTextColor,
    );
  }

  @override
  ThemeExtension<WeChatThemeExtension> lerp(
      ThemeExtension<WeChatThemeExtension>? other, double t) {
    if (other is! WeChatThemeExtension) return this;
    return WeChatThemeExtension(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      appBarColor: Color.lerp(appBarColor, other.appBarColor, t),
      chatBackgroundColor: Color.lerp(chatBackgroundColor, other.chatBackgroundColor, t),
      senderBubbleColor: Color.lerp(senderBubbleColor, other.senderBubbleColor, t),
      receiverBubbleColor: Color.lerp(receiverBubbleColor, other.receiverBubbleColor, t),
      senderTextColor: Color.lerp(senderTextColor, other.senderTextColor, t),
      receiverTextColor: Color.lerp(receiverTextColor, other.receiverTextColor, t),
      greyColor: Color.lerp(greyColor, other.greyColor, t),
      statusColor: Color.lerp(statusColor, other.statusColor, t),
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      statusCircleColor: Color.lerp(statusCircleColor, other.statusCircleColor, t),
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t),
      systemMessageColor: Color.lerp(systemMessageColor, other.systemMessageColor, t),
      systemMessageTextColor: Color.lerp(systemMessageTextColor, other.systemMessageTextColor, t),
    );
  }
}