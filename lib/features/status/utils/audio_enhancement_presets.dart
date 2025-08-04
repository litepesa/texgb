// lib/features/status/utils/audio_enhancement_presets.dart
class AudioEnhancementPresets {
  
  /// TikTok-style audio enhancement - based on proven create_post_screen processing with crispness refinements
  static List<String> get tiktokStyle => [
    // 1. Initial volume boost and EQ foundation (from create_post_screen)
    'volume=2.2',
    
    // 2. Enhanced frequency cleanup (refined from create_post_screen)
    'highpass=f=42',    // Slightly tighter than original 40Hz for cleaner low end
    'lowpass=f=14800',  // Slightly lower than original 15000Hz for smoother highs
    
    // 3. Core EQ signature (from create_post_screen with micro-refinements)
    'equalizer=f=60:width_type=h:width=2:g=3.2',   // Sub-bass (+0.2dB more punch)
    'equalizer=f=150:width_type=h:width=2:g=2.2',  // Bass warmth (+0.2dB)
    'equalizer=f=800:width_type=h:width=3:g=1.5',  // NEW: Lower-mid clarity
    'equalizer=f=2500:width_type=h:width=4:g=2.8', // NEW: Vocal intelligibility  
    'equalizer=f=8000:width_type=h:width=2:g=1.3', // High-freq clarity (+0.3dB)
    'equalizer=f=12000:width_type=h:width=3:g=0.8', // NEW: Air and sparkle
    
    // 4. Advanced dynamic processing (from create_post_screen with refinements)
    'compand=attacks=0.18:decays=0.38:points=-80/-80|-50/-20|-30/-15|-20/-10|-5/-5|0/-2|20/-2', // Slightly faster attack/decay
    
    // 5. Additional crispness enhancements (new additions)
    'acompressor=threshold=0.002:ratio=2.8:attack=120:release=800', // Gentle pre-compression
    'deesser=i=0.06:m=0.35:f=6800:s=o', // Smooth sibilants without losing crispness
    
    // 6. Harmonic enhancement for presence (new addition)
    'aexciter=level_in=0.9:level_out=1:amount=1.8:drive=6.5:blend=35:freq=7800:ceil=15000',
    
    // 7. Final broadcast normalization (from create_post_screen with minor refinement)
    'loudnorm=I=-10.2:TP=-1.4:LRA=6.8:linear=true', // Slightly more controlled dynamics
    
    // 8. Final polish compression (new addition for extra punch)
    'acompressor=threshold=0.001:ratio=1.6:attack=25:release=350',
  ];

  /// TikTok Classic - exact copy of working create_post_screen audio filter
  static List<String> get tiktokStyleClassic => [
    'volume=2.2',
    'equalizer=f=60:width_type=h:width=2:g=3',
    'equalizer=f=150:width_type=h:width=2:g=2',
    'equalizer=f=8000:width_type=h:width=2:g=1',
    'compand=attacks=0.2:decays=0.4:points=-80/-80|-50/-20|-30/-15|-20/-10|-5/-5|0/-2|20/-2',
    'highpass=f=40',
    'lowpass=f=15000',
    'loudnorm=I=-10:TP=-1.5:LRA=7:linear=true'
  ];

  /// TikTok Crisp - maximum crispness while maintaining loudness
  static List<String> get tiktokStyleCrisp => [
    // Stage 1: Foundation (from create_post_screen)
    'volume=2.2',
    
    // Stage 2: Enhanced cleanup
    'highpass=f=45',    // Tighter low-end cleanup
    'lowpass=f=14500',  // Smoother high-end rolloff
    
    // Stage 3: Expanded EQ for maximum clarity
    'equalizer=f=60:width_type=h:width=2:g=3.2',   // Extra sub-bass punch
    'equalizer=f=150:width_type=h:width=2:g=2.1',  // Slightly more warmth
    'equalizer=f=500:width_type=h:width=2.5:g=1.2', // NEW: Lower-mid definition
    'equalizer=f=1200:width_type=h:width=3:g=1.8',  // NEW: Vocal intelligibility
    'equalizer=f=3000:width_type=h:width=4:g=2.5',  // NEW: Vocal presence
    'equalizer=f=5000:width_type=h:width=3:g=1.6',  // NEW: Consonant clarity
    'equalizer=f=8000:width_type=h:width=2:g=1.4',  // Enhanced high-freq (+0.4dB)
    'equalizer=f=11000:width_type=h:width=2.5:g=1.1', // NEW: Air and detail
    
    // Stage 4: Advanced dynamics (refined from create_post_screen)  
    'compand=attacks=0.15:decays=0.35:points=-80/-80|-50/-19|-30/-14|-20/-9|-5/-4|0/-1.8|20/-1.8',
    
    // Stage 5: Crispness enhancements
    'acompressor=threshold=0.0015:ratio=2.2:attack=80:release=600', // Gentle compression
    'deesser=i=0.05:m=0.3:f=7000:s=o', // Subtle de-essing
    'aexciter=level_in=0.85:level_out=1:amount=1.5:drive=5.8:blend=30:freq=8000:ceil=14500', // Harmonic excitement
    
    // Stage 6: Final normalization (maintaining same loudness as original)
    'loudnorm=I=-10.1:TP=-1.45:LRA=6.9:linear=true',
    
    // Stage 7: Final punch
    'acompressor=threshold=0.0008:ratio=1.4:attack=20:release=250', // Micro-compression for consistency
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
      case 'tiktok_classic':
      case 'tiktok_style_classic':
        return tiktokStyleClassic;
      case 'tiktok_crisp':
      case 'tiktok_style_crisp':
        return tiktokStyleCrisp;
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
    'tiktok_style_classic',
    'tiktok_style_crisp',
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
        return 'Enhanced loudness with crisp clarity - viral content ready! (Based on proven create_post_screen processing)';
      case 'tiktok_classic':
      case 'tiktok_style_classic':
        return 'Exact copy of working create_post_screen audio filter - proven performance';
      case 'tiktok_crisp':
      case 'tiktok_style_crisp':
        return 'Maximum crispness and detail while maintaining viral loudness';
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