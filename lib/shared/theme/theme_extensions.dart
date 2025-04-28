import 'package:flutter/material.dart';
import 'modern_colors.dart';

/// Helper extension to easily access theme extensions from BuildContext
extension ExtendedTheme on BuildContext {
  ModernThemeExtension get modernTheme {
    return Theme.of(this).extension<ModernThemeExtension>()!;
  }

  ResponsiveThemeExtension get responsiveTheme {
    return Theme.of(this).extension<ResponsiveThemeExtension>()!;
  }

  AnimationThemeExtension get animationTheme {
    return Theme.of(this).extension<AnimationThemeExtension>()!;
  }

  ChatThemeExtension get chatTheme {
    return Theme.of(this).extension<ChatThemeExtension>()!;
  }
}

/// Modern theme extension for app-specific styling
class ModernThemeExtension extends ThemeExtension<ModernThemeExtension> {
  final Color? backgroundColor;
  final Color? surfaceColor;
  final Color? surfaceVariantColor;
  final Color? appBarColor;
  final Color? textColor;
  final Color? textSecondaryColor;
  final Color? textTertiaryColor;
  final Color? dividerColor;
  final Color? primaryColor;
  final Color? secondaryColor;
  final Color? accentColor;
  final Color? borderColor;

  const ModernThemeExtension({
    this.backgroundColor,
    this.surfaceColor,
    this.surfaceVariantColor,
    this.appBarColor,
    this.textColor,
    this.textSecondaryColor,
    this.textTertiaryColor,
    this.dividerColor,
    this.primaryColor,
    this.secondaryColor,
    this.accentColor,
    this.borderColor,
  });

  static const lightMode = ModernThemeExtension(
    backgroundColor: ModernColors.lightBackground,
    surfaceColor: ModernColors.lightSurface,
    surfaceVariantColor: ModernColors.lightSurfaceVariant,
    appBarColor: ModernColors.lightAppBar,
    textColor: ModernColors.lightText,
    textSecondaryColor: ModernColors.lightTextSecondary,
    textTertiaryColor: ModernColors.lightTextTertiary,
    dividerColor: ModernColors.lightDivider,
    primaryColor: ModernColors.primaryTeal,
    secondaryColor: ModernColors.accentTealBlue,
    accentColor: ModernColors.success,
    borderColor: ModernColors.lightBorder,
  );

  static const darkMode = ModernThemeExtension(
    backgroundColor: ModernColors.darkBackground,
    surfaceColor: ModernColors.darkSurface,
    surfaceVariantColor: ModernColors.darkSurfaceVariant,
    appBarColor: ModernColors.darkAppBar,
    textColor: ModernColors.darkText,
    textSecondaryColor: ModernColors.darkTextSecondary,
    textTertiaryColor: ModernColors.darkTextTertiary,
    dividerColor: ModernColors.darkDivider,
    primaryColor: ModernColors.primaryGreen,
    secondaryColor: ModernColors.accentBlue,
    accentColor: ModernColors.success,
    borderColor: ModernColors.darkBorder,
  );

  get inputBackgroundColor => null;

  @override
  ThemeExtension<ModernThemeExtension> copyWith({
    Color? backgroundColor,
    Color? surfaceColor,
    Color? surfaceVariantColor,
    Color? appBarColor,
    Color? textColor,
    Color? textSecondaryColor,
    Color? textTertiaryColor,
    Color? dividerColor,
    Color? primaryColor,
    Color? secondaryColor,
    Color? accentColor,
    Color? borderColor,
  }) {
    return ModernThemeExtension(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      surfaceVariantColor: surfaceVariantColor ?? this.surfaceVariantColor,
      appBarColor: appBarColor ?? this.appBarColor,
      textColor: textColor ?? this.textColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      textTertiaryColor: textTertiaryColor ?? this.textTertiaryColor,
      dividerColor: dividerColor ?? this.dividerColor,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      accentColor: accentColor ?? this.accentColor,
      borderColor: borderColor ?? this.borderColor,
    );
  }

  @override
  ThemeExtension<ModernThemeExtension> lerp(
      ThemeExtension<ModernThemeExtension>? other, double t) {
    if (other is! ModernThemeExtension) return this;
    return ModernThemeExtension(
      backgroundColor: Color.lerp(backgroundColor, other.backgroundColor, t),
      surfaceColor: Color.lerp(surfaceColor, other.surfaceColor, t),
      surfaceVariantColor: Color.lerp(surfaceVariantColor, other.surfaceVariantColor, t),
      appBarColor: Color.lerp(appBarColor, other.appBarColor, t),
      textColor: Color.lerp(textColor, other.textColor, t),
      textSecondaryColor: Color.lerp(textSecondaryColor, other.textSecondaryColor, t),
      textTertiaryColor: Color.lerp(textTertiaryColor, other.textTertiaryColor, t),
      dividerColor: Color.lerp(dividerColor, other.dividerColor, t),
      primaryColor: Color.lerp(primaryColor, other.primaryColor, t),
      secondaryColor: Color.lerp(secondaryColor, other.secondaryColor, t),
      accentColor: Color.lerp(accentColor, other.accentColor, t),
      borderColor: Color.lerp(borderColor, other.borderColor, t),
    );
  }
}

/// Chat-specific theme extension
class ChatThemeExtension extends ThemeExtension<ChatThemeExtension> {
  final Color? chatBackgroundColor;
  final Color? senderBubbleColor;
  final Color? receiverBubbleColor;
  final Color? senderTextColor;
  final Color? receiverTextColor;
  final Color? systemMessageColor;
  final Color? systemMessageTextColor;
  final Color? timestampColor;
  final Color? inputBackgroundColor;
  final BorderRadius? senderBubbleRadius;
  final BorderRadius? receiverBubbleRadius;

  const ChatThemeExtension({
    this.chatBackgroundColor,
    this.senderBubbleColor,
    this.receiverBubbleColor,
    this.senderTextColor,
    this.receiverTextColor,
    this.systemMessageColor,
    this.systemMessageTextColor,
    this.timestampColor,
    this.inputBackgroundColor,
    this.senderBubbleRadius,
    this.receiverBubbleRadius,
  });

  static final lightMode = ChatThemeExtension(
    chatBackgroundColor: ModernColors.lightChatBackground,
    senderBubbleColor: ModernColors.lightSenderBubble,
    receiverBubbleColor: ModernColors.lightReceiverBubble,
    senderTextColor: ModernColors.lightText,
    receiverTextColor: ModernColors.lightText,
    systemMessageColor: ModernColors.lightSystemMessage,
    systemMessageTextColor: ModernColors.lightTextSecondary,
    timestampColor: ModernColors.lightTextTertiary,
    inputBackgroundColor: ModernColors.lightInputBackground,
    senderBubbleRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4),
    ),
    receiverBubbleRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    ),
  );

  static final darkMode = ChatThemeExtension(
    chatBackgroundColor: ModernColors.darkChatBackground,
    senderBubbleColor: ModernColors.darkSenderBubble,
    receiverBubbleColor: ModernColors.darkReceiverBubble,
    senderTextColor: ModernColors.darkText,
    receiverTextColor: ModernColors.darkText,
    systemMessageColor: ModernColors.darkSystemMessage,
    systemMessageTextColor: ModernColors.darkTextSecondary,
    timestampColor: ModernColors.darkTextTertiary,
    inputBackgroundColor: ModernColors.darkInputBackground,
    senderBubbleRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(16),
      bottomRight: Radius.circular(4),
    ),
    receiverBubbleRadius: const BorderRadius.only(
      topLeft: Radius.circular(16),
      topRight: Radius.circular(16),
      bottomLeft: Radius.circular(4),
      bottomRight: Radius.circular(16),
    ),
  );

  @override
  ThemeExtension<ChatThemeExtension> copyWith({
    Color? chatBackgroundColor,
    Color? senderBubbleColor,
    Color? receiverBubbleColor,
    Color? senderTextColor,
    Color? receiverTextColor,
    Color? systemMessageColor,
    Color? systemMessageTextColor,
    Color? timestampColor,
    Color? inputBackgroundColor,
    BorderRadius? senderBubbleRadius,
    BorderRadius? receiverBubbleRadius,
  }) {
    return ChatThemeExtension(
      chatBackgroundColor: chatBackgroundColor ?? this.chatBackgroundColor,
      senderBubbleColor: senderBubbleColor ?? this.senderBubbleColor,
      receiverBubbleColor: receiverBubbleColor ?? this.receiverBubbleColor,
      senderTextColor: senderTextColor ?? this.senderTextColor,
      receiverTextColor: receiverTextColor ?? this.receiverTextColor,
      systemMessageColor: systemMessageColor ?? this.systemMessageColor,
      systemMessageTextColor: systemMessageTextColor ?? this.systemMessageTextColor,
      timestampColor: timestampColor ?? this.timestampColor,
      inputBackgroundColor: inputBackgroundColor ?? this.inputBackgroundColor,
      senderBubbleRadius: senderBubbleRadius ?? this.senderBubbleRadius,
      receiverBubbleRadius: receiverBubbleRadius ?? this.receiverBubbleRadius,
    );
  }

  @override
  ThemeExtension<ChatThemeExtension> lerp(
      ThemeExtension<ChatThemeExtension>? other, double t) {
    if (other is! ChatThemeExtension) return this;
    return ChatThemeExtension(
      chatBackgroundColor: Color.lerp(chatBackgroundColor, other.chatBackgroundColor, t),
      senderBubbleColor: Color.lerp(senderBubbleColor, other.senderBubbleColor, t),
      receiverBubbleColor: Color.lerp(receiverBubbleColor, other.receiverBubbleColor, t),
      senderTextColor: Color.lerp(senderTextColor, other.senderTextColor, t),
      receiverTextColor: Color.lerp(receiverTextColor, other.receiverTextColor, t),
      systemMessageColor: Color.lerp(systemMessageColor, other.systemMessageColor, t),
      systemMessageTextColor: Color.lerp(systemMessageTextColor, other.systemMessageTextColor, t),
      timestampColor: Color.lerp(timestampColor, other.timestampColor, t),
      inputBackgroundColor: Color.lerp(inputBackgroundColor, other.inputBackgroundColor, t),
      senderBubbleRadius: BorderRadius.lerp(senderBubbleRadius, other.senderBubbleRadius, t),
      receiverBubbleRadius: BorderRadius.lerp(receiverBubbleRadius, other.receiverBubbleRadius, t),
    );
  }
}

/// Responsive spacing and sizing theme extension
class ResponsiveThemeExtension extends ThemeExtension<ResponsiveThemeExtension> {
  final double compactSpacing;
  final double mediumSpacing;
  final double expandedSpacing;
  final double compactRadius;
  final double mediumRadius;
  final double expandedRadius;

  const ResponsiveThemeExtension({
    this.compactSpacing = 8.0,
    this.mediumSpacing = 16.0, 
    this.expandedSpacing = 24.0,
    this.compactRadius = 8.0,
    this.mediumRadius = 16.0,
    this.expandedRadius = 24.0,
  });

  /// Get responsive spacing based on constraints
  double getResponsiveSpacing(BoxConstraints constraints) {
    if (constraints.maxWidth < 600) return compactSpacing;
    if (constraints.maxWidth < 840) return mediumSpacing;
    return expandedSpacing;
  }

  /// Get responsive radius based on constraints
  double getResponsiveRadius(BoxConstraints constraints) {
    if (constraints.maxWidth < 600) return compactRadius;
    if (constraints.maxWidth < 840) return mediumRadius;
    return expandedRadius;
  }

  @override
  ThemeExtension<ResponsiveThemeExtension> copyWith({
    double? compactSpacing,
    double? mediumSpacing,
    double? expandedSpacing,
    double? compactRadius,
    double? mediumRadius,
    double? expandedRadius,
  }) {
    return ResponsiveThemeExtension(
      compactSpacing: compactSpacing ?? this.compactSpacing,
      mediumSpacing: mediumSpacing ?? this.mediumSpacing,
      expandedSpacing: expandedSpacing ?? this.expandedSpacing,
      compactRadius: compactRadius ?? this.compactRadius,
      mediumRadius: mediumRadius ?? this.mediumRadius,
      expandedRadius: expandedRadius ?? this.expandedRadius,
    );
  }

  @override
  ThemeExtension<ResponsiveThemeExtension> lerp(
      ThemeExtension<ResponsiveThemeExtension>? other, double t) {
    if (other is! ResponsiveThemeExtension) return this;
    return ResponsiveThemeExtension(
      compactSpacing: lerpDouble(compactSpacing, other.compactSpacing, t)!,
      mediumSpacing: lerpDouble(mediumSpacing, other.mediumSpacing, t)!,
      expandedSpacing: lerpDouble(expandedSpacing, other.expandedSpacing, t)!,
      compactRadius: lerpDouble(compactRadius, other.compactRadius, t)!,
      mediumRadius: lerpDouble(mediumRadius, other.mediumRadius, t)!,
      expandedRadius: lerpDouble(expandedRadius, other.expandedRadius, t)!,
    );
  }
}

/// Animation durations and curves theme extension
class AnimationThemeExtension extends ThemeExtension<AnimationThemeExtension> {
  final Duration shortDuration;
  final Duration mediumDuration;
  final Duration longDuration;
  final Curve standardCurve;
  final Curve emphasizedCurve;
  
  const AnimationThemeExtension({
    this.shortDuration = const Duration(milliseconds: 150),
    this.mediumDuration = const Duration(milliseconds: 300),
    this.longDuration = const Duration(milliseconds: 500),
    this.standardCurve = Curves.easeInOut,
    this.emphasizedCurve = Curves.easeOutCubic,
  });

  @override
  ThemeExtension<AnimationThemeExtension> copyWith({
    Duration? shortDuration,
    Duration? mediumDuration,
    Duration? longDuration,
    Curve? standardCurve,
    Curve? emphasizedCurve,
  }) {
    return AnimationThemeExtension(
      shortDuration: shortDuration ?? this.shortDuration,
      mediumDuration: mediumDuration ?? this.mediumDuration,
      longDuration: longDuration ?? this.longDuration,
      standardCurve: standardCurve ?? this.standardCurve,
      emphasizedCurve: emphasizedCurve ?? this.emphasizedCurve,
    );
  }

  @override
  ThemeExtension<AnimationThemeExtension> lerp(
      ThemeExtension<AnimationThemeExtension>? other, double t) {
    if (other is! AnimationThemeExtension) return this;
    // Duration can't be lerped, so we return the target duration when t > 0.5
    return AnimationThemeExtension(
      shortDuration: t > 0.5 ? other.shortDuration : shortDuration,
      mediumDuration: t > 0.5 ? other.mediumDuration : mediumDuration,
      longDuration: t > 0.5 ? other.longDuration : longDuration,
      standardCurve: t > 0.5 ? other.standardCurve : standardCurve,
      emphasizedCurve: t > 0.5 ? other.emphasizedCurve : emphasizedCurve,
    );
  }
}

/// Helper to lerp doubles that might be null
double? lerpDouble(double? a, double? b, double t) {
  if (a == null && b == null) return null;
  if (a == null) return b! * t;
  if (b == null) return a * (1.0 - t);
  return a + (b - a) * t;
}