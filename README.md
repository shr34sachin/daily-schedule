# Daily Schedule — Standalone Visual Routine & Task Planner

A standalone, accessible Flutter application for daily routine scheduling, visual task completion, and multi-person assignment. Specially tailored for special education classrooms, clinics, therapy centers, and families.

---

## 🌟 Key Features

1. **Person / Profile Assignment System**
   - **Multi-Profile Management**: Add, edit, and manage profiles with distinct avatar emojis, theme colors, and roles (e.g., Student, Child, Sibling, Self).
   - **Activity Assignment**: Each activity can be assigned to a specific individual or marked as **Shared / All**.
   - **Horizontal Filter Bar**: Quickly switch views between **All / Shared** or filter to an individual person's specific routine.
   - **Visual Identity Badges**: Schedule cards display the assigned person's avatar emoji and name in their dedicated color theme.
   - **Profile-Aware Greetings**: Time-of-day greetings dynamically greet the active person by name (e.g., *"Good morning, Maya!"*).

2. **9-Phase Time-of-Day Engine & Audio Synthesis**
   - Automatically detects the time of day across 9 distinct phases (Dawn, Early Morning, Morning, Midday, Afternoon, Late Afternoon, Evening, Night, Late Night).
   - Dynamic background gradient card with one-tap text-to-speech announcement.
   - Audio prompt confirmation (*"Is [Activity] done?"*) with enthusiastic voice feedback (*"Great job! [Activity] is done!"*).

3. **Two-Column Visual Board (TO DO & DONE)**
   - Left column for pending activities; right column for completed activities.
   - Tap any card in **TO DO** to trigger audio confirmation and move it to **DONE**.
   - Tap any card in **DONE** to easily move it back to **TO DO**.
   - Real-time task counter badges for both columns.

4. **7-Day Strip with Person-Filtered Completion Badges**
   - Horizontal day strip (Sun–Sat) showing daily progress (e.g., `3/6`).
   - Automatically highlights "TODAY" with an active ring indicator.
   - Filtered dynamically based on the selected person profile.

5. **Routine Editor & Activity Builder**
   - **31 Visual Activity Presets**: Categorized icons and colors covering personal care, education, leisure, and therapy.
   - **Drag-and-Drop Reordering**: Smooth drag handles powered by Flutter's reorderable list.
   - **Day Copy & Cloning**: Easily copy routines from any day to another, or clone across all weekdays.
   - **Custom Activities**: Ability to add custom names and times.

---

## 📁 Project Architecture

```
lib/
├── main.dart                             # Application entrypoint & Material 3 theme configuration
├── models/
│   ├── person_model.dart                 # Person entity, starter profiles, JSON serialization
│   └── schedule_model.dart               # 9-phase greeting, 31 presets, ScheduleItem, DaySchedule, WeeklySchedule
├── screens/
│   ├── schedule_screen.dart              # Main board: Person filter bar, greeting banner, 2 columns, audio dialogs
│   ├── edit_schedule_screen.dart         # Routine editor: presets grid, person selector, reordering, day cloning
│   └── person_management_screen.dart     # Person profile manager: add/edit/delete profiles, color & emoji pickers
└── services/
    └── schedule_service.dart             # Central ChangeNotifier singleton with SharedPreferences persistence
```

---

## 🚀 Running the Project

### Prerequisites
- Flutter SDK (3.47+ recommended)
- Android Studio / VS Code with Flutter extension
- Connected physical device or emulator

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Run Static Analysis & Tests
```bash
flutter analyze
flutter test
```

### 3. Launch the Application
```bash
flutter run
```

---

## 🧩 Android TTS Configuration
On Android 11+ (API level 30+), text-to-speech queries are configured in `android/app/src/main/AndroidManifest.xml`:

```xml
<queries>
    <intent>
        <action android:name="android.intent.action.TTS_SERVICE" />
    </intent>
</queries>
```

---

## 💾 Local Persistence
All routines, completion states, and person profiles persist locally using `SharedPreferences` keys:
- `daily_schedule_persons`: List of registered `Person` JSON objects.
- `daily_schedule_active_person`: Currently active person ID for filtered view.
- `daily_schedule_weekly_data`: Complete 7-day schedule JSON.
- `daily_schedule_last_opened_date`: Auto-shift reference date for resetting tasks at midnight.
