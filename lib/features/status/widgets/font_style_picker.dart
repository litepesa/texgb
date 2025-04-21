import 'package:flutter/material.dart';

class FontStylePicker extends StatelessWidget {
  final String selectedStyle;
  final Function(String) onStyleSelected;

  const FontStylePicker({
    Key? key,
    required this.selectedStyle,
    required this.onStyleSelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // List of font styles to choose from
    final fontStyles = [
      {'name': 'Normal', 'value': 'normal'},
      {'name': 'Roboto', 'value': 'Roboto'},
      {'name': 'Playfair', 'value': 'Playfair'},
      {'name': 'Oswald', 'value': 'Oswald'},
      {'name': 'Raleway', 'value': 'Raleway'},
      {'name': 'Ubuntu', 'value': 'Ubuntu'},
    ];

    return SizedBox(
      height: 50,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: fontStyles.length,
        itemBuilder: (context, index) {
          final style = fontStyles[index];
          final isSelected = selectedStyle == style['value'];
          
          return GestureDetector(
            onTap: () => onStyleSelected(style['value']!),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? Theme.of(context).primaryColor : Colors.grey[200],
                borderRadius: BorderRadius.circular(20),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Theme.of(context).primaryColor.withOpacity(0.3),
                          blurRadius: 4,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
              child: Text(
                style['name']!,
                style: TextStyle(
                  fontFamily: style['value'] == 'normal' ? null : style['value'],
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}