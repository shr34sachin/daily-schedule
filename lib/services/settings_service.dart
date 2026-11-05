import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends ChangeNotifier {
  SettingsService._();
  static final SettingsService instance = SettingsService._();

  final FlutterTts _flutterTts = FlutterTts();

  // Theme settings
  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  // TTS settings
  double _speechRate = 0.65; // Default faster and more natural than 0.45
  double _pitch = 1.05;      // Slightly cheerful pitch for kids
  double _volume = 1.0;
  String? _selectedVoiceName;
  String? _selectedVoiceLocale;
  List<Map<String, String>> _availableVoices = [];
  bool _isSpeaking = false;

  double get speechRate => _speechRate;
  double get pitch => _pitch;
  double get volume => _volume;
  String? get selectedVoiceName => _selectedVoiceName;
  String? get selectedVoiceLocale => _selectedVoiceLocale;
  List<Map<String, String>> get availableVoices => List.unmodifiable(_availableVoices);
  bool get isSpeaking => _isSpeaking;

  static const String _keyThemeMode = 'app_theme_mode';
  static const String _keySpeechRate = 'tts_speech_rate';
  static const String _keyPitch = 'tts_pitch';
  static const String _keyVolume = 'tts_volume';
  static const String _keyVoiceName = 'tts_voice_name';
  static const String _keyVoiceLocale = 'tts_voice_locale';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();

    // Load Theme
    final themeStr = prefs.getString(_keyThemeMode);
    if (themeStr == 'light') {
      _themeMode = ThemeMode.light;
    } else if (themeStr == 'dark') {
      _themeMode = ThemeMode.dark;
    } else {
      _themeMode = ThemeMode.system;
    }

    // Load TTS Settings
    _speechRate = prefs.getDouble(_keySpeechRate) ?? 0.65;
    _pitch = prefs.getDouble(_keyPitch) ?? 1.05;
    _volume = prefs.getDouble(_keyVolume) ?? 1.0;
    _selectedVoiceName = prefs.getString(_keyVoiceName);
    _selectedVoiceLocale = prefs.getString(_keyVoiceLocale);

    await _initTtsEngine();
    notifyListeners();
  }

  Future<void> _initTtsEngine() async {
    try {
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);

      // Handler for speech completion
      _flutterTts.setCompletionHandler(() {
        _isSpeaking = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        _isSpeaking = false;
        notifyListeners();
      });

      // Load available platform voices
      await loadAvailableVoices();

      // Apply selected voice if any
      if (_selectedVoiceName != null) {
        await _flutterTts.setVoice({
          'name': _selectedVoiceName!,
          'locale': _selectedVoiceLocale ?? 'en-US',
        });
      } else {
        await _flutterTts.setLanguage('en-US');
      }
    } catch (e) {
      debugPrint('TTS engine init info/warning: $e');
    }
  }

  /// Reloads system voices from the platform (laptop or mobile)
  Future<void> loadAvailableVoices() async {
    try {
      final dynamic rawVoices = await _flutterTts.getVoices;
      if (rawVoices is List) {
        final List<Map<String, String>> parsed = [];
        for (var item in rawVoices) {
          if (item is Map) {
            final name = item['name']?.toString() ?? '';
            final locale = item['locale']?.toString() ?? '';
            if (name.isNotEmpty) {
              parsed.add({'name': name, 'locale': locale});
            }
          }
        }
        // Sort alphabetically by voice name
        parsed.sort((a, b) => a['name']!.compareTo(b['name']!));
        _availableVoices = parsed;
      }
    } catch (e) {
      debugPrint('Unable to query platform voices: $e');
    }
  }

  /// Changes and persists the app ThemeMode
  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    String val = 'system';
    if (mode == ThemeMode.light) val = 'light';
    if (mode == ThemeMode.dark) val = 'dark';
    await prefs.setString(_keyThemeMode, val);
  }

  /// Toggles between Light and Dark mode
  Future<void> toggleTheme(BuildContext context) async {
    final isCurrentDark = _themeMode == ThemeMode.dark ||
        (_themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);
    await setThemeMode(isCurrentDark ? ThemeMode.light : ThemeMode.dark);
  }

  /// Sets speech rate (0.2 slow to 1.2 fast)
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate.clamp(0.2, 1.2);
    try {
      await _flutterTts.setSpeechRate(_speechRate);
    } catch (_) {}
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keySpeechRate, _speechRate);
  }

  /// Sets voice pitch (0.5 deeper to 1.5 higher)
  Future<void> setPitch(double pitch) async {
    _pitch = pitch.clamp(0.5, 1.5);
    try {
      await _flutterTts.setPitch(_pitch);
    } catch (_) {}
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyPitch, _pitch);
  }

  /// Sets volume (0.0 mute to 1.0 max)
  Future<void> setVolume(double volume) async {
    _volume = volume.clamp(0.0, 1.0);
    try {
      await _flutterTts.setVolume(_volume);
    } catch (_) {}
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyVolume, _volume);
  }

  /// Selects a specific voice from the platform
  Future<void> setVoice(String? name, String? locale) async {
    _selectedVoiceName = name;
    _selectedVoiceLocale = locale;

    try {
      if (name != null) {
        await _flutterTts.setVoice({'name': name, 'locale': locale ?? 'en-US'});
      } else {
        await _flutterTts.setLanguage('en-US');
      }
    } catch (_) {}

    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    if (name != null) {
      await prefs.setString(_keyVoiceName, name);
      if (locale != null) await prefs.setString(_keyVoiceLocale, locale);
    } else {
      await prefs.remove(_keyVoiceName);
      await prefs.remove(_keyVoiceLocale);
    }
  }

  /// Resets TTS settings to default fast & natural kid settings
  Future<void> resetAudioDefaults() async {
    await setSpeechRate(0.65);
    await setPitch(1.05);
    await setVolume(1.0);
    await setVoice(null, null);
  }

  /// Speaks text using the configured audio settings
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    try {
      _isSpeaking = true;
      notifyListeners();
      await _flutterTts.stop();
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);
      await _flutterTts.setVolume(_volume);
      if (_selectedVoiceName != null) {
        await _flutterTts.setVoice({
          'name': _selectedVoiceName!,
          'locale': _selectedVoiceLocale ?? 'en-US',
        });
      }
      await _flutterTts.speak(text);
    } catch (e) {
      _isSpeaking = false;
      notifyListeners();
      debugPrint('TTS speak error: $e');
    }
  }

  /// Stops current speech
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }
}

