import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/person_model.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import 'schedule_screen.dart';
import 'person_management_screen.dart';
import 'edit_schedule_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  const UserSelectionScreen({super.key});

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final FlutterTts _flutterTts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  Future<void> _initTts() async {
    try {
      await _flutterTts.setSpeechRate(0.48);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.05); // Friendly pitch for kids
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

  void _onKidSelected(Person kid) async {
    _speak("Hi ${kid.name}! Let's check your schedule!");
    await ScheduleService.instance.setActivePerson(kid.id);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleScreen(initialPersonId: kid.id),
      ),
    );
    setState(() {});
  }

  void _onSharedScheduleSelected() async {
    _speak("Viewing all family schedules.");
    await ScheduleService.instance.setActivePerson(null);
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ScheduleScreen(initialPersonId: null),
      ),
    );
    setState(() {});
  }

  void _showQuickAddKidDialog() {
    final nameController = TextEditingController();
    final roleController = TextEditingController(text: 'Kid');
    int selectedColor = 0xFF1976D2;
    String selectedEmoji = '👧';

    final colors = [
      0xFF9C27B0, // Purple
      0xFF1976D2, // Blue
      0xFF00796B, // Teal
      0xFFE65100, // Orange
      0xFFD81B60, // Pink
      0xFF388E3C, // Green
    ];

    final emojis = ['👧', '👦', '🧒', '👶', '🦸', '🐱', '🐶', '🦁', '🦄', '🦖', '🚀', '⭐'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              top: 20,
              left: 20,
              right: 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Add Kid Profile',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  TextField(
                    controller: nameController,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: "Kid's Name",
                      hintText: "e.g. Leo, Emma, Noah",
                      prefixIcon: const Icon(Icons.child_care),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text('Choose Avatar:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: emojis.map((emoji) {
                      final isSelected = selectedEmoji == emoji;
                      return InkWell(
                        onTap: () => setModalState(() => selectedEmoji = emoji),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Color(selectedColor).withValues(alpha: 0.25) : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected ? Color(selectedColor) : Colors.grey.shade300,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 24)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  const Text('Choose Color:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: colors.map((colVal) {
                      final isSelected = selectedColor == colVal;
                      return InkWell(
                        onTap: () => setModalState(() => selectedColor = colVal),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: Color(colVal),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black87 : Colors.white,
                              width: isSelected ? 3 : 1.5,
                            ),
                          ),
                          child: isSelected ? const Icon(Icons.check, size: 20, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;
                        final newKid = Person(
                          id: 'person_${DateTime.now().millisecondsSinceEpoch}',
                          name: name,
                          colorValue: selectedColor,
                          role: roleController.text.trim().isEmpty ? 'Kid' : roleController.text.trim(),
                          avatarEmoji: selectedEmoji,
                        );
                        await ScheduleService.instance.addPerson(newKid);
                        if (context.mounted) Navigator.pop(ctx);
                        _speak("Welcome $name! Tap your avatar to start!");
                        setState(() {});
                      },
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Save Profile', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(selectedColor),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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
        final persons = ScheduleService.instance.persons;
        final now = DateTime.now();
        final currentDayIndex = now.weekday == 7 ? 0 : now.weekday;
        final greetingInfo = TimeOfDayGreetingInfo.getForTime(now);

        return Scaffold(
          backgroundColor: const Color(0xFFF3F6FD),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.calendar_month_rounded, color: Color(0xFF1976D2), size: 24),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Daily Schedule',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF1A237E)),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, color: Color(0xFF1976D2), size: 22),
                tooltip: 'Listen to instructions',
                onPressed: () {
                  _speak("Welcome to your Daily Schedule! Tap your picture to see what's in your schedule today!");
                },
              ),
              IconButton(
                icon: const Icon(Icons.manage_accounts_rounded, color: Color(0xFF455A64), size: 22),
                tooltip: 'Manage Profiles',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PersonManagementScreen()),
                  );
                  setState(() {});
                },
              ),
              IconButton(
                icon: const Icon(Icons.edit_calendar_rounded, color: Color(0xFF455A64), size: 22),
                tooltip: 'Edit Weekly Schedules',
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditScheduleScreen(
                        initialDayOfWeek: currentDayIndex,
                        personId: persons.isNotEmpty ? persons.first.id : null,
                      ),
                    ),
                  );
                  setState(() {});
                },
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: CustomScrollView(
                slivers: [
                  // 1. GREETING BANNER
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                      child: _buildWelcomeHeader(greetingInfo, now),
                    ),
                  ),

                  // 2. SUBTITLE / INSTRUCTION
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.amber.shade100,
                              shape: BoxShape.circle,
                            ),
                            child: const Text('👉', style: TextStyle(fontSize: 14)),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Tap your picture to check your schedule:',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF263238),
                              ),
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _showQuickAddKidDialog,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('+ Add Kid', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFF1976D2),
                              padding: const EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // 3. KID PROFILE CARDS GRID
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
                    sliver: SliverLayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.crossAxisExtent;
                        int crossAxisCount = 2;
                        double childAspectRatio = 0.82;
                        bool isHorizontal = false;

                        if (width > 800) {
                          crossAxisCount = 4;
                          childAspectRatio = 0.90;
                        } else if (width > 550) {
                          crossAxisCount = 3;
                          childAspectRatio = 0.88;
                        } else if (width < 340) {
                          crossAxisCount = 1;
                          childAspectRatio = 2.4;
                          isHorizontal = true;
                        }

                        if (persons.isEmpty) {
                          return SliverToBoxAdapter(child: _buildNoProfilesState());
                        }

                        return SliverGrid(
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: crossAxisCount,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: childAspectRatio,
                          ),
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final kid = persons[index];
                              return _buildKidCard(kid, currentDayIndex, isHorizontal: isHorizontal);
                            },
                            childCount: persons.length,
                          ),
                        );
                      },
                    ),
                  ),

                  // 4. SHARED / FAMILY SCHEDULE CARD
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 2, 14, 28),
                      child: _buildSharedScheduleCard(currentDayIndex),
                    ),
                  ),
                ],
              ),
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _showQuickAddKidDialog,
            backgroundColor: const Color(0xFF1976D2),
            foregroundColor: Colors.white,
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Add Profile', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        );
      },
    );
  }

  // Welcome Header Banner
  Widget _buildWelcomeHeader(TimeOfDayGreetingInfo greeting, DateTime now) {
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final currentDay = now.weekday == 7 ? 0 : now.weekday;
    final dateStr = "${dayNames[currentDay]}, ${monthNames[now.month - 1]} ${now.day}";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            greeting.themeColor,
            greeting.themeColor.withValues(alpha: 0.84),
            const Color(0xFF1976D2),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: greeting.themeColor.withValues(alpha: 0.32),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.22),
              shape: BoxShape.circle,
            ),
            child: Icon(greeting.icon, size: 30, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  children: [
                    Text(
                      dateStr,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.2,
                      ),
                    ),
                    Text(
                      "• ${greeting.phase}",
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${greeting.greeting}! ☀️",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Who is ready for their day?",
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.95),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarBubble(Person kid, bool isAllDone, {required double size}) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                kid.color.withValues(alpha: 0.3),
                kid.color.withValues(alpha: 0.1),
              ],
            ),
            border: Border.all(color: kid.color, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: kid.color.withValues(alpha: 0.25),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            kid.avatarEmoji,
            style: TextStyle(fontSize: size * 0.52),
          ),
        ),
        if (isAllDone)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: const BoxDecoration(
                color: Colors.amber,
                shape: BoxShape.circle,
              ),
              child: const Text('⭐', style: TextStyle(fontSize: 11)),
            ),
          ),
      ],
    );
  }

  // Kid Avatar Card
  Widget _buildKidCard(Person kid, int currentDayIndex, {bool isHorizontal = false}) {
    final progress = ScheduleService.instance.getDayProgress(currentDayIndex, personId: kid.id);
    final isAllDone = progress.total > 0 && progress.completed == progress.total;
    final percent = progress.total > 0 ? progress.completed / progress.total : 0.0;

    return Card(
      elevation: 2.5,
      shadowColor: kid.color.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: kid.color.withValues(alpha: 0.40), width: 1.8),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: () => _onKidSelected(kid),
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: isHorizontal
              ? Row(
                  children: [
                    _buildAvatarBubble(kid, isAllDone, size: 56),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            kid.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: kid.color,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            kid.role,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: kid.color,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (progress.total > 0) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percent,
                                minHeight: 4,
                                backgroundColor: Colors.grey.shade200,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  isAllDone ? Colors.green : kid.color,
                                ),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              isAllDone ? "All done! 🎉" : "${progress.completed}/${progress.total} Done",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isAllDone ? Colors.green.shade700 : Colors.grey.shade800,
                              ),
                            ),
                          ] else ...[
                            Text(
                              "Free day! 🎈",
                              style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios, size: 12, color: kid.color),
                  ],
                )
              : SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildAvatarBubble(kid, isAllDone, size: 68),
                      const SizedBox(height: 6),
                      Text(
                        kid.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: kid.color,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                        decoration: BoxDecoration(
                          color: kid.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          kid.role,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: kid.color,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (progress.total > 0) ...[
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 5,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isAllDone ? Colors.green : kid.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isAllDone
                              ? "All done! 🎉"
                              : "${progress.completed}/${progress.total} Done",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isAllDone ? Colors.green.shade700 : Colors.grey.shade800,
                          ),
                        ),
                      ] else ...[
                        Text(
                          "Free day! 🎈",
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                      const SizedBox(height: 6),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: kid.color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Open Schedule',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: kid.color,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.arrow_forward_rounded, size: 10, color: kid.color),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // Shared Family Schedule Card
  Widget _buildSharedScheduleCard(int currentDayIndex) {
    final progress = ScheduleService.instance.getDayProgress(currentDayIndex, personId: null);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: Colors.blueGrey.shade200),
      ),
      color: Colors.white,
      child: InkWell(
        onTap: _onSharedScheduleSelected,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.indigo.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Text('👨‍👩‍👧‍👦', style: TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Family & Shared Schedule',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF263238)),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'View all routines together (${progress.completed}/${progress.total} done)',
                      style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF1976D2).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF1976D2)),
                    ),
                    SizedBox(width: 3),
                    Icon(Icons.arrow_forward_ios, size: 9, color: Color(0xFF1976D2)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Zero-state if all profiles removed
  Widget _buildNoProfilesState() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text('👋', style: TextStyle(fontSize: 44)),
            const SizedBox(height: 10),
            const Text(
              'No Kid Profiles Yet',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Add your kids so each of them can tap their picture and follow their schedule!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _showQuickAddKidDialog,
              icon: const Icon(Icons.add),
              label: const Text('Add Kid Profile'),
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
