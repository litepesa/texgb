import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/enums/enums.dart';
import 'package:textgb/features/contacts/providers/contacts_provider.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/features/status/widgets/privacy_settings_sheet.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';
import 'package:textgb/shared/utilities/global_methods.dart';
import 'package:textgb/shared/widgets/app_bar_back_button.dart';

class CreateStatusScreen extends ConsumerStatefulWidget {
  const CreateStatusScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<CreateStatusScreen> createState() => _CreateStatusScreenState();
}

class _CreateStatusScreenState extends ConsumerState<CreateStatusScreen> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _captionController = TextEditingController();
  StatusType _selectedType = StatusType.text;
  File? _mediaFile;
  bool _isLoading = false;
  StatusPrivacyType _privacyType = StatusPrivacyType.all_contacts;

  @override
  void dispose() {
    _textController.dispose();
    _captionController.dispose();
    super.dispose();
  }

  void _showPrivacySettings() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => const PrivacySettingsSheet(),
    );
    
    if (result != null) {
      final privacyType = result['privacyType'] as StatusPrivacyType;
      
      // Update provider state with privacy settings
      ref.read(statusNotifierProvider.notifier).setPrivacySettings(
        privacyType: privacyType,
        selectedContacts: result['selectedContacts'] ?? [],
      );
      
      setState(() {
        _privacyType = privacyType;
      });
    }
  }

  Future<void> _pickImage(bool fromCamera) async {
    File? image = await pickImage(
      fromCamera: fromCamera,
      onFail: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error)),
        );
      },
    );
    
    if (image != null) {
      setState(() {
        _mediaFile = image;
        _selectedType = StatusType.image;
      });
    }
  }

  Future<void> _pickVideo(bool fromCamera) async {
    if (fromCamera) {
      File? video = await pickVideoFromCamera(
        onFail: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        },
        maxDuration: const Duration(seconds: 30),
      );
      
      if (video != null) {
        setState(() {
          _mediaFile = video;
          _selectedType = StatusType.video;
        });
      }
    } else {
      File? video = await pickVideo(
        onFail: (error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error)),
          );
        },
        maxDuration: const Duration(seconds: 30),
      );
      
      if (video != null) {
        setState(() {
          _mediaFile = video;
          _selectedType = StatusType.video;
        });
      }
    }
  }

  Future<void> _createStatus() async {
    if (_isLoading) return;
    
    // Validate inputs based on status type
    if (_selectedType == StatusType.text) {
      if (_textController.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter some text')),
        );
        return;
      }
    } else if (_mediaFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select media')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      final statusNotifier = ref.read(statusNotifierProvider.notifier);
      final statusState = ref.read(statusNotifierProvider).value;
      
      // Get privacy settings from state
      List<String> visibleTo = [];
      List<String> hiddenFrom = [];
      
      if (_privacyType == StatusPrivacyType.only && statusState != null) {
        visibleTo = statusState.selectedContacts.map((contact) => contact.uid).toList();
      } else if (_privacyType == StatusPrivacyType.except && statusState != null) {
        hiddenFrom = statusState.selectedContacts.map((contact) => contact.uid).toList();
      }
      
      if (_selectedType == StatusType.text) {
        await statusNotifier.createTextStatus(
          text: _textController.text.trim(),
          privacyType: _privacyType,
          visibleTo: visibleTo,
          hiddenFrom: hiddenFrom,
        );
      } else if (_mediaFile != null) {
        await statusNotifier.createMediaStatus(
          mediaFile: _mediaFile!,
          mediaType: _selectedType,
          caption: _captionController.text.trim(),
          privacyType: _privacyType,
          visibleTo: visibleTo,
          hiddenFrom: hiddenFrom,
        );
      }
      
      // Return to status screen on success
      if (mounted) {
        Navigator.popUntil(
          context, 
          ModalRoute.withName(Constants.homeScreen)
        );
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Status created successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating status: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = context.modernTheme;
    
    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.backgroundColor,
        elevation: 0,
        leading: AppBarBackButton(
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create Status',
          style: TextStyle(
            color: modernTheme.textColor,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.privacy_tip_outlined,
              color: modernTheme.primaryColor,
            ),
            onPressed: _showPrivacySettings,
            tooltip: 'Privacy settings',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status type selector
              _buildStatusTypeSelector(modernTheme),
              
              const SizedBox(height: 20),
              
              // Content input based on selected type
              _buildContentInput(modernTheme),
              
              const SizedBox(height: 24),
              
              // Privacy indicator
              _buildPrivacyIndicator(modernTheme),
              
              const SizedBox(height: 40),
              
              // Create button
              _buildCreateButton(modernTheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusTypeSelector(ModernThemeExtension modernTheme) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: modernTheme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        children: [
          _buildTypeOption(
            modernTheme,
            StatusType.text,
            'Text',
            Icons.text_format,
          ),
          _buildTypeOption(
            modernTheme,
            StatusType.image,
            'Photo',
            Icons.photo,
            onLongPress: () => _showMediaSourceDialog(isImage: true),
          ),
          _buildTypeOption(
            modernTheme,
            StatusType.video,
            'Video',
            Icons.videocam,
            onLongPress: () => _showMediaSourceDialog(isImage: false),
          ),
          _buildTypeOption(
            modernTheme,
            StatusType.link,
            'Link',
            Icons.link,
          ),
        ],
      ),
    );
  }

  Widget _buildTypeOption(
    ModernThemeExtension modernTheme,
    StatusType type,
    String name,
    IconData icon, {
    VoidCallback? onLongPress,
  }) {
    final isSelected = _selectedType == type;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedType = type;
          
          // If switching to image/video, show media picker
          if (type == StatusType.image) {
            _showMediaSourceDialog(isImage: true);
          } else if (type == StatusType.video) {
            _showMediaSourceDialog(isImage: false);
          }
        });
      },
      onLongPress: onLongPress,
      child: Container(
        width: 70,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? modernTheme.primaryColor!.withOpacity(0.1) : null,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? modernTheme.primaryColor! : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 28,
              color: isSelected ? modernTheme.primaryColor : modernTheme.textSecondaryColor,
            ),
            const SizedBox(height: 8),
            Text(
              name,
              style: TextStyle(
                color: isSelected ? modernTheme.primaryColor : modernTheme.textSecondaryColor,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContentInput(ModernThemeExtension modernTheme) {
    switch (_selectedType) {
      case StatusType.text:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your text status:',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'What\'s on your mind?',
                  hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                ),
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                ),
                maxLines: 5,
                minLines: 3,
              ),
            ),
          ],
        );
        
      case StatusType.image:
      case StatusType.video:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  _selectedType == StatusType.image ? 'Selected photo:' : 'Selected video:',
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const Spacer(),
                if (_mediaFile != null)
                  TextButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Change'),
                    onPressed: () => _showMediaSourceDialog(
                      isImage: _selectedType == StatusType.image,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (_mediaFile != null)
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: modernTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                  image: _selectedType == StatusType.image 
                      ? DecorationImage(
                          image: FileImage(_mediaFile!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                alignment: Alignment.center,
                child: _selectedType == StatusType.video
                    ? Icon(
                        Icons.play_circle_fill,
                        size: 48,
                        color: modernTheme.primaryColor,
                      )
                    : null,
              )
            else
              GestureDetector(
                onTap: () => _showMediaSourceDialog(
                  isImage: _selectedType == StatusType.image,
                ),
                child: CustomPaint(
                  painter: DashedBorderPainter(
                    color: modernTheme.primaryColor!.withOpacity(0.3),
                    strokeWidth: 2,
                    gap: 5,
                    radius: 12,
                  ),
                  child: Container(
                    height: 200,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: modernTheme.surfaceColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _selectedType == StatusType.image ? Icons.add_photo_alternate : Icons.video_call,
                          size: 48,
                          color: modernTheme.primaryColor,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _selectedType == StatusType.image ? 'Tap to add photo' : 'Tap to add video',
                          style: TextStyle(
                            color: modernTheme.textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
            if (_mediaFile != null) ...[
              const SizedBox(height: 16),
              Text(
                'Add a caption (optional):',
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: modernTheme.surfaceColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: TextField(
                  controller: _captionController,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Add a caption...',
                    hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  ),
                  style: TextStyle(
                    color: modernTheme.textColor,
                    fontSize: 16,
                  ),
                  maxLines: 2,
                ),
              ),
            ],
          ],
        );
        
      case StatusType.link:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share a link:',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _textController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Paste your link here',
                  hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                  prefixIcon: Icon(
                    Icons.link,
                    color: modernTheme.textSecondaryColor,
                  ),
                ),
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                ),
                keyboardType: TextInputType.url,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Add a caption (optional):',
              style: TextStyle(
                color: modernTheme.textColor,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: modernTheme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _captionController,
                decoration: InputDecoration(
                  border: InputBorder.none,
                  hintText: 'What\'s this link about?',
                  hintStyle: TextStyle(color: modernTheme.textSecondaryColor),
                ),
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 16,
                ),
                maxLines: 2,
              ),
            ),
          ],
        );
    }
  }

  Widget _buildPrivacyIndicator(ModernThemeExtension modernTheme) {
    String privacyText;
    IconData privacyIcon;
    
    switch (_privacyType) {
      case StatusPrivacyType.all_contacts:
        privacyText = 'All contacts can see this status';
        privacyIcon = Icons.group;
        break;
      case StatusPrivacyType.except:
        privacyText = 'All contacts except selected ones will see this status';
        privacyIcon = Icons.person_remove;
        break;
      case StatusPrivacyType.only:
        privacyText = 'Only selected contacts will see this status';
        privacyIcon = Icons.person_add;
        break;
      case StatusPrivacyType.public:
        // TODO: Handle this case.
        throw UnimplementedError();
      case StatusPrivacyType.public_except_contacts:
        // TODO: Handle this case.
        throw UnimplementedError();
      case StatusPrivacyType.public_except_some:
        // TODO: Handle this case.
        throw UnimplementedError();
    }
    
    return GestureDetector(
      onTap: _showPrivacySettings,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: modernTheme.surfaceColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: modernTheme.primaryColor!.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              privacyIcon,
              color: modernTheme.primaryColor,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                privacyText,
                style: TextStyle(
                  color: modernTheme.textColor,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: modernTheme.textSecondaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreateButton(ModernThemeExtension modernTheme) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _createStatus,
        style: ElevatedButton.styleFrom(
          backgroundColor: modernTheme.primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
        child: _isLoading 
            ? const SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Text(
                'Share Status',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showMediaSourceDialog({required bool isImage}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isImage ? 'Select Photo Source' : 'Select Video Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: Text(isImage ? 'Gallery' : 'Video Library'),
              onTap: () {
                Navigator.pop(context);
                if (isImage) {
                  _pickImage(false);
                } else {
                  _pickVideo(false);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: Text(isImage ? 'Camera' : 'Record Video'),
              onTap: () {
                Navigator.pop(context);
                if (isImage) {
                  _pickImage(true);
                } else {
                  _pickVideo(true);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter for dashed border
class DashedBorderPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gap;
  final double radius;

  DashedBorderPainter({
    required this.color,
    required this.strokeWidth,
    required this.gap,
    required this.radius,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          Radius.circular(radius),
        ),
      );

    final Path dashedPath = Path();
    const double dashWidth = 6.0;

    for (PathMetric metric in path.computeMetrics()) {
      double distance = 0.0;
      while (distance < metric.length) {
        double next = distance + dashWidth;
        if (next > metric.length) {
          next = metric.length;
        }
        dashedPath.addPath(
          metric.extractPath(distance, next),
          Offset.zero,
        );
        distance = next + gap;
      }
    }

    canvas.drawPath(dashedPath, paint);
  }

  @override
  bool shouldRepaint(DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.gap != gap ||
        oldDelegate.radius != radius;
  }
}