import 'package:flutter/material.dart';

class Person {
  final String id;
  final String name;
  final int colorValue;
  final int iconCodePoint;
  final String role;
  final String avatarEmoji;
  final String customImageBase64;

  const Person({
    required this.id,
    required this.name,
    required this.colorValue,
    this.iconCodePoint = 58544, // Icons.person
    this.role = 'Member',
    this.avatarEmoji = '👤',
    this.customImageBase64 = '',
  });

  Color get color => Color(colorValue);
  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');
  bool get hasCustomImage => customImageBase64.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'colorValue': colorValue,
        'iconCodePoint': iconCodePoint,
        'role': role,
        'avatarEmoji': avatarEmoji,
        'customImageBase64': customImageBase64,
      };

  factory Person.fromJson(Map<String, dynamic> json) => Person(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: json['name'] ?? 'Unnamed',
        colorValue: json['colorValue'] ?? 0xFF2196F3,
        iconCodePoint: json['iconCodePoint'] ?? 58544,
        role: json['role'] ?? 'Member',
        avatarEmoji: json['avatarEmoji'] ?? '👤',
        customImageBase64: json['customImageBase64'] ?? '',
      );

  Person copyWith({
    String? id,
    String? name,
    int? colorValue,
    int? iconCodePoint,
    String? role,
    String? avatarEmoji,
    String? customImageBase64,
  }) {
    return Person(
      id: id ?? this.id,
      name: name ?? this.name,
      colorValue: colorValue ?? this.colorValue,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      role: role ?? this.role,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      customImageBase64: customImageBase64 ?? this.customImageBase64,
    );
  }

  // Built-in starter profiles
  static List<Person> defaultPersons() => [
        const Person(
          id: 'person_maya',
          name: 'Maya',
          colorValue: 0xFF9C27B0, // Purple
          iconCodePoint: 58544,
          role: 'Student',
          avatarEmoji: '👧',
        ),
        const Person(
          id: 'person_alex',
          name: 'Alex',
          colorValue: 0xFF1976D2, // Blue
          iconCodePoint: 58544,
          role: 'Student',
          avatarEmoji: '👦',
        ),
        const Person(
          id: 'person_sam',
          name: 'Sam',
          colorValue: 0xFF00796B, // Teal
          iconCodePoint: 58544,
          role: 'Child',
          avatarEmoji: '🧒',
        ),
      ];
}
