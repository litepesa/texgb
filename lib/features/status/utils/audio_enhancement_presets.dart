// lib/features/status/utils/audio_enhancement_presets.dart
class AudioEnhancementPresets {
  
  /// TikTok-style audio enhancement - maximum loudness with clarity
  static List<String> get tiktokStyle => [
    // 1. Clean up the audio first
    'highpass=f=80', // Remove low rumble
    'lowpass=f=16000', // Remove high frequency noise
    
    // 2. Initial normalization
    'loudnorm=I=-16:TP=-1.5:LRA=7',
    
    // 3. Dynamic range compression for consistent levels
    'acompressor=threshold=0.003:ratio=4:attack=200:release=1000',
    
    // 4. Multi-band EQ for TikTok sound signature
    'equalizer=f=100:width_type=h:width=50:g=1.5',   // Sub-bass presence
    'equalizer=f=250:width_type=h:width=100:g=2',    // Bass warmth
    'equalizer=f=1000:width_type=h:width=200:g=1',   // Vocal clarity
    'equalizer=f=3000:width_type=h:width=800:g=3',   // Vocal presence (key frequency)
    'equalizer=f=6000:width_type=h:width=1500:g=2',  // Consonant clarity
    'equalizer=f=10000:width_type=h:width=2000:g=1.5', // Air and sparkle
    
    // 5. Aggressive compression for punch
    'acompressor=threshold=0.001:ratio=6:attack=50:release=500',
    
    // 6. Harmonic exciter simulation for presence
    'aexciter=level_in=1:level_out=1:amount=2:drive=8.5:blend=50:freq=7500:ceil=16000',
    
    // 7. Final limiter for maximum loudness
    'alimiter=level_in=1.5:level_out=0.98:limit=0.98:attack=5:release=50',
    
    // 8. Final broadcast normalization
    'loudnorm=I=-14:TP=-1:LRA=4:linear=true'
  ];

  /// Instagram Reels style - balanced and musical
  static List<String> get instagramStyle => [
    'highpass=f=60',
    'lowpass=f=18000',
    'loudnorm=I=-14:TP=-1.5:LRA=6',
    'acompressor=threshold=0.005:ratio=4:attack=200:release=1200',
    'equalizer=f=200:width_type=h:width=100:g=1.5',
    'equalizer=f=2500:width_type=h:width=600:g=3',
    'equalizer=f=8000:width_type=h:width=2000:g=2',
    'alimiter=level_in=1.5:level_out=0.97:limit=0.97:attack=8:release=80',
    'loudnorm=I=-11:TP=-0.8:LRA=4'  // Instagram loudness
  ];

  /// YouTube Shorts style - clear and punchy
  static List<String> get youtubeStyle => [
    'highpass=f=85',
    'loudnorm=I=-16:TP=-1.8:LRA=6',
    'acompressor=threshold=0.003:ratio=4.5:attack=150:release=1000',
    'equalizer=f=150:width_type=h:width=80:g=1.5',
    'equalizer=f=2800:width_type=h:width=700:g=3.2',
    'equalizer=f=7500:width_type=h:width=1800:g=2.2',
    'alimiter=level_in=1.4:level_out=0.96:limit=0.96:attack=6:release=70',
    'loudnorm=I=-12:TP=-1:LRA=4'  // YouTube Shorts loudness
  ];

  /// Podcast/Voice optimization - clarity focused
  static List<String> get voiceOptimized => [
    'highpass=f=100', // Remove mouth noise and handling
    'lowpass=f=12000', // Remove sibilance harshness
    'loudnorm=I=-20:TP=-3:LRA=8',
    
    // De-esser to reduce harsh S sounds
    'deesser=i=0.1:m=0.5:f=6000:s=o',
    
    // Voice-specific EQ
    'equalizer=f=200:width_type=h:width=100:g=-1',   // Reduce muddiness
    'equalizer=f=1200:width_type=h:width=300:g=2',   // Vocal intelligibility
    'equalizer=f=3500:width_type=h:width=800:g=3',   // Vocal presence
    'equalizer=f=8000:width_type=h:width=2000:g=1',  // Clarity without harshness
    
    // Gentle compression for consistency
    'acompressor=threshold=0.02:ratio=2.5:attack=500:release=2000',
    
    // Final limiting
    'alimiter=level_in=1.1:level_out=0.92:limit=0.92:attack=20:release=200',
    'loudnorm=I=-18:TP=-2:LRA=6'
  ];

  /// Music enhancement - preserve dynamics but add presence
  static List<String> get musicEnhanced => [
    'highpass=f=30', // Preserve bass but remove subsonic
    'loudnorm=I=-19:TP=-2.5:LRA=9',
    
    // Gentle multiband processing
    'acompressor=threshold=0.05:ratio=2:attack=1000:release=3000',
    
    // Musical EQ curve
    'equalizer=f=60:width_type=h:width=40:g=1',      // Sub-bass
    'equalizer=f=200:width_type=h:width=150:g=0.5',  // Warmth
    'equalizer=f=1000:width_type=h:width=300:g=0.5', // Midrange clarity
    'equalizer=f=4000:width_type=h:width=1000:g=1.5', // Presence
    'equalizer=f=12000:width_type=h:width=3000:g=1',  // Air
    
    // Gentle limiting to preserve dynamics
    'alimiter=level_in=1.05:level_out=0.90:limit=0.90:attack=15:release=150',
    'loudnorm=I=-17:TP=-2:LRA=8'
  ];

  /// Gentle enhancement - subtle improvements
  static List<String> get gentle => [
    'highpass=f=50',
    'loudnorm=I=-20:TP=-3:LRA=10',
    'acompressor=threshold=0.1:ratio=1.5:attack=2000:release=5000',
    'equalizer=f=3000:width_type=h:width=1000:g=1',
    'alimiter=level_in=1.02:level_out=0.88:limit=0.88:attack=30:release=300'
  ];

  /// Get preset by name
  static List<String>? getPreset(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'tiktok':
      case 'tiktok_style':
        return tiktokStyle;
      case 'instagram':
      case 'instagram_style':
        return instagramStyle;
      case 'youtube':
      case 'youtube_style':
        return youtubeStyle;
      case 'voice':
      case 'voice_optimized':
        return voiceOptimized;
      case 'music':
      case 'music_enhanced':
        return musicEnhanced;
      case 'gentle':
        return gentle;
      default:
        return null;
    }
  }

  /// Get all available preset names
  static List<String> get availablePresets => [
    'tiktok_style',
    'instagram_style', 
    'youtube_style',
    'voice_optimized',
    'music_enhanced',
    'gentle'
  ];

  /// Get preset description
  static String getPresetDescription(String presetName) {
    switch (presetName.toLowerCase()) {
      case 'tiktok':
      case 'tiktok_style':
        return 'MAXIMUM loudness with crisp clarity - viral content ready!';
      case 'instagram':
      case 'instagram_style':
        return 'Loud and musical enhancement perfect for Reels';
      case 'youtube':
      case 'youtube_style':
        return 'Clear and punchy audio optimized for Shorts';
      case 'voice':
      case 'voice_optimized':
        return 'Crystal clear speech with noise reduction';
      case 'music':
      case 'music_enhanced':
        return 'Enhanced music with preserved dynamics';
      case 'gentle':
        return 'Subtle improvements maintaining natural sound';
      default:
        return 'Unknown preset';
    }
  }

  /// Custom filter builder for advanced users
  static List<String> buildCustomFilter({
    double bassBoost = 0,        // dB: -10 to +10
    double midBoost = 0,         // dB: -10 to +10  
    double trebleBoost = 0,      // dB: -10 to +10
    double loudness = -16,       // LUFS: -30 to -6
    double compression = 2,      // Ratio: 1 to 10
    bool enableLimiter = true,
    bool enableDeEsser = false,
  }) {
    List<String> filters = [];
    
    // Basic cleanup
    filters.addAll([
      'highpass=f=80',
      'lowpass=f=16000',
    ]);

    // Initial normalization
    filters.add('loudnorm=I=${loudness.clamp(-30, -6)}:TP=-2:LRA=8');
    
    // Compression
    if (compression > 1) {
      final threshold = (1 / compression * 0.1).clamp(0.001, 0.5);
      filters.add('acompressor=threshold=$threshold:ratio=${compression.clamp(1, 10)}:attack=200:release=1000');
    }
    
    // EQ adjustments
    if (bassBoost.abs() > 0.1) {
      filters.add('equalizer=f=200:width_type=h:width=150:g=${bassBoost.clamp(-10, 10)}');
    }
    if (midBoost.abs() > 0.1) {
      filters.add('equalizer=f=3000:width_type=h:width=800:g=${midBoost.clamp(-10, 10)}');
    }
    if (trebleBoost.abs() > 0.1) {
      filters.add('equalizer=f=8000:width_type=h:width=2000:g=${trebleBoost.clamp(-10, 10)}');
    }
    
    // De-esser for voice content
    if (enableDeEsser) {
      filters.add('deesser=i=0.1:m=0.5:f=6000:s=o');
    }
    
    // Final limiting
    if (enableLimiter) {
      filters.add('alimiter=level_in=1.2:level_out=0.95:limit=0.95:attack=10:release=100');
    }
    
    // Final normalization
    filters.add('loudnorm=I=${(loudness + 2).clamp(-28, -4)}:TP=-1:LRA=6');
    
    return filters;
  }
}