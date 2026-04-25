import 'dart:convert';
import 'dart:typed_data';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/theme.dart';
import '../../models/outfit_log.dart';
import '../../widgets/decorative_symbols.dart';
import '../../services/weather_service.dart';
import '../../services/image_service.dart';
import '../outfits/outfit_controller.dart';

// ─── LocalStorage photo persistence ──────────────────────────────────────────

class _PhotoStorage {
  static const _key = 'fitcheck_calendar_photos';

  static Map<DateTime, List<Uint8List>> load() {
    try {
      final raw = html.window.localStorage[_key];
      if (raw == null || raw.isEmpty) return {};
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final result = <DateTime, List<Uint8List>>{};
      for (final entry in json.entries) {
        final parts = entry.key.split('-');
        if (parts.length != 3) continue;
        final date = DateTime(
          int.parse(parts[0]),
          int.parse(parts[1]),
          int.parse(parts[2]),
        );
        final list = (entry.value as List).cast<String>();
        result[date] = list.map((b64) => base64Decode(b64)).toList();
      }
      return result;
    } catch (_) {
      return {};
    }
  }

  /// Returns true on success, false if the save failed (quota or unavailable).
  static bool save(Map<DateTime, List<Uint8List>> photos) {
    try {
      final json = <String, dynamic>{};
      for (final entry in photos.entries) {
        final k = '${entry.key.year}-${entry.key.month}-${entry.key.day}';
        json[k] = entry.value.map((b) => base64Encode(b)).toList();
      }
      html.window.localStorage[_key] = jsonEncode(json);
      return true;
    } catch (_) {
      // Quota exceeded or localStorage unavailable
      return false;
    }
  }
}

final calendarLogsProvider = StateProvider<Map<DateTime, List<OutfitLog>>>(
  (ref) => {},
);

// Stores outfit photos per day (taken date → bytes list), persisted to localStorage
final calendarPhotosProvider = StateProvider<Map<DateTime, List<Uint8List>>>(
  (ref) => _PhotoStorage.load(),
);

final selectedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());
final focusedDayProvider = StateProvider<DateTime>((ref) => DateTime.now());

class CalendarScreen extends ConsumerWidget {
  const CalendarScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDay = ref.watch(selectedDayProvider);
    final focusedDay = ref.watch(focusedDayProvider);
    final logs = ref.watch(calendarLogsProvider);
    final photos = ref.watch(calendarPhotosProvider);
    final weatherAsync = ref.watch(weatherProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Design My Day')),
      body: WithDecorations(
        sparse: true,
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime.utc(2024, 1, 1),
              lastDay: DateTime.utc(2030, 12, 31),
              focusedDay: focusedDay,
              selectedDayPredicate: (day) => isSameDay(selectedDay, day),
              onDaySelected: (selected, focused) {
                ref.read(selectedDayProvider.notifier).state = selected;
                ref.read(focusedDayProvider.notifier).state = focused;
              },
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return [...(logs[key] ?? []), ...(photos[key] ?? [])];
              },
              calendarBuilders: CalendarBuilders(
                markerBuilder: (ctx, day, events) {
                  final key = DateTime(day.year, day.month, day.day);
                  final hasPhotos = (photos[key] ?? []).isNotEmpty;
                  final hasLogs = (logs[key] ?? []).isNotEmpty;
                  if (!hasPhotos && !hasLogs) return null;
                  return Positioned(
                    bottom: 4,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasPhotos)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                              color: AppTheme.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (hasLogs)
                          Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: const BoxDecoration(
                              color: AppTheme.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  );
                },
                defaultBuilder: (ctx, day, _) =>
                    _DayCell(day: day, weather: weatherAsync.value),
                selectedBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  weather: weatherAsync.value,
                  isSelected: true,
                ),
                todayBuilder: (ctx, day, _) => _DayCell(
                  day: day,
                  weather: weatherAsync.value,
                  isToday: true,
                ),
              ),
              calendarStyle: const CalendarStyle(
                markerSize: 6,
                markerDecoration: BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
              ),
            ),

            // Weather summary strip for selected day
            weatherAsync.when(
              loading: () => const SizedBox(height: 8),
              error: (_, __) => const SizedBox(height: 8),
              data: (weather) {
                final key = DateTime(
                  selectedDay.year,
                  selectedDay.month,
                  selectedDay.day,
                );
                final w = weather[key];
                if (w == null) return const SizedBox(height: 8);
                return Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: w.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: w.color.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(w.icon, color: w.color, size: 22),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            w.description,
                            style: TextStyle(
                              color: w.color,
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            w.tempRange,
                            style: TextStyle(
                              color: w.color.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${selectedDay.month}/${selectedDay.day}',
                        style: TextStyle(
                          color: w.color,
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),

            // Day content
            Expanded(
              child: _SelectedDayContent(
                selectedDay: selectedDay,
                logs: logs,
                photos: photos,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'calendar_fab',
        onPressed: () => _showLogSheet(context, ref, selectedDay),
        backgroundColor: AppTheme.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showLogSheet(BuildContext context, WidgetRef ref, DateTime day) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _LogOutfitSheet(day: day),
    );
  }
}

// ─── Day Cell (shows weather icon) ──────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final Map<DateTime, WeatherDay>? weather;
  final bool isSelected;
  final bool isToday;

  const _DayCell({
    required this.day,
    required this.weather,
    this.isSelected = false,
    this.isToday = false,
  });

  @override
  Widget build(BuildContext context) {
    final key = DateTime(day.year, day.month, day.day);
    final w = weather?[key];

    return Container(
      margin: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: isSelected
            ? AppTheme.primary
            : isToday
                ? AppTheme.primary.withValues(alpha: 0.2)
                : null,
        shape: BoxShape.circle,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${day.day}',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppTheme.textPrimary,
            ),
          ),
          if (w != null)
            Icon(
              w.icon,
              size: 13,
              color: isSelected ? Colors.white70 : w.color,
            ),
        ],
      ),
    );
  }
}

// ─── Selected Day Content ─────────────────────────────────────────────────────

class _SelectedDayContent extends ConsumerWidget {
  final DateTime selectedDay;
  final Map<DateTime, List<OutfitLog>> logs;
  final Map<DateTime, List<Uint8List>> photos;

  const _SelectedDayContent({
    required this.selectedDay,
    required this.logs,
    required this.photos,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final key = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
    final dayLogs = logs[key] ?? [];
    final dayPhotos = photos[key] ?? [];
    final aiStore = ref.watch(localOutfitStoreProvider);

    if (dayLogs.isEmpty && dayPhotos.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.event_note,
              size: 48,
              color: AppTheme.textSecondary.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            const Text(
              'No outfit logged for this day',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to log what you wore',
              style: TextStyle(
                color: AppTheme.textSecondary.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        if (dayPhotos.isNotEmpty) ...[
          const Padding(
            padding: EdgeInsets.only(top: 8, bottom: 10),
            child: Text(
              'My Looks',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          ...dayPhotos.map(
            (bytes) => Container(
              margin: const EdgeInsets.only(bottom: 12),
              height: 280,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primary.withValues(alpha: 0.15),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  width: double.infinity,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
        ],
        ...dayLogs.map((log) {
          // Check if this log references an AI outfit
          final aiOutfit = log.outfitId.isNotEmpty
              ? findLocalOutfit(aiStore, log.outfitId)
              : null;

          if (aiOutfit != null) {
            return _AiOutfitLogCard(store: aiOutfit, notes: log.notes);
          }

          return Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.style, color: AppTheme.primary),
              ),
              title: const Text(
                'Outfit logged',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: log.notes != null ? Text(log.notes!) : null,
            ),
          );
        }),
      ],
    );
  }
}

class _AiOutfitLogCard extends StatelessWidget {
  final LocalOutfitStore store;
  final String? notes;
  const _AiOutfitLogCard({required this.store, this.notes});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        store.outfit.occasion?.toUpperCase() ?? 'AI OUTFIT',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'AI Generated',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                if (store.items.isNotEmpty)
                  Text(
                    store.items
                        .take(3)
                        .map((i) => i.name ?? i.category.label)
                        .join(' · '),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (notes != null && notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    notes!,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Log Outfit Sheet ─────────────────────────────────────────────────────────

class _LogOutfitSheet extends ConsumerStatefulWidget {
  final DateTime day;
  const _LogOutfitSheet({required this.day});

  @override
  ConsumerState<_LogOutfitSheet> createState() => _LogOutfitSheetState();
}

class _LogOutfitSheetState extends ConsumerState<_LogOutfitSheet> {
  final _notesCtrl = TextEditingController();
  Uint8List? _photo;
  String? _selectedAiOutfitId;
  String? _selectedAiOutfitLabel;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.day.year, widget.day.month, widget.day.day);
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.utc(2024, 1, 1),
      lastDate: DateTime.utc(2030, 12, 31),
      helpText: 'Which day is this outfit for?',
    );
    if (picked != null) {
      setState(
        () => _selectedDate = DateTime(picked.year, picked.month, picked.day),
      );
    }
  }

  Future<void> _pickPhoto() async {
    final source = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () => Navigator.pop(ctx, 'camera'),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () => Navigator.pop(ctx, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.auto_awesome, color: AppTheme.primary),
              title: const Text('Select AI Generated Outfit'),
              onTap: () {
                Navigator.pop(ctx);
                _pickAiOutfit();
              },
            ),
          ],
        ),
      ),
    );
    if (source == null) return;
    final imageService = ref.read(imageServiceProvider);
    final bytes = source == 'camera'
        ? await imageService.pickFromCamera()
        : await imageService.pickFromGallery();
    if (bytes != null) {
      setState(() {
        _photo = bytes;
        _selectedAiOutfitId = null;
        _selectedAiOutfitLabel = null;
      });
    }
  }

  void _pickAiOutfit() {
    final store = ref.read(localOutfitStoreProvider);
    if (store.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No AI outfits generated yet — tap Generate first!'),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize: 0.85,
        builder: (_, sc) => Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Select AI Outfit',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                controller: sc,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: store.length,
                itemBuilder: (_, i) {
                  final s = store[i];
                  return ListTile(
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.auto_awesome,
                        color: AppTheme.primary,
                      ),
                    ),
                    title: Text(
                      s.outfit.occasion?.toUpperCase() ?? 'OUTFIT',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    subtitle: Text(
                      s.items
                          .take(3)
                          .map((i) => i.name ?? i.category.label)
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    onTap: () {
                      setState(() {
                        _selectedAiOutfitId = s.outfit.id;
                        _selectedAiOutfitLabel =
                            s.outfit.occasion?.toUpperCase() ?? 'AI OUTFIT';
                        _photo = null; // clear any photo
                      });
                      Navigator.pop(ctx);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _save() {
    // Use the user-selected date instead of the day they were originally viewing
    final key = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    // Save photo first (always, if picked)
    if (_photo != null) {
      final photos = Map<DateTime, List<Uint8List>>.from(
        ref.read(calendarPhotosProvider),
      );
      photos[key] = [...(photos[key] ?? []), _photo!];
      ref.read(calendarPhotosProvider.notifier).state = photos;
      final persisted = _PhotoStorage.save(photos);
      if (!persisted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Photo saved for this session but browser storage is full. '
              'It may not survive a page refresh.',
            ),
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }

    // Only save a log entry if there are notes or an AI outfit — not for photo-only saves
    final hasNotes = _notesCtrl.text.trim().isNotEmpty;
    final hasAiOutfit = _selectedAiOutfitId != null;
    if (hasNotes || hasAiOutfit) {
      final logs = Map<DateTime, List<OutfitLog>>.from(
        ref.read(calendarLogsProvider),
      );
      logs[key] = [
        ...(logs[key] ?? []),
        OutfitLog(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          userId: 'user',
          outfitId: _selectedAiOutfitId ?? '',
          wornDate: key,
          notes: _notesCtrl.text.isEmpty ? null : _notesCtrl.text,
          createdAt: DateTime.now(),
        ),
      ];
      ref.read(calendarLogsProvider.notifier).state = logs;
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Log Outfit',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),

            // ── Date picker ──
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.accent.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.accent.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppTheme.accent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Date',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.edit_calendar,
                      size: 16,
                      color: AppTheme.accent,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // AI Outfit badge (when one is selected)
            if (_selectedAiOutfitLabel != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.primary.withValues(alpha: 0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      color: AppTheme.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI Outfit: $_selectedAiOutfitLabel',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _selectedAiOutfitId = null;
                        _selectedAiOutfitLabel = null;
                      }),
                      child: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
            ],

            // Photo picker area (shown when no AI outfit selected)
            if (_selectedAiOutfitLabel == null)
              GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: _photo != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.memory(_photo!, fit: BoxFit.cover),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.add_a_photo,
                              size: 36,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Add photo or select AI outfit',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

            // AI outfit picker shortcut when photo is present
            if (_selectedAiOutfitLabel == null) ...[
              const SizedBox(height: 8),
              GestureDetector(
                onTap: _pickAiOutfit,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 15,
                      color: AppTheme.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'or pick from AI Outfits',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 14),

            TextField(
              controller: _notesCtrl,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. Work meeting, feeling great!',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            ElevatedButton(onPressed: _save, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
