import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';
import '../utils/image_utils.dart';

class EditScheduleScreen extends StatefulWidget {
  final int initialDayOfWeek;
  final String? personId;
  const EditScheduleScreen({
    super.key,
    required this.initialDayOfWeek,
    this.personId,
  });

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late int _activeDay;
  late String? _selectedPersonId;
  late List<ScheduleItem> _items;

  @override
  void initState() {
    super.initState();
    _activeDay = widget.initialDayOfWeek;
    _selectedPersonId = widget.personId ??
        ScheduleService.instance.activePersonId ??
        (ScheduleService.instance.persons.isNotEmpty
            ? ScheduleService.instance.persons.first.id
            : null);
    _loadItemsForDay();
  }

  void _loadItemsForDay() {
    final schedule = ScheduleService.instance.getScheduleForPerson(_selectedPersonId);
    final daySchedule = schedule.getDay(_activeDay);
    _items = daySchedule.items.map((e) => e.copyWith()).toList();
  }

  Future<void> _saveChanges() async {
    await ScheduleService.instance.savePersonDaySchedule(_selectedPersonId, _activeDay, _items);
    if (mounted) {
      final personName = ScheduleService.instance.getPersonById(_selectedPersonId)?.name ?? 'Kid';
      final dayName = ScheduleService.instance.getScheduleForPerson(_selectedPersonId).getDay(_activeDay).dayName;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Saved $personName's $dayName schedule!"),
          backgroundColor: Colors.green.shade700,
        ),
      );
      Navigator.pop(context);
    }
  }

  void _confirmClearCurrentDay() {
    final personName = ScheduleService.instance.getPersonById(_selectedPersonId)?.name ?? 'Kid';
    final dayName = ScheduleService.instance.getScheduleForPerson(_selectedPersonId).getDay(_activeDay).dayName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text('Clear $personName\'s $dayName?')),
          ],
        ),
        content: Text('Are you sure you want to delete all ${_items.length} activities for $personName on $dayName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () {
              setState(() {
                _items.clear();
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete All'),
          ),
        ],
      ),
    );
  }

  void _showAddOrEditItemDialog({ScheduleItem? itemToEdit, int? editIndex}) {
    String selectedTitle = itemToEdit?.title ?? SchedulePresets.all.first.label;
    bool hasTime = itemToEdit != null && itemToEdit.time.isNotEmpty;
    TimeOfDay selectedTime = TimeOfDay.now();
    String customImageBase64 = itemToEdit?.customImageBase64 ?? '';

    if (itemToEdit != null && itemToEdit.time.isNotEmpty) {
      final parts = itemToEdit.time.split(' ');
      if (parts.isNotEmpty) {
        final timeParts = parts[0].split(':');
        if (timeParts.length == 2) {
          int h = int.tryParse(timeParts[0]) ?? 8;
          int m = int.tryParse(timeParts[1]) ?? 0;
          if (parts.length > 1 && parts[1].toUpperCase() == 'PM' && h < 12) h += 12;
          if (parts.length > 1 && parts[1].toUpperCase() == 'AM' && h == 12) h = 0;
          selectedTime = TimeOfDay(hour: h, minute: m);
        }
      }
    }

    final customTitleController = TextEditingController(
      text: itemToEdit != null && !SchedulePresets.all.any((e) => e.label == itemToEdit.title) ? itemToEdit.title : '',
    );
    final notesController = TextEditingController(text: itemToEdit?.notes ?? '');
    bool isCustom = itemToEdit != null && !SchedulePresets.all.any((e) => e.label == itemToEdit.title);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final formattedTime = selectedTime.format(context);
            final screenWidth = MediaQuery.of(context).size.width;
            final crossAxisCount = screenWidth > 700 ? 5 : (screenWidth > 500 ? 4 : 3);
            final currentPerson = ScheduleService.instance.getPersonById(_selectedPersonId);
            final currentTitle = isCustom && customTitleController.text.trim().isNotEmpty
                ? customTitleController.text.trim()
                : selectedTitle;
            final currentPresetColor = SchedulePresets.getColorForLabel(currentTitle);

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
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
                        Text(
                          itemToEdit == null
                              ? "Add to ${currentPerson?.name ?? 'Routine'}"
                              : 'Edit Activity',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),

                    // Activity Picture Section (Custom Photo or Preset Icon)
                    Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: currentPresetColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: currentPresetColor.withValues(alpha: 0.28)),
                      ),
                      child: Row(
                        children: [
                          ImageUtils.buildActivityPicture(
                            ScheduleItem(
                              id: 'preview',
                              title: currentTitle,
                              time: '',
                              iconCodePoint: SchedulePresets.getIconForLabel(currentTitle).codePoint,
                              customImageBase64: customImageBase64,
                            ),
                            size: 60,
                            color: currentPresetColor,
                            borderRadius: 14,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  customImageBase64.isNotEmpty ? 'Custom Activity Picture' : 'Preset Icon Active',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  customImageBase64.isNotEmpty
                                      ? 'Photo is displayed prominently on the kid\'s board.'
                                      : 'Add a photo (e.g. kid\'s toy, toothbrush, book) for this activity!',
                                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 6,
                                  children: [
                                    ElevatedButton.icon(
                                      onPressed: () async {
                                        final base64 = await ImageUtils.pickImageAsBase64(context);
                                        if (base64 != null) {
                                          setModalState(() {
                                            customImageBase64 = base64;
                                          });
                                        }
                                      },
                                      icon: const Icon(Icons.add_a_photo, size: 16),
                                      label: Text(
                                        customImageBase64.isNotEmpty ? 'Change Photo' : 'Upload Photo',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        backgroundColor: currentPresetColor,
                                        foregroundColor: Colors.white,
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                    if (customImageBase64.isNotEmpty)
                                      OutlinedButton.icon(
                                        onPressed: () {
                                          setModalState(() {
                                            customImageBase64 = '';
                                          });
                                        },
                                        icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                                        label: const Text('Use Preset Icon', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
                                        style: OutlinedButton.styleFrom(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          minimumSize: Size.zero,
                                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Choose Preset Grid
                    const Text('Choose Activity Preset:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 230,
                      child: GridView.builder(
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 8,
                          childAspectRatio: screenWidth < 360 ? 0.85 : 0.95,
                        ),
                        itemCount: SchedulePresets.all.length,
                        itemBuilder: (context, index) {
                          final template = SchedulePresets.all[index];
                          final isSelected = !isCustom && selectedTitle == template.label;
                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                isCustom = false;
                                selectedTitle = template.label;
                                customTitleController.clear();
                              });
                            },
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? template.color.withValues(alpha: 0.22)
                                    : Colors.grey.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected ? template.color : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(template.icon, size: 26, color: template.color),
                                  const SizedBox(height: 4),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      template.label,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                        color: isSelected ? template.color : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Custom Title Field
                    TextField(
                      controller: customTitleController,
                      decoration: InputDecoration(
                        labelText: 'Or enter custom activity name',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                      onChanged: (val) {
                        if (val.trim().isNotEmpty) {
                          setModalState(() {
                            isCustom = true;
                            selectedTitle = val.trim();
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 14),

                    // Optional Time Setting
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.blue.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.access_time, color: Colors.blue, size: 22),
                              const SizedBox(width: 10),
                              const Expanded(
                                child: Text(
                                  'Set Specific Time (Optional)',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                              ),
                              Switch(
                                value: hasTime,
                                activeThumbColor: Colors.blue,
                                onChanged: (val) => setModalState(() => hasTime = val),
                              ),
                            ],
                          ),
                          if (hasTime) ...[
                            const Divider(),
                            InkWell(
                              onTap: () async {
                                final picked = await showTimePicker(
                                  context: context,
                                  initialTime: selectedTime,
                                );
                                if (picked != null) {
                                  setModalState(() => selectedTime = picked);
                                }
                              },
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: Colors.blue.shade400, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      formattedTime,
                                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
                                    ),
                                    const Text('Change Time', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Notes Field
                    TextField(
                      controller: notesController,
                      decoration: InputDecoration(
                        labelText: 'Optional notes / instructions',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      ),
                    ),
                    const SizedBox(height: 18),

                    // Submit Action Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          backgroundColor: currentPerson?.color ?? Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final titleToUse = isCustom && customTitleController.text.trim().isNotEmpty
                              ? customTitleController.text.trim()
                              : selectedTitle;

                          final timeToUse = hasTime ? formattedTime : '';

                          if (itemToEdit == null) {
                            // Add New Activity
                            setState(() {
                              _items.add(
                                ScheduleItem(
                                  id: '${DateTime.now().millisecondsSinceEpoch}_${titleToUse.replaceAll(' ', '_')}',
                                  title: titleToUse,
                                  time: timeToUse,
                                  iconCodePoint: SchedulePresets.getIconForLabel(titleToUse).codePoint,
                                  notes: notesController.text.trim(),
                                  assignedPersonId: _selectedPersonId,
                                  isCompleted: false,
                                  customImageBase64: customImageBase64,
                                ),
                              );
                            });
                          } else {
                            // Edit Existing
                            setState(() {
                              itemToEdit.title = titleToUse;
                              itemToEdit.time = timeToUse;
                              itemToEdit.iconCodePoint = SchedulePresets.getIconForLabel(titleToUse).codePoint;
                              itemToEdit.notes = notesController.text.trim();
                              itemToEdit.assignedPersonId = _selectedPersonId;
                              itemToEdit.customImageBase64 = customImageBase64;
                            });
                          }
                          Navigator.pop(ctx);
                        },
                        icon: const Icon(Icons.check),
                        label: Text(
                          itemToEdit == null ? 'Add Activity' : 'Save Changes',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showCopyFromDayDialog() {
    int sourceDay = (_activeDay == 1 ? 0 : 1);
    final schedule = ScheduleService.instance.getScheduleForPerson(_selectedPersonId);
    final personName = ScheduleService.instance.getPersonById(_selectedPersonId)?.name ?? 'Kid';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final targetName = schedule.getDay(_activeDay).dayName;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: [
                const Icon(Icons.copy, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(child: Text("Copy $personName's Routine")),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Replace $targetName with $personName\'s routine from:'),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<int>(
                      value: sourceDay,
                      isExpanded: true,
                      items: List.generate(7, (index) {
                        final day = schedule.getDay(index);
                        return DropdownMenuItem<int>(
                          value: index,
                          child: Text("${day.dayName} (${day.items.length} items)"),
                        );
                      }),
                      onChanged: (val) {
                        if (val != null) setDialogState(() => sourceDay = val);
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  final sourceItems = schedule.getDay(sourceDay).items;
                  setState(() {
                    _items = sourceItems.map((e) => e.copyWith(
                      id: '${DateTime.now().millisecondsSinceEpoch}_${e.title}',
                      isCompleted: false,
                      assignedPersonId: _selectedPersonId,
                    )).toList();
                  });
                  Navigator.pop(ctx);
                },
                child: const Text('Copy Items'),
              ),
            ],
          );
        },
      ),
    );
  }

  // Kid Selector Bar
  Widget _buildPersonSelectorBar() {
    final persons = ScheduleService.instance.persons;
    if (persons.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      color: Colors.white,
      child: Row(
        children: [
          const Text('Kid:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
          const SizedBox(width: 8),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: persons.length,
              itemBuilder: (context, index) {
                final p = persons[index];
                final isSelected = _selectedPersonId == p.id;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: ChoiceChip(
                    avatar: Text(p.avatarEmoji, style: const TextStyle(fontSize: 14)),
                    label: Text(p.name),
                    selected: isSelected,
                    selectedColor: p.color.withValues(alpha: 0.25),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isSelected ? p.color : Colors.black87,
                    ),
                    side: BorderSide(
                      color: isSelected ? p.color : Colors.grey.shade300,
                      width: isSelected ? 2 : 1,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _selectedPersonId = p.id;
                          _loadItemsForDay();
                        });
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final currentPerson = ScheduleService.instance.getPersonById(_selectedPersonId);
    final schedule = ScheduleService.instance.getScheduleForPerson(_selectedPersonId);
    final daySchedule = schedule.getDay(_activeDay);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentPerson != null) ...[
              ImageUtils.buildPersonAvatar(currentPerson, size: 28, showGlow: false),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                currentPerson != null
                    ? "Edit ${currentPerson.name}'s ${daySchedule.dayName}"
                    : "Edit ${daySchedule.dayName}",
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: currentPerson?.color,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Save Schedule',
            onPressed: _saveChanges,
          ),
          PopupMenuButton<String>(
            tooltip: 'Options',
            onSelected: (val) {
              if (val == 'copy') {
                _showCopyFromDayDialog();
              } else if (val == 'clear') {
                if (_items.isNotEmpty) _confirmClearCurrentDay();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'copy',
                child: Row(
                  children: [
                    Icon(Icons.copy, size: 20, color: Colors.blueAccent),
                    SizedBox(width: 8),
                    Text('Copy from another day'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'clear',
                enabled: _items.isNotEmpty,
                child: const Row(
                  children: [
                    Icon(Icons.delete_sweep, size: 20, color: Colors.redAccent),
                    SizedBox(width: 8),
                    Text('Clear this day'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Column(
            children: [
              // Kid Switcher Strip
              _buildPersonSelectorBar(),

              // 7-Day Selector Bar
              Container(
                height: 54,
                color: isDark ? Colors.grey.shade900 : Colors.grey.shade100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: 7,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  itemBuilder: (context, index) {
                    final isSelected = _activeDay == index;
                    final day = schedule.getDay(index);
                    final hasItems = day.items.isNotEmpty;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(
                          day.shortDayName,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            color: isSelected ? Colors.white : (hasItems ? Colors.black87 : Colors.grey),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: currentPerson?.color ?? theme.primaryColor,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _activeDay = index;
                              _loadItemsForDay();
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Activities List
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.event_note, size: 54, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              currentPerson != null
                                  ? "No activities for ${currentPerson.name} on ${daySchedule.dayName}"
                                  : "No activities on ${daySchedule.dayName}",
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            const Text('Tap "+ Add Activity" below to get started!'),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 80),
                        itemCount: _items.length,
                        // ignore: deprecated_member_use
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (oldIndex < newIndex) newIndex -= 1;
                            final item = _items.removeAt(oldIndex);
                            _items.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final presetColor = SchedulePresets.getColorForLabel(item.title);

                          return Card(
                            key: ValueKey(item.id),
                            margin: const EdgeInsets.only(bottom: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(color: presetColor.withValues(alpha: 0.35)),
                            ),
                            child: ListTile(
                              leading: ImageUtils.buildActivityPicture(
                                item,
                                size: 48,
                                color: presetColor,
                                borderRadius: 10,
                              ),
                              title: Text(
                                item.title,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: item.time.isNotEmpty
                                  ? Row(
                                      children: [
                                        Icon(Icons.access_time, size: 12, color: Colors.grey.shade600),
                                        const SizedBox(width: 4),
                                        Text(
                                          item.time,
                                          style: TextStyle(
                                            color: Colors.grey.shade700,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        if (item.notes.isNotEmpty) ...[
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              "• ${item.notes}",
                                              style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ],
                                    )
                                  : (item.notes.isNotEmpty
                                      ? Text(
                                          item.notes,
                                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                          overflow: TextOverflow.ellipsis,
                                        )
                                      : null),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: 'Edit Activity',
                                    onPressed: () => _showAddOrEditItemDialog(itemToEdit: item, editIndex: index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                    tooltip: 'Delete Activity',
                                    onPressed: () {
                                      setState(() {
                                        _items.removeAt(index);
                                      });
                                    },
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Icon(Icons.drag_handle, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 6,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showAddOrEditItemDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: currentPerson?.color ?? theme.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.check),
                  label: const Text('Save Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
