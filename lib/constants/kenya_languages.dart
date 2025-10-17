// lib/core/constants/kenya_languages.dart

/// All 42 Kenyan tribes + Foreign option (43 total)
/// Users select their tribe as their native language identifier
library;


class KenyaLanguages {
  /// All 42 Kenyan tribes organized by linguistic groups + Foreign
  static const List<String> allTribes = [
    // Bantu Group (23 tribes)
    'Kikuyu',
    'Luhya',
    'Kamba',
    'Kisii',
    'Meru',
    'Mijikenda',
    'Embu',
    'Taita',
    'Kuria',
    'Mbeere',
    'Tharaka',
    'Pokomo',
    'Taveta',
    'Maragoli',
    'Bukusu',
    'Idakho',
    'Isukha',
    'Kabras',
    'Khayo',
    'Marachi',
    'Samia',
    'Tachoni',
    'Wanga',

    // Nilotic Group (15 tribes)
    'Luo',
    'Kalenjin',
    'Maasai',
    'Turkana',
    'Samburu',
    'Teso',
    'Pokot',
    'Nandi',
    'Kipsigis',
    'Tugen',
    'Keiyo',
    'Marakwet',
    'Sabaot',
    'Njemps',
    'Terik',

    // Cushitic Group (4 tribes)
    'Somali',
    'Oromo',
    'Rendille',
    'Borana',

    // Foreign (Non-Kenyan) - 43rd option
    'Foreign',
  ];

  /// Tribes organized by linguistic groups for categorized display
  static const Map<String, List<String>> tribesByGroup = {
    'Bantu': [
      'Kikuyu',
      'Luhya',
      'Kamba',
      'Kisii',
      'Meru',
      'Mijikenda',
      'Embu',
      'Taita',
      'Kuria',
      'Mbeere',
      'Tharaka',
      'Pokomo',
      'Taveta',
      'Maragoli',
      'Bukusu',
      'Idakho',
      'Isukha',
      'Kabras',
      'Khayo',
      'Marachi',
      'Samia',
      'Tachoni',
      'Wanga',
    ],
    'Nilotic': [
      'Luo',
      'Kalenjin',
      'Maasai',
      'Turkana',
      'Samburu',
      'Teso',
      'Pokot',
      'Nandi',
      'Kipsigis',
      'Tugen',
      'Keiyo',
      'Marakwet',
      'Sabaot',
      'Njemps',
      'Terik',
    ],
    'Cushitic': [
      'Somali',
      'Oromo',
      'Rendille',
      'Borana',
    ],
    'Foreign': [
      'Foreign',
    ],
  };

  /// Get all tribes as a simple list (43 total)
  static List<String> get tribes => List.unmodifiable(allTribes);

  /// Get total count
  static int get totalCount => allTribes.length; // 43

  /// Check if a tribe is valid
  static bool isValid(String tribe) {
    return allTribes.contains(tribe);
  }

  /// Check if selection is foreign
  static bool isForeign(String tribe) {
    return tribe.toLowerCase() == 'foreign';
  }

  /// Search tribes by query
  static List<String> search(String query) {
    if (query.isEmpty) return tribes;
    
    final lowerQuery = query.toLowerCase();
    return allTribes
        .where((tribe) => tribe.toLowerCase().contains(lowerQuery))
        .toList();
  }

  /// Get linguistic group for a tribe
  static String? getGroup(String tribe) {
    for (var entry in tribesByGroup.entries) {
      if (entry.value.contains(tribe)) {
        return entry.key;
      }
    }
    return null;
  }

  /// Get count by linguistic group
  static Map<String, int> get countByGroup {
    return {
      'Bantu': tribesByGroup['Bantu']!.length,
      'Nilotic': tribesByGroup['Nilotic']!.length,
      'Cushitic': tribesByGroup['Cushitic']!.length,
      'Foreign': tribesByGroup['Foreign']!.length,
    };
  }

  /// Get only Kenyan tribes (exclude Foreign)
  static List<String> get kenyanTribesOnly {
    return allTribes.where((tribe) => tribe != 'Foreign').toList();
  }

  /// Get tribes for a specific linguistic group
  static List<String> getTribesInGroup(String group) {
    return tribesByGroup[group] ?? [];
  }
}