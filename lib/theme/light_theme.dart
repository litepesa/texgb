import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';

ThemeData wechatLightTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFFF6F6F6),  // WeChat light background
    extensions: [WeChatThemeExtension.lightMode],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFEDEDED),     // WeChat app bar color
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Color(0xFF000000),  // Black text in WeChat light mode
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(
        color: Color(0xFF000000),  // Black icons in WeChat light mode
      ),
    ),
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFFEDEDED),  // WeChat bottom nav background
      selectedItemColor: Color(0xFF07C160),  // WeChat green for selected
      unselectedItemColor: Color(0xFF8E8E93),  // Secondary text color for unselected
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: Color(0xFF07C160),  // WeChat green
          width: 2,
        ),
      ),
      unselectedLabelColor: Color(0xFF8E8E93),  // Grey for unselected tabs
      labelColor: Color(0xFF07C160),  // WeChat green for selected tab
      unselectedLabelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      labelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF07C160),  // WeChat green
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4), // WeChat uses subtle rounded corners
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF07C160),
        side: const BorderSide(color: Color(0xFF07C160)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFF07C160),
      ),
    ),
    cardTheme: CardTheme(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
    ),
    dialogBackgroundColor: Colors.white,
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: Colors.white,
      elevation: 24,
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF07C160),  // WeChat green
      foregroundColor: Colors.white,
      elevation: 0,
      shape: CircleBorder(),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF8E8E93),
      textColor: Color(0xFF000000),
      tileColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 20,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF07C160); // WeChat green when on
        }
        return Colors.white; // White when off
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return const Color(0xFF07C160).withOpacity(0.5); // Transparent green when on
        }
        return Colors.grey.withOpacity(0.5); // Grey when off
      }),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFDBDBDB),  // WeChat light divider color
      thickness: 0.5,
      indent: 16,
      endIndent: 16,
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF8E8E93),  // WeChat secondary color
      size: 24,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFDBDBDB), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFFDBDBDB), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF07C160), width: 1),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
    ),
  );
}