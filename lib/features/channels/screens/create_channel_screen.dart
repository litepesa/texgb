// lib/features/channels/screens/create_channel_screen.dart
import 'dart:io';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:textgb/core/router/app_router.dart';
import 'package:textgb/features/channels/models/channel_model.dart';
import 'package:textgb/features/channels/providers/channels_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

/// Screen for creating a new channel
class CreateChannelScreen extends ConsumerStatefulWidget {
  const CreateChannelScreen({super.key});

  @override
  ConsumerState<CreateChannelScreen> createState() => _CreateChannelScreenState();
}

class _CreateChannelScreenState extends ConsumerState<CreateChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();

  ChannelType _selectedType = ChannelType.public;
  int? _subscriptionPrice;
  bool _isCreating = false;

  File? _avatarImage;
  final ImagePicker _picker = ImagePicker();

  // Name availability checking
  Timer? _nameCheckTimer;
  bool _isCheckingName = false;
  bool? _isNameAvailable;
  String? _nameAvailabilityMessage;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_onNameChanged);
  }

  @override
  void dispose() {
    _nameCheckTimer?.cancel();
    _nameController.removeListener(_onNameChanged);
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _onNameChanged() {
    // Cancel any existing timer
    _nameCheckTimer?.cancel();

    final name = _nameController.text.trim();

    // Reset state if name is too short
    if (name.length < 3) {
      setState(() {
        _isCheckingName = false;
        _isNameAvailable = null;
        _nameAvailabilityMessage = null;
      });
      return;
    }

    // Set checking state
    setState(() {
      _isCheckingName = true;
      _isNameAvailable = null;
    });

    // Debounce: check after 500ms of no typing
    _nameCheckTimer = Timer(const Duration(milliseconds: 500), () {
      _checkNameAvailability(name);
    });
  }

  Future<void> _checkNameAvailability(String name) async {
    final actionsNotifier = ref.read(channelActionsProvider.notifier);
    final result = await actionsNotifier.checkNameAvailability(name);

    if (mounted) {
      setState(() {
        _isCheckingName = false;
        _isNameAvailable = result['available'] as bool?;
        _nameAvailabilityMessage = result['message'] as String?;
      });
    }
  }

  ModernThemeExtension _getModernTheme() {
    final extension = Theme.of(context).extension<ModernThemeExtension>();
    if (extension != null) return extension;

    // Fallback theme
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ModernThemeExtension(
      primaryColor: const Color(0xFF07C160),
      backgroundColor: isDark ? Colors.black : Colors.white,
      surfaceColor: isDark ? Colors.grey[900] : Colors.grey[50],
      textColor: isDark ? Colors.white : Colors.black,
      textSecondaryColor: isDark ? Colors.grey[400] : Colors.grey[600],
      dividerColor: isDark ? Colors.grey[800] : Colors.grey[300],
      textTertiaryColor: isDark ? Colors.grey[500] : Colors.grey[400],
      surfaceVariantColor: isDark ? Colors.grey[800] : Colors.grey[100],
    );
  }

  Future<void> _pickAvatar() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _avatarImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final modernTheme = _getModernTheme();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: modernTheme.backgroundColor,
      appBar: AppBar(
        backgroundColor: modernTheme.surfaceColor,
        elevation: 0,
        title: Text(
          'Create Channel',
          style: TextStyle(
            color: modernTheme.textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(CupertinoIcons.back, color: modernTheme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isCreating)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: modernTheme.primaryColor,
                  ),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _createChannel,
              child: Text(
                'Create',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: modernTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Avatar & Banner Section
            _buildImagesSection(modernTheme),
            const SizedBox(height: 24),

            // Channel Name
            TextFormField(
              controller: _nameController,
              style: TextStyle(color: modernTheme.textColor),
              decoration: InputDecoration(
                labelText: 'Channel Name',
                labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                hintText: 'Enter channel name',
                hintStyle: TextStyle(color: modernTheme.textTertiaryColor),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: modernTheme.dividerColor!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: modernTheme.dividerColor!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: modernTheme.primaryColor!, width: 2),
                ),
                prefixIcon: Icon(Icons.tv, color: modernTheme.textSecondaryColor),
                suffixIcon: _buildNameAvailabilityIcon(modernTheme),
                filled: true,
                fillColor: modernTheme.surfaceColor,
                counterStyle: TextStyle(color: modernTheme.textSecondaryColor),
                helperText: _nameAvailabilityMessage,
                helperStyle: TextStyle(
                  color: _isNameAvailable == true
                      ? Colors.green
                      : _isNameAvailable == false
                          ? Colors.red
                          : modernTheme.textSecondaryColor,
                ),
              ),
              maxLength: 50,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a channel name';
                }
                if (value.trim().length < 3) {
                  return 'Name must be at least 3 characters';
                }
                if (_isNameAvailable == false) {
                  return 'This channel name is already taken';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descriptionController,
              style: TextStyle(color: modernTheme.textColor),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                hintText: 'Describe what your channel is about',
                hintStyle: TextStyle(color: modernTheme.textTertiaryColor),
                border: OutlineInputBorder(
                  borderSide: BorderSide(color: modernTheme.dividerColor!),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: modernTheme.dividerColor!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: modernTheme.primaryColor!, width: 2),
                ),
                prefixIcon: Icon(Icons.description, color: modernTheme.textSecondaryColor),
                alignLabelWithHint: true,
                filled: true,
                fillColor: modernTheme.surfaceColor,
                counterStyle: TextStyle(color: modernTheme.textSecondaryColor),
              ),
              maxLines: 4,
              maxLength: 500,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a description';
                }
                if (value.trim().length < 10) {
                  return 'Description must be at least 10 characters';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),

            // Channel Type
            Text(
              'Channel Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: modernTheme.textColor,
              ),
            ),
            const SizedBox(height: 12),

            // Public Option
            _buildTypeOption(
              type: ChannelType.public,
              icon: Icons.public,
              title: 'Public',
              description: 'Anyone can discover and subscribe to your channel',
              color: Colors.green,
              modernTheme: modernTheme,
            ),
            const SizedBox(height: 12),

            // Private Option
            _buildTypeOption(
              type: ChannelType.private,
              icon: Icons.lock,
              title: 'Private',
              description: 'Only people you invite can see and subscribe',
              color: Colors.purple,
              modernTheme: modernTheme,
            ),
            const SizedBox(height: 12),

            // Premium Option
            _buildTypeOption(
              type: ChannelType.premium,
              icon: Icons.star,
              title: 'Premium',
              description: 'Subscribers pay to access your content',
              color: Colors.amber,
              modernTheme: modernTheme,
            ),

            // Premium Subscription Price
            if (_selectedType == ChannelType.premium) ...[
              const SizedBox(height: 16),
              Container(
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(isDark ? 0.2 : 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.withOpacity(0.5),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber),
                        const SizedBox(width: 8),
                        Text(
                          'Premium Channel Settings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.amber[300] : Colors.amber[900],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _priceController,
                      style: TextStyle(color: modernTheme.textColor),
                      decoration: InputDecoration(
                        labelText: 'Subscription Price (Coins)',
                        labelStyle: TextStyle(color: modernTheme.textSecondaryColor),
                        hintText: 'e.g., 100',
                        hintStyle: TextStyle(color: modernTheme.textTertiaryColor),
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: modernTheme.dividerColor!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: modernTheme.dividerColor!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.amber, width: 2),
                        ),
                        prefixIcon: Icon(Icons.attach_money, color: modernTheme.textSecondaryColor),
                        filled: true,
                        fillColor: modernTheme.backgroundColor,
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (_selectedType == ChannelType.premium) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter subscription price';
                          }
                          final price = int.tryParse(value);
                          if (price == null || price <= 0) {
                            return 'Please enter a valid price';
                          }
                          if (price < 10) {
                            return 'Minimum price is 10 coins';
                          }
                        }
                        return null;
                      },
                      onChanged: (value) {
                        setState(() {
                          _subscriptionPrice = int.tryParse(value);
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Note: Platform takes 20% of subscription fees',
                      style: TextStyle(
                        fontSize: 12,
                        color: modernTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 24),

            // Guidelines
            Container(
              decoration: BoxDecoration(
                color: (modernTheme.primaryColor ?? Colors.blue).withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: (modernTheme.primaryColor ?? Colors.blue).withOpacity(0.5),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lightbulb_outline, color: modernTheme.primaryColor),
                      const SizedBox(width: 8),
                      Text(
                        'Channel Guidelines',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: modernTheme.textColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildGuideline('You can add up to 8 admins/moderators', modernTheme),
                  _buildGuideline('Regular posts: ≤5 minutes or ≤100MB', modernTheme),
                  _buildGuideline('Premium posts: up to 2GB supported', modernTheme),
                  _buildGuideline('Multi-threaded comments enabled', modernTheme),
                  _buildGuideline('All notifications are silent by default', modernTheme),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildImagesSection(ModernThemeExtension modernTheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Channel Avatar',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: modernTheme.textColor,
          ),
        ),
        const SizedBox(height: 12),

        // Avatar Picker
        Row(
          children: [
            GestureDetector(
              onTap: _pickAvatar,
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: modernTheme.surfaceColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: modernTheme.dividerColor!,
                    width: 2,
                  ),
                ),
                child: _avatarImage != null
                    ? ClipOval(
                        child: Image.file(
                          _avatarImage!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Icon(
                        Icons.add_a_photo,
                        size: 40,
                        color: modernTheme.textSecondaryColor,
                      ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Channel Icon',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: modernTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Recommended: 500x500px\nSquare image, max 5MB',
                    style: TextStyle(
                      fontSize: 12,
                      color: modernTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTypeOption({
    required ChannelType type,
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required ModernThemeExtension modernTheme,
  }) {
    final isSelected = _selectedType == type;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withOpacity(isDark ? 0.2 : 0.1)
              : modernTheme.surfaceColor,
          border: Border.all(
            color: isSelected ? color : modernTheme.dividerColor!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? color : modernTheme.dividerColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? color : modernTheme.textColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: modernTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: color,
                size: 28,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuideline(String text, ModernThemeExtension modernTheme) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 16,
            color: modernTheme.primaryColor,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: modernTheme.textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget? _buildNameAvailabilityIcon(ModernThemeExtension modernTheme) {
    if (_isCheckingName) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_isNameAvailable == true) {
      return const Icon(Icons.check_circle, color: Colors.green);
    }

    if (_isNameAvailable == false) {
      return const Icon(Icons.cancel, color: Colors.red);
    }

    return null;
  }

  Future<void> _createChannel() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isCreating = true);

    try {
      final actionsNotifier = ref.read(channelActionsProvider.notifier);
      final result = await actionsNotifier.createChannel(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        type: _selectedType,
        subscriptionPriceCoins: _selectedType == ChannelType.premium
            ? _subscriptionPrice
            : null,
        avatar: _avatarImage,
      );

      if (mounted) {
        if (result['channel'] != null) {
          // Success - navigate to the new channel
          final channel = result['channel'] as ChannelModel;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${channel.name} created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Navigate to channel detail
          Navigator.pop(context);
          context.goToChannelDetail(channel.id);
        } else {
          // Failed - show specific error message
          final errorMessage = result['error'] as String? ?? 'Failed to create channel. Please try again.';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
          setState(() => _isCreating = false);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isCreating = false);
      }
    }
  }
}
