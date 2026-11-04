import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:daily_schedule/main.dart';
import 'package:daily_schedule/models/person_model.dart';
import 'package:daily_schedule/models/schedule_model.dart';
import 'package:daily_schedule/screens/schedule_screen.dart';
import 'package:daily_schedule/screens/person_management_screen.dart';
import 'package:daily_schedule/screens/edit_schedule_screen.dart';
import 'package:daily_schedule/services/schedule_service.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await ScheduleService.instance.init();
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

  testWidgets('ScheduleScreen allows marking uncompleted items done',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    // Add an anytime activity so it is in TO DO
    final now = DateTime.now();
    final currentDay = now.weekday == 7 ? 0 : now.weekday;
    final daySchedule = ScheduleService.instance.weeklySchedule.getDay(currentDay);
    daySchedule.items.add(
      ScheduleItem(
        id: 'test_story_time',
        title: 'Story Time',
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

    // Find and tap "Story Time" card in TO DO
    expect(find.text('Story Time'), findsOneWidget);
    await tester.tap(find.text('Story Time'));
    await tester.pumpAndSettle();

    // Dialog should ask "Is it done?"
    expect(find.text('Is it done?'), findsOneWidget);
    expect(find.text('Yes, Done!'), findsOneWidget);

    // Confirm it is done
    await tester.tap(find.text('Yes, Done!'));
    await tester.pumpAndSettle();

    // Verify it is now marked completed
    final updatedItem = daySchedule.items.firstWhere((i) => i.id == 'test_story_time');
    expect(updatedItem.isCompleted, isTrue);
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

  testWidgets('EditScheduleScreen opens and renders day tabs and activities',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      const MaterialApp(
        home: EditScheduleScreen(initialDayOfWeek: 1),
      ),
    );
    await tester.pumpAndSettle();

    // Check day tabs
    expect(find.text('Mon'), findsWidgets);
    expect(find.text('Add Activity'), findsOneWidget);
    expect(find.text('Save Schedule'), findsOneWidget);
  });
}
