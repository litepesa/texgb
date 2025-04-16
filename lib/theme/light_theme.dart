import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/common/extension/custom_theme_extension.dart';
import 'package:textgb/utilities/coloors.dart';

ThemeData lightTheme() {
  final ThemeData base = ThemeData.light();
  return base.copyWith(
    scaffoldBackgroundColor: Coloors.backgroundLight,
    extensions: [CustomThemeExtension.lightMode],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,  // WhatsApp's light theme app bar color
      titleTextStyle: TextStyle(
        fontSize: 25,
        fontWeight: FontWeight.bold,
        color: Color(0xFF25D366),
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,  // White status bar icons on green background
      ),
      iconTheme: IconThemeData(
        color: Colors.black,
      ),
    ),
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.white,  // White background for light mode
      selectedItemColor: Color(0xFF25D366),  // WhatsApp green for selected
      unselectedItemColor: Color(0xFF8696A0),  // Grey for unselected
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
          color: Colors.black,
          width: 2,
        ),
      ),
      unselectedLabelColor: Color(0xFF8696A0),  // Slightly transparent white for unselected tabs
      labelColor: Color(0xFF25D366),  // WhatsApp green for selected tab text
      unselectedLabelStyle: TextStyle(
        fontSize: 16,  // Adjust size for unselected tabs
        fontWeight: FontWeight.w500,
      ),
      labelStyle: TextStyle(
        fontSize: 18,  // Adjust size for selected tabs
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: Coloors.greenLight,
        foregroundColor: Colors.white,
        splashFactory: NoSplash.splashFactory,
        elevation: 0,
        shadowColor: Colors.transparent,
      ),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      modalBackgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
    ),
    dialogBackgroundColor: Colors.white,
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF008069),  // WhatsApp's light theme green
      foregroundColor: Colors.white,
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: Color(0xFF8696A0),  // WhatsApp's light theme secondary icon color
      tileColor: Colors.white,
    ),
    switchTheme: const SwitchThemeData(
      thumbColor: WidgetStatePropertyAll(Colors.white),
      trackColor: WidgetStatePropertyAll(Color(0xFF25D366)),  // WhatsApp's light green for active switch
    ),
    textTheme: TextTheme(
      bodyLarge: const TextStyle(color: Color(0xFF111B21)),  // Primary text color
      bodyMedium: const TextStyle(color: Color(0xFF111B21)),
      titleMedium: const TextStyle(color: Color(0xFF111B21)),
      titleSmall: TextStyle(color: Colors.grey[600]),  // Secondary text color
    ),
    dividerTheme: const DividerThemeData(
      color: Color(0xFFE9EDEF),  // WhatsApp's light divider color
      thickness: 0.5,
    ),
    iconTheme: const IconThemeData(
      color: Color(0xFF54656F),  // WhatsApp's light theme icon color
    ),
  );
}
