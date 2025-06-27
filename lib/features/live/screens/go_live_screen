import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class GoLiveScreen extends ConsumerStatefulWidget {
  const GoLiveScreen({super.key});

  @override
  ConsumerState<GoLiveScreen> createState() => _GoLiveScreenState();
}

class _GoLiveScreenState extends ConsumerState<GoLiveScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  bool _isPrivate = false;
  String _selectedCategory = 'General';
  
  final List<String> _categories = [
    'General',
    'Gaming',
    'Music',
    'Art & Creative',
    'Education',
    'Technology',
    'Sports',
    'Cooking',
    'Travel',
    'Fitness'
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.surfaceColor, // Changed from backgroundColor to surfaceColor
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Header
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.videocam,
                      size: 30,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Go Live',
                          style: TextStyle(
                            color: modernTheme.textColor,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Start broadcasting to your audience',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 40),
              
              // Stream Title
              _buildSectionTitle('Stream Title', modernTheme),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _titleController,
                hintText: 'Enter your stream title...',
                modernTheme: modernTheme,
              ),
              
              const SizedBox(height: 24),
              
              // Description
              _buildSectionTitle('Description (Optional)', modernTheme),
              const SizedBox(height: 8),
              _buildTextField(
                controller: _descriptionController,
                hintText: 'Tell viewers what your stream is about...',
                modernTheme: modernTheme,
                maxLines: 3,
              ),
              
              const SizedBox(height: 24),
              
              // Category
              _buildSectionTitle('Category', modernTheme),
              const SizedBox(height: 8),
              _buildCategorySelector(modernTheme),
              
              const SizedBox(height: 24),
              
              // Privacy Settings
              _buildSectionTitle('Privacy Settings', modernTheme),
              const SizedBox(height: 12),
              _buildPrivacyToggle(modernTheme),
              
              const SizedBox(height: 40),
              
              // Camera Preview Placeholder
              _buildCameraPreview(modernTheme),
              
              const SizedBox(height: 30),
              
              // Go Live Button
              _buildGoLiveButton(modernTheme),
              
              const SizedBox(height: 20),
              
              // Quick Tips
              _buildQuickTips(modernTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ModernThemeExtension modernTheme) {
    return Text(
      title,
      style: TextStyle(
        color: modernTheme.textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required ModernThemeExtension modernTheme,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: TextStyle(
        color: modernTheme.textColor,
        fontSize: 16,
      ),
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(
          color: modernTheme.textSecondaryColor,
        ),
        filled: true,
        fillColor: modernTheme.backgroundColor,
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildCategorySelector(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor, // Use backgroundColor for contrast against surfaceColor
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
        ),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        underline: const SizedBox(),
        style: TextStyle(
          color: modernTheme.textColor,
          fontSize: 16,
        ),
        dropdownColor: modernTheme.backgroundColor, // Use backgroundColor for dropdown
        icon: Icon(
          Icons.keyboard_arrow_down,
          color: modernTheme.textSecondaryColor,
        ),
        items: _categories.map((category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            setState(() {
              _selectedCategory = value;
            });
          }
        },
      ),
    );
  }

  Widget _buildPrivacyToggle(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.backgroundColor, // Use backgroundColor for contrast against surfaceColor
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _isPrivate ? Icons.lock : Icons.public,
            color: modernTheme.primaryColor,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPrivate ? 'Private Stream' : 'Public Stream',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  _isPrivate 
                      ? 'Only your followers can see this stream'
                      : 'Anyone can discover and watch this stream',
                  style: TextStyle(
                    color: modernTheme.textSecondaryColor,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPrivate,
            onChanged: (value) {
              setState(() {
                _isPrivate = value;
              });
            },
            activeColor: modernTheme.primaryColor,
          ),
        ],
      ),
    );
  }

  Widget _buildCameraPreview(ModernThemeExtension modernTheme) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: modernTheme.dividerColor?.withOpacity(0.3) ?? Colors.grey.withOpacity(0.3),
        ),
      ),
      child: Stack(
        children: [
          // Camera preview placeholder
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.videocam_off,
                  size: 48,
                  color: Colors.white.withOpacity(0.7),
                ),
                const SizedBox(height: 12),
                Text(
                  'Camera Preview',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Tap to enable camera',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          
          // Camera controls
          Positioned(
            top: 12,
            right: 12,
            child: Row(
              children: [
                _buildCameraControl(Icons.flip_camera_ios, modernTheme),
                const SizedBox(width: 8),
                _buildCameraControl(Icons.flash_on, modernTheme),
                const SizedBox(width: 8),
                _buildCameraControl(Icons.settings, modernTheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCameraControl(IconData icon, ModernThemeExtension modernTheme) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 20,
      ),
    );
  }

  Widget _buildGoLiveButton(ModernThemeExtension modernTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          // TODO: Implement go live functionality
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Go Live feature coming soon...'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        icon: const Icon(Icons.live_tv, size: 24),
        label: const Text(
          'Start Live Stream',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildQuickTips(ModernThemeExtension modernTheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: modernTheme.primaryColor?.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: modernTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Tips',
                style: TextStyle(
                  color: modernTheme.primaryColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildTip('• Choose an engaging title to attract viewers', modernTheme),
          _buildTip('• Ensure good lighting and audio quality', modernTheme),
          _buildTip('• Interact with your audience in real-time', modernTheme),
          _buildTip('• Select the right category for better discoverability', modernTheme),
        ],
      ),
    );
  }

  Widget _buildTip(String tip, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        tip,
        style: TextStyle(
          color: modernTheme.textSecondaryColor,
          fontSize: 14,
        ),
      ),
    );
  }
}