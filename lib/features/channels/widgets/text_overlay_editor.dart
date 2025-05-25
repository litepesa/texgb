import 'package:flutter/material.dart';
import 'package:textgb/features/channels/models/edited_media_model.dart';

class TextOverlayEditor extends StatefulWidget {
  final Function(TextOverlay) onTextAdded;
  final Function(int, TextOverlay) onTextUpdated;
  final Function(int) onTextDeleted;
  final List<TextOverlay> existingTexts;

  const TextOverlayEditor({
    Key? key,
    required this.onTextAdded,
    required this.onTextUpdated,
    required this.onTextDeleted,
    required this.existingTexts,
  }) : super(key: key);

  @override
  State<TextOverlayEditor> createState() => _TextOverlayEditorState();
}

class _TextOverlayEditorState extends State<TextOverlayEditor> {
  final TextEditingController _textController = TextEditingController();
  
  // Text style properties
  Color _selectedColor = Colors.white;
  Color _selectedBgColor = Colors.black.withOpacity(0.5);
  double _fontSize = 24;
  FontWeight _fontWeight = FontWeight.normal;
  String _fontFamily = 'Roboto';
  TextAnimation? _selectedAnimation;
  
  // Available options
  final List<Color> _textColors = [
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.pink,
    Colors.purple,
    Colors.blue,
    Colors.cyan,
    Colors.green,
    Colors.yellow,
    Colors.orange,
  ];
  
  final List<String> _fontFamilies = [
    'Roboto',
    'Bebas Neue',
    'Pacifico',
    'Dancing Script',
    'Permanent Marker',
    'Shadows Into Light',
  ];
  
  final Map<String, TextAnimation> _animations = {
    'None': TextAnimation.fadeIn,
    'Fade In': TextAnimation.fadeIn,
    'Slide In': TextAnimation.slideIn,
    'Bounce': TextAnimation.bounce,
    'Typewriter': TextAnimation.typewriter,
    'Scale': TextAnimation.scale,
    'Rotate': TextAnimation.rotate,
  };

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _addText() {
    if (_textController.text.isEmpty) return;
    
    final textOverlay = TextOverlay(
      text: _textController.text,
      style: TextStyle(
        color: _selectedColor,
        backgroundColor: _selectedBgColor,
        fontSize: _fontSize,
        fontWeight: _fontWeight,
        fontFamily: _fontFamily,
      ),
      position: const Offset(50, 100),
      animation: _selectedAnimation,
    );
    
    widget.onTextAdded(textOverlay);
    _textController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          // Text input
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: BorderRadius.circular(25),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _textController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'Add text...',
                      hintStyle: TextStyle(color: Colors.white54),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _addText,
                  icon: const Icon(Icons.add_circle, color: Colors.white),
                ),
              ],
            ),
          ),
          
          // Style options
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Font family selector
                  _buildSectionTitle('Font'),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _fontFamilies.length,
                      itemBuilder: (context, index) {
                        final font = _fontFamilies[index];
                        final isSelected = font == _fontFamily;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _fontFamily = font),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withOpacity(0.3) 
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              font,
                              style: TextStyle(
                                color: Colors.white,
                                fontFamily: font,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Color selector
                  _buildSectionTitle('Text Color'),
                  _buildColorSelector(
                    selectedColor: _selectedColor,
                    onColorSelected: (color) => setState(() => _selectedColor = color),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Background color selector
                  _buildSectionTitle('Background'),
                  _buildColorSelector(
                    selectedColor: _selectedBgColor,
                    onColorSelected: (color) => setState(() => _selectedBgColor = color),
                    includeTransparent: true,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Size and weight
                  _buildSectionTitle('Size & Style'),
                  Row(
                    children: [
                      // Font size slider
                      Expanded(
                        child: Slider(
                          value: _fontSize,
                          min: 12,
                          max: 48,
                          onChanged: (value) => setState(() => _fontSize = value),
                          activeColor: Colors.white,
                          inactiveColor: Colors.white30,
                        ),
                      ),
                      // Bold toggle
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _fontWeight = _fontWeight == FontWeight.bold 
                                ? FontWeight.normal 
                                : FontWeight.bold;
                          });
                        },
                        icon: Icon(
                          Icons.format_bold,
                          color: _fontWeight == FontWeight.bold 
                              ? Colors.white 
                              : Colors.white30,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Animation selector
                  _buildSectionTitle('Animation'),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: _animations.length,
                      itemBuilder: (context, index) {
                        final animName = _animations.keys.elementAt(index);
                        final animation = _animations[animName];
                        final isSelected = animation == _selectedAnimation;
                        
                        return GestureDetector(
                          onTap: () => setState(() => _selectedAnimation = animation),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected 
                                  ? Colors.white.withOpacity(0.3) 
                                  : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                              ),
                            ),
                            child: Text(
                              animName,
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildColorSelector({
    required Color selectedColor,
    required Function(Color) onColorSelected,
    bool includeTransparent = false,
  }) {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _textColors.length + (includeTransparent ? 1 : 0),
        itemBuilder: (context, index) {
          Color color;
          bool isTransparent = false;
          
          if (includeTransparent && index == 0) {
            color = Colors.transparent;
            isTransparent = true;
          } else {
            color = _textColors[includeTransparent ? index - 1 : index];
          }
          
          final isSelected = color == selectedColor || 
              (isTransparent && selectedColor == Colors.transparent);
          
          return GestureDetector(
            onTap: () => onColorSelected(color),
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isTransparent ? null : color,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.white : Colors.white30,
                  width: isSelected ? 3 : 1,
                ),
                gradient: isTransparent 
                    ? LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.3),
                          Colors.transparent,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: isTransparent 
                  ? const Icon(
                      Icons.block,
                      color: Colors.white54,
                      size: 20,
                    )
                  : null,
            ),
          );
        },
      ),
    );
  }
}