import 'package:flutter/material.dart';
import '../models/person_model.dart';
import '../services/schedule_service.dart';
import '../utils/image_utils.dart';

class PersonManagementScreen extends StatefulWidget {
  const PersonManagementScreen({super.key});

  @override
  State<PersonManagementScreen> createState() => _PersonManagementScreenState();
}

class _PersonManagementScreenState extends State<PersonManagementScreen> {
  static const List<int> _colorPalette = [
    0xFF9C27B0, // Purple
    0xFF1976D2, // Blue
    0xFF00796B, // Teal
    0xFFE65100, // Deep Orange
    0xFFD81B60, // Pink
    0xFF388E3C, // Green
    0xFF5D4037, // Brown
    0xFF455A64, // Blue Grey
  ];

  static const List<String> _emojiPalette = [
    // Kids & Characters
    '👧', '👦', '🧒', '👶', '🧑', '🦸', '🦸‍♂️', '🦸‍♀️', '🧙', '🧚',
    // Animals kids love
    '🐱', '🐶', '🦁', '🐯', '🐼', '🐨', '🦊', '🐰', '🦄', '🦖', '🐻', '🐵',
    // Fun & Themes
    '🚀', '⚽', '🎨', '⭐', '🌈', '🎮', '🏆', '🍎', '🧁', '🎸', '🚗', '🧩',
  ];

  void _showAddOrEditPersonDialog({Person? personToEdit}) {
    final nameController = TextEditingController(text: personToEdit?.name ?? '');
    final roleController = TextEditingController(text: personToEdit?.role ?? 'Student');
    int selectedColor = personToEdit?.colorValue ?? _colorPalette.first;
    String selectedEmoji = personToEdit?.avatarEmoji ?? _emojiPalette.first;
    String customImageBase64 = personToEdit?.customImageBase64 ?? '';

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
                      Text(
                        personToEdit == null ? 'Add Person / Profile' : 'Edit Person',
                        style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
                      ),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),

                  // Character Photo Upload & Live Avatar Preview
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(selectedColor).withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Color(selectedColor).withValues(alpha: 0.25)),
                    ),
                    child: Row(
                      children: [
                        ImageUtils.buildPersonAvatar(
                          Person(
                            id: 'preview',
                            name: nameController.text.isEmpty ? 'Kid' : nameController.text,
                            colorValue: selectedColor,
                            role: 'Child',
                            avatarEmoji: selectedEmoji,
                            customImageBase64: customImageBase64,
                          ),
                          size: 58,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                customImageBase64.isNotEmpty ? 'Custom Photo Uploaded' : 'Emoji Avatar Active',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                customImageBase64.isNotEmpty
                                    ? 'Tap below to change or switch back.'
                                    : 'Upload a picture of the child / character!',
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
                                      backgroundColor: Color(selectedColor),
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
                                      label: const Text('Use Emoji', style: TextStyle(fontSize: 12, color: Colors.redAccent)),
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
                  const SizedBox(height: 14),

                  // Name Field
                  TextField(
                    controller: nameController,
                    autofocus: personToEdit == null,
                    decoration: InputDecoration(
                      labelText: 'Person / Student Name',
                      hintText: 'e.g. Maya, Alex, Sam',
                      prefixIcon: const Icon(Icons.badge_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onChanged: (_) => setModalState(() {}),
                  ),
                  const SizedBox(height: 14),

                  // Role Field
                  TextField(
                    controller: roleController,
                    decoration: InputDecoration(
                      labelText: 'Role / Relationship',
                      hintText: 'e.g. Student, Child, Client, Family',
                      prefixIcon: const Icon(Icons.school_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Avatar Emoji Selection
                  const Text('Or Choose Avatar Emoji:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _emojiPalette.map((emoji) {
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
                          child: Text(emoji, style: const TextStyle(fontSize: 22)),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Color Palette Selection
                  const Text('Theme / Tag Color:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _colorPalette.map((colVal) {
                      final isSelected = selectedColor == colVal;
                      final col = Color(colVal);
                      return InkWell(
                        onTap: () => setModalState(() => selectedColor = colVal),
                        customBorder: const CircleBorder(),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: col,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.black87 : Colors.white,
                              width: isSelected ? 3 : 1.5,
                            ),
                            boxShadow: [
                              if (isSelected)
                                BoxShadow(
                                  color: col.withValues(alpha: 0.4),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                            ],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 20, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final name = nameController.text.trim();
                        if (name.isEmpty) return;

                        if (personToEdit != null) {
                          await ScheduleService.instance.updatePerson(personToEdit.copyWith(
                            name: name,
                            role: roleController.text.trim().isEmpty ? 'Member' : roleController.text.trim(),
                            colorValue: selectedColor,
                            avatarEmoji: selectedEmoji,
                            customImageBase64: customImageBase64,
                          ));
                        } else {
                          await ScheduleService.instance.addPerson(Person(
                            id: 'person_${DateTime.now().millisecondsSinceEpoch}',
                            name: name,
                            role: roleController.text.trim().isEmpty ? 'Member' : roleController.text.trim(),
                            colorValue: selectedColor,
                            avatarEmoji: selectedEmoji,
                            customImageBase64: customImageBase64,
                          ));
                        }

                        if (!mounted) return;
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }
                        setState(() {});
                      },
                      icon: const Icon(Icons.save),
                      label: Text(personToEdit == null ? 'Add Person' : 'Save Changes'),
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  void _confirmDeletePerson(Person person) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Expanded(child: Text('Delete ${person.name}?')),
          ],
        ),
        content: Text(
          'Are you sure you want to delete ${person.name}? Any tasks assigned to them will be unassigned and kept in the schedule.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            onPressed: () async {
              Navigator.pop(ctx);
              await ScheduleService.instance.deletePerson(person.id);
              if (mounted) setState(() {});
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  int _countAssignedActivities(String personId) {
    int count = 0;
    for (int day = 0; day <= 6; day++) {
      final items = ScheduleService.instance.weeklySchedule.getDay(day).items;
      count += items.where((i) => i.assignedPersonId == personId).length;
    }
    return count;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ScheduleService.instance,
      builder: (context, _) {
        final persons = ScheduleService.instance.persons;
        final activeId = ScheduleService.instance.activePersonId;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Persons'),
            actions: [
              IconButton(
                icon: const Icon(Icons.person_add),
                tooltip: 'Add Person',
                onPressed: () => _showAddOrEditPersonDialog(),
              ),
            ],
          ),
          body: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.25)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Each person has their own personalized view of the daily schedule. Select a person to filter their tasks, or choose "View All" on the main board.',
                        style: TextStyle(fontSize: 13, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Registered Persons (${persons.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    TextButton.icon(
                      onPressed: () async {
                        await ScheduleService.instance.setActivePerson(null);
                        if (!mounted) return;
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: const Text('View All (Shared)'),
                    ),
                  ],
                ),
              ),

              // Persons List
              Expanded(
                child: persons.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.person_off_outlined, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            const Text('No persons added yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 6),
                            const Text('Add children, students, or family members to assign routines.'),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => _showAddOrEditPersonDialog(),
                              icon: const Icon(Icons.add),
                              label: const Text('Add Person'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: persons.length,
                        itemBuilder: (context, index) {
                          final person = persons[index];
                          final isSelected = activeId == person.id;
                          final taskCount = _countAssignedActivities(person.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: isSelected ? person.color : person.color.withValues(alpha: 0.3),
                                width: isSelected ? 2.5 : 1.2,
                              ),
                            ),
                            elevation: isSelected ? 2 : 0.8,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              leading: ImageUtils.buildPersonAvatar(person, size: 48),
                              title: Row(
                                children: [
                                  Text(
                                    person.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: person.color.withValues(alpha: 0.14),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      person.role,
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: person.color),
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  '$taskCount activities assigned throughout week',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                                ),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined, size: 20),
                                    tooltip: 'Edit Person',
                                    onPressed: () => _showAddOrEditPersonDialog(personToEdit: person),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                                    tooltip: 'Delete Person',
                                    onPressed: () => _confirmDeletePerson(person),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                                      color: isSelected ? person.color : Colors.grey,
                                      size: 24,
                                    ),
                                    tooltip: isSelected ? 'Active Profile' : 'Select Profile',
                                    onPressed: () async {
                                      await ScheduleService.instance.setActivePerson(person.id);
                                      if (!mounted) return;
                                      if (context.mounted) Navigator.pop(context);
                                    },
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddOrEditPersonDialog(),
        icon: const Icon(Icons.add),
        label: const Text('Add Person'),
      ),
    );
      },
    );
  }
}
