import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_schedule/main.dart';
import 'package:daily_schedule/models/person_model.dart';
import 'package:daily_schedule/models/schedule_model.dart';
import 'package:daily_schedule/screens/schedule_screen.dart';
import 'package:daily_schedule/screens/person_management_screen.dart';
import 'package:daily_schedule/screens/edit_schedule_screen.dart';
import 'package:daily_schedule/screens/settings_screen.dart';
import 'package:daily_schedule/services/schedule_service.dart';
import 'package:daily_schedule/services/settings_service.dart';
import 'package:daily_schedule/services/csv_storage_service.dart';

void main() {
  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (MethodCall call) async {
        if (call.method == 'getVoices') {
          return [
            {'name': 'English Voice 1', 'locale': 'en-US'},
            {'name': 'English Voice 2', 'locale': 'en-GB'},
          ];
        }
        return 1;
      },
    );
    SharedPreferences.setMockInitialValues({});
    await ScheduleService.instance.init();
    await SettingsService.instance.init();
    await CsvStorageService.instance.init();
    await CsvStorageService.instance.setOfflineCsvMode(false);
    await CsvStorageService.instance.setActiveCsvFilePath(null);
    ScheduleService.instance.onDataChanged = () {
      CsvStorageService.instance.autoSaveIfOfflineMode();
    };
  });

  testWidgets('DailyScheduleApp boots to front page showing kid profiles and navigates to kid schedule',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DailyScheduleApp());
    await tester.pumpAndSettle();

    // Verify Title on front page
    expect(find.text('Daily Schedule'), findsOneWidget);

    // Verify Instruction & Profiles
    expect(find.text('Tap your picture to check your schedule:'), findsOneWidget);
    expect(find.text('Maya'), findsWidgets);
    expect(find.text('Alex'), findsWidgets);
    expect(find.text('Sam'), findsWidgets);
    expect(find.text('Family & Shared Schedule'), findsOneWidget);

    // Tap on Maya's profile card to open her schedule
    await tester.tap(find.text('Maya').first);
    await tester.pumpAndSettle();

    // Active person should now be Maya
    expect(ScheduleService.instance.activePersonId, 'person_maya');

    // Should now be on ScheduleScreen with Maya's Routine
    expect(find.text("Maya's Routine"), findsOneWidget);
    expect(find.text('TO DO'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);
    expect(find.text('Switch Kid'), findsOneWidget);

    // In each character's schedule, ensure there is NO list of the other people
    expect(find.text('All / Shared'), findsNothing);
    expect(find.text('+ Manage'), findsNothing);

    // Tap "Switch Kid" to return to the front page
    await tester.tap(find.text('Switch Kid'));
    await tester.pumpAndSettle();

    // Back on UserSelectionScreen
    expect(find.text('Tap your picture to check your schedule:'), findsOneWidget);
  });

  testWidgets('Renders front page without overflow on small screen (320x568)',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(const DailyScheduleApp());
    await tester.pumpAndSettle();

    expect(find.text('Daily Schedule'), findsOneWidget);
    expect(find.text('Maya'), findsWidgets);
    expect(find.text('Alex'), findsWidgets);
  });

  testWidgets('Each user has individual schedule: editing Maya does not change Alex',
      (WidgetTester tester) async {
    // 1. Verify Maya and Alex start with their own schedules
    final mayaSchedule = ScheduleService.instance.getScheduleForPerson('person_maya');
    final alexSchedule = ScheduleService.instance.getScheduleForPerson('person_alex');

    expect(mayaSchedule.getDay(1).items.any((i) => i.title == 'Study Time'), isTrue);
    expect(alexSchedule.getDay(1).items.any((i) => i.title == 'Outdoor Time'), isTrue);

    // 2. Add an exclusive activity to Maya's Monday schedule
    await ScheduleService.instance.savePersonDaySchedule(
      'person_maya',
      1,
      [
        ScheduleItem(
          id: 'maya_piano_solo',
          title: 'Music Time',
          time: '04:30 PM',
          iconCodePoint: 58544,
          assignedPersonId: 'person_maya',
          isCompleted: false,
        ),
      ],
    );

    // 3. Maya should have Music Time on Monday, Alex must NOT have it
    final updatedMayaItems = ScheduleService.instance.getScheduleForPerson('person_maya').getDay(1).items;
    final updatedAlexItems = ScheduleService.instance.getScheduleForPerson('person_alex').getDay(1).items;

    expect(updatedMayaItems.any((i) => i.id == 'maya_piano_solo'), isTrue);
    expect(updatedAlexItems.any((i) => i.id == 'maya_piano_solo'), isFalse);
  });

  testWidgets('ScheduleScreen allows marking uncompleted items done for specific person',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Add an anytime activity for Maya so it is in TO DO
    final now = DateTime.now();
    final currentDay = now.weekday == 7 ? 0 : now.weekday;
    final mayaDaySchedule = ScheduleService.instance.getScheduleForPerson('person_maya').getDay(currentDay);
    mayaDaySchedule.items.add(
      ScheduleItem(
        id: 'test_drawing_time',
        title: 'Drawing Time',
        time: '', // Anytime, won't auto-complete
        iconCodePoint: 58544,
        assignedPersonId: 'person_maya',
        isCompleted: false,
      ),
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleScreen(initialPersonId: 'person_maya'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Maya's Routine"), findsOneWidget);
    expect(find.text('TO DO'), findsOneWidget);
    expect(find.text('DONE'), findsOneWidget);

    // Find and tap "Drawing Time" card in TO DO
    expect(find.text('Drawing Time'), findsOneWidget);
    await tester.tap(find.text('Drawing Time'));
    await tester.pumpAndSettle();

    // Dialog should ask "Is it done?"
    expect(find.text('Is it done?'), findsOneWidget);
    expect(find.text('Yes, Done!'), findsOneWidget);

    // Confirm it is done
    await tester.tap(find.text('Yes, Done!'));
    await tester.pumpAndSettle();

    // Verify it is now marked completed for Maya
    final updatedItem = mayaDaySchedule.items.firstWhere((i) => i.id == 'test_drawing_time');
    expect(updatedItem.isCompleted, isTrue);

    // Alex's schedule should NOT have this item
    final alexDaySchedule = ScheduleService.instance.getScheduleForPerson('person_alex').getDay(currentDay);
    expect(alexDaySchedule.items.any((i) => i.id == 'test_drawing_time'), isFalse);
  });

  testWidgets('PersonManagementScreen allows adding and listing persons',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: PersonManagementScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Check title and starter profiles
    expect(find.text('Manage Persons'), findsOneWidget);
    expect(find.text('Maya'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);

    // Add a new person
    await ScheduleService.instance.addPerson(
      const Person(
        id: 'person_test_charlie',
        name: 'Charlie',
        colorValue: 0xFFE65100,
        role: 'Student',
        avatarEmoji: '⭐',
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Charlie'), findsOneWidget);
  });

  testWidgets('EditScheduleScreen opens and renders day tabs and activities for specified kid',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: EditScheduleScreen(initialDayOfWeek: 1, personId: 'person_alex'),
      ),
    );
    await tester.pumpAndSettle();

    // Check day tabs and person-aware header
    expect(find.text('Mon'), findsWidgets);
    expect(find.text("Edit Alex's Monday"), findsOneWidget);
    expect(find.text('Add Activity'), findsOneWidget);
    expect(find.text('Save Schedule'), findsOneWidget);
  });

  testWidgets('Renders custom uploaded photos for both person avatar and schedule activity',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    const sampleBase64 =
        'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=';

    // 1. Add person with custom photo
    final customPerson = const Person(
      id: 'person_photo_test',
      name: 'Oliver',
      colorValue: 0xFF00796B,
      role: 'Super Kid',
      avatarEmoji: '🦸',
      customImageBase64: sampleBase64,
    );
    await ScheduleService.instance.addPerson(customPerson);

    // 2. Add an activity with custom photo for Oliver
    final now = DateTime.now();
    final currentDay = now.weekday == 7 ? 0 : now.weekday;
    await ScheduleService.instance.savePersonDaySchedule(
      'person_photo_test',
      currentDay,
      [
        ScheduleItem(
          id: 'oliver_origami',
          title: 'Origami Craft',
          time: '',
          iconCodePoint: 58544,
          assignedPersonId: 'person_photo_test',
          isCompleted: false,
          customImageBase64: sampleBase64,
        ),
      ],
    );

    // 3. Pump ScheduleScreen for Oliver
    await tester.pumpWidget(
      const MaterialApp(
        home: ScheduleScreen(initialPersonId: 'person_photo_test'),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Oliver's Routine title
    expect(find.text("Oliver's Routine"), findsOneWidget);

    // Verify activity title
    expect(find.text('Origami Craft'), findsOneWidget);

    // Verify Image.memory widgets are present (both Oliver's avatar and Origami's picture)
    expect(find.byType(Image), findsWidgets);

    // Verify NO other person chips are present
    expect(find.text('All / Shared'), findsNothing);
  });

  testWidgets('SettingsService manages theme mode and speech speed settings with persistence',
      (WidgetTester tester) async {
    // 1. Initial defaults
    expect(SettingsService.instance.speechRate, 0.65);
    expect(SettingsService.instance.pitch, 1.05);

    // 2. Adjust speech rate (faster)
    await SettingsService.instance.setSpeechRate(0.85);
    expect(SettingsService.instance.speechRate, 0.85);

    // 3. Adjust pitch
    await SettingsService.instance.setPitch(1.20);
    expect(SettingsService.instance.pitch, 1.20);

    // 4. Change theme to Dark
    await SettingsService.instance.setThemeMode(ThemeMode.dark);
    expect(SettingsService.instance.themeMode, ThemeMode.dark);

    // 5. Change theme to Light
    await SettingsService.instance.setThemeMode(ThemeMode.light);
    expect(SettingsService.instance.themeMode, ThemeMode.light);

    // 6. Reset audio defaults
    await SettingsService.instance.resetAudioDefaults();
    expect(SettingsService.instance.speechRate, 0.65);
    expect(SettingsService.instance.pitch, 1.05);
  });

  testWidgets('SettingsScreen renders theme options and audio controls and updates settings',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify sections
    expect(find.text('Settings & Preferences'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Light Mode'), findsOneWidget);
    expect(find.text('Dark Mode'), findsOneWidget);
    expect(find.text('System Default'), findsOneWidget);
    expect(find.text('Audio & Speech (TTS)'), findsOneWidget);
    expect(find.text('Speech Speed'), findsOneWidget);
    expect(find.text('Device Voice'), findsOneWidget);
    expect(find.text('Test Audio 🔊'), findsOneWidget);

    // Select Dark Mode tile
    await tester.tap(find.text('Dark Mode'));
    await tester.pumpAndSettle();
    expect(SettingsService.instance.themeMode, ThemeMode.dark);

    // Test Audio button
    await tester.tap(find.text('Test Audio 🔊'));
    await tester.pump();
  });

  testWidgets('UserSelectionScreen AppBar allows quick theme toggle and opening SettingsScreen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 1400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await SettingsService.instance.setThemeMode(ThemeMode.light);

    await tester.pumpWidget(const DailyScheduleApp());
    await tester.pumpAndSettle();

    // Check quick theme toggle tooltip
    final themeToggleFinder = find.byTooltip('Switch to Dark Mode');
    expect(themeToggleFinder, findsOneWidget);

    // Tap quick theme toggle
    await tester.tap(themeToggleFinder);
    await tester.pumpAndSettle();

    // Theme should now be Dark
    expect(SettingsService.instance.themeMode, ThemeMode.dark);
    expect(find.byTooltip('Switch to Light Mode'), findsOneWidget);

    // Tap Settings button
    final settingsButtonFinder = find.byTooltip('Audio & Theme Settings');
    expect(settingsButtonFinder, findsOneWidget);
    await tester.tap(settingsButtonFinder);
    await tester.pumpAndSettle();

    // Now on SettingsScreen
    expect(find.text('Settings & Preferences'), findsOneWidget);
    expect(find.text('Speech Speed'), findsOneWidget);
  });

  test('CsvStorageService exports and imports data with images and reflects edits', () async {
    final tempDir = Directory.systemTemp.createTempSync('csv_test_');
    addTearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    final csvFilePath = '${tempDir.path}${Platform.pathSeparator}test_schedule.csv';

    // Add a custom image to Maya
    final dummyImageBytes = base64Decode(
      'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8z8BQDwAEhQGAhKmMIQAAAABJRU5ErkJggg==',
    );
    final dummyBase64 = base64Encode(dummyImageBytes);

    await ScheduleService.instance.updatePerson(
      Person(
        id: 'person_maya',
        name: 'Maya SuperStar',
        role: 'Big Sister',
        colorValue: Colors.purple.toARGB32(),
        avatarEmoji: '🌟',
        customImageBase64: dummyBase64,
      ),
    );

    // Export to CSV
    final exportedPath = await CsvStorageService.instance.exportToCsvFile(
      targetFilePath: csvFilePath,
    );
    expect(exportedPath, isNotNull);
    final csvFile = File(csvFilePath);
    expect(csvFile.existsSync(), isTrue);

    // Verify images folder and person image file exist
    final imagesDir = Directory('${tempDir.path}${Platform.pathSeparator}images');
    expect(imagesDir.existsSync(), isTrue);
    final expectedPersonImg = File('${imagesDir.path}${Platform.pathSeparator}person_person_maya.png');
    expect(expectedPersonImg.existsSync(), isTrue);
    expect(expectedPersonImg.readAsBytesSync(), dummyImageBytes);

    // Verify CSV file content contains Maya SuperStar and PERSON record
    String content = csvFile.readAsStringSync();
    expect(content.contains('Maya SuperStar'), isTrue);
    expect(content.contains('images/person_person_maya.png'), isTrue);

    // EDIT the CSV directly as a user would in Excel or Notepad:
    // Change Maya's name to "Maya The Explorer" and edit an activity title
    content = content.replaceAll('Maya SuperStar', 'Maya The Explorer');
    content = content.replaceAll('Wake-up Time', 'Jump Out of Bed');
    csvFile.writeAsStringSync(content);

    // Re-import from CSV
    final success = await CsvStorageService.instance.importFromCsvFile(
      filePath: csvFilePath,
    );
    expect(success, isTrue);

    // Verify the changes are reflected in ScheduleService
    final updatedMaya = ScheduleService.instance.persons.firstWhere((p) => p.id == 'person_maya');
    expect(updatedMaya.name, 'Maya The Explorer');
    expect(updatedMaya.customImageBase64, dummyBase64); // Image reloaded from images directory!

    final mayaSundayItems = ScheduleService.instance.getScheduleForPerson('person_maya').getDay(0).items;
    final hasRenamedActivity = mayaSundayItems.any((item) => item.title == 'Jump Out of Bed');
    expect(hasRenamedActivity, isTrue);
  });

  test('CsvStorageService auto-saves edits when offline CSV mode is enabled', () async {
    final tempDir = Directory.systemTemp.createTempSync('csv_autosave_');
    addTearDown(() {
      if (tempDir.existsSync()) {
        try {
          tempDir.deleteSync(recursive: true);
        } catch (_) {}
      }
    });

    final csvFilePath = '${tempDir.path}${Platform.pathSeparator}auto_schedule.csv';
    await CsvStorageService.instance.exportToCsvFile(targetFilePath: csvFilePath);
    await CsvStorageService.instance.setOfflineCsvMode(true);
    await CsvStorageService.instance.setActiveCsvFilePath(csvFilePath);

    ScheduleService.instance.onDataChanged = () {
      CsvStorageService.instance.autoSaveIfOfflineMode();
    };

    // Add a new activity to Maya
    final newActivity = ScheduleItem(
      id: 'act_unique_12345',
      title: 'Practice Piano',
      time: '04:00 PM',
      iconCodePoint: Icons.music_note.codePoint,
      notes: 'Song 3',
      isCompleted: false,
      assignedPersonId: 'person_maya',
    );
    final currentSchedule = ScheduleService.instance.getScheduleForPerson('person_maya');
    final mondayItems = List<ScheduleItem>.from(currentSchedule.getDay(1).items)..add(newActivity);
    await ScheduleService.instance.savePersonDaySchedule('person_maya', 1, mondayItems);

    // Verify auto-save immediately synced into the CSV file
    final csvFile = File(csvFilePath);
    expect(csvFile.readAsStringSync().contains('Practice Piano'), isTrue);
  });

  testWidgets('SettingsScreen displays Offline CSV Mode toggle, file status and options',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: SettingsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Offline CSV Mode section header and items
    expect(find.text('Offline CSV Mode & Sync'), findsOneWidget);
    expect(find.text('Offline CSV Mode'), findsOneWidget);
    expect(find.text('Save and sync all data to a CSV file on your device'), findsOneWidget);

    // Offline mode is initially disabled
    expect(CsvStorageService.instance.isOfflineCsvModeEnabled, isFalse);

    // Tap switch to enable
    final switchFinder = find.byType(Switch).first;
    await tester.tap(switchFinder);
    await tester.pumpAndSettle();

    expect(CsvStorageService.instance.isOfflineCsvModeEnabled, isTrue);

    // Since it is enabled, action buttons appear
    expect(find.text('Save / Export to CSV'), findsOneWidget);
    expect(find.text('Choose / Upload CSV'), findsOneWidget);

    // Tap View CSV Format & Column Details button
    final viewFormatBtn = find.text('View CSV Format & Column Details');
    expect(viewFormatBtn, findsOneWidget);
    await tester.tap(viewFormatBtn);
    await tester.pumpAndSettle();

    // Verify dialog opens with format details
    expect(find.text('CSV Format & Columns'), findsOneWidget);
    expect(find.text('CSV Header Columns:'), findsOneWidget);
    expect(find.text('1. Profile Row (PERSON):'), findsOneWidget);
    expect(find.text('2. Activity Row (ACTIVITY):'), findsOneWidget);

    // Close dialog
    await tester.tap(find.text('Close'));
    await tester.pumpAndSettle();
    expect(find.text('CSV Format & Columns'), findsNothing);
  });
}
