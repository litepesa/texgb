// lib/features/status/screens/create_text_status_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textgb/constants.dart';
import 'package:textgb/features/status/providers/status_provider.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

class CreateTextStatusScreen extends ConsumerStatefulWidget {
  const CreateTextStatusScreen({super.key});

  @override
  ConsumerState<CreateTextStatusScreen> createState() => _CreateTextStatusScreenState();
}

class _CreateTextStatusScreenState extends ConsumerState<CreateTextStatusScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  int _selectedBackgroundIndex = 0;
  int _selectedFontIndex = 0;
  String _privacyLevel = Constants.statusPrivacyContacts;
  
  final List<Color> _backgroundColors = [
    const Color(0xFF1976D2), // Blue
    const Color(0xFF388E3C), // Green
    const Color(0xFFD32F2F), // Red
    const Color(0xFFF57C00), // Orange
    const Color(0xFF7B1FA2), // Purple
    const Color(0xFF303F9F), // Indigo
    const Color(0xFF0097A7), // Cyan
    const Color(0xFF5D4037), // Brown
    const Color(0xFF455A64), // Blue Grey
    const Color(0xFF424242), // Grey
  ];
  
  final List<String> _fontFamilies = [
    'Roboto',
    'Roboto Bold',
    'Roboto Light',
    'Dancing Script',
    'Pacifico',
    'Lobster',
    'Comfortaa',
    'Quicksand',
  ];

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final statusState = ref.watch(statusNotifierProvider);
    
    return Scaffold(
      backgroundColor: _backgroundColors[_selectedBackgroundIndex],
      body: SafeArea(
        child: Column(
          children: [
            // Top app bar
            _buildAppBar(theme),
            
            // Status preview
            Expanded(
              child: _buildStatusPreview(),
            ),
            
            // Bottom controls
            _buildBottomControls(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.close,
              color: Colors.white,
            ),
          ),
          
          const Spacer(),
          
          // Privacy selector
          GestureDetector(
            onTap: _showPrivacyOptions,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _getPrivacyIcon(),
                    color: Colors.white,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _getPrivacyLabel(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Send button
          Consumer(
            builder: (context, ref, child) {
              final statusState = ref.watch(statusNotifierProvider);
              final isCreating = statusState.valueOrNull?.isCreatingStatus ?? false;
              
              return GestureDetector(
                onTap: isCreating ? null : _createStatus,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: _textController.text.trim().isNotEmpty 
                        ? Colors.white 
                        : Colors.white.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: isCreating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.grey),
                          ),
                        )
                      : Icon(
                          Icons.send,
                          color: _textController.text.trim().isNotEmpty 
                              ? _backgroundColors[_selectedBackgroundIndex]
                              : Colors.white,
                          size: 24,
                        ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPreview() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      child: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: TextField(
              controller: _textController,
              focusNode: _focusNode,
              maxLines: null,
              maxLength: Constants.maxStatusLength,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w500,
                fontFamily: _fontFamilies[_selectedFontIndex],
                height: 1.3,
              ),
              decoration: InputDecoration(
                hintText: "What's on your mind?",
                hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 24,
                  fontFamily: _fontFamilies[_selectedFontIndex],
                ),
                border: InputBorder.none,
                counterStyle: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
              onChanged: (text) => setState(() {}),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(ModernThemeExtension theme) {
    return Container(
      color: Colors.black.withOpacity(0.3),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Background colors
            Container(
              height: 60,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _backgroundColors.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedBackgroundIndex;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedBackgroundIndex = index;
                      });
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: _backgroundColors[index],
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.white, width: 3)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                },
              ),
            ),
            
            // Font selector
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _fontFamilies.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _selectedFontIndex;
                  
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedFontIndex = index;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? Colors.white.withOpacity(0.2)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: isSelected
                            ? Border.all(color: Colors.white.withOpacity(0.5))
                            : null,
                      ),
                      child: Text(
                        'Aa',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: _fontFamilies[index],
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getPrivacyIcon() {
    switch (_privacyLevel) {
      case Constants.statusPrivacyContacts:
        return Icons.contacts;
      case Constants.statusPrivacyCustom:
        return Icons.person_outline;
      case Constants.statusPrivacyClose:
        return Icons.favorite;
      default:
        return Icons.contacts;
    }
  }

  String _getPrivacyLabel() {
    switch (_privacyLevel) {
      case Constants.statusPrivacyContacts:
        return 'Contacts';
      case Constants.statusPrivacyCustom:
        return 'Custom';
      case Constants.statusPrivacyClose:
        return 'Close Friends';
      default:
        return 'Contacts';
    }
  }

  void _showPrivacyOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildPrivacyBottomSheet(),
    );
  }

  Widget _buildPrivacyBottomSheet() {
    final theme = context.modernTheme;
    
    return Container(
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(top: 12),
              decoration: BoxDecoration(
                color: theme.dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Title
            Text(
              'Status Privacy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: theme.textColor,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Privacy options
            _buildPrivacyOption(
              icon: Icons.contacts,
              title: 'My contacts',
              subtitle: 'Share with all your contacts',
              value: Constants.statusPrivacyContacts,
            ),
            
            _buildPrivacyOption(
              icon: Icons.person_outline,
              title: 'Only share with...',
              subtitle: 'Share with selected contacts only',
              value: Constants.statusPrivacyCustom,
            ),
            
            _buildPrivacyOption(
              icon: Icons.favorite,
              title: 'Close friends',
              subtitle: 'Share with close friends only',
              value: Constants.statusPrivacyClose,
            ),
            
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
  }) {
    final theme = context.modernTheme;
    final isSelected = _privacyLevel == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          _privacyLevel = value;
        });
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected 
                    ? theme.primaryColor!.withOpacity(0.1)
                    : theme.surfaceVariantColor,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? theme.primaryColor : theme.textSecondaryColor,
                size: 20,
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
                      fontWeight: FontWeight.w500,
                      color: theme.textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            if (isSelected)
              Icon(
                Icons.check_circle,
                color: theme.primaryColor,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  void _createStatus() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      await ref.read(statusNotifierProvider.notifier).createTextStatus(
        content: text,
        backgroundColor: _backgroundColors[_selectedBackgroundIndex].value.toString(),
        textColor: Colors.white.value.toString(),
        font: _fontFamilies[_selectedFontIndex],
        privacyLevel: _privacyLevel,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Status posted successfully'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to post status: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }
}