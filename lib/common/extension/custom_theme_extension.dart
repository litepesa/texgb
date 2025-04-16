import 'package:flutter/material.dart';

extension ExtendedTheme on BuildContext {
  CustomThemeExtension get theme {
    return Theme.of(this).extension<CustomThemeExtension>()!;
  }
}

class CustomThemeExtension extends ThemeExtension<CustomThemeExtension> {
  final Color? circleImageColor;
  final Color? greyColor;
  final Color? blueColor;
  final Color? langBgColor;
  final Color? langHightlightColor;
  final Color? authAppbarTextColor;
  final Color? photoIconBgColor;
  final Color? photoIconColor;
  final Color? profilePageBg;
  final Color? chatTextFieldBg;
  final Color? chatPageBgColor;
  final Color? chatPageDoodleColor;
  final Color? senderChatCardBg;
  final Color? receiverChatCardBg;
  final Color? yellowCardBgColor;
  final Color? yellowCardTextColor;

  const CustomThemeExtension({
    this.circleImageColor,
    this.greyColor,
    this.blueColor,
    this.langBgColor,
    this.langHightlightColor,
    this.authAppbarTextColor,
    this.photoIconBgColor,
    this.photoIconColor,
    this.profilePageBg,
    this.chatTextFieldBg,
    this.chatPageBgColor,
    this.chatPageDoodleColor,
    this.senderChatCardBg,
    this.receiverChatCardBg,
    this.yellowCardBgColor,
    this.yellowCardTextColor,
  });

  static const lightMode = CustomThemeExtension(
    circleImageColor: Color(0xFF25D366),          // WhatsApp status circle color
    greyColor: Color(0xFF667781),                 // Secondary text color
    blueColor: Color(0xFF027EB5),                 // Light mode selection color
    langBgColor: Color(0xFFF7F8FA),               // Language selection background
    langHightlightColor: Color(0xFFE8E8ED),       // Language selection highlight
    authAppbarTextColor: Color(0xFF008069),       // Auth page appbar text color
    photoIconBgColor: Color(0xFFF0F2F5),          // Photo icon background
    photoIconColor: Color(0xFF8696A0),            // Photo icon color
    profilePageBg: Color(0xFFF7F8FA),             // Profile page background
    chatTextFieldBg: Color(0xFFF0F2F5),           // Chat input field background
    chatPageBgColor: Color(0xFFE4DDD6),           // WhatsApp light chat background
    chatPageDoodleColor: Color(0xFFFFFFFF),       // WhatsApp chat doodle/pattern overlay
    senderChatCardBg: Color(0xFFD9FDD3),          // Sender message bubble (light green)
    receiverChatCardBg: Color(0xFFFFFFFF),        // Receiver message bubble (white)
    yellowCardBgColor: Color(0xFFFFF3C4),         // System message background
    yellowCardTextColor: Color(0xFF54656F),       // System message text color
  );

  static const darkMode = CustomThemeExtension(
    circleImageColor: Color(0xFF00A884),          // WhatsApp status circle dark
    greyColor: Color(0xFF8596A0),                 // Dark mode secondary text
    blueColor: Color(0xFF53BDEB),                 // Dark mode selection color
    langBgColor: Color(0xFF182229),               // Language selection background
    langHightlightColor: Color(0xFF09141A),       // Language selection highlight
    authAppbarTextColor: Color(0xFFE9EDEF),       // Auth page appbar text color
    photoIconBgColor: Color(0xFF283339),          // Photo icon background
    photoIconColor: Color(0xFF61717B),            // Photo icon color
    profilePageBg: Color(0xFF0B141A),             // Profile page background
    chatTextFieldBg: Color(0xFF1F2C34),           // Chat input field background
    chatPageBgColor: Color(0xFF0B141A),           // WhatsApp dark chat background
    chatPageDoodleColor: Color(0xFF172428),       // WhatsApp chat doodle/pattern overlay
    senderChatCardBg: Color(0xFF005C4B),          // Sender message bubble (dark teal)
    receiverChatCardBg: Color(0xFF1F2C34),        // Receiver message bubble (dark gray)
    yellowCardBgColor: Color(0xFF222E35),         // System message background
    yellowCardTextColor: Color(0xFFFFD279),       // System message text color
  );

  @override
  ThemeExtension<CustomThemeExtension> copyWith({
    Color? circleImageColor,
    Color? greyColor,
    Color? blueColor,
    Color? langBgColor,
    Color? langHightlightColor,
    Color? authAppbarTextColor,
    Color? photoIconBgColor,
    Color? photoIconColor,
    Color? profilePageBg,
    Color? chatTextFieldBg,
    Color? chatPageBgColor,
    Color? chatPageDoodleColor,
    Color? senderChatCardBg,
    Color? receiverChatCardBg,
    Color? yellowCardBgColor,
    Color? yellowCardTextColor,
  }) {
    return CustomThemeExtension(
      circleImageColor: circleImageColor ?? this.circleImageColor,
      greyColor: greyColor ?? this.greyColor,
      blueColor: blueColor ?? this.blueColor,
      langBgColor: langBgColor ?? this.langBgColor,
      langHightlightColor: langHightlightColor ?? this.langHightlightColor,
      authAppbarTextColor: authAppbarTextColor ?? this.authAppbarTextColor,
      photoIconBgColor: photoIconBgColor ?? this.photoIconBgColor,
      photoIconColor: photoIconColor ?? this.photoIconColor,
      profilePageBg: profilePageBg ?? this.profilePageBg,
      chatTextFieldBg: chatTextFieldBg ?? this.chatTextFieldBg,
      chatPageBgColor: chatPageBgColor ?? this.chatPageBgColor,
      chatPageDoodleColor: chatPageDoodleColor ?? this.chatPageDoodleColor,
      senderChatCardBg: senderChatCardBg ?? this.senderChatCardBg,
      receiverChatCardBg: receiverChatCardBg ?? this.receiverChatCardBg,
      yellowCardBgColor: yellowCardBgColor ?? this.yellowCardBgColor,
      yellowCardTextColor: yellowCardTextColor ?? this.yellowCardTextColor,
    );
  }

  @override
  ThemeExtension<CustomThemeExtension> lerp(
      ThemeExtension<CustomThemeExtension>? other, double t) {
    if (other is! CustomThemeExtension) return this;
    return CustomThemeExtension(
      circleImageColor: Color.lerp(circleImageColor, other.circleImageColor, t),
      greyColor: Color.lerp(greyColor, other.greyColor, t),
      blueColor: Color.lerp(blueColor, other.blueColor, t),
      langBgColor: Color.lerp(langBgColor, other.langBgColor, t),
      langHightlightColor:
          Color.lerp(langHightlightColor, other.langHightlightColor, t),
      authAppbarTextColor:
          Color.lerp(authAppbarTextColor, other.authAppbarTextColor, t),
      photoIconBgColor: Color.lerp(photoIconBgColor, other.photoIconBgColor, t),
      photoIconColor: Color.lerp(photoIconColor, other.photoIconColor, t),
      profilePageBg: Color.lerp(profilePageBg, other.profilePageBg, t),
      chatTextFieldBg: Color.lerp(chatTextFieldBg, other.chatTextFieldBg, t),
      chatPageBgColor: Color.lerp(chatPageBgColor, other.chatPageBgColor, t),
      senderChatCardBg: Color.lerp(senderChatCardBg, other.senderChatCardBg, t),
      yellowCardBgColor:
          Color.lerp(yellowCardBgColor, other.yellowCardBgColor, t),
      yellowCardTextColor:
          Color.lerp(yellowCardTextColor, other.yellowCardTextColor, t),
      receiverChatCardBg:
          Color.lerp(receiverChatCardBg, other.receiverChatCardBg, t),
      chatPageDoodleColor:
          Color.lerp(chatPageDoodleColor, other.chatPageDoodleColor, t),
    );
  }
}