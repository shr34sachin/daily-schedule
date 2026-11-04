import 'package:flutter/material.dart';
import '../models/schedule_model.dart';
import '../services/schedule_service.dart';

class EditScheduleScreen extends StatefulWidget {
  final int initialDayOfWeek;
  const EditScheduleScreen({super.key, required this.initialDayOfWeek});

  @override
  State<EditScheduleScreen> createState() => _EditScheduleScreenState();
}

class _EditScheduleScreenState extends State<EditScheduleScreen> {
  late int _activeDay;
  late List<ScheduleItem> _items;

  @override
  void initState() {
    super.initState();
    _activeDay = widget.initialDayOfWeek;
    _loadItemsForDay();
  }

  void _loadItemsForDay() {
    final daySchedule = ScheduleService.instance.weeklySchedule.getDay(_activeDay);
    _items = daySchedule.items.map((e) => e.copyWith()).toList();
  }

  Future<void> _saveChanges() async {
    ScheduleService.instance.weeklySchedule.days[_activeDay] = DaySchedule(
      dayOfWeek: _activeDay,
      items: _items,
    );
    await ScheduleService.instance.saveSchedule();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Saved ${ScheduleService.instance.weeklySchedule.getDay(_activeDay).dayName} schedule!')),
      );
      Navigator.pop(context);
    }
  }

  void _confirmClearCurrentDay() {
    final dayName = ScheduleService.instance.weeklySchedule.getDay(_activeDay).dayName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.delete_sweep, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text('Clear $dayName?')),
          ],
        ),
        content: Text('Are you sure you want to delete all ${_items.length} activities for $dayName?'),
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
    String? assignedPersonId = itemToEdit?.assignedPersonId;

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
            final persons = ScheduleService.instance.persons;

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
                          itemToEdit == null ? 'Add Activity' : 'Edit Activity',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                        ),
                        IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                      ],
                    ),
                    const Divider(),

                    // Person Assignment Section
                    const Row(
                      children: [
                        Icon(Icons.person_pin, size: 18, color: Colors.indigo),
                        SizedBox(width: 6),
                        Text(
                          'Assign to Person:',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            avatar: const Icon(Icons.groups, size: 16),
                            label: const Text('Shared / All'),
                            selected: assignedPersonId == null,
                            onSelected: (val) {
                              if (val) setModalState(() => assignedPersonId = null);
                            },
                          ),
                          const SizedBox(width: 8),
                          ...persons.map((person) {
                            final isSelected = assignedPersonId == person.id;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                avatar: Text(person.avatarEmoji, style: const TextStyle(fontSize: 14)),
                                label: Text(person.name),
                                selected: isSelected,
                                selectedColor: person.color.withValues(alpha: 0.25),
                                labelStyle: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? person.color : Colors.black87,
                                ),
                                side: BorderSide(
                                  color: isSelected ? person.color : Colors.grey.shade300,
                                  width: isSelected ? 1.8 : 1.0,
                                ),
                                onSelected: (val) {
                                  if (val) setModalState(() => assignedPersonId = person.id);
                                },
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

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
                        itemBuilder: (context, idx) {
                          final template = SchedulePresets.all[idx];
                          final isSelected = !isCustom && selectedTitle == template.label;

                          return InkWell(
                            onTap: () {
                              setModalState(() {
                                isCustom = false;
                                selectedTitle = template.label;
                              });
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                              decoration: BoxDecoration(
                                color: isSelected ? template.color.withValues(alpha: 0.22) : Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: isSelected ? template.color : Colors.grey.shade400,
                                  width: isSelected ? 2.5 : 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Flexible(
                                    child: FittedBox(
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: template.color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(template.icon, size: 26, color: template.color),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Flexible(
                                    child: Text(
                                      template.label,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
                                        color: isSelected ? template.color : Colors.black87,
                                      ),
                                      maxLines: 2,
                                      textAlign: TextAlign.center,
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

                    // Action Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () {
                          final finalTitle = isCustom && customTitleController.text.trim().isNotEmpty
                              ? customTitleController.text.trim()
                              : selectedTitle;
                          final finalIcon = SchedulePresets.getIconForLabel(finalTitle);
                          final finalTime = hasTime ? formattedTime : '';

                          if (itemToEdit != null && editIndex != null) {
                            setState(() {
                              _items[editIndex] = itemToEdit.copyWith(
                                title: finalTitle,
                                time: finalTime,
                                iconCodePoint: finalIcon.codePoint,
                                notes: notesController.text.trim(),
                                assignedPersonId: assignedPersonId,
                              );
                            });
                          } else {
                            setState(() {
                              _items.add(ScheduleItem(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: finalTitle,
                                time: finalTime,
                                iconCodePoint: finalIcon.codePoint,
                                notes: notesController.text.trim(),
                                assignedPersonId: assignedPersonId,
                              ));
                            });
                          }
                          Navigator.pop(ctx);
                        },
                        child: Text(
                          itemToEdit == null ? 'Add to Schedule' : 'Update Activity',
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

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          final targetName = ScheduleService.instance.weeklySchedule.getDay(_activeDay).dayName;

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Row(
              children: [
                Icon(Icons.copy, color: Colors.blue),
                SizedBox(width: 8),
                Text('Copy Routine'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Replace $targetName with the complete schedule from:'),
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
                        final day = ScheduleService.instance.weeklySchedule.getDay(index);
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
                  final sourceItems = ScheduleService.instance.weeklySchedule.getDay(sourceDay).items;
                  setState(() {
                    _items = sourceItems.map((e) => e.copyWith(
                      id: '${DateTime.now().millisecondsSinceEpoch}_${e.title}',
                      isCompleted: false,
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final daySchedule = ScheduleService.instance.weeklySchedule.getDay(_activeDay);

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit ${daySchedule.dayName}', overflow: TextOverflow.ellipsis),
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
                    Text('Clear current day'),
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
              // Day Tabs Header
              Container(
                height: 52,
                color: theme.colorScheme.surface,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  itemCount: 7,
                  itemBuilder: (context, index) {
                    final isSelected = _activeDay == index;
                    final day = ScheduleService.instance.weeklySchedule.getDay(index);

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        label: Text(day.shortDayName, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? Colors.white : Colors.black87)),
                        selected: isSelected,
                        selectedColor: theme.primaryColor,
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
              const Divider(height: 1),

              // Reorderable list of items
              Expanded(
                child: _items.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.playlist_add, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              'No activities yet for ${daySchedule.dayName}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87),
                            ),
                            const SizedBox(height: 6),
                            const Text('Tap "+ Add Activity" below to build this day\'s schedule.', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      )
                    : ReorderableListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                        itemCount: _items.length,
                        onReorderItem: (oldIndex, newIndex) {
                          setState(() {
                            final item = _items.removeAt(oldIndex);
                            _items.insert(newIndex, item);
                          });
                        },
                        itemBuilder: (context, index) {
                          final item = _items[index];
                          final presetColor = SchedulePresets.getColorForLabel(item.title);
                          final assignedPerson = ScheduleService.instance.getPersonById(item.assignedPersonId);

                          return Card(
                            key: ValueKey(item.id),
                            margin: const EdgeInsets.only(bottom: 10),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isDark ? presetColor.withValues(alpha: 0.5) : presetColor.withValues(alpha: 0.35),
                                width: 1.2,
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              child: Row(
                                children: [
                                  // Order Index Badge
                                  Container(
                                    width: 26,
                                    height: 26,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: isDark ? Colors.white70 : Colors.grey.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),

                                  // Icon
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: presetColor.withValues(alpha: 0.16),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(item.icon, color: presetColor, size: 24),
                                  ),
                                  const SizedBox(width: 12),

                                  // Title, Assigned Person Badge & Subtitle Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            // Assigned Person Badge
                                            if (assignedPerson != null)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: assignedPerson.color.withValues(alpha: 0.14),
                                                  borderRadius: BorderRadius.circular(6),
                                                  border: Border.all(color: assignedPerson.color.withValues(alpha: 0.4)),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Text(assignedPerson.avatarEmoji, style: const TextStyle(fontSize: 11)),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      assignedPerson.name,
                                                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: assignedPerson.color),
                                                    ),
                                                  ],
                                                ),
                                              )
                                            else
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.grey.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: const Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    Icon(Icons.groups, size: 11, color: Colors.grey),
                                                    SizedBox(width: 4),
                                                    Text('Shared', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                                                  ],
                                                ),
                                              ),

                                            // Time badge
                                            if (item.time.isNotEmpty)
                                              Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.withValues(alpha: 0.12),
                                                  borderRadius: BorderRadius.circular(6),
                                                ),
                                                child: Row(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    const Icon(Icons.access_time, size: 11, color: Colors.blue),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      item.time,
                                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.blue),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Action Buttons
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20, color: Colors.blueAccent),
                                    tooltip: 'Edit',
                                    onPressed: () => _showAddOrEditItemDialog(itemToEdit: item, editIndex: index),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                    tooltip: 'Remove',
                                    onPressed: () => setState(() => _items.removeAt(index)),
                                  ),
                                  ReorderableDragStartListener(
                                    index: index,
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4.0),
                                      child: Icon(Icons.drag_handle, color: Colors.grey),
                                    ),
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
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _showAddOrEditItemDialog(),
                  icon: const Icon(Icons.add),
                  label: const Text('Add Activity', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save),
                  label: const Text('Save Schedule', style: TextStyle(fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
