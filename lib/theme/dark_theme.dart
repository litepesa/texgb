import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';

ThemeData wechatDarkTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF1F1F1F),  // WeChat dark background
    extensions: [WeChatThemeExtension.darkMode],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF2C2C2C),  // WeChat dark app bar color
      elevation: 0,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,  // White text in WeChat dark mode
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,  // White icons in WeChat dark mode
      ),
    ),
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF2C2C2C),  // WeChat dark bottom nav background
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
      color: const Color(0xFF2C2C2C),  // Slightly lighter than background
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF2C2C2C),
      modalBackgroundColor: Color(0xFF2C2C2C),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(12),
        ),
      ),
    ),
    dialogBackgroundColor: const Color(0xFF2C2C2C),
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      backgroundColor: const Color(0xFF2C2C2C),
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
      textColor: Colors.white,
      tileColor: Color(0xFF2C2C2C),
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
      color: Color(0xFF3D3D3D),  // WeChat dark divider color
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
      fillColor: const Color(0xFF323232),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF3D3D3D), width: 0.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF3D3D3D), width: 0.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(4),
        borderSide: const BorderSide(color: Color(0xFF07C160), width: 1),
      ),
      hintStyle: const TextStyle(color: Color(0xFF8E8E93)),
    ),
    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: Colors.white),
      bodyMedium: TextStyle(color: Colors.white),
      titleMedium: TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Color(0xFF8E8E93)),
    ),
  );
}