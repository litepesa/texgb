import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/common/extension/wechat_theme_extension.dart';

class TextStatusCreator extends StatefulWidget {
  final Function(String, Map<String, String>) onSave;

  const TextStatusCreator({
    Key? key,
    required this.onSave,
  }) : super(key: key);

  @override
  State<TextStatusCreator> createState() => _TextStatusCreatorState();
}

class _TextStatusCreatorState extends State<TextStatusCreator> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // Background and text styling options
  List<Color> _backgroundColors = [
    const Color(0xFF09BB07), // WeChat green
    Colors.blue,
    Colors.purple,
    Colors.orange,
    Colors.red,
    Colors.teal,
    Colors.indigo,
    Colors.black,
  ];
  
  Map<String, String> _backgroundInfo = {
    'color': '0xFF09BB07', // Default WeChat green
    'fontFamily': 'Roboto',
    'alignment': 'center',
  };
  
  int _selectedColorIndex = 0;
  
  @override
  void initState() {
    super.initState();
    // Focus the text field automatically
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }
  
  void _updateBackgroundColor(int index) {
    setState(() {
      _selectedColorIndex = index;
      // Convert color to string for storage
      _backgroundInfo['color'] = '0x${_backgroundColors[index].value.toRadixString(16).padLeft(8, '0')}';
    });
  }
  
  void _updateTextAlignment(String alignment) {
    setState(() {
      _backgroundInfo['alignment'] = alignment;
    });
  }
  
  bool get _canSave => _textController.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final themeExtension = Theme.of(context).extension<WeChatThemeExtension>();
    final accentColor = themeExtension?.accentColor ?? const Color(0xFF09BB07);
    
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Create Text Status',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Text preview area with current styling
          Container(
            constraints: BoxConstraints(maxHeight: 200),
            width: double.infinity,
            color: _backgroundColors[_selectedColorIndex],
            padding: const EdgeInsets.all(20),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              maxLength: 280, // Twitter-style character limit
              maxLengthEnforcement: MaxLengthEnforcement.enforced,
              textAlign: _backgroundInfo['alignment'] == 'center'
                  ? TextAlign.center
                  : _backgroundInfo['alignment'] == 'right'
                      ? TextAlign.right
                      : TextAlign.left,
              style: TextStyle(
                color: _getContrastingTextColor(_backgroundColors[_selectedColorIndex]),
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: _backgroundInfo['fontFamily'],
              ),
              decoration: InputDecoration(
                hintText: 'Type your status here...',
                hintStyle: TextStyle(
                  color: _getContrastingTextColor(_backgroundColors[_selectedColorIndex]).withOpacity(0.6),
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                border: InputBorder.none,
                counterStyle: TextStyle(
                  color: _getContrastingTextColor(_backgroundColors[_selectedColorIndex]),
                ),
              ),
              onChanged: (_) => setState(() {}), // Refresh for save button state
            ),
          ),
          
          // Styling options
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                // Color selection
                SizedBox(
                  height: 50,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _backgroundColors.length,
                    itemBuilder: (context, index) {
                      final bool isSelected = _selectedColorIndex == index;
                      return GestureDetector(
                        onTap: () => _updateBackgroundColor(index),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _backgroundColors[index],
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: _backgroundColors[index].withOpacity(0.5),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Text alignment options
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.format_align_left),
                      color: _backgroundInfo['alignment'] == 'left' ? accentColor : null,
                      onPressed: () => _updateTextAlignment('left'),
                    ),
                    IconButton(
                      icon: Icon(Icons.format_align_center),
                      color: _backgroundInfo['alignment'] == 'center' ? accentColor : null,
                      onPressed: () => _updateTextAlignment('center'),
                    ),
                    IconButton(
                      icon: Icon(Icons.format_align_right),
                      color: _backgroundInfo['alignment'] == 'right' ? accentColor : null,
                      onPressed: () => _updateTextAlignment('right'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Action buttons
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _canSave
                      ? () {
                          widget.onSave(
                            _textController.text.trim(), 
                            _backgroundInfo,
                          );
                          Navigator.pop(context);
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accentColor,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Create Status'),
                ),
              ],
            ),
          ),
        ],
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
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= this;
    }
    return result;
  }
}