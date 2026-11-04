import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/person_model.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import 'edit_schedule_screen.dart';
import 'person_management_screen.dart';
import 'user_selection_screen.dart';

class ScheduleScreen extends StatefulWidget {
  final String? initialPersonId;
  const ScheduleScreen({super.key, this.initialPersonId});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  final FlutterTts _flutterTts = FlutterTts();
  late int _selectedDayOfWeek; // 0 = Sunday ... 6 = Saturday

  @override
  void initState() {
    super.initState();
    if (widget.initialPersonId != null) {
      ScheduleService.instance.setActivePerson(widget.initialPersonId);
    }
    final now = DateTime.now();
    _selectedDayOfWeek = now.weekday == 7 ? 0 : now.weekday;
    _initTts();
    _checkTimeShift();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setLanguage("en-US");
    } catch (_) {}
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }

  void _speak(String text) async {
    try {
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  void _checkTimeShift() {
    final now = DateTime.now();
    final currentDay = now.weekday == 7 ? 0 : now.weekday;
    final todaySchedule = ScheduleService.instance.weeklySchedule.getDay(currentDay);

    bool changed = false;
    for (var item in todaySchedule.items) {
      if (item.time.isNotEmpty && !item.isCompleted) {
        final itemTime = _parseTimeOfDay(item.time);
        if (itemTime != null) {
          final itemMinutes = itemTime.hour * 60 + itemTime.minute;
          final nowMinutes = now.hour * 60 + now.minute;
          if (nowMinutes > itemMinutes) {
            item.isCompleted = true;
            changed = true;
          }
        }
      }
    }
    if (changed) {
      ScheduleService.instance.saveSchedule();
      setState(() {});
    }
  }

  TimeOfDay? _parseTimeOfDay(String timeStr) {
    if (timeStr.isEmpty) return null;
    try {
      final parts = timeStr.trim().split(' ');
      final timeParts = parts[0].split(':');
      if (timeParts.length == 2) {
        int h = int.parse(timeParts[0]);
        int m = int.parse(timeParts[1]);
        if (parts.length > 1) {
          if (parts[1].toUpperCase() == 'PM' && h < 12) h += 12;
          if (parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
        }
        return TimeOfDay(hour: h, minute: m);
      }
    } catch (_) {}
    return null;
  }

  void _promptMarkAsDone(ScheduleItem item) {
    _speak("Is ${item.title} done?");

    showDialog(
      context: context,
      builder: (ctx) {
        final presetColor = SchedulePresets.getColorForLabel(item.title);
        final assignedPerson = ScheduleService.instance.getPersonById(item.assignedPersonId);

        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
          contentPadding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: presetColor.withValues(alpha: 0.18),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, size: 50, color: presetColor),
                ),
                const SizedBox(height: 14),
                Text(
                  item.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                if (assignedPerson != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: assignedPerson.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: assignedPerson.color.withValues(alpha: 0.4)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(assignedPerson.avatarEmoji, style: const TextStyle(fontSize: 13)),
                        const SizedBox(width: 4),
                        Text(
                          assignedPerson.name,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: assignedPerson.color),
                        ),
                      ],
                    ),
                  ),
                ],
                if (item.time.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      item.time,
                      style: TextStyle(fontSize: 13, color: Colors.grey.shade800, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                const Text(
                  'Is it done?',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green),
                ),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.all(16),
          actions: [
            OutlinedButton(
              onPressed: () => Navigator.pop(ctx),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text('Not yet'),
            ),
            ElevatedButton.icon(
              onPressed: () async {
                Navigator.pop(ctx);
                setState(() {
                  item.isCompleted = true;
                });
                await ScheduleService.instance.saveSchedule();
                final kid = ScheduleService.instance.activePerson;
                if (kid != null) {
                  _speak("Great job ${kid.name}! ${item.title} is done! ⭐");
                } else {
                  _speak("Great job! ${item.title} is done! ⭐");
                }
              },
              icon: const Icon(Icons.check_circle, size: 20),
              label: const Text('Yes, Done!'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              ),
            ),
          ],
        );
      },
    );
  }

  void _promptMoveBackToTodo(ScheduleItem item) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.undo, color: Colors.orangeAccent),
            SizedBox(width: 10),
            Expanded(child: Text('Move to To Do?')),
          ],
        ),
        content: Text('Move "${item.title}" back to the TO DO list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Keep in Done'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              setState(() {
                item.isCompleted = false;
              });
              await ScheduleService.instance.saveSchedule();
              _speak("${item.title} moved back to To Do.");
            },
            child: const Text('Move to To Do'),
          ),
        ],
      ),
    );
  }

  void _showCopyDialog() {
    final currentDay = ScheduleService.instance.weeklySchedule.getDay(_selectedDayOfWeek);
    int targetDay = (_selectedDayOfWeek + 1) % 7;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.copy_all, color: Colors.blueAccent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Copy ${currentDay.dayName}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Copy ${currentDay.items.length} activities to another day:'),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: targetDay,
                        isExpanded: true,
                        items: List.generate(7, (index) {
                          final day = ScheduleService.instance.weeklySchedule.getDay(index);
                          return DropdownMenuItem<int>(
                            value: index,
                            child: Text(
                              day.dayName + (index == _selectedDayOfWeek ? ' (Current)' : ''),
                              style: TextStyle(fontWeight: index == _selectedDayOfWeek ? FontWeight.bold : FontWeight.normal),
                            ),
                          );
                        }),
                        onChanged: (val) {
                          if (val != null) setDialogState(() => targetDay = val);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ScheduleService.instance.copyDayToAllWeekdays(_selectedDayOfWeek);
                      setState(() {});
                    },
                    icon: const Icon(Icons.calendar_view_week, size: 18),
                    label: const Text('Copy to All Weekdays (Mon - Fri)'),
                  ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await ScheduleService.instance.copyDayToAllDays(_selectedDayOfWeek);
                      setState(() {});
                    },
                    icon: const Icon(Icons.date_range, size: 18),
                    label: const Text('Copy to All 7 Days'),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  await ScheduleService.instance.copyDay(_selectedDayOfWeek, targetDay);
                  setState(() {
                    _selectedDayOfWeek = targetDay;
                  });
                },
                child: const Text('Copy to Selected Day'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ScheduleService.instance,
      builder: (context, _) {
        final theme = Theme.of(context);
        final now = DateTime.now();
        final greetingInfo = TimeOfDayGreetingInfo.getForTime(now);
        final daySchedule = ScheduleService.instance.weeklySchedule.getDay(_selectedDayOfWeek);
        final isToday = (now.weekday == 7 ? 0 : now.weekday) == _selectedDayOfWeek;
        final activePerson = ScheduleService.instance.activePerson;

        // Filter items based on active person
        final filteredItems = ScheduleService.instance.filterItems(daySchedule.items);
        final todoItems = filteredItems.where((e) => !e.isCompleted).toList();
        final doneItems = filteredItems.where((e) => e.isCompleted).toList();

        return Scaffold(
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              tooltip: 'Switch Kid / Home',
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
                  );
                }
              },
            ),
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (activePerson != null) ...[
                  Text(activePerson.avatarEmoji, style: const TextStyle(fontSize: 22)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      "${activePerson.name}'s Routine",
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontWeight: FontWeight.bold, color: activePerson.color),
                    ),
                  ),
                ] else ...[
                  const Text('Daily Schedule', overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.people_alt_outlined, size: 18),
                label: const Text('Switch Kid', style: TextStyle(fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: activePerson?.color ?? theme.primaryColor,
                ),
                onPressed: () {
                  if (Navigator.canPop(context)) {
                    Navigator.pop(context);
                  } else {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const UserSelectionScreen()),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.manage_accounts_outlined),
                tooltip: 'Manage Persons',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PersonManagementScreen()),
                  );
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_calendar),
                tooltip: 'Set / Edit Schedule',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditScheduleScreen(initialDayOfWeek: _selectedDayOfWeek),
                    ),
                  );
                  setState(() {
                    _checkTimeShift();
                  });
                },
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More options',
                onSelected: (val) {
                  if (val == 'copy') _showCopyDialog();
                  if (val == 'clear_day') {
                    ScheduleService.instance.clearDay(_selectedDayOfWeek);
                    setState(() {});
                  }
                  if (val == 'clear_all') {
                    ScheduleService.instance.clearAllSchedules();
                    setState(() {});
                  }
                  if (val == 'manage_people') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PersonManagementScreen()),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(value: 'manage_people', child: Text('Manage People / Profiles')),
                  const PopupMenuDivider(),
                  const PopupMenuItem(value: 'copy', child: Text('Copy Schedule to Another Day')),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'clear_day', child: Text('Clear ${daySchedule.dayName}')),
                  const PopupMenuItem(value: 'clear_all', child: Text('Clear All 7 Days')),
                ],
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 950),
              child: Column(
                children: [
                  // 1. PERSON SELECTOR CHIP BAR
                  _buildPersonSelectorBar(),

                  // 2. TIME OF DAY GREETING BANNER
                  _buildTimeOfDayBanner(greetingInfo, isToday, now, activePerson),

                  // 3. 7-DAY SELECTOR STRIP
                  _buildDaySelectorStrip(theme, now),

                  // 4. TWO-COLUMN (TO DO & DONE) SCHEDULE BOARD
                  Expanded(
                    child: filteredItems.isEmpty
                        ? _buildEmptyScheduleView(daySchedule, activePerson)
                        : _buildTwoColumnBoard(todoItems, doneItems, theme),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditScheduleScreen(initialDayOfWeek: _selectedDayOfWeek),
                ),
              );
              setState(() {
                _checkTimeShift();
              });
            },
            icon: const Icon(Icons.add_task),
            label: Text(
              activePerson != null
                  ? 'Set ${activePerson.name}\'s ${daySchedule.shortDayName}'
                  : 'Set ${daySchedule.shortDayName} Schedule',
            ),
          ),
        );
      },
    );
  }

  // Person Selector Horizontal Chip Bar
  Widget _buildPersonSelectorBar() {
    final persons = ScheduleService.instance.persons;
    final activeId = ScheduleService.instance.activePersonId;

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Theme.of(context).colorScheme.surface,
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          // "All / Shared" Filter Chip
          Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: FilterChip(
              avatar: const Icon(Icons.groups, size: 16),
              label: const Text('All / Shared'),
              selected: activeId == null,
              onSelected: (val) {
                if (val) ScheduleService.instance.setActivePerson(null);
              },
            ),
          ),

          // Individual Person Chips
          ...persons.map((person) {
            final isSelected = activeId == person.id;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: FilterChip(
                avatar: Text(person.avatarEmoji, style: const TextStyle(fontSize: 14)),
                label: Text(person.name),
                selected: isSelected,
                selectedColor: person.color.withValues(alpha: 0.25),
                checkmarkColor: person.color,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isSelected ? person.color : Colors.black87,
                ),
                side: BorderSide(
                  color: isSelected ? person.color : Colors.grey.shade300,
                  width: isSelected ? 1.8 : 1.0,
                ),
                onSelected: (val) {
                  ScheduleService.instance.setActivePerson(val ? person.id : null);
                },
              ),
            );
          }),

          // Manage Persons Button Chip
          ActionChip(
            avatar: const Icon(Icons.person_add_alt_1, size: 16),
            label: const Text('+ Manage'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PersonManagementScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  // Time-of-Day Banner
  Widget _buildTimeOfDayBanner(TimeOfDayGreetingInfo greeting, bool isToday, DateTime now, Person? activePerson) {
    final timeStr = "${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}";
    final greetingText = activePerson != null
        ? "${greeting.greeting}, ${activePerson.name}!"
        : "${greeting.greeting}!";

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            greeting.themeColor.withValues(alpha: 0.90),
            greeting.themeColor.withValues(alpha: 0.70),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: greeting.themeColor.withValues(alpha: 0.25),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Icon(greeting.icon, size: 28, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    Text(
                      greeting.phase,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      "• ${greeting.timeRange}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.90),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                Text(
                  greetingText,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.volume_up, color: Colors.white, size: 24),
            tooltip: 'Announce Greeting',
            onPressed: () {
              _speak("$greetingText It is currently ${greeting.phase.toLowerCase()}, time is $timeStr.");
            },
          ),
        ],
      ),
    );
  }

  // 7-Day Horizontal Selector Strip
  Widget _buildDaySelectorStrip(ThemeData theme, DateTime now) {
    final todayDayIndex = now.weekday == 7 ? 0 : now.weekday;

    return Container(
      height: 78,
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: 7,
        itemBuilder: (context, index) {
          final isSelected = _selectedDayOfWeek == index;
          final isCurrentToday = todayDayIndex == index;
          final day = ScheduleService.instance.weeklySchedule.getDay(index);
          final progress = ScheduleService.instance.getDayProgress(index);

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () => setState(() => _selectedDayOfWeek = index),
              borderRadius: BorderRadius.circular(14),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 62,
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.primaryColor
                      : (isCurrentToday ? theme.primaryColor.withValues(alpha: 0.14) : Colors.grey.withValues(alpha: 0.08)),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? theme.primaryColor
                        : (isCurrentToday ? theme.primaryColor.withValues(alpha: 0.6) : Colors.grey.shade400),
                    width: isSelected || isCurrentToday ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: FittedBox(
                        child: Text(
                          day.shortDayName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (isCurrentToday ? theme.primaryColor : Colors.black87),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: FittedBox(
                        child: progress.total > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: isSelected ? Colors.white.withValues(alpha: 0.3) : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${progress.completed}/${progress.total}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: isSelected ? Colors.white : Colors.black87,
                                  ),
                                ),
                              )
                            : Text(
                                'Empty',
                                style: TextStyle(
                                  fontSize: 9,
                                  color: isSelected ? Colors.white70 : Colors.grey.shade600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Two Column Board (TO DO on Left, DONE on Right)
  Widget _buildTwoColumnBoard(List<ScheduleItem> todoItems, List<ScheduleItem> doneItems, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 76),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column 1: TO DO
          Expanded(
            child: _buildColumnSection(
              title: 'TO DO',
              count: todoItems.length,
              headerColor: Colors.blueAccent,
              icon: Icons.pending_actions,
              items: todoItems,
              isDoneSection: false,
            ),
          ),
          const SizedBox(width: 12),

          // Column 2: DONE
          Expanded(
            child: _buildColumnSection(
              title: 'DONE',
              count: doneItems.length,
              headerColor: Colors.green,
              icon: Icons.check_circle_outline,
              items: doneItems,
              isDoneSection: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildColumnSection({
    required String title,
    required int count,
    required Color headerColor,
    required IconData icon,
    required List<ScheduleItem> items,
    required bool isDoneSection,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDoneSection ? Colors.green.withValues(alpha: 0.04) : Colors.blue.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: headerColor.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Column Header Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: headerColor.withValues(alpha: 0.14),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18, color: headerColor),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: headerColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                    decoration: BoxDecoration(
                      color: headerColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "$count",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Column Items List
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: isDoneSection
                          ? Text(
                              'No completed activities yet',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic,
                                fontWeight: FontWeight.w500,
                              ),
                              textAlign: TextAlign.center,
                            )
                          : Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Text('🎉', style: TextStyle(fontSize: 28)),
                                const SizedBox(height: 4),
                                Text(
                                  'All done! Super job! ⭐',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green.shade700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _buildScheduleItemCard(item, isDoneSection);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleItemCard(ScheduleItem item, bool isDoneSection) {
    final presetColor = SchedulePresets.getColorForLabel(item.title);
    final assignedPerson = ScheduleService.instance.getPersonById(item.assignedPersonId);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: isDoneSection ? 0.8 : 2.5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isDoneSection ? Colors.green.withValues(alpha: 0.5) : presetColor.withValues(alpha: 0.4),
          width: isDoneSection ? 1.5 : 1.2,
        ),
      ),
      color: isDoneSection ? Colors.green.withValues(alpha: 0.06) : Colors.white,
      child: InkWell(
        onTap: () {
          if (!isDoneSection) {
            _promptMarkAsDone(item);
          } else {
            _promptMoveBackToTodo(item);
          }
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          child: Row(
            children: [
              // Circular Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isDoneSection
                      ? Colors.green.withValues(alpha: 0.18)
                      : presetColor.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  item.icon,
                  size: 20,
                  color: isDoneSection ? Colors.green.shade700 : presetColor,
                ),
              ),
              const SizedBox(width: 8),

              // Title, Person Tag & optional Time
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        decoration: isDoneSection ? TextDecoration.lineThrough : null,
                        color: isDoneSection ? Colors.grey.shade600 : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        // Person Badge Tag
                        if (assignedPerson != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: assignedPerson.color.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: assignedPerson.color.withValues(alpha: 0.35)),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(assignedPerson.avatarEmoji, style: const TextStyle(fontSize: 10)),
                                  const SizedBox(width: 3),
                                  Text(
                                    assignedPerson.name,
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: assignedPerson.color),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Time Tag
                        if (item.time.isNotEmpty)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: (isDoneSection ? Colors.grey : presetColor).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 10, color: isDoneSection ? Colors.grey.shade700 : presetColor),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.time,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: isDoneSection ? Colors.grey.shade700 : presetColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Speaker button for kids to hear activity
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: 20),
                color: isDoneSection ? Colors.grey.shade500 : presetColor,
                tooltip: 'Listen to activity',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: () {
                  _speak("${item.title}${item.time.isNotEmpty ? " at ${item.time}" : ""}");
                },
              ),
              const SizedBox(width: 4),

              // Action Icon Indicator
              Icon(
                isDoneSection ? Icons.check_circle : Icons.arrow_forward_ios,
                size: 16,
                color: isDoneSection ? Colors.green.shade600 : Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Empty State View
  Widget _buildEmptyScheduleView(DaySchedule daySchedule, Person? activePerson) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 8),
            Text(
              activePerson != null
                  ? "No Activities for ${activePerson.name} on ${daySchedule.dayName}"
                  : "No Activities for ${daySchedule.dayName}",
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              "Start by adding activities or copy from another day.",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 14),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditScheduleScreen(initialDayOfWeek: _selectedDayOfWeek),
                      ),
                    );
                    setState(() {
                      _checkTimeShift();
                    });
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Activities'),
                  style: ElevatedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _showCopyDialog,
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy Day'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
