import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person_model.dart';
import '../models/schedule_model.dart';

class ScheduleService extends ChangeNotifier {
  static final ScheduleService instance = ScheduleService._internal();
  ScheduleService._internal();

  WeeklySchedule weeklySchedule = WeeklySchedule.createDefault();
  List<Person> persons = [];
  String? activePersonId; // null = View All / Shared

  static const String _scheduleStorageKey = 'daily_schedule_weekly';
  static const String _personsStorageKey = 'daily_schedule_persons';
  static const String _activePersonKey = 'daily_schedule_active_person_id';

  Person? get activePerson {
    if (activePersonId == null) return null;
    try {
      return persons.firstWhere((p) => p.id == activePersonId);
    } catch (_) {
      return null;
    }
  }

  Person? getPersonById(String? id) {
    if (id == null || id.isEmpty) return null;
    try {
      return persons.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Load Persons
    final personsJson = prefs.getString(_personsStorageKey);
    if (personsJson != null && personsJson.isNotEmpty) {
      try {
        final List<dynamic> decoded = jsonDecode(personsJson);
        persons = decoded.map((e) => Person.fromJson(e as Map<String, dynamic>)).toList();
      } catch (_) {
        persons = Person.defaultPersons();
      }
    } else {
      persons = Person.defaultPersons();
      await savePersons();
    }

    // 2. Load Active Person Selection
    activePersonId = prefs.getString(_activePersonKey);
    if (activePersonId != null && !persons.any((p) => p.id == activePersonId)) {
      activePersonId = null;
    }

    // 3. Load Weekly Schedule
    final scheduleJson = prefs.getString(_scheduleStorageKey);
    if (scheduleJson != null && scheduleJson.isNotEmpty) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(scheduleJson);
        weeklySchedule = WeeklySchedule.fromJson(decoded);
      } catch (_) {
        weeklySchedule = _createInitialDefaultSchedule();
      }
    } else {
      weeklySchedule = _createInitialDefaultSchedule();
      await saveSchedule();
    }

    notifyListeners();
  }

  Future<void> saveSchedule() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scheduleStorageKey, jsonEncode(weeklySchedule.toJson()));
    notifyListeners();
  }

  Future<void> savePersons() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personsStorageKey, jsonEncode(persons.map((e) => e.toJson()).toList()));
    notifyListeners();
  }

  Future<void> setActivePerson(String? id) async {
    activePersonId = id;
    final prefs = await SharedPreferences.getInstance();
    if (id == null) {
      await prefs.remove(_activePersonKey);
    } else {
      await prefs.setString(_activePersonKey, id);
    }
    notifyListeners();
  }

  Future<void> addPerson(Person person) async {
    persons.add(person);
    await savePersons();
  }

  Future<void> updatePerson(Person person) async {
    final index = persons.indexWhere((p) => p.id == person.id);
    if (index != -1) {
      persons[index] = person;
      await savePersons();
    }
  }

  Future<void> deletePerson(String personId) async {
    persons.removeWhere((p) => p.id == personId);
    if (activePersonId == personId) {
      activePersonId = null;
    }

    // Unassign activities that were assigned to this deleted person
    for (int day = 0; day <= 6; day++) {
      final daySchedule = weeklySchedule.getDay(day);
      for (var item in daySchedule.items) {
        if (item.assignedPersonId == personId) {
          item.assignedPersonId = null;
        }
      }
    }

    await savePersons();
    await saveSchedule();
  }

  /// Filter items by the currently active person or a specific person
  List<ScheduleItem> filterItems(
    List<ScheduleItem> items, {
    String? personId,
    bool includeShared = true,
  }) {
    final targetId = personId ?? activePersonId;
    if (targetId == null) {
      // Return all items if view is set to All / Shared
      return items;
    }
    if (includeShared) {
      return items
          .where((item) =>
              item.assignedPersonId == targetId ||
              item.assignedPersonId == null ||
              item.assignedPersonId!.isEmpty)
          .toList();
    }
    return items.where((item) => item.assignedPersonId == targetId).toList();
  }

  /// Count completed and total items for a day considering the active person filter
  ({int completed, int total}) getDayProgress(
    int dayIndex, {
    String? personId,
    bool includeShared = true,
  }) {
    final dayItems = filterItems(
      weeklySchedule.getDay(dayIndex).items,
      personId: personId,
      includeShared: includeShared,
    );
    final completedCount = dayItems.where((i) => i.isCompleted).length;
    return (completed: completedCount, total: dayItems.length);
  }

  /// Clones a day's schedule to another target day
  Future<void> copyDay(int fromDay, int toDay) async {
    final sourceDay = weeklySchedule.getDay(fromDay);
    final clonedItems = sourceDay.items.map((e) => e.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      isCompleted: false, // Reset completion status
    )).toList();

    weeklySchedule.days[toDay] = DaySchedule(dayOfWeek: toDay, items: clonedItems);
    await saveSchedule();
  }

  /// Clones active day to all weekdays (Mon-Fri = 1..5)
  Future<void> copyDayToAllWeekdays(int fromDay) async {
    for (int day = 1; day <= 5; day++) {
      if (day != fromDay) {
        await copyDay(fromDay, day);
      }
    }
  }

  /// Clones active day to all 7 days of the week (Sun-Sat = 0..6)
  Future<void> copyDayToAllDays(int fromDay) async {
    for (int day = 0; day <= 6; day++) {
      if (day != fromDay) {
        await copyDay(fromDay, day);
      }
    }
  }

  /// Clears activities for a specific day
  Future<void> clearDay(int dayOfWeek) async {
    weeklySchedule.days[dayOfWeek] = DaySchedule(dayOfWeek: dayOfWeek, items: []);
    await saveSchedule();
  }

  /// Resets all 7 days to empty
  Future<void> clearAllSchedules() async {
    for (int day = 0; day <= 6; day++) {
      weeklySchedule.days[day] = DaySchedule(dayOfWeek: day, items: []);
    }
    await saveSchedule();
  }

  /// Starter default routine with assignments to demonstrate multi-person capabilities
  WeeklySchedule _createInitialDefaultSchedule() {
    final schedule = WeeklySchedule.createDefault();

    for (int day = 0; day < 7; day++) {
      schedule.days[day] = DaySchedule(
        dayOfWeek: day,
        items: [
          ScheduleItem(
            id: 'sample_${day}_1',
            title: 'Wake-up Time',
            time: '07:00 AM',
            iconCodePoint: SchedulePresets.getIconForLabel('Wake-up Time').codePoint,
            assignedPersonId: 'person_maya',
            isCompleted: false,
          ),
          ScheduleItem(
            id: 'sample_${day}_2',
            title: 'Teeth Time',
            time: '07:15 AM',
            iconCodePoint: SchedulePresets.getIconForLabel('Teeth Time').codePoint,
            assignedPersonId: 'person_alex',
            isCompleted: false,
          ),
          ScheduleItem(
            id: 'sample_${day}_3',
            title: 'Meal Time',
            time: '07:45 AM',
            iconCodePoint: SchedulePresets.getIconForLabel('Meal Time').codePoint,
            assignedPersonId: null, // Shared / Family meal
            isCompleted: false,
          ),
          ScheduleItem(
            id: 'sample_${day}_4',
            title: 'Arrival Time',
            time: '08:30 AM',
            iconCodePoint: SchedulePresets.getIconForLabel('Arrival Time').codePoint,
            assignedPersonId: 'person_maya',
            isCompleted: false,
          ),
          ScheduleItem(
            id: 'sample_${day}_5',
            title: 'Circle Time',
            time: '09:00 AM',
            iconCodePoint: SchedulePresets.getIconForLabel('Circle Time').codePoint,
            assignedPersonId: 'person_alex',
            isCompleted: false,
          ),
          ScheduleItem(
            id: 'sample_${day}_6',
            title: 'Therapy Time',
            time: '10:30 AM',
            iconCodePoint: SchedulePresets.getIconForLabel('Therapy Time').codePoint,
            assignedPersonId: 'person_sam',
            isCompleted: false,
          ),
        ],
      );
    }

    return schedule;
  }
}
