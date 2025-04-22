import 'package:flutter/material.dart';

class StatusTextContent extends StatelessWidget {
  final String text;
  final Map<String, String> backgroundInfo;
  final bool previewMode;

  const StatusTextContent({
    Key? key,
    required this.text,
    required this.backgroundInfo,
    this.previewMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Parse background color from string
    final bgColorString = backgroundInfo['color'] ?? '0xFF09BB07'; // Default to green
    final bgColor = Color(int.parse(bgColorString.replaceFirst('0x', ''), radix: 16));
    
    // Get font family
    final fontFamily = backgroundInfo['fontFamily'] ?? 'Roboto';
    
    // Get text alignment
    TextAlign textAlign;
    switch (backgroundInfo['alignment']) {
      case 'left':
        textAlign = TextAlign.left;
        break;
      case 'right':
        textAlign = TextAlign.right;
        break;
      case 'center':
      default:
        textAlign = TextAlign.center;
    }
    
    // Background decoration - can be solid color or gradient
    BoxDecoration getDecoration() {
      if (backgroundInfo.containsKey('gradient')) {
        // If gradient is specified
        final gradientColors = (backgroundInfo['gradient'] ?? '')
            .split(',')
            .map((colorStr) => Color(int.parse(colorStr.trim().replaceFirst('0x', ''), radix: 16)))
            .toList();
        
        if (gradientColors.length >= 2) {
          return BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradientColors,
            ),
          );
        }
      }
      
      // Default to solid color
      return BoxDecoration(
        color: bgColor,
      );
    }
    
    return Container(
      decoration: getDecoration(),
      padding: previewMode 
          ? const EdgeInsets.all(8.0) 
          : const EdgeInsets.all(32.0),
      width: double.infinity,
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontFamily: fontFamily,
            fontSize: previewMode ? 14.0 : 24.0,
            fontWeight: FontWeight.bold,
            color: _getContrastingTextColor(bgColor),
            height: 1.5,
          ),
          textAlign: textAlign,
        ),
      ),
    );
  }
  
  // Calculate contrasting text color (black or white) based on background color
  Color _getContrastingTextColor(Color backgroundColor) {
    // Calculate relative luminance using the formula for sRGB
    final double r = backgroundColor.red / 255.0;
    final double g = backgroundColor.green / 255.0;
    final double b = backgroundColor.blue / 255.0;
    
    final double rLinear = r <= 0.03928 ? r / 12.92 : Math.pow((r + 0.055) / 1.055, 2.4);
    final double gLinear = g <= 0.03928 ? g / 12.92 : Math.pow((g + 0.055) / 1.055, 2.4);
    final double bLinear = b <= 0.03928 ? b / 12.92 : Math.pow((b + 0.055) / 1.055, 2.4);
    
    final double luminance = 0.2126 * rLinear + 0.7152 * gLinear + 0.0722 * bLinear;
    
    // Use white text for dark backgrounds, black text for light backgrounds
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

// Dart Math.pow workaround
class Math {
  static double pow(double x, double exponent) {
    return x.pow(exponent);
  }
}

// Extension method for double.pow
extension DoublePowExtension on double {
  double pow(double exponent) {
    return double.parse((this).toStringAsFixed(10)).toDouble().pow(exponent);
  }
}