// lib/features/chat/widgets/attachment_picker.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class AttachmentPicker extends StatefulWidget {
  final Function(AttachmentType) onAttachmentSelected;
  final VoidCallback onClose;

  const AttachmentPicker({
    Key? key,
    required this.onAttachmentSelected,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AttachmentPicker> createState() => _AttachmentPickerState();
}

class _AttachmentPickerState extends State<AttachmentPicker>
    with TickerProviderStateMixin {
  late AnimationController _slideController;
  late AnimationController _staggerController;
  late Animation<Offset> _slideAnimation;
  late List<Animation<double>> _itemAnimations;

  static const Duration _animationDuration = Duration(milliseconds: 400);
  static const Duration _staggerDelay = Duration(milliseconds: 50);

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimation();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: _animationDuration,
      vsync: this,
    );

    _staggerController = AnimationController(
      duration: Duration(milliseconds: attachmentOptions.length * 50 + 200),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.elasticOut,
    ));

    // Create staggered animations for each item
    _itemAnimations = List.generate(
      attachmentOptions.length,
      (index) => Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: _staggerController,
        curve: Interval(
          index * 0.1,
          (index * 0.1) + 0.5,
          curve: Curves.elasticOut,
        ),
      )),
    );
  }

  void _startAnimation() {
    _slideController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _staggerController.forward();
    });
  }

  Future<void> _close() async {
    HapticFeedback.lightImpact();
    await _staggerController.reverse();
    await _slideController.reverse();
    widget.onClose();
  }

  @override
  void dispose() {
    _slideController.dispose();
    _staggerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return GestureDetector(
      onTap: _close,
      child: Container(
        color: Colors.black.withOpacity(0.3),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              SlideTransition(
                position: _slideAnimation,
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: modernTheme.surfaceColor,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: modernTheme.dividerColor?.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Title
                      Text(
                        'Share Content',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: modernTheme.textColor,
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Attachment options grid
                      _buildAttachmentGrid(modernTheme),
                      
                      const SizedBox(height: 16),
                      
                      // Cancel button
                      _buildCancelButton(modernTheme),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttachmentGrid(ModernThemeExtension modernTheme) {
    return AnimatedBuilder(
      animation: _staggerController,
      builder: (context, child) {
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.0,
          ),
          itemCount: attachmentOptions.length,
          itemBuilder: (context, index) {
            final option = attachmentOptions[index];
            return Transform.scale(
              scale: _itemAnimations[index].value,
              child: _buildAttachmentOption(option, modernTheme),
            );
          },
        );
      },
    );
  }

  Widget _buildAttachmentOption(AttachmentOption option, ModernThemeExtension modernTheme) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onAttachmentSelected(option.type);
          _close();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                option.color,
                option.color.withOpacity(0.8),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: option.color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  option.icon,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                option.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCancelButton(ModernThemeExtension modernTheme) {
    return SizedBox(
      width: double.infinity,
      child: TextButton(
        onPressed: _close,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: modernTheme.surfaceVariantColor?.withOpacity(0.5),
        ),
        child: Text(
          'Cancel',
          style: TextStyle(
            color: modernTheme.textColor,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

// Attachment types enum
enum AttachmentType {
  gallery,
  camera,
  video,
  document,
  location,
  contact,
}

// Attachment option model
class AttachmentOption {
  final AttachmentType type;
  final IconData icon;
  final String label;
  final Color color;

  const AttachmentOption({
    required this.type,
    required this.icon,
    required this.label,
    required this.color,
  });
}

// Predefined attachment options
const List<AttachmentOption> attachmentOptions = [
  AttachmentOption(
    type: AttachmentType.gallery,
    icon: Icons.photo_library_rounded,
    label: 'Gallery',
    color: Colors.purple,
  ),
  AttachmentOption(
    type: AttachmentType.camera,
    icon: Icons.camera_alt_rounded,
    label: 'Camera',
    color: Colors.red,
  ),
  AttachmentOption(
    type: AttachmentType.video,
    icon: Icons.videocam_rounded,
    label: 'Video',
    color: Colors.blue,
  ),
  AttachmentOption(
    type: AttachmentType.document,
    icon: Icons.insert_drive_file_rounded,
    label: 'Document',
    color: Colors.orange,
  ),
  AttachmentOption(
    type: AttachmentType.location,
    icon: Icons.location_on_rounded,
    label: 'Location',
    color: Colors.green,
  ),
  AttachmentOption(
    type: AttachmentType.contact,
    icon: Icons.person_rounded,
    label: 'Contact',
    color: Colors.teal,
  ),
];