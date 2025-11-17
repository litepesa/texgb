// ===============================
// Status Templates
// Pre-made templates for text statuses
// ===============================

import 'package:textgb/features/status/models/status_enums.dart';

class StatusTemplate {
  final String id;
  final String category;
  final String text;
  final TextStatusBackground background;
  final String? emoji;

  const StatusTemplate({
    required this.id,
    required this.category,
    required this.text,
    required this.background,
    this.emoji,
  });
}

class StatusTemplates {
  StatusTemplates._();

  // ===============================
  // MOTIVATIONAL
  // ===============================

  static const List<StatusTemplate> motivational = [
    StatusTemplate(
      id: 'mot_1',
      category: 'Motivational',
      text: 'Believe you can and you\'re halfway there',
      background: TextStatusBackground.gradient1,
      emoji: '💪',
    ),
    StatusTemplate(
      id: 'mot_2',
      category: 'Motivational',
      text: 'The only way to do great work is to love what you do',
      background: TextStatusBackground.gradient2,
      emoji: '✨',
    ),
    StatusTemplate(
      id: 'mot_3',
      category: 'Motivational',
      text: 'Success is not final, failure is not fatal',
      background: TextStatusBackground.gradient3,
      emoji: '🔥',
    ),
    StatusTemplate(
      id: 'mot_4',
      category: 'Motivational',
      text: 'Dream big, work hard, stay focused',
      background: TextStatusBackground.gradient4,
      emoji: '🎯',
    ),
    StatusTemplate(
      id: 'mot_5',
      category: 'Motivational',
      text: 'Every day is a new beginning',
      background: TextStatusBackground.gradient5,
      emoji: '🌅',
    ),
  ];

  // ===============================
  // MOOD
  // ===============================

  static const List<StatusTemplate> mood = [
    StatusTemplate(
      id: 'mood_1',
      category: 'Mood',
      text: 'Feeling blessed today 🙏',
      background: TextStatusBackground.gradient6,
      emoji: '😊',
    ),
    StatusTemplate(
      id: 'mood_2',
      category: 'Mood',
      text: 'Living my best life',
      background: TextStatusBackground.gradient1,
      emoji: '😎',
    ),
    StatusTemplate(
      id: 'mood_3',
      category: 'Mood',
      text: 'Good vibes only ✌️',
      background: TextStatusBackground.gradient3,
      emoji: '✨',
    ),
    StatusTemplate(
      id: 'mood_4',
      category: 'Mood',
      text: 'Grateful for everything',
      background: TextStatusBackground.gradient5,
      emoji: '❤️',
    ),
    StatusTemplate(
      id: 'mood_5',
      category: 'Mood',
      text: 'Happy Friday! 🎉',
      background: TextStatusBackground.gradient4,
      emoji: '🎊',
    ),
  ];

  // ===============================
  // LOVE & RELATIONSHIPS
  // ===============================

  static const List<StatusTemplate> love = [
    StatusTemplate(
      id: 'love_1',
      category: 'Love',
      text: 'Love is all you need ❤️',
      background: TextStatusBackground.gradient1,
      emoji: '💕',
    ),
    StatusTemplate(
      id: 'love_2',
      category: 'Love',
      text: 'You make my heart smile',
      background: TextStatusBackground.gradient4,
      emoji: '😍',
    ),
    StatusTemplate(
      id: 'love_3',
      category: 'Love',
      text: 'Forever grateful for you',
      background: TextStatusBackground.gradient6,
      emoji: '🥰',
    ),
    StatusTemplate(
      id: 'love_4',
      category: 'Love',
      text: 'Together is my favorite place to be',
      background: TextStatusBackground.gradient5,
      emoji: '💑',
    ),
  ];

  // ===============================
  // FUNNY
  // ===============================

  static const List<StatusTemplate> funny = [
    StatusTemplate(
      id: 'funny_1',
      category: 'Funny',
      text: 'I\'m not lazy, I\'m on energy saving mode 😴',
      background: TextStatusBackground.gradient2,
      emoji: '😂',
    ),
    StatusTemplate(
      id: 'funny_2',
      category: 'Funny',
      text: 'Coffee first, adulting second ☕',
      background: TextStatusBackground.gradient3,
      emoji: '🤪',
    ),
    StatusTemplate(
      id: 'funny_3',
      category: 'Funny',
      text: 'I\'m not arguing, I\'m just explaining why I\'m right',
      background: TextStatusBackground.gradient1,
      emoji: '😜',
    ),
    StatusTemplate(
      id: 'funny_4',
      category: 'Funny',
      text: 'Professional overthinker 🧠',
      background: TextStatusBackground.gradient4,
      emoji: '🤔',
    ),
  ];

  // ===============================
  // WISDOM
  // ===============================

  static const List<StatusTemplate> wisdom = [
    StatusTemplate(
      id: 'wisdom_1',
      category: 'Wisdom',
      text: 'Be yourself, everyone else is taken',
      background: TextStatusBackground.solid1,
      emoji: '🌟',
    ),
    StatusTemplate(
      id: 'wisdom_2',
      category: 'Wisdom',
      text: 'The best time for a new beginning is now',
      background: TextStatusBackground.solid2,
      emoji: '⏰',
    ),
    StatusTemplate(
      id: 'wisdom_3',
      category: 'Wisdom',
      text: 'Life is short, make it sweet',
      background: TextStatusBackground.solid3,
      emoji: '🍭',
    ),
    StatusTemplate(
      id: 'wisdom_4',
      category: 'Wisdom',
      text: 'Your vibe attracts your tribe',
      background: TextStatusBackground.solid4,
      emoji: '🌈',
    ),
  ];

  // ===============================
  // CELEBRATION
  // ===============================

  static const List<StatusTemplate> celebration = [
    StatusTemplate(
      id: 'cel_1',
      category: 'Celebration',
      text: 'It\'s my birthday! 🎂',
      background: TextStatusBackground.gradient4,
      emoji: '🎉',
    ),
    StatusTemplate(
      id: 'cel_2',
      category: 'Celebration',
      text: 'Cheers to new beginnings! 🥂',
      background: TextStatusBackground.gradient6,
      emoji: '🎊',
    ),
    StatusTemplate(
      id: 'cel_3',
      category: 'Celebration',
      text: 'Feeling accomplished today ✅',
      background: TextStatusBackground.gradient3,
      emoji: '🏆',
    ),
    StatusTemplate(
      id: 'cel_4',
      category: 'Celebration',
      text: 'Weekend mode: ON 🎮',
      background: TextStatusBackground.gradient2,
      emoji: '🎯',
    ),
  ];

  // ===============================
  // ALL CATEGORIES
  // ===============================

  static Map<String, List<StatusTemplate>> get allCategories => {
        'Motivational': motivational,
        'Mood': mood,
        'Love': love,
        'Funny': funny,
        'Wisdom': wisdom,
        'Celebration': celebration,
      };

  static List<StatusTemplate> get allTemplates => [
        ...motivational,
        ...mood,
        ...love,
        ...funny,
        ...wisdom,
        ...celebration,
      ];

  static List<String> get categories => [
        'Motivational',
        'Mood',
        'Love',
        'Funny',
        'Wisdom',
        'Celebration',
      ];

  static List<StatusTemplate> getByCategory(String category) {
    return allCategories[category] ?? [];
  }
}
