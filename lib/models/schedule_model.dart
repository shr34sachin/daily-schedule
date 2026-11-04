import 'package:flutter/material.dart';

class TimeOfDayGreetingInfo {
  final String phase;
  final String timeRange;
  final String greeting;
  final IconData icon;
  final Color themeColor;

  const TimeOfDayGreetingInfo({
    required this.phase,
    required this.timeRange,
    required this.greeting,
    required this.icon,
    required this.themeColor,
  });

  static TimeOfDayGreetingInfo getForTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute;
    final timeInMinutes = hour * 60 + minute;

    // 00:00 - 06:00
    if (timeInMinutes < 6 * 60) {
      return const TimeOfDayGreetingInfo(
        phase: 'Midnight / Night',
        timeRange: '00:00 - 06:00',
        greeting: 'Good night',
        icon: Icons.dark_mode,
        themeColor: Colors.deepPurple,
      );
    }
    // 06:00 - 09:00
    if (timeInMinutes < 9 * 60) {
      return const TimeOfDayGreetingInfo(
        phase: 'Morning',
        timeRange: '06:00 - 09:00',
        greeting: 'Good morning',
        icon: Icons.wb_sunny_outlined,
        themeColor: Colors.amber,
      );
    }
    // 09:00 - 12:00
    if (timeInMinutes < 12 * 60) {
      return const TimeOfDayGreetingInfo(
        phase: 'Late morning',
        timeRange: '09:00 - 12:00',
        greeting: 'Good morning',
        icon: Icons.wb_sunny,
        themeColor: Colors.orangeAccent,
      );
    }
    // 12:00 - 12:30
    if (timeInMinutes < 12 * 60 + 30) {
      return const TimeOfDayGreetingInfo(
        phase: 'Noon / Midday',
        timeRange: '12:00 - 12:30',
        greeting: 'Good noon',
        icon: Icons.light_mode,
        themeColor: Colors.orange,
      );
    }
    // 12:30 - 16:00
    if (timeInMinutes < 16 * 60) {
      return const TimeOfDayGreetingInfo(
        phase: 'Afternoon',
        timeRange: '12:30 - 16:00',
        greeting: 'Good afternoon',
        icon: Icons.brightness_medium,
        themeColor: Colors.blue,
      );
    }
    // 16:00 - 17:00
    if (timeInMinutes < 17 * 60) {
      return const TimeOfDayGreetingInfo(
        phase: 'Late afternoon',
        timeRange: '16:00 - 17:00',
        greeting: 'Good afternoon',
        icon: Icons.wb_twilight,
        themeColor: Colors.deepOrangeAccent,
      );
    }
    // 17:00 - 19:00
    if (timeInMinutes < 19 * 60) {
      return const TimeOfDayGreetingInfo(
        phase: 'Early evening',
        timeRange: '17:00 - 19:00',
        greeting: 'Good evening',
        icon: Icons.brightness_4,
        themeColor: Colors.indigo,
      );
    }
    // 19:00 - 21:00
    if (timeInMinutes < 21 * 60) {
      return const TimeOfDayGreetingInfo(
        phase: 'Evening',
        timeRange: '19:00 - 21:00',
        greeting: 'Good evening',
        icon: Icons.nightlight_round,
        themeColor: Colors.indigoAccent,
      );
    }
    // 21:00 - 23:59
    return const TimeOfDayGreetingInfo(
      phase: 'Late evening',
      timeRange: '21:00 - 23:59',
      greeting: 'Good evening for the night',
      icon: Icons.bedtime,
      themeColor: Colors.deepPurpleAccent,
    );
  }
}

class ScheduleActivityTemplate {
  final String label;
  final IconData icon;
  final Color color;

  const ScheduleActivityTemplate({
    required this.label,
    required this.icon,
    required this.color,
  });
}

class SchedulePresets {
  static const List<ScheduleActivityTemplate> all = [
    ScheduleActivityTemplate(label: 'Arrival Time', icon: Icons.directions_bus, color: Colors.blue),
    ScheduleActivityTemplate(label: 'Circle Time', icon: Icons.groups, color: Colors.purple),
    ScheduleActivityTemplate(label: 'Work Time', icon: Icons.edit_note, color: Colors.indigo),
    ScheduleActivityTemplate(label: 'Snack Time', icon: Icons.cookie, color: Colors.amber),
    ScheduleActivityTemplate(label: 'Lunch Time', icon: Icons.lunch_dining, color: Colors.deepOrange),
    ScheduleActivityTemplate(label: 'Play Time', icon: Icons.sports_esports, color: Colors.pinkAccent),
    ScheduleActivityTemplate(label: 'Specialist Time', icon: Icons.psychology, color: Colors.teal),
    ScheduleActivityTemplate(label: 'Therapy Time', icon: Icons.self_improvement, color: Colors.green),
    ScheduleActivityTemplate(label: 'Sensory Time', icon: Icons.bubble_chart, color: Colors.cyan),
    ScheduleActivityTemplate(label: 'Bathroom Time', icon: Icons.wc, color: Colors.blueGrey),
    ScheduleActivityTemplate(label: 'Departure Time', icon: Icons.logout, color: Colors.redAccent),
    ScheduleActivityTemplate(label: 'Wake-up Time', icon: Icons.alarm, color: Colors.amberAccent),
    ScheduleActivityTemplate(label: 'Dressing Time', icon: Icons.checkroom, color: Colors.teal),
    ScheduleActivityTemplate(label: 'Meal Time', icon: Icons.restaurant, color: Colors.orange),
    ScheduleActivityTemplate(label: 'Teeth Time', icon: Icons.clean_hands, color: Colors.lightBlue),
    ScheduleActivityTemplate(label: 'Study Time', icon: Icons.menu_book, color: Colors.indigoAccent),
    ScheduleActivityTemplate(label: 'Screen Time', icon: Icons.tv, color: Colors.deepPurple),
    ScheduleActivityTemplate(label: 'Quiet Time', icon: Icons.volume_off, color: Colors.blueGrey),
    ScheduleActivityTemplate(label: 'chill Time', icon: Icons.weekend, color: Colors.brown),
    ScheduleActivityTemplate(label: 'Outdoor Time', icon: Icons.park, color: Colors.green),
    ScheduleActivityTemplate(label: 'Chore Time', icon: Icons.cleaning_services, color: Colors.blue),
    ScheduleActivityTemplate(label: 'Tidy-up Time', icon: Icons.inventory_2, color: Colors.amber),
    ScheduleActivityTemplate(label: 'Bath Time', icon: Icons.bathtub, color: Colors.cyan),
    ScheduleActivityTemplate(label: 'Sleep Time', icon: Icons.bed, color: Colors.indigo),
    ScheduleActivityTemplate(label: 'Break Time', icon: Icons.pause_circle, color: Colors.teal),
    ScheduleActivityTemplate(label: 'Movement Time', icon: Icons.directions_run, color: Colors.deepOrange),
    ScheduleActivityTemplate(label: 'Waiting Time', icon: Icons.hourglass_bottom, color: Colors.purpleAccent),
    ScheduleActivityTemplate(label: 'Music Time', icon: Icons.music_note, color: Colors.pink),
    ScheduleActivityTemplate(label: 'Assembly Time', icon: Icons.campaign, color: Colors.indigo),
    ScheduleActivityTemplate(label: 'Home Time', icon: Icons.home, color: Colors.deepOrange),
    ScheduleActivityTemplate(label: 'Story Time', icon: Icons.auto_stories, color: Colors.teal),
  ];

  static IconData getIconForLabel(String label) {
    final match = all.firstWhere(
      (e) => e.label.toLowerCase() == label.toLowerCase(),
      orElse: () => const ScheduleActivityTemplate(label: '', icon: Icons.event_note, color: Colors.blue),
    );
    return match.icon;
  }

  static Color getColorForLabel(String label) {
    final match = all.firstWhere(
      (e) => e.label.toLowerCase() == label.toLowerCase(),
      orElse: () => const ScheduleActivityTemplate(label: '', icon: Icons.event_note, color: Colors.blue),
    );
    return match.color;
  }
}

class ScheduleItem {
  String id;
  String title;
  String time; // e.g. "08:30 AM" or empty for anytime
  int iconCodePoint;
  String? iconFontFamily;
  String? iconFontPackage;
  String customImageBase64;
  bool isCompleted;
  String notes;
  String? assignedPersonId; // null or empty for All / Shared

  ScheduleItem({
    required this.id,
    required this.title,
    required this.time,
    required this.iconCodePoint,
    this.iconFontFamily,
    this.iconFontPackage,
    this.customImageBase64 = '',
    this.isCompleted = false,
    this.notes = '',
    this.assignedPersonId,
  });

  IconData get icon => SchedulePresets.getIconForLabel(title);

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'time': time,
        'iconCodePoint': iconCodePoint,
        'iconFontFamily': iconFontFamily,
        'iconFontPackage': iconFontPackage,
        'customImageBase64': customImageBase64,
        'isCompleted': isCompleted,
        'notes': notes,
        'assignedPersonId': assignedPersonId,
      };

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: json['title'] ?? '',
        time: json['time'] ?? '',
        iconCodePoint: json['iconCodePoint'] ?? Icons.event_note.codePoint,
        iconFontFamily: json['iconFontFamily'],
        iconFontPackage: json['iconFontPackage'],
        customImageBase64: json['customImageBase64'] ?? '',
        isCompleted: json['isCompleted'] ?? false,
        notes: json['notes'] ?? '',
        assignedPersonId: json['assignedPersonId'],
      );

  ScheduleItem copyWith({
    String? id,
    String? title,
    String? time,
    int? iconCodePoint,
    String? iconFontFamily,
    String? iconFontPackage,
    String? customImageBase64,
    bool? isCompleted,
    String? notes,
    String? assignedPersonId,
  }) {
    return ScheduleItem(
      id: id ?? this.id,
      title: title ?? this.title,
      time: time ?? this.time,
      iconCodePoint: iconCodePoint ?? this.iconCodePoint,
      iconFontFamily: iconFontFamily ?? this.iconFontFamily,
      iconFontPackage: iconFontPackage ?? this.iconFontPackage,
      customImageBase64: customImageBase64 ?? this.customImageBase64,
      isCompleted: isCompleted ?? this.isCompleted,
      notes: notes ?? this.notes,
      assignedPersonId: assignedPersonId ?? this.assignedPersonId,
    );
  }
}

class DaySchedule {
  final int dayOfWeek; // 0: Sunday, 1: Monday, ..., 6: Saturday
  List<ScheduleItem> items;

  DaySchedule({
    required this.dayOfWeek,
    required this.items,
  });

  String get dayName {
    switch (dayOfWeek) {
      case 0:
        return 'Sunday';
      case 1:
        return 'Monday';
      case 2:
        return 'Tuesday';
      case 3:
        return 'Wednesday';
      case 4:
        return 'Thursday';
      case 5:
        return 'Friday';
      case 6:
        return 'Saturday';
      default:
        return 'Day';
    }
  }

  String get shortDayName {
    switch (dayOfWeek) {
      case 0:
        return 'Sun';
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      default:
        return '';
    }
  }

  Map<String, dynamic> toJson() => {
        'dayOfWeek': dayOfWeek,
        'items': items.map((e) => e.toJson()).toList(),
      };

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
        dayOfWeek: json['dayOfWeek'] ?? 0,
        items: (json['items'] as List? ?? [])
            .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}

class WeeklySchedule {
  Map<int, DaySchedule> days; // 0..6

  WeeklySchedule({required this.days});

  DaySchedule getDay(int dayOfWeek) {
    return days[dayOfWeek] ?? DaySchedule(dayOfWeek: dayOfWeek, items: []);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> map = {};
    days.forEach((key, value) {
      map[key.toString()] = value.toJson();
    });
    return map;
  }

  factory WeeklySchedule.fromJson(Map<String, dynamic> json) {
    final Map<int, DaySchedule> map = {};
    for (int i = 0; i < 7; i++) {
      if (json.containsKey(i.toString())) {
        map[i] = DaySchedule.fromJson(json[i.toString()]);
      } else {
        map[i] = DaySchedule(dayOfWeek: i, items: []);
      }
    }
    return WeeklySchedule(days: map);
  }

  factory WeeklySchedule.createDefault() {
    final Map<int, DaySchedule> map = {};
    for (int i = 0; i < 7; i++) {
      map[i] = DaySchedule(dayOfWeek: i, items: []);
    }
    return WeeklySchedule(days: map);
  }
}

