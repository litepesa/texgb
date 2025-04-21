import 'package:flutter/material.dart';

class ColorPickerRow extends StatelessWidget {
  final String selectedColor;
  final Function(String) onColorSelected;
  final List<String> colors;

  const ColorPickerRow({
    Key? key,
    required this.selectedColor,
    required this.onColorSelected,
    required this.colors,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: colors.length,
        itemBuilder: (context, index) {
          final color = colors[index];
          final isSelected = selectedColor == color;
          
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: _parseColor(color),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey,
                  width: isSelected ? 3 : 1,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: isSelected
                  ? Icon(
                      Icons.check,
                      color: _isLightColor(color) ? Colors.black : Colors.white,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }

  // Helper function to parse hex color
  Color _parseColor(String hexCode) {
    try {
      hexCode = hexCode.replaceAll('#', '');
      if (hexCode.length == 6) {
        hexCode = 'FF$hexCode';
      }
      return Color(int.parse(hexCode, radix: 16));
    } catch (e) {
      return hexCode.toLowerCase() == '#ffffff' ? Colors.white : Colors.black;
    }
  }

  // Helper function to determine if a color is light or dark
  bool _isLightColor(String hexCode) {
    final color = _parseColor(hexCode);
    // Convert color to grayscale value using perceptual weights
    final luminance = (0.299 * color.red + 0.587 * color.green + 0.114 * color.blue) / 255;
    // Return true if color is light
    return luminance > 0.5;
  }
}