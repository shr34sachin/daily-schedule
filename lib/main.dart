import 'package:flutter/material.dart';
import 'package:daily_schedule/screens/user_selection_screen.dart';
import 'package:daily_schedule/services/schedule_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScheduleService.instance.init();
  runApp(const DailyScheduleApp());
}

class DailyScheduleApp extends StatelessWidget {
  const DailyScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daily Schedule',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E88E5), // Blue accent theme
          primary: const Color(0xFF1976D2),
          secondary: const Color(0xFF43A047),
          surface: const Color(0xFFF6F8FC),
        ),
        scaffoldBackgroundColor: const Color(0xFFF6F8FC),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          scrolledUnderElevation: 1,
          centerTitle: false,
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: Colors.grey.shade200),
          ),
        ),
      ),
      home: const UserSelectionScreen(),
    );
  }
}
