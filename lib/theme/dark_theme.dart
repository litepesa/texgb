import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/common/extension/custom_theme_extension.dart';

ThemeData darkTheme() {
  final ThemeData base = ThemeData.dark();
  return base.copyWith(
    scaffoldBackgroundColor: const Color(0xFF121B22),  // WhatsApp dark background color
    extensions: [CustomThemeExtension.darkMode],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF111B21),  // WhatsApp dark mode app bar color
      titleTextStyle: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: Colors.white,  // WhatsApp uses white text in dark mode
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(
        color: Colors.white,  // WhatsApp uses white icons in dark mode
      ),
    ),
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Color(0xFF1F2C34),  // WhatsApp dark bottom nav background
      selectedItemColor: Color(0xFF00A884),  // WhatsApp's accent green for selected
      unselectedItemColor: Color(0xFF8596A0),  // Secondary text color for unselected
      selectedLabelStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      unselectedLabelStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: Color(0xFF00A884),  // WhatsApp's accent green color
          width: 2,
        ),
      ),
      unselectedLabelColor: Color(0xFF8596A0),  // Lighter grey for unselected tabs
      labelColor: Color(0xFF00A884),  // WhatsApp's accent green for selected tab
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF00A884),  // WhatsApp's accent green
        foregroundColor: Colors.white,
        splashFactory: NoSplash.splashFactory,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1F2C34),  // WhatsApp's dark mode modal color
      modalBackgroundColor: Color(0xFF1F2C34),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
    ),
    dialogBackgroundColor: const Color(0xFF1F2C34),  // WhatsApp's dark mode dialog color
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF00A884),  // WhatsApp's accent green
      foregroundColor: Colors.white,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Colors.white,  // WhatsApp uses white icons in dark mode
      tileColor: Color(0xFF121B22),  // WhatsApp's dark background color
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStatePropertyAll(Color(0xFF344047)),
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Colors.white),
      bodyMedium: const TextStyle(color: Colors.white),
      titleMedium: const TextStyle(color: Colors.white),
      titleSmall: TextStyle(color: Colors.grey[400]),
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFF262D31),  // WhatsApp's dark mode divider color
      thickness: 0.5,
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF8596A0),  // WhatsApp's secondary icon color
    ),
  );
}