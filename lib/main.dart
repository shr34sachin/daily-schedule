import 'package:flutter/material.dart';
import 'screens/user_selection_screen.dart';
import 'services/csv_storage_service.dart';
import 'services/schedule_service.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ScheduleService.instance.init();
  await SettingsService.instance.init();
  await CsvStorageService.instance.init();

  // Connect auto-save listener for offline CSV mode
  ScheduleService.instance.onDataChanged = () {
    CsvStorageService.instance.autoSaveIfOfflineMode();
  };

  runApp(const DailyScheduleApp());
}

class DailyScheduleApp extends StatelessWidget {
  const DailyScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: SettingsService.instance,
      builder: (context, _) {
        return MaterialApp(
          title: 'Daily Schedule',
          debugShowCheckedModeBanner: false,
          themeMode: SettingsService.instance.themeMode,
          theme: _buildLightTheme(),
          darkTheme: _buildDarkTheme(),
          home: const UserSelectionScreen(),
        );
      },
    );
  }

  ThemeData _buildLightTheme() {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF1E88E5),
      brightness: Brightness.light,
      primary: const Color(0xFF1976D2),
      secondary: const Color(0xFF43A047),
      surface: const Color(0xFFFFFFFF),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: const Color(0xFFF6F8FC),
      cardColor: Colors.white,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: Color(0xFF263238)),
        titleTextStyle: TextStyle(
          color: Color(0xFF1A237E),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: Colors.grey.shade200),
        ),
      ),
      dividerColor: Colors.grey.shade200,
    );
  }

  ThemeData _buildDarkTheme() {
    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF42A5F5),
      brightness: Brightness.dark,
      primary: const Color(0xFF42A5F5),
      secondary: const Color(0xFF66BB6A),
      surface: const Color(0xFF1E2228),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: const Color(0xFF121418),
      cardColor: const Color(0xFF1E2228),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E2228),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2C323D)),
        ),
      ),
      dividerColor: const Color(0xFF2C323D),
    );
  }
}
