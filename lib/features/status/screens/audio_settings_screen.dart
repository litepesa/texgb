// lib/features/status/screens/audio_settings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:textgb/features/status/utils/audio_enhancement_presets.dart';
import 'package:textgb/shared/theme/theme_extensions.dart';

// Provider for audio preset preference
final audioPresetProvider = StateNotifierProvider<AudioPresetNotifier, String>((ref) {
  return AudioPresetNotifier();
});

class AudioPresetNotifier extends StateNotifier<String> {
  AudioPresetNotifier() : super('tiktok_style') {
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final prefs = await SharedPreferences.getInstance();
    final savedPreset = prefs.getString('audio_preset') ?? 'tiktok_style';
    state = savedPreset;
  }

  Future<void> setPreset(String preset) async {
    state = preset;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('audio_preset', preset);
  }
}

class AudioSettingsScreen extends ConsumerStatefulWidget {
  const AudioSettingsScreen({super.key});

  @override
  ConsumerState<AudioSettingsScreen> createState() => _AudioSettingsScreenState();
}

class _AudioSettingsScreenState extends ConsumerState<AudioSettingsScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = context.modernTheme;
    final currentPreset = ref.watch(audioPresetProvider);
    
    return Scaffold(
      backgroundColor: theme.backgroundColor,
      appBar: AppBar(
        backgroundColor: theme.surfaceColor,
        title: Text(
          'Audio Enhancement',
          style: TextStyle(color: theme.textColor),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.textColor),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: theme.primaryColor!.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq,
                        color: theme.primaryColor,
                        size: 28,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Audio Enhancement',
                        style: TextStyle(
                          color: theme.textColor,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Choose how your status videos should sound. Each preset is optimized for different platforms and content types.',
                    style: TextStyle(
                      color: theme.textSecondaryColor,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Current selection indicator
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.surfaceColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.primaryColor!, width: 2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle,
                    color: theme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Current: ${_getPresetDisplayName(currentPreset)}',
                          style: TextStyle(
                            color: theme.textColor,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          AudioEnhancementPresets.getPresetDescription(currentPreset),
                          style: TextStyle(
                            color: theme.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            Text(
              'Available Presets',
              style: TextStyle(
                color: theme.textColor,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Preset options
            ...AudioEnhancementPresets.availablePresets.map((preset) {
              return _buildPresetOption(preset, currentPreset, theme);
            }).toList(),
            
            const SizedBox(height: 32),
            
            // Advanced settings section
            _buildAdvancedSection(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildPresetOption(String preset, String currentPreset, ModernThemeExtension theme) {
    final isSelected = preset == currentPreset;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          ref.read(audioPresetProvider.notifier).setPreset(preset);
          
          // Show feedback
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Audio preset changed to ${_getPresetDisplayName(preset)}'),
              backgroundColor: theme.primaryColor,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected 
                ? theme.primaryColor!.withOpacity(0.1)
                : theme.surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                  ? theme.primaryColor! 
                  : theme.dividerColor!,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Preset icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: isSelected 
                      ? theme.primaryColor
                      : theme.surfaceVariantColor,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getPresetIcon(preset),
                  color: isSelected ? Colors.white : theme.textSecondaryColor,
                  size: 24,
                ),
              ),
              
              const SizedBox(width: 16),
              
              // Preset info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getPresetDisplayName(preset),
                      style: TextStyle(
                        color: theme.textColor,
                        fontSize: 16,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AudioEnhancementPresets.getPresetDescription(preset),
                      style: TextStyle(
                        color: theme.textSecondaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Selection indicator
              if (isSelected)
                Icon(
                  Icons.radio_button_checked,
                  color: theme.primaryColor,
                  size: 24,
                )
              else
                Icon(
                  Icons.radio_button_off,
                  color: theme.textSecondaryColor,
                  size: 24,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAdvancedSection(ModernThemeExtension theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.surfaceColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                color: theme.textSecondaryColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                'How It Works',
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          _buildInfoItem(
            icon: Icons.volume_up,
            title: 'Volume Normalization',
            description: 'Automatically adjusts audio levels for consistent volume across all videos',
            theme: theme,
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoItem(
            icon: Icons.equalizer,
            title: 'EQ Enhancement',
            description: 'Boosts specific frequencies to make voices clearer and more present',
            theme: theme,
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoItem(
            icon: Icons.compress,
            title: 'Dynamic Compression',
            description: 'Reduces volume differences for professional, consistent sound',
            theme: theme,
          ),
          
          const SizedBox(height: 12),
          
          _buildInfoItem(
            icon: Icons.shield,
            title: 'Limiting Protection',
            description: 'Prevents audio distortion while maximizing loudness',
            theme: theme,
          ),
          
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Audio enhancement is applied automatically when you create video statuses. The process typically takes a few seconds.',
                    style: TextStyle(
                      color: Colors.blue,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String description,
    required ModernThemeExtension theme,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: theme.primaryColor!.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            icon,
            color: theme.primaryColor,
            size: 18,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: theme.textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(
                  color: theme.textSecondaryColor,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _getPresetDisplayName(String preset) {
    switch (preset) {
      case 'tiktok_style':
        return 'TikTok Style';
      case 'instagram_style':
        return 'Instagram Style';
      case 'youtube_style':
        return 'YouTube Style';
      case 'voice_optimized':
        return 'Voice Optimized';
      case 'music_enhanced':
        return 'Music Enhanced';
      case 'gentle':
        return 'Gentle Enhancement';
      default:
        return preset.replaceAll('_', ' ').toUpperCase();
    }
  }

  IconData _getPresetIcon(String preset) {
    switch (preset) {
      case 'tiktok_style':
        return Icons.trending_up;
      case 'instagram_style':
        return Icons.photo_camera;
      case 'youtube_style':
        return Icons.play_circle_filled;
      case 'voice_optimized':
        return Icons.mic;
      case 'music_enhanced':
        return Icons.music_note;
      case 'gentle':
        return Icons.tune;
      default:
        return Icons.audiotrack;
    }
  }
}