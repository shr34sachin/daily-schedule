import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/person_model.dart';
import '../models/schedule_model.dart';

class ImageUtils {
  static final ImagePicker _picker = ImagePicker();

  /// Prompts the user to pick an image from Gallery or Camera and returns it as a Base64 string
  static Future<String?> pickImageAsBase64(BuildContext context) async {
    ImageSource? selectedSource;

    // Show source choice bottom sheet
    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Select Photo Source',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded, color: Colors.blueAccent),
                title: const Text('Choose from Gallery / Photos'),
                onTap: () {
                  selectedSource = ImageSource.gallery;
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded, color: Colors.green),
                title: const Text('Take Photo with Camera'),
                onTap: () {
                  selectedSource = ImageSource.camera;
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        ),
      ),
    );

    if (selectedSource == null) return null;

    try {
      final XFile? file = await _picker.pickImage(
        source: selectedSource!,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        return base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
    }
    return null;
  }

  /// Builds a responsive circular avatar for a character/person (shows uploaded image or fallback emoji)
  static Widget buildPersonAvatar(
    Person person, {
    required double size,
    BoxBorder? border,
    bool showGlow = true,
  }) {
    final hasImage = person.hasCustomImage;

    Widget content;
    if (hasImage) {
      try {
        final bytes = base64Decode(person.customImageBase64);
        content = ClipOval(
          child: Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallbackEmoji(person, size),
          ),
        );
      } catch (_) {
        content = _buildFallbackEmoji(person, size);
      }
    } else {
      content = _buildFallbackEmoji(person, size);
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: border ?? Border.all(color: person.color, width: 2.5),
        boxShadow: showGlow
            ? [
                BoxShadow(
                  color: person.color.withValues(alpha: 0.28),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: content,
    );
  }

  static Widget _buildFallbackEmoji(Person person, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            person.color.withValues(alpha: 0.35),
            person.color.withValues(alpha: 0.12),
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        person.avatarEmoji,
        style: TextStyle(fontSize: size * 0.52),
      ),
    );
  }

  /// Builds a comfortably visible picture for an activity (custom uploaded picture or preset icon)
  static Widget buildActivityPicture(
    ScheduleItem item, {
    required double size,
    required Color color,
    double borderRadius = 14,
    bool isCompleted = false,
  }) {
    final hasImage = item.customImageBase64.isNotEmpty;

    if (hasImage) {
      try {
        final bytes = base64Decode(item.customImageBase64);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: isCompleted ? Colors.green.shade600 : color.withValues(alpha: 0.5),
              width: 1.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(borderRadius - 1.8),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => _buildFallbackActivityIcon(item, size, color, borderRadius, isCompleted),
                ),
                if (isCompleted)
                  Container(
                    color: Colors.green.withValues(alpha: 0.20),
                    alignment: Alignment.topRight,
                    padding: const EdgeInsets.all(4),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, size: 14, color: Colors.green),
                    ),
                  ),
              ],
            ),
          ),
        );
      } catch (_) {
        return _buildFallbackActivityIcon(item, size, color, borderRadius, isCompleted);
      }
    }

    return _buildFallbackActivityIcon(item, size, color, borderRadius, isCompleted);
  }

  static Widget _buildFallbackActivityIcon(
    ScheduleItem item,
    double size,
    Color color,
    double borderRadius,
    bool isCompleted,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isCompleted
            ? Colors.green.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: isCompleted ? Colors.green.shade600 : color.withValues(alpha: 0.4),
          width: 1.5,
        ),
      ),
      child: Icon(
        item.icon,
        size: size * 0.54,
        color: isCompleted ? Colors.green.shade700 : color,
      ),
    );
  }
}
