import 'package:flutter/material.dart';
import '../services/csv_storage_service.dart';
import '../services/settings_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh voices on opening settings
    SettingsService.instance.loadAvailableVoices().then((_) {
      if (mounted) setState(() {});
    });
  }

  String _formatSpeedLabel(double rate) {
    // 0.65 is ~100% normal base speed
    final percentage = (rate / 0.65 * 100).round();
    if (rate <= 0.35) return '$percentage% (Very Slow)';
    if (rate <= 0.50) return '$percentage% (Slow)';
    if (rate <= 0.70) return '$percentage% (Normal)';
    if (rate <= 0.90) return '$percentage% (Fast)';
    return '$percentage% (Super Fast)';
  }

  String _formatPitchLabel(double pitch) {
    if (pitch <= 0.8) return 'Deeper';
    if (pitch <= 1.1) return 'Normal / Friendly';
    return 'Higher / Cheerful';
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([SettingsService.instance, CsvStorageService.instance]),
      builder: (context, _) {
        final settings = SettingsService.instance;
        final csvService = CsvStorageService.instance;
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Settings & Preferences'),
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                children: [
                  // =================== SECTION 1: APPEARANCE ===================
                  _buildSectionHeader(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    subtitle: 'Choose between Light and Dark mode',
                    color: Colors.deepPurple,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          _buildThemeOptionTile(
                            title: 'Light Mode',
                            subtitle: 'Bright, clean, kid-friendly look',
                            icon: Icons.light_mode_rounded,
                            color: Colors.amber.shade700,
                            isSelected: settings.themeMode == ThemeMode.light,
                            onTap: () => settings.setThemeMode(ThemeMode.light),
                          ),
                          const Divider(height: 1),
                          _buildThemeOptionTile(
                            title: 'Dark Mode',
                            subtitle: 'Easy on the eyes for evening routines',
                            icon: Icons.dark_mode_rounded,
                            color: Colors.indigoAccent,
                            isSelected: settings.themeMode == ThemeMode.dark,
                            onTap: () => settings.setThemeMode(ThemeMode.dark),
                          ),
                          const Divider(height: 1),
                          _buildThemeOptionTile(
                            title: 'System Default',
                            subtitle: 'Matches your laptop or mobile device settings',
                            icon: Icons.brightness_auto_rounded,
                            color: Colors.teal,
                            isSelected: settings.themeMode == ThemeMode.system,
                            onTap: () => settings.setThemeMode(ThemeMode.system),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================== SECTION 2: AUDIO & TTS ===================
                  _buildSectionHeader(
                    icon: Icons.record_voice_over_rounded,
                    title: 'Audio & Speech (TTS)',
                    subtitle: 'Adjust speech speed and select system voice',
                    color: Colors.blueAccent,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. SPEECH SPEED SLIDER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.speed_rounded, size: 20, color: Colors.blueAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    'Speech Speed',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  _formatSpeedLabel(settings.speechRate),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blueAccent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Slider(
                            value: settings.speechRate,
                            min: 0.2,
                            max: 1.2,
                            divisions: 20,
                            label: _formatSpeedLabel(settings.speechRate),
                            onChanged: (val) => settings.setSpeechRate(val),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('🐢 Slower (0.2x)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Text('Default (0.65x)', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                              Text('Faster (1.2x) 🚀', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                            ],
                          ),

                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 12),

                          // 2. VOICE PICKER (FROM SYSTEM)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.mic_external_on_rounded, size: 20, color: Colors.deepOrange),
                                  SizedBox(width: 8),
                                  Text(
                                    'Device Voice',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              TextButton.icon(
                                onPressed: () async {
                                  await settings.loadAvailableVoices();
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('Found ${settings.availableVoices.length} system voices'),
                                        duration: const Duration(seconds: 1),
                                      ),
                                    );
                                  }
                                },
                                icon: const Icon(Icons.refresh, size: 16),
                                label: const Text('Refresh', style: TextStyle(fontSize: 12)),
                                style: TextButton.styleFrom(
                                  minimumSize: Size.zero,
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            settings.availableVoices.isEmpty
                                ? 'Using default system TTS synthesizer'
                                : 'Choose a voice installed on your laptop or mobile device:',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                          const SizedBox(height: 10),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String?>(
                                value: settings.selectedVoiceName,
                                isExpanded: true,
                                hint: const Text('Default Device Voice'),
                                items: [
                                  const DropdownMenuItem<String?>(
                                    value: null,
                                    child: Text('Default Device Voice (Auto)'),
                                  ),
                                  ...settings.availableVoices.map((v) {
                                    final name = v['name'] ?? '';
                                    final locale = v['locale'] ?? '';
                                    return DropdownMenuItem<String?>(
                                      value: name,
                                      child: Text(
                                        locale.isNotEmpty ? '$name ($locale)' : name,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    );
                                  }),
                                ],
                                onChanged: (selectedName) {
                                  if (selectedName == null) {
                                    settings.setVoice(null, null);
                                  } else {
                                    final match = settings.availableVoices.firstWhere(
                                      (v) => v['name'] == selectedName,
                                      orElse: () => {'name': selectedName, 'locale': 'en-US'},
                                    );
                                    settings.setVoice(match['name'], match['locale']);
                                  }
                                },
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),
                          const Divider(),
                          const SizedBox(height: 12),

                          // 3. VOICE PITCH SLIDER
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.tune_rounded, size: 20, color: Colors.purpleAccent),
                                  SizedBox(width: 8),
                                  Text(
                                    'Voice Pitch',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                ],
                              ),
                              Text(
                                _formatPitchLabel(settings.pitch),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.purple.shade400,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Slider(
                            value: settings.pitch,
                            min: 0.6,
                            max: 1.4,
                            divisions: 16,
                            label: settings.pitch.toStringAsFixed(2),
                            onChanged: (val) => settings.setPitch(val),
                          ),

                          const SizedBox(height: 14),

                          // 4. TEST AUDIO & RESET BUTTONS
                          Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    backgroundColor: settings.isSpeaking ? Colors.redAccent : Colors.green,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () {
                                    if (settings.isSpeaking) {
                                      settings.stop();
                                    } else {
                                      settings.speak(
                                        "Hi! Great job completing your routine today! This voice speed and tone will be used throughout the app.",
                                      );
                                    }
                                  },
                                  icon: Icon(settings.isSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded),
                                  label: Text(
                                    settings.isSpeaking ? 'Stop Voice' : 'Test Audio 🔊',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 1,
                                child: OutlinedButton(
                                  style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  onPressed: () async {
                                    await settings.resetAudioDefaults();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Reset speech settings to defaults!'),
                                          duration: Duration(seconds: 1),
                                        ),
                                      );
                                    }
                                  },
                                  child: const Text('Reset', style: TextStyle(fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // =================== SECTION 3: OFFLINE CSV MODE ===================
                  _buildSectionHeader(
                    icon: Icons.table_view_rounded,
                    title: 'Offline CSV Mode & Sync',
                    subtitle: 'Store routines and images in a local CSV file editable in Excel',
                    color: Colors.teal,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. OFFLINE CSV MODE TOGGLE
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.teal.withValues(alpha: 0.14),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.file_present_rounded, color: Colors.teal, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Offline CSV Mode',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Save and sync all data to a CSV file on your device',
                                      style: TextStyle(fontSize: 12, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ),
                              Switch(
                                value: csvService.isOfflineCsvModeEnabled,
                                activeThumbColor: Colors.teal,
                                onChanged: (val) async {
                                  await csvService.setOfflineCsvMode(val);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          val
                                              ? 'Offline CSV Mode enabled! Choose or export a CSV file below.'
                                              : 'Offline CSV Mode disabled.',
                                        ),
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),

                          if (!csvService.isOfflineCsvModeEnabled) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.info_outline, size: 18, color: Colors.grey.shade600),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      'Enable Offline CSV Mode to choose or export a CSV file and sync routines with Excel or Google Sheets.',
                                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],

                          if (csvService.isOfflineCsvModeEnabled) ...[
                            const SizedBox(height: 16),
                            const Divider(),
                            const SizedBox(height: 12),

                            // ACTIVE FILE PATH BADGE
                            const Text(
                              'Linked CSV File:',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: (csvService.activeCsvFilePath != null ? Colors.teal : Colors.amber)
                                    .withValues(alpha: isDark ? 0.16 : 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: (csvService.activeCsvFilePath != null ? Colors.teal : Colors.amber)
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        csvService.activeCsvFilePath != null
                                            ? Icons.check_circle_rounded
                                            : Icons.warning_amber_rounded,
                                        size: 16,
                                        color: csvService.activeCsvFilePath != null ? Colors.teal : Colors.amber.shade800,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        csvService.activeCsvFilePath != null
                                            ? 'Active CSV Linked'
                                            : 'No CSV File Selected',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                          color: csvService.activeCsvFilePath != null ? Colors.teal : Colors.amber.shade800,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    csvService.activeCsvFilePath ?? 'Choose an existing CSV file or export current data to create one.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontFamily: csvService.activeCsvFilePath != null ? 'monospace' : null,
                                      color: isDark ? Colors.grey.shade300 : Colors.grey.shade800,
                                    ),
                                  ),
                                  if (csvService.lastSyncedAt != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Last synced: ${_formatTimestamp(csvService.lastSyncedAt!)}',
                                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ACTION BUTTONS (CHOOSE/UPLOAD, SAVE/EXPORT, SYNC/RELOAD)
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () async {
                                    final success = await csvService.importFromCsvFile();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            success
                                                ? 'Successfully loaded schedules and images from CSV!'
                                                : 'Import cancelled or invalid CSV file.',
                                          ),
                                          backgroundColor: success ? Colors.green.shade700 : null,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.file_open_rounded, size: 18),
                                  label: const Text('Choose / Upload CSV'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.teal,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () async {
                                    final path = await csvService.exportToCsvFile();
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            path != null
                                                ? 'Saved all routines & images to CSV!'
                                                : 'Export cancelled.',
                                          ),
                                          backgroundColor: path != null ? Colors.teal.shade700 : null,
                                        ),
                                      );
                                    }
                                  },
                                  icon: const Icon(Icons.save_as_rounded, size: 18),
                                  label: const Text('Save / Export to CSV'),
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                                if (csvService.activeCsvFilePath != null)
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      final success = await csvService.reloadFromActiveCsv();
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              success
                                                  ? 'Synced latest edits from CSV file!'
                                                  : 'Failed to read active CSV file.',
                                            ),
                                            backgroundColor: success ? Colors.green.shade700 : Colors.redAccent,
                                          ),
                                        );
                                      }
                                    },
                                    icon: const Icon(Icons.sync_rounded, size: 18),
                                    label: const Text('Sync Edits Now'),
                                    style: OutlinedButton.styleFrom(
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                              ],
                            ),

                            const SizedBox(height: 16),

                            // IMAGE STORAGE EXPLANATION & CSV FORMAT
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: isDark ? 0.14 : 0.06),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(Icons.photo_library_outlined, size: 18, color: Colors.blue),
                                      SizedBox(width: 8),
                                      Text(
                                        'How Images & Edits Work:',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    '• Character and activity images are stored in an "images/" subfolder right where your CSV file is located.\n'
                                    '• Open the CSV in Excel, Notepad, or Google Sheets to add or edit activities, change times, or mark tasks done.\n'
                                    '• When you save your edits in Excel, tap "Sync Edits Now" or restart the app to immediately see the changes reflected!',
                                    style: TextStyle(fontSize: 12, height: 1.45, color: isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.14),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOptionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: isSelected ? color : null,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              color: isSelected ? color : Colors.grey.shade400,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}

