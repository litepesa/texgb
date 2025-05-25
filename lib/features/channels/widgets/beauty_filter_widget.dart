import 'package:flutter/material.dart';

class BeautyFilterWidget extends StatefulWidget {
  final double beautyLevel;
  final Function(double) onBeautyChanged;

  const BeautyFilterWidget({
    Key? key,
    required this.beautyLevel,
    required this.onBeautyChanged,
  }) : super(key: key);

  @override
  State<BeautyFilterWidget> createState() => _BeautyFilterWidgetState();
}

class _BeautyFilterWidgetState extends State<BeautyFilterWidget> {
  // Individual beauty settings
  double _smoothness = 0.5;
  double _brightness = 0.3;
  double _eyeEnhance = 0.2;
  double _faceSlim = 0.1;
  double _teethWhiten = 0.3;
  
  // Preset filters
  String _selectedPreset = 'Natural';
  
  final Map<String, Map<String, double>> _presets = {
    'None': {
      'smoothness': 0.0,
      'brightness': 0.0,
      'eyeEnhance': 0.0,
      'faceSlim': 0.0,
      'teethWhiten': 0.0,
    },
    'Natural': {
      'smoothness': 0.3,
      'brightness': 0.2,
      'eyeEnhance': 0.1,
      'faceSlim': 0.0,
      'teethWhiten': 0.2,
    },
    'Smooth': {
      'smoothness': 0.6,
      'brightness': 0.3,
      'eyeEnhance': 0.2,
      'faceSlim': 0.1,
      'teethWhiten': 0.3,
    },
    'Glamour': {
      'smoothness': 0.8,
      'brightness': 0.5,
      'eyeEnhance': 0.4,
      'faceSlim': 0.2,
      'teethWhiten': 0.5,
    },
    'Pro': {
      'smoothness': 0.5,
      'brightness': 0.4,
      'eyeEnhance': 0.3,
      'faceSlim': 0.15,
      'teethWhiten': 0.4,
    },
  };

  @override
  void initState() {
    super.initState();
    // Initialize with current beauty level
    if (widget.beautyLevel > 0) {
      _smoothness = widget.beautyLevel;
    }
  }

  void _applyPreset(String preset) {
    final settings = _presets[preset]!;
    setState(() {
      _selectedPreset = preset;
      _smoothness = settings['smoothness']!;
      _brightness = settings['brightness']!;
      _eyeEnhance = settings['eyeEnhance']!;
      _faceSlim = settings['faceSlim']!;
      _teethWhiten = settings['teethWhiten']!;
    });
    
    // Calculate overall beauty level (average of all settings)
    final overallLevel = (_smoothness + _brightness + _eyeEnhance + _faceSlim + _teethWhiten) / 5;
    widget.onBeautyChanged(overallLevel);
  }

  void _updateBeautyLevel() {
    // Calculate overall beauty level
    final overallLevel = (_smoothness + _brightness + _eyeEnhance + _faceSlim + _teethWhiten) / 5;
    widget.onBeautyChanged(overallLevel);
    
    // Check if current settings match any preset
    setState(() {
      _selectedPreset = 'Custom';
      for (final entry in _presets.entries) {
        final settings = entry.value;
        if ((settings['smoothness']! - _smoothness).abs() < 0.01 &&
            (settings['brightness']! - _brightness).abs() < 0.01 &&
            (settings['eyeEnhance']! - _eyeEnhance).abs() < 0.01 &&
            (settings['faceSlim']! - _faceSlim).abs() < 0.01 &&
            (settings['teethWhiten']! - _teethWhiten).abs() < 0.01) {
          _selectedPreset = entry.key;
          break;
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.9),
      child: Column(
        children: [
          // Preset filters
          Container(
            height: 80,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _presets.length,
              itemBuilder: (context, index) {
                final presetName = _presets.keys.elementAt(index);
                final isSelected = _selectedPreset == presetName;
                
                return GestureDetector(
                  onTap: () => _applyPreset(presetName),
                  child: Container(
                    width: 80,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.white : Colors.white30,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Preset icon
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.pink.withOpacity(0.3),
                                Colors.purple.withOpacity(0.2),
                              ],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getPresetIcon(presetName),
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          presetName,
                          style: TextStyle(
                            color: isSelected ? Colors.white : Colors.white70,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: Colors.white12,
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),
          
          // Individual controls
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildBeautySlider(
                    label: 'Skin Smoothing',
                    icon: Icons.blur_on,
                    value: _smoothness,
                    onChanged: (value) {
                      setState(() => _smoothness = value);
                      _updateBeautyLevel();
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildBeautySlider(
                    label: 'Brightening',
                    icon: Icons.wb_sunny,
                    value: _brightness,
                    onChanged: (value) {
                      setState(() => _brightness = value);
                      _updateBeautyLevel();
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildBeautySlider(
                    label: 'Eye Enhancement',
                    icon: Icons.remove_red_eye,
                    value: _eyeEnhance,
                    onChanged: (value) {
                      setState(() => _eyeEnhance = value);
                      _updateBeautyLevel();
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildBeautySlider(
                    label: 'Face Slimming',
                    icon: Icons.face_retouching_natural,
                    value: _faceSlim,
                    onChanged: (value) {
                      setState(() => _faceSlim = value);
                      _updateBeautyLevel();
                    },
                  ),
                  const SizedBox(height: 20),
                  
                  _buildBeautySlider(
                    label: 'Teeth Whitening',
                    icon: Icons.sentiment_satisfied_alt,
                    value: _teethWhiten,
                    onChanged: (value) {
                      setState(() => _teethWhiten = value);
                      _updateBeautyLevel();
                    },
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Reset button
                  Center(
                    child: TextButton.icon(
                      onPressed: () => _applyPreset('None'),
                      icon: const Icon(Icons.refresh, color: Colors.white70),
                      label: const Text(
                        'Reset All',
                        style: TextStyle(color: Colors.white70),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
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

  IconData _getPresetIcon(String preset) {
    switch (preset) {
      case 'None':
        return Icons.block;
      case 'Natural':
        return Icons.eco;
      case 'Smooth':
        return Icons.blur_circular;
      case 'Glamour':
        return Icons.auto_awesome;
      case 'Pro':
        return Icons.camera;
      default:
        return Icons.face;
    }
  }

  Widget _buildBeautySlider({
    required String label,
    required IconData icon,
    required double value,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(value * 100).round()}%',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: Colors.pink,
            inactiveTrackColor: Colors.white30,
            thumbColor: Colors.pink,
            overlayColor: Colors.pink.withOpacity(0.3),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
            trackHeight: 4,
          ),
          child: Slider(
            value: value,
            min: 0.0,
            max: 1.0,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}