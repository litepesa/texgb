import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'modern_colors.dart';
import 'theme_extensions.dart';

ThemeData modernLightTheme() {
  final ThemeData base = ThemeData.light();
  
  // Define font styles with Google Fonts
  final textTheme = _createTextTheme();
  
  return base.copyWith(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: ModernColors.primaryTeal,
      brightness: Brightness.light,
      primary: ModernColors.primaryTeal,
      secondary: ModernColors.accentTealBlue,
    ),
    scaffoldBackgroundColor: ModernColors.lightBackground,
    
    // Extensions
    extensions: [
      ModernThemeExtension.lightMode,
      ChatThemeExtension.lightMode,
      const ResponsiveThemeExtension(),
      const AnimationThemeExtension(),
    ],
    
    // AppBar Theme
    appBarTheme: const AppBarTheme(
      backgroundColor: ModernColors.lightAppBar,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: ModernColors.lightText,
      ),
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
      iconTheme: IconThemeData(
        color: ModernColors.primaryTeal,
        size: 24,
      ),
    ),
    
    // Text Theme
    textTheme: textTheme,
    
    // Bottom Navigation Theme
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: ModernColors.lightSurface,
      selectedItemColor: ModernColors.primaryTeal,
      unselectedItemColor: ModernColors.lightTextSecondary,
      selectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      unselectedLabelStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
      showSelectedLabels: true,
      showUnselectedLabels: true,
      type: BottomNavigationBarType.fixed,
      elevation: 8,
    ),
    
    // Tab Bar Theme
    tabBarTheme: const TabBarTheme(
      indicator: UnderlineTabIndicator(
        borderSide: BorderSide(
          color: ModernColors.primaryTeal,
          width: 2,
        ),
      ),
      unselectedLabelColor: ModernColors.lightTextSecondary,
      labelColor: ModernColors.primaryTeal,
      unselectedLabelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.normal,
      ),
      labelStyle: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    ),
    
    // Button Themes
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: ModernColors.primaryTeal,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: ModernColors.primaryTeal,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        side: const BorderSide(color: ModernColors.primaryTeal, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: ModernColors.primaryTeal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        textStyle: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
    ),
    
    // Card Theme
    cardTheme: CardTheme(
      color: ModernColors.lightSurface,
      elevation: 1,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
    ),
    
    // Modal and Dialog Themes
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: ModernColors.lightSurface,
      modalBackgroundColor: ModernColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
    ),
    
    dialogBackgroundColor: ModernColors.lightSurface,
    dialogTheme: DialogTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: ModernColors.lightSurface,
      elevation: 8,
      titleTextStyle: const TextStyle(
        color: ModernColors.lightText,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      contentTextStyle: const TextStyle(
        color: ModernColors.lightText,
        fontSize: 16,
      ),
    ),
    
    // FAB Theme
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: ModernColors.primaryTeal,
      foregroundColor: Colors.white,
      elevation: 2,
      highlightElevation: 4,
      splashColor: Colors.white.withOpacity(0.2),
      shape: const CircleBorder(),
      extendedPadding: const EdgeInsets.all(16),
    ),
    
    // List Tile Theme
    listTileTheme: ListTileThemeData(
      iconColor: ModernColors.lightTextSecondary,
      textColor: ModernColors.lightText,
      tileColor: ModernColors.lightSurface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
      minLeadingWidth: 20,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      selectedTileColor: ModernColors.primaryTeal.withOpacity(0.05),
      selectedColor: ModernColors.primaryTeal,
    ),
    
    // Switch Theme
    switchTheme: SwitchThemeData(
      thumbColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ModernColors.primaryTeal;
        }
        return Colors.white;
      }),
      trackColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ModernColors.primaryTeal.withOpacity(0.3);
        }
        return ModernColors.lightTextTertiary.withOpacity(0.3);
      }),
      trackOutlineColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return Colors.transparent;
        }
        return Colors.transparent;
      }),
    ),
    
    // Checkbox Theme
    checkboxTheme: CheckboxThemeData(
      fillColor: MaterialStateProperty.resolveWith((states) {
        if (states.contains(MaterialState.selected)) {
          return ModernColors.primaryTeal;
        }
        return Colors.transparent;
      }),
      checkColor: MaterialStateProperty.resolveWith((states) {
        return Colors.white;
      }),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
      side: const BorderSide(
        color: ModernColors.lightTextTertiary,
        width: 1.5,
      ),
    ),
    
    // Divider Theme
    dividerTheme: const DividerThemeData(
      color: ModernColors.lightDivider,
      thickness: 1,
      indent: 16,
      endIndent: 16,
    ),
    
    // Icon Theme
    iconTheme: const IconThemeData(
      color: ModernColors.lightTextSecondary,
      size: 24,
    ),
    
    // Input Decoration Theme
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: ModernColors.lightInputBackground,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: ModernColors.primaryTeal, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(24),
        borderSide: const BorderSide(color: ModernColors.error, width: 1.5),
      ),
      hintStyle: const TextStyle(color: ModernColors.lightTextTertiary),
      labelStyle: const TextStyle(color: ModernColors.lightTextSecondary),
      helperStyle: const TextStyle(color: ModernColors.lightTextTertiary, fontSize: 12),
      errorStyle: const TextStyle(color: ModernColors.error, fontSize: 12),
      prefixIconColor: ModernColors.lightTextSecondary,
      suffixIconColor: ModernColors.lightTextSecondary,
    ),
    
    // Chip Theme
    chipTheme: ChipThemeData(
      backgroundColor: ModernColors.lightSurfaceVariant,
      disabledColor: ModernColors.lightSurfaceVariant.withOpacity(0.5),
      selectedColor: ModernColors.primaryTeal.withOpacity(0.2),
      secondarySelectedColor: ModernColors.primaryTeal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      labelStyle: const TextStyle(
        color: ModernColors.lightText,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
    ),
    
    // Slider Theme
    sliderTheme: const SliderThemeData(
      activeTrackColor: ModernColors.primaryTeal,
      inactiveTrackColor: ModernColors.lightTextTertiary,
      thumbColor: ModernColors.primaryTeal,
      overlayColor: Color(0x29008069),
      trackHeight: 4.0,
    ),
    
    // Progress Indicator Theme
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: ModernColors.primaryTeal,
      circularTrackColor: ModernColors.lightSurfaceVariant,
      linearTrackColor: ModernColors.lightSurfaceVariant,
    ),
    
    // Page Transitions Theme
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    
    // Snack Bar Theme
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Colors.white,
      contentTextStyle: const TextStyle(color: ModernColors.lightText),
      actionTextColor: ModernColors.primaryTeal,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      behavior: SnackBarBehavior.floating,
    ),
    
    // Banner Theme
    bannerTheme: const MaterialBannerThemeData(
      backgroundColor: ModernColors.lightSurfaceVariant,
      contentTextStyle: TextStyle(color: ModernColors.lightText),
      padding: EdgeInsets.all(16),
    ),
    
    // Bottom App Bar Theme
    bottomAppBarTheme: const BottomAppBarTheme(
      color: ModernColors.lightSurface,
      elevation: 8,
      shape: CircularNotchedRectangle(),
    ),
  );
}

TextTheme _createTextTheme() {
  return TextTheme(
    displayLarge: GoogleFonts.inter(
      fontSize: 57, 
      fontWeight: FontWeight.w400,
      letterSpacing: -0.25,
      color: ModernColors.lightText,
    ),
    displayMedium: GoogleFonts.inter(
      fontSize: 45, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: ModernColors.lightText,
    ),
    displaySmall: GoogleFonts.inter(
      fontSize: 36, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0,
      color: ModernColors.lightText,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 32, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: ModernColors.lightText,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 28, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: ModernColors.lightText,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 24, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0,
      color: ModernColors.lightText,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0,
      color: ModernColors.lightText,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.15,
      color: ModernColors.lightText,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w600,
      letterSpacing: 0.1,
      color: ModernColors.lightText,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.5,
      color: ModernColors.lightText,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.25,
      color: ModernColors.lightText,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12, 
      fontWeight: FontWeight.w400,
      letterSpacing: 0.4,
      color: ModernColors.lightTextSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.1,
      color: ModernColors.lightText,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: ModernColors.lightText,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, 
      fontWeight: FontWeight.w500,
      letterSpacing: 0.5,
      color: ModernColors.lightTextSecondary,
    ),
  );
}