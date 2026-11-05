import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person_model.dart';
import '../models/schedule_model.dart';

class ScheduleService extends ChangeNotifier {
  static final ScheduleService instance = ScheduleService._internal();
  ScheduleService._internal();

  final Map<String, WeeklySchedule> _personSchedules = {};
  WeeklySchedule _sharedSchedule = WeeklySchedule.createDefault();
  List<Person> persons = [];
  String? activePersonId; // null = View All / Shared
  VoidCallback? onDataChanged;

  static const String _personSchedulePrefix = 'daily_schedule_person_';
  static const String _sharedScheduleKey = 'daily_schedule_shared';
  static const String _legacyScheduleStorageKey = 'daily_schedule_weekly';
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

  /// Returns the individual 7-day schedule for the requested person
  WeeklySchedule getScheduleForPerson(String? personId) {
    if (personId == null || personId.isEmpty) {
      return _sharedSchedule;
    }
    if (!_personSchedules.containsKey(personId)) {
      _personSchedules[personId] = _createInitialScheduleForPerson(personId);
    }
    return _personSchedules[personId]!;
  }

  /// Shortcut to the active person's weekly schedule
  WeeklySchedule get weeklySchedule => getScheduleForPerson(activePersonId);

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

    // 3. Load Shared Schedule
    final sharedJson = prefs.getString(_sharedScheduleKey);
    if (sharedJson != null && sharedJson.isNotEmpty) {
      try {
        _sharedSchedule = WeeklySchedule.fromJson(jsonDecode(sharedJson));
      } catch (_) {
        _sharedSchedule = WeeklySchedule.createDefault();
      }
    } else {
      _sharedSchedule = WeeklySchedule.createDefault();
    }

    // 4. Load or Migrate Individual Schedules for each person
    final legacyScheduleJson = prefs.getString(_legacyScheduleStorageKey);
    WeeklySchedule? legacyWeekly;
    if (legacyScheduleJson != null && legacyScheduleJson.isNotEmpty) {
      try {
        legacyWeekly = WeeklySchedule.fromJson(jsonDecode(legacyScheduleJson));
      } catch (_) {}
    }

    for (final person in persons) {
      final personScheduleJson = prefs.getString('$_personSchedulePrefix${person.id}');
      if (personScheduleJson != null && personScheduleJson.isNotEmpty) {
        try {
          _personSchedules[person.id] = WeeklySchedule.fromJson(jsonDecode(personScheduleJson));
        } catch (_) {
          _personSchedules[person.id] = _createInitialScheduleForPerson(person.id);
          await savePersonSchedule(person.id);
        }
      } else {
        // Migrate from legacy single schedule if items were assigned to this person
        if (legacyWeekly != null) {
          final migratedSchedule = WeeklySchedule.createDefault();
          bool foundItems = false;
          for (int day = 0; day < 7; day++) {
            final dayItems = legacyWeekly
                .getDay(day)
                .items
                .where((item) => item.assignedPersonId == person.id)
                .map((e) => e.copyWith())
                .toList();
            if (dayItems.isNotEmpty) {
              foundItems = true;
              migratedSchedule.days[day] = DaySchedule(dayOfWeek: day, items: dayItems);
            }
          }
          if (foundItems) {
            _personSchedules[person.id] = migratedSchedule;
          } else {
            _personSchedules[person.id] = _createInitialScheduleForPerson(person.id);
          }
        } else {
          _personSchedules[person.id] = _createInitialScheduleForPerson(person.id);
        }
        await savePersonSchedule(person.id);
      }
    }

    notifyListeners();
  }

  /// Persists the individual schedule for a specific person
  Future<void> savePersonSchedule(String? personId, {bool triggerAutoSave = true}) async {
    final prefs = await SharedPreferences.getInstance();
    if (personId == null || personId.isEmpty) {
      await prefs.setString(_sharedScheduleKey, jsonEncode(_sharedSchedule.toJson()));
    } else {
      final schedule = getScheduleForPerson(personId);
      await prefs.setString('$_personSchedulePrefix$personId', jsonEncode(schedule.toJson()));
    }
    notifyListeners();
    if (triggerAutoSave) {
      onDataChanged?.call();
    }
  }

  /// Saves activities for a specific day for a specific person
  Future<void> savePersonDaySchedule(String? personId, int dayOfWeek, List<ScheduleItem> items) async {
    final schedule = getScheduleForPerson(personId);
    schedule.days[dayOfWeek] = DaySchedule(
      dayOfWeek: dayOfWeek,
      items: items.map((e) => e.copyWith(assignedPersonId: personId)).toList(),
    );
    await savePersonSchedule(personId);
  }

  /// Saves the active person's schedule
  Future<void> saveSchedule() async {
    await savePersonSchedule(activePersonId);
  }

  Future<void> savePersons({bool triggerAutoSave = true}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_personsStorageKey, jsonEncode(persons.map((e) => e.toJson()).toList()));
    notifyListeners();
    if (triggerAutoSave) {
      onDataChanged?.call();
    }
  }

  /// Fully replaces in-memory schedule and profiles with imported CSV data
  Future<void> replaceAllData({
    required List<Person> newPersons,
    required Map<String, WeeklySchedule> newPersonSchedules,
    required WeeklySchedule newSharedSchedule,
  }) async {
    persons = newPersons;
    _personSchedules.clear();
    _personSchedules.addAll(newPersonSchedules);
    _sharedSchedule = newSharedSchedule;

    if (activePersonId != null && !persons.any((p) => p.id == activePersonId)) {
      activePersonId = null;
    }

    await savePersons(triggerAutoSave: false);
    for (final p in persons) {
      await savePersonSchedule(p.id, triggerAutoSave: false);
    }
    await savePersonSchedule(null, triggerAutoSave: false);
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
    _personSchedules[person.id] = _createInitialScheduleForPerson(person.id);
    await savePersons();
    await savePersonSchedule(person.id);
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
    _personSchedules.remove(personId);
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_personSchedulePrefix$personId');
    if (activePersonId == personId) {
      activePersonId = null;
    }
    await savePersons();
    notifyListeners();
  }

  /// Filter items by person ID
  List<ScheduleItem> filterItems(
    List<ScheduleItem> items, {
    String? personId,
    bool includeShared = true,
  }) {
    final targetId = personId ?? activePersonId;
    if (targetId == null) {
      return items;
    }
    return items.where((item) => item.assignedPersonId == targetId).toList();
  }

  /// Count completed and total items for a day considering the specified person
  ({int completed, int total}) getDayProgress(int dayIndex, {String? personId}) {
    final targetId = personId ?? activePersonId;
    final schedule = getScheduleForPerson(targetId);
    final dayItems = schedule.getDay(dayIndex).items;
    final completedCount = dayItems.where((i) => i.isCompleted).length;
    return (completed: completedCount, total: dayItems.length);
  }

  /// Clones a day's schedule to another target day for a specific person
  Future<void> copyDay(int fromDay, int toDay, {String? personId}) async {
    final targetId = personId ?? activePersonId;
    final schedule = getScheduleForPerson(targetId);
    final sourceDay = schedule.getDay(fromDay);
    final clonedItems = sourceDay.items.map((e) => e.copyWith(
      id: '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(9999)}',
      isCompleted: false, // Reset completion status
      assignedPersonId: targetId,
    )).toList();

    schedule.days[toDay] = DaySchedule(dayOfWeek: toDay, items: clonedItems);
    await savePersonSchedule(targetId);
  }

  /// Clones active day to all weekdays (Mon-Fri = 1..5) for a specific person
  Future<void> copyDayToAllWeekdays(int fromDay, {String? personId}) async {
    for (int day = 1; day <= 5; day++) {
      if (day != fromDay) {
        await copyDay(fromDay, day, personId: personId);
      }
    }
  }

  /// Clones active day to all 7 days of the week (Sun-Sat = 0..6) for a specific person
  Future<void> copyDayToAllDays(int fromDay, {String? personId}) async {
    for (int day = 0; day <= 6; day++) {
      if (day != fromDay) {
        await copyDay(fromDay, day, personId: personId);
      }
    }
  }

  /// Clears activities for a specific day for a specific person
  Future<void> clearDay(int dayOfWeek, {String? personId}) async {
    final targetId = personId ?? activePersonId;
    final schedule = getScheduleForPerson(targetId);
    schedule.days[dayOfWeek] = DaySchedule(dayOfWeek: dayOfWeek, items: []);
    await savePersonSchedule(targetId);
  }

  /// Resets all 7 days to empty for a specific person
  Future<void> clearAllSchedules({String? personId}) async {
    final targetId = personId ?? activePersonId;
    final schedule = getScheduleForPerson(targetId);
    for (int day = 0; day <= 6; day++) {
      schedule.days[day] = DaySchedule(dayOfWeek: day, items: []);
    }
    await savePersonSchedule(targetId);
  }

  /// Creates distinct individual starter routines for each kid
  WeeklySchedule _createInitialScheduleForPerson(String personId) {
    final schedule = WeeklySchedule.createDefault();

    List<({String title, String time})> itemsTemplate;

    if (personId == 'person_maya') {
      itemsTemplate = [
        (title: 'Wake-up Time', time: '07:00 AM'),
        (title: 'Teeth Time', time: '07:15 AM'),
        (title: 'Meal Time', time: '07:45 AM'),
        (title: 'Arrival Time', time: '08:30 AM'),
        (title: 'Study Time', time: '09:30 AM'),
        (title: 'Lunch Time', time: '12:00 PM'),
        (title: 'Play Time', time: '03:30 PM'),
        (title: 'Story Time', time: '07:30 PM'),
        (title: 'Sleep Time', time: '08:30 PM'),
      ];
    } else if (personId == 'person_alex') {
      itemsTemplate = [
        (title: 'Wake-up Time', time: '07:15 AM'),
        (title: 'Teeth Time', time: '07:30 AM'),
        (title: 'Meal Time', time: '08:00 AM'),
        (title: 'Arrival Time', time: '08:45 AM'),
        (title: 'Circle Time', time: '10:00 AM'),
        (title: 'Lunch Time', time: '12:30 PM'),
        (title: 'Outdoor Time', time: '04:00 PM'),
        (title: 'Bath Time', time: '08:00 PM'),
        (title: 'Sleep Time', time: '09:00 PM'),
      ];
    } else if (personId == 'person_sam') {
      itemsTemplate = [
        (title: 'Wake-up Time', time: '07:30 AM'),
        (title: 'Dressing Time', time: '07:45 AM'),
        (title: 'Meal Time', time: '08:15 AM'),
        (title: 'Sensory Time', time: '09:30 AM'),
        (title: 'Therapy Time', time: '10:30 AM'),
        (title: 'Lunch Time', time: '12:00 PM'),
        (title: 'Quiet Time', time: '01:00 PM'),
        (title: 'Snack Time', time: '03:30 PM'),
        (title: 'Sleep Time', time: '08:00 PM'),
      ];
    } else {
      itemsTemplate = [
        (title: 'Wake-up Time', time: '07:30 AM'),
        (title: 'Teeth Time', time: '07:45 AM'),
        (title: 'Meal Time', time: '08:15 AM'),
        (title: 'Work Time', time: '09:00 AM'),
        (title: 'Lunch Time', time: '12:30 PM'),
        (title: 'Play Time', time: '04:00 PM'),
        (title: 'Sleep Time', time: '08:30 PM'),
      ];
    }

    for (int day = 0; day < 7; day++) {
      schedule.days[day] = DaySchedule(
        dayOfWeek: day,
        items: itemsTemplate.asMap().entries.map((entry) {
          final idx = entry.key;
          final itemData = entry.value;
          return ScheduleItem(
            id: '${personId}_${day}_$idx',
            title: itemData.title,
            time: itemData.time,
            iconCodePoint: SchedulePresets.getIconForLabel(itemData.title).codePoint,
            assignedPersonId: personId,
            isCompleted: false,
          );
        }).toList(),
      );
    }

    return schedule;
  }
}
