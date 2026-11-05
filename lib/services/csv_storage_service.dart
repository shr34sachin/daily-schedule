import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/person_model.dart';
import '../models/schedule_model.dart';
import 'schedule_service.dart';

class CsvStorageService extends ChangeNotifier {
  CsvStorageService._();
  static final CsvStorageService instance = CsvStorageService._();

  static const String _keyOfflineMode = 'setting_offline_csv_mode';
  static const String _keyActiveCsvPath = 'setting_offline_csv_path';
  static const String _keyLastSync = 'setting_offline_csv_last_sync';

  bool _isOfflineCsvModeEnabled = false;
  String? _activeCsvFilePath;
  DateTime? _lastSyncedAt;

  bool get isOfflineCsvModeEnabled => _isOfflineCsvModeEnabled;
  String? get activeCsvFilePath => _activeCsvFilePath;
  DateTime? get lastSyncedAt => _lastSyncedAt;

  static const List<String> dayNames = [
    'Sunday',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _isOfflineCsvModeEnabled = prefs.getBool(_keyOfflineMode) ?? false;
    _activeCsvFilePath = prefs.getString(_keyActiveCsvPath);
    final lastSyncStr = prefs.getString(_keyLastSync);
    if (lastSyncStr != null) {
      _lastSyncedAt = DateTime.tryParse(lastSyncStr);
    }

    // If offline mode is enabled and an active file exists, automatically reload it
    if (!kIsWeb && _isOfflineCsvModeEnabled && _activeCsvFilePath != null) {
      final file = File(_activeCsvFilePath!);
      if (file.existsSync()) {
        try {
          await importFromCsvFile(filePath: _activeCsvFilePath!);
        } catch (e) {
          debugPrint('Error auto-syncing from active CSV on startup: $e');
        }
      }
    }
  }

  /// Toggles Offline CSV Mode
  Future<void> setOfflineCsvMode(bool enabled) async {
    _isOfflineCsvModeEnabled = enabled;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOfflineMode, enabled);

    // If turned on and an active CSV path exists, sync from it
    if (!kIsWeb && enabled && _activeCsvFilePath != null && File(_activeCsvFilePath!).existsSync()) {
      await reloadFromActiveCsv();
    }
  }

  /// Sets the active CSV file path
  Future<void> setActiveCsvFilePath(String? path) async {
    _activeCsvFilePath = path;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (path != null) {
      await prefs.setString(_keyActiveCsvPath, path);
    } else {
      await prefs.remove(_keyActiveCsvPath);
    }
  }

  /// Updates the last sync timestamp
  Future<void> _updateLastSync() async {
    _lastSyncedAt = DateTime.now();
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastSync, _lastSyncedAt!.toIso8601String());
  }

  // =========================================================================
  // EXPORT TO CSV + IMAGES
  // =========================================================================

  /// Exports all current profiles, weekly routines, and images to a CSV file.
  /// If [targetFilePath] is null, opens file picker or uses default documents folder.
  Future<String?> exportToCsvFile({String? targetFilePath}) async {
    final scheduleService = ScheduleService.instance;
    final persons = scheduleService.persons;

    final List<List<dynamic>> rows = [];

    // Header Row
    rows.add([
      'record_type',
      'day',
      'person_id',
      'person_name',
      'person_role',
      'person_color',
      'person_emoji',
      'person_image',
      'activity_id',
      'activity_title',
      'time',
      'notes',
      'is_completed',
      'activity_image',
    ]);

    // 1. Export Persons
    for (final person in persons) {
      String personImageRelative = '';
      if (person.hasCustomImage) {
        final safeName = 'person_${person.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}.png';
        personImageRelative = 'images/$safeName';
      }

      rows.add([
        'PERSON',
        '', // day
        person.id,
        person.name,
        person.role,
        _colorToHex(person.color),
        person.avatarEmoji,
        personImageRelative,
        '', // activity_id
        '', // activity_title
        '', // time
        '', // notes
        '', // is_completed
        '', // activity_image
      ]);
    }

    // 2. Export Activities for each person across 7 days
    for (final person in persons) {
      final schedule = scheduleService.getScheduleForPerson(person.id);
      for (int day = 0; day < 7; day++) {
        final daySchedule = schedule.getDay(day);
        final dayName = dayNames[day];

        for (final item in daySchedule.items) {
          String activityImageRelative = '';
          if (item.customImageBase64.isNotEmpty) {
            final safeName = 'activity_${item.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}.png';
            activityImageRelative = 'images/$safeName';
          }

          rows.add([
            'ACTIVITY',
            dayName,
            person.id,
            person.name,
            '', // role
            '', // color
            '', // emoji
            '', // person_image
            item.id,
            item.title,
            item.time,
            item.notes,
            item.isCompleted ? 'TRUE' : 'FALSE',
            activityImageRelative,
          ]);
        }
      }
    }

    // 3. Export Shared Schedule (Family / Shared Activities)
    final sharedSchedule = scheduleService.getScheduleForPerson(null);
    for (int day = 0; day < 7; day++) {
      final daySchedule = sharedSchedule.getDay(day);
      final dayName = dayNames[day];

      for (final item in daySchedule.items) {
        String activityImageRelative = '';
        if (item.customImageBase64.isNotEmpty) {
          final safeName = 'activity_${item.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}.png';
          activityImageRelative = 'images/$safeName';
        }

        rows.add([
          'ACTIVITY',
          dayName,
          '', // person_id
          'Shared', // person_name
          '', // role
          '', // color
          '', // emoji
          '', // person_image
          item.id,
          item.title,
          item.time,
          item.notes,
          item.isCompleted ? 'TRUE' : 'FALSE',
          activityImageRelative,
        ]);
      }
    }

    // Encode CSV string and bytes
    final csvString = Csv().encode(rows);
    final csvBytes = Uint8List.fromList(utf8.encode(csvString));

    if (kIsWeb) {
      try {
        await FilePicker.saveFile(
          dialogTitle: 'Save Schedule CSV',
          fileName: 'daily_schedule.csv',
          bytes: csvBytes,
          mimeType: 'text/csv',
        );
        await setActiveCsvFilePath('daily_schedule.csv');
        await _updateLastSync();
        return 'daily_schedule.csv';
      } catch (e) {
        debugPrint('Web FilePicker saveFile error: $e');
        return null;
      }
    }

    // Non-Web (Desktop & Mobile)
    String? path = targetFilePath;

    if (path == null) {
      bool userCancelled = false;
      try {
        final uri = await FilePicker.saveFile(
          dialogTitle: 'Select location to save Schedule CSV',
          fileName: 'daily_schedule.csv',
          bytes: csvBytes,
          mimeType: 'text/csv',
        );
        if (uri != null) {
          path = uri.isScheme('file') ? uri.toFilePath() : uri.path;
        } else {
          userCancelled = true;
        }
      } catch (e) {
        debugPrint('FilePicker saveFile error/fallback: $e');
      }

      if (userCancelled) {
        return null;
      }

      if (path == null) {
        try {
          final dir = await getApplicationDocumentsDirectory();
          path = '${dir.path}${Platform.pathSeparator}daily_schedule.csv';
        } catch (_) {
          return null;
        }
      }
    }

    if (!path.toLowerCase().endsWith('.csv')) {
      path = '$path.csv';
    }

    final csvFile = File(path);
    final csvDir = csvFile.parent;
    if (!csvDir.existsSync()) {
      csvDir.createSync(recursive: true);
    }

    // Images directory alongside the CSV file: [csvDir]/images/
    final imagesDir = Directory('${csvDir.path}${Platform.pathSeparator}images');
    if (!imagesDir.existsSync()) {
      imagesDir.createSync(recursive: true);
    }

    // Save Person images to imagesDir
    for (final person in persons) {
      if (person.hasCustomImage) {
        try {
          final imageBytes = base64Decode(person.customImageBase64);
          final safeName = 'person_${person.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}.png';
          final imageFile = File('${imagesDir.path}${Platform.pathSeparator}$safeName');
          imageFile.writeAsBytesSync(imageBytes);
        } catch (e) {
          debugPrint('Error saving person image: $e');
        }
      }
    }

    // Save Activity images to imagesDir
    void writeItemImages(List<ScheduleItem> items) {
      for (final item in items) {
        if (item.customImageBase64.isNotEmpty) {
          try {
            final imageBytes = base64Decode(item.customImageBase64);
            final safeName = 'activity_${item.id.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_')}.png';
            final imageFile = File('${imagesDir.path}${Platform.pathSeparator}$safeName');
            imageFile.writeAsBytesSync(imageBytes);
          } catch (e) {
            debugPrint('Error saving activity image: $e');
          }
        }
      }
    }

    for (final person in persons) {
      final schedule = scheduleService.getScheduleForPerson(person.id);
      for (int day = 0; day < 7; day++) {
        writeItemImages(schedule.getDay(day).items);
      }
    }
    for (int day = 0; day < 7; day++) {
      writeItemImages(sharedSchedule.getDay(day).items);
    }

    csvFile.writeAsStringSync(csvString);

    await setActiveCsvFilePath(path);
    await _updateLastSync();

    return path;
  }

  // =========================================================================
  // IMPORT FROM CSV + IMAGES
  // =========================================================================

  /// Imports profiles, routines, and images from a CSV file.
  /// If [filePath] is null, opens file picker dialog.
  Future<bool> importFromCsvFile({String? filePath}) async {
    String? path = filePath;
    String content = '';
    Directory? csvDir;

    if (kIsWeb) {
      try {
        final result = await FilePicker.pickFile(
          type: FileType.custom,
          allowedExtensions: ['csv'],
          dialogTitle: 'Select Schedule CSV to Import',
        );
        if (result != null) {
          final bytes = await result.readAsBytes();
          if (bytes.isNotEmpty) {
            content = utf8.decode(bytes);
            path = result.name;
          }
        }
      } catch (e) {
        debugPrint('Web FilePicker pickFile error: $e');
      }
    } else {
      if (path == null) {
        try {
          final result = await FilePicker.pickFile(
            type: FileType.custom,
            allowedExtensions: ['csv'],
            dialogTitle: 'Select Schedule CSV to Import',
          );
          if (result != null) {
            path = result.path;
            if (path == null) {
              final bytes = await result.readAsBytes();
              if (bytes.isNotEmpty) {
                content = utf8.decode(bytes);
                path = result.name;
              }
            }
          }
        } catch (e) {
          debugPrint('FilePicker pickFile error: $e');
        }
      }

      if (path == null) return false;

      if (content.isEmpty) {
        final file = File(path);
        if (!file.existsSync()) return false;
        content = file.readAsStringSync();
        csvDir = file.parent;
      }
    }

    if (content.trim().isEmpty) return false;

    // Parse CSV
    final List<List<dynamic>> rows = Csv(
      dynamicTyping: false,
    ).decode(content);

    if (rows.length < 2) return false; // Needs at least header + 1 row

    final headers = rows.first.map((e) => e.toString().trim().toLowerCase()).toList();

    int colIndex(String name) => headers.indexOf(name);

    final idxType = colIndex('record_type');
    final idxDay = colIndex('day');
    final idxPersonId = colIndex('person_id');
    final idxPersonName = colIndex('person_name');
    final idxPersonRole = colIndex('person_role');
    final idxPersonColor = colIndex('person_color');
    final idxPersonEmoji = colIndex('person_emoji');
    final idxPersonImage = colIndex('person_image');
    final idxActivityId = colIndex('activity_id');
    final idxActivityTitle = colIndex('activity_title');
    final idxTime = colIndex('time');
    final idxNotes = colIndex('notes');
    final idxIsCompleted = colIndex('is_completed');
    final idxActivityImage = colIndex('activity_image');

    String getCol(List<dynamic> row, int index) {
      if (index < 0 || index >= row.length) return '';
      return row[index]?.toString().trim() ?? '';
    }

    final List<Person> newPersons = [];
    final Map<String, WeeklySchedule> newSchedules = {};
    WeeklySchedule newSharedSchedule = WeeklySchedule.createDefault();

    // Pass 1: Parse Persons
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final type = getCol(row, idxType).toUpperCase();
      final personName = getCol(row, idxPersonName);
      final activityTitle = getCol(row, idxActivityTitle);

      // If record_type is PERSON or no activity title is present but name exists
      if (type == 'PERSON' || (type.isEmpty && activityTitle.isEmpty && personName.isNotEmpty)) {
        String personId = getCol(row, idxPersonId);
        if (personId.isEmpty) {
          personId = 'person_${personName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
        }

        final role = getCol(row, idxPersonRole).isNotEmpty ? getCol(row, idxPersonRole) : 'Kid';
        final colorHex = getCol(row, idxPersonColor);
        final colorVal = _hexToColorInt(colorHex);
        final emoji = getCol(row, idxPersonEmoji).isNotEmpty ? getCol(row, idxPersonEmoji) : '🧒';

        // Load custom image if present at CSV directory
        String imageBase64 = '';
        final imagePathRel = getCol(row, idxPersonImage);
        if (!kIsWeb && csvDir != null && imagePathRel.isNotEmpty) {
          final imgFile = File('${csvDir.path}${Platform.pathSeparator}$imagePathRel');
          if (imgFile.existsSync()) {
            try {
              imageBase64 = base64Encode(imgFile.readAsBytesSync());
            } catch (e) {
              debugPrint('Error reading person image file: $e');
            }
          }
        }

        final person = Person(
          id: personId,
          name: personName,
          role: role,
          colorValue: colorVal,
          avatarEmoji: emoji,
          customImageBase64: imageBase64,
        );

        if (!newPersons.any((p) => p.id == person.id)) {
          newPersons.add(person);
          newSchedules[person.id] = WeeklySchedule.createDefault();
        }
      }
    }

    // Ensure at least default persons if CSV had none defined
    if (newPersons.isEmpty) {
      newPersons.addAll(ScheduleService.instance.persons);
      for (var p in newPersons) {
        newSchedules[p.id] = WeeklySchedule.createDefault();
      }
    }

    // Pass 2: Parse Activities
    for (int i = 1; i < rows.length; i++) {
      final row = rows[i];
      if (row.isEmpty) continue;

      final type = getCol(row, idxType).toUpperCase();
      final activityTitle = getCol(row, idxActivityTitle);
      if (activityTitle.isEmpty && type != 'ACTIVITY') continue;
      if (activityTitle.isEmpty) continue;

      final dayStr = getCol(row, idxDay);
      final dayOfWeek = _parseDayOfWeek(dayStr);

      String personId = getCol(row, idxPersonId);
      final personName = getCol(row, idxPersonName);

      // Match person by ID or by Name
      if (personId.isEmpty && personName.isNotEmpty) {
        final match = newPersons.cast<Person?>().firstWhere(
              (p) => p?.name.toLowerCase() == personName.toLowerCase(),
              orElse: () => null,
            );
        if (match != null) {
          personId = match.id;
        } else if (personName.toLowerCase() != 'shared') {
          // Create new person on-the-fly if user added a new person in CSV activity row!
          personId = 'person_${personName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';
          final newP = Person(
            id: personId,
            name: personName,
            role: 'Kid',
            colorValue: 0xFF1976D2,
            avatarEmoji: '⭐',
          );
          newPersons.add(newP);
          newSchedules[personId] = WeeklySchedule.createDefault();
        }
      }

      String activityId = getCol(row, idxActivityId);
      if (activityId.isEmpty) {
        activityId = 'act_${DateTime.now().millisecondsSinceEpoch}_$i';
      }

      final time = getCol(row, idxTime);
      final notes = getCol(row, idxNotes);
      final isCompStr = getCol(row, idxIsCompleted).toUpperCase();
      final isCompleted = isCompStr == 'TRUE' || isCompStr == '1' || isCompStr == 'YES';

      // Load custom activity image if present
      String activityImageBase64 = '';
      final actImgRel = getCol(row, idxActivityImage);
      if (!kIsWeb && csvDir != null && actImgRel.isNotEmpty) {
        final imgFile = File('${csvDir.path}${Platform.pathSeparator}$actImgRel');
        if (imgFile.existsSync()) {
          try {
            activityImageBase64 = base64Encode(imgFile.readAsBytesSync());
          } catch (e) {
            debugPrint('Error reading activity image file: $e');
          }
        }
      }

      final item = ScheduleItem(
        id: activityId,
        title: activityTitle,
        time: time,
        iconCodePoint: SchedulePresets.getIconForLabel(activityTitle).codePoint,
        notes: notes,
        isCompleted: isCompleted,
        assignedPersonId: personId.isEmpty ? null : personId,
        customImageBase64: activityImageBase64,
      );

      if (personId.isEmpty || personName.toLowerCase() == 'shared') {
        newSharedSchedule.getDay(dayOfWeek).items.add(item);
      } else {
        if (!newSchedules.containsKey(personId)) {
          newSchedules[personId] = WeeklySchedule.createDefault();
        }
        newSchedules[personId]!.getDay(dayOfWeek).items.add(item);
      }
    }

    // Apply into ScheduleService
    await ScheduleService.instance.replaceAllData(
      newPersons: newPersons,
      newPersonSchedules: newSchedules,
      newSharedSchedule: newSharedSchedule,
    );

    await setActiveCsvFilePath(path);
    await _updateLastSync();

    return true;
  }

  /// Re-syncs from the active CSV file (reflects external edits in Excel/Notepad)
  Future<bool> reloadFromActiveCsv() async {
    if (kIsWeb || _activeCsvFilePath == null) return false;
    final file = File(_activeCsvFilePath!);
    if (!file.existsSync()) return false;
    return await importFromCsvFile(filePath: _activeCsvFilePath!);
  }

  /// Automatically called after schedule modifications if Offline CSV Mode is active
  Future<void> autoSaveIfOfflineMode() async {
    if (kIsWeb || !_isOfflineCsvModeEnabled || _activeCsvFilePath == null) return;
    try {
      await exportToCsvFile(targetFilePath: _activeCsvFilePath);
    } catch (e) {
      debugPrint('Error auto-saving to CSV in offline mode: $e');
    }
  }

  // =========================================================================
  // HELPER METHODS
  // =========================================================================

  int _parseDayOfWeek(String str) {
    final s = str.trim().toLowerCase();
    if (s.isEmpty) return 0;
    if (s.startsWith('sun') || s == '0') return 0;
    if (s.startsWith('mon') || s == '1') return 1;
    if (s.startsWith('tue') || s == '2') return 2;
    if (s.startsWith('wed') || s == '3') return 3;
    if (s.startsWith('thu') || s == '4') return 4;
    if (s.startsWith('fri') || s == '5') return 5;
    if (s.startsWith('sat') || s == '6') return 6;
    return 0;
  }

  String _colorToHex(Color color) {
    final argb = color.toARGB32();
    return '#${argb.toRadixString(16).padLeft(8, '0').toUpperCase()}';
  }

  int _hexToColorInt(String hex) {
    if (hex.isEmpty) return 0xFF1976D2;
    var clean = hex.replaceAll('#', '').replaceAll('0x', '');
    if (clean.length == 6) {
      clean = 'FF$clean';
    }
    return int.tryParse(clean, radix: 16) ?? 0xFF1976D2;
  }
}
