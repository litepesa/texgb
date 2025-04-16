import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/providers/authentication_provider.dart';
import 'package:textgb/providers/status_provider.dart';
import 'package:textgb/utilities/global_methods.dart';
import 'package:textgb/widgets/app_bar_back_button.dart';

class TextStatusEditor extends StatefulWidget {
  const TextStatusEditor({Key? key}) : super(key: key);

  @override
  State<TextStatusEditor> createState() => _TextStatusEditorState();
}

class _TextStatusEditorState extends State<TextStatusEditor> {
  final TextEditingController _textController = TextEditingController();
  Color _backgroundColor = Colors.black;
  Color _textColor = Colors.white;
  String _fontStyle = 'normal';
  
  final List<String> _fontStyles = [
    'normal',
    'italic',
    'bold',
    'handwriting',
    'fancy',
  ];

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  // Show color picker dialog
  void _showColorPicker({required bool isBackground}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isBackground ? 'Pick Background Color' : 'Pick Text Color'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: isBackground ? _backgroundColor : _textColor,
            onColorChanged: (color) {
              setState(() {
                if (isBackground) {
                  _backgroundColor = color;
                } else {
                  _textColor = color;
                }
              });
            },
            pickerAreaHeightPercent: 0.8,
            enableAlpha: false,
            displayThumbColor: true,
            showLabel: true,
            paletteType: PaletteType.hsv,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // Upload text status
  Future<void> _uploadTextStatus() async {
    if (_textController.text.trim().isEmpty) {
      showSnackBar(context, 'Please add some text');
      return;
    }

    final currentUser = context.read<AuthenticationProvider>().userModel!;
    final statusProvider = context.read<StatusProvider>();

    try {
      await statusProvider.createTextStatus(
        currentUser: currentUser,
        text: _textController.text.trim(),
        backgroundColor: '#${_backgroundColor.value.toRadixString(16).substring(2)}',
        textColor: '#${_textColor.value.toRadixString(16).substring(2)}',
        fontStyle: _fontStyle,
        onSuccess: () {
          Navigator.pop(context, true);
          showSnackBar(context, 'Status uploaded successfully');
        },
        onError: (error) {
          showSnackBar(context, 'Error uploading status: $error');
        },
      );
    } catch (e) {
      showSnackBar(context, 'Error uploading status: $e');
    }
  }

  // Get font style based on selected style
  TextStyle _getTextStyle() {
    switch (_fontStyle) {
      case 'italic':
        return GoogleFonts.roboto(
          color: _textColor,
          fontSize: 30,
          fontStyle: FontStyle.italic,
        );
      case 'bold':
        return GoogleFonts.roboto(
          color: _textColor,
          fontSize: 30,
          fontWeight: FontWeight.bold,
        );
      case 'handwriting':
        return GoogleFonts.dancingScript(
          color: _textColor,
          fontSize: 30,
        );
      case 'fancy':
        return GoogleFonts.pacifico(
          color: _textColor,
          fontSize: 30,
        );
      case 'normal':
      default:
        return GoogleFonts.roboto(
          color: _textColor,
          fontSize: 30,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusProvider = context.watch<StatusProvider>();
    
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.send),
            onPressed: statusProvider.isUploading
                ? null
                : _uploadTextStatus,
          ),
        ],
      ),
      body: Stack(
        children: [
          // Text input area
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: TextField(
                controller: _textController,
                style: _getTextStyle(),
                maxLines: null,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Type your status',
                  hintStyle: TextStyle(color: Colors.white54),
                ),
                autofocus: true,
              ),
            ),
          ),
          
          // Controls at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Background color picker
                  InkWell(
                    onTap: () => _showColorPicker(isBackground: true),
                    child: CircleAvatar(
                      backgroundColor: _backgroundColor,
                      child: const Icon(Icons.format_color_fill),
                    ),
                  ),
                  
                  // Text color picker
                  InkWell(
                    onTap: () => _showColorPicker(isBackground: false),
                    child: CircleAvatar(
                      backgroundColor: _textColor,
                      child: const Icon(Icons.format_color_text),
                    ),
                  ),
                  
                  // Font style selector
                  DropdownButton<String>(
                    value: _fontStyle,
                    dropdownColor: Colors.black87,
                    style: const TextStyle(color: Colors.white),
                    iconEnabledColor: Colors.white,
                    underline: Container(),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _fontStyle = newValue;
                        });
                      }
                    },
                    items: _fontStyles.map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(
                          value.toUpperCase(),
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          // Loading overlay
          if (statusProvider.isUploading)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Uploading status...',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}