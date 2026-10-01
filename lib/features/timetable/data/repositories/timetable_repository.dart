import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/timetable_model.dart';
import '../services/timetable_api_service.dart';

const Map<int, List<ClassEntry>> defaultScheduleData = {
  1: [
    ClassEntry(period: 1, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 2, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
    ClassEntry(period: 3, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
  ],
  2: [
    ClassEntry(period: 1, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 2, subject: 'Matematika', teacher: 'Bonjakowa Ogultuwak', room: '3136'),
    ClassEntry(period: 3, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
  ],
  3: [
    ClassEntry(period: 1, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 2, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 3, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
  ],
  4: [
    ClassEntry(period: 1, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 2, subject: 'Fizika', teacher: 'Amanmammedowa Maýsagül', room: '3119'),
    ClassEntry(period: 3, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
  ],
  5: [
    ClassEntry(period: 1, subject: 'Informatika', teacher: 'Başymow Serdar', room: '3136'),
    ClassEntry(period: 2, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
    ClassEntry(period: 3, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
  ],
  6: [
    ClassEntry(period: 1, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
    ClassEntry(period: 2, subject: 'Türkmen dili', teacher: 'Ýoldaşowa Zylyha', room: '3341'),
    ClassEntry(period: 3, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
  ],
};

final timetableApiServiceProvider = Provider<TimetableApiService>((ref) {
  final service = TimetableApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

class TimetableNotifier extends StateNotifier<Map<int, List<ClassEntry>>> {
  final TimetableApiService _apiService;
  static const String _prefKey = 'topar115_cached_timetable_v2';

  TimetableNotifier(this._apiService) : super(defaultScheduleData) {
    _init();
  }

  Future<void> _init() async {
    await _loadCache();
    await syncWithServer();
  }

  Future<void> _loadCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is Map) {
          final Map<int, List<ClassEntry>> loaded = {};
          decoded.forEach((key, val) {
            final day = int.tryParse(key.toString());
            if (day != null && val is List) {
              loaded[day] = val
                  .map((e) => ClassEntry.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
          });
          if (loaded.isNotEmpty) {
            state = loaded;
          }
        }
      }
    } catch (e) {
      debugPrint('[TimetableNotifier] _loadCache error: $e');
    }
  }

  Future<void> _saveCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final mapped = state.map((k, v) => MapEntry(k.toString(), v.map((e) => e.toJson()).toList()));
      await prefs.setString(_prefKey, jsonEncode(mapped));
    } catch (e) {
      debugPrint('[TimetableNotifier] _saveCache error: $e');
    }
  }

  Future<void> syncWithServer() async {
    try {
      final remote = await _apiService.fetchTimetable();
      if (remote != null && remote.isNotEmpty) {
        state = remote;
        await _saveCache();
      }
    } catch (e) {
      debugPrint('[TimetableNotifier] syncWithServer error: $e');
    }
  }

  /// Adds a new lesson (e.g. 4th lesson) to a day
  Future<bool> addLesson(int day, ClassEntry newEntry) async {
    final dayList = List<ClassEntry>.from(state[day] ?? []);
    final nextPeriod = dayList.length + 1;
    final entryWithPeriod = newEntry.copyWith(period: nextPeriod);
    dayList.add(entryWithPeriod);

    final newState = Map<int, List<ClassEntry>>.from(state);
    newState[day] = dayList;
    state = newState;
    await _saveCache();

    final ok = await _apiService.saveDay(day, dayList);
    return ok;
  }

  /// Updates an existing lesson
  Future<bool> updateLesson(int day, int index, ClassEntry updated) async {
    final dayList = List<ClassEntry>.from(state[day] ?? []);
    if (index < 0 || index >= dayList.length) return false;

    dayList[index] = updated;

    final newState = Map<int, List<ClassEntry>>.from(state);
    newState[day] = dayList;
    state = newState;
    await _saveCache();

    final ok = await _apiService.saveDay(day, dayList);
    return ok;
  }

  /// Deletes a lesson from a day and normalizes periods (1, 2, 3...)
  Future<bool> deleteLesson(int day, int index) async {
    final dayList = List<ClassEntry>.from(state[day] ?? []);
    if (index < 0 || index >= dayList.length) return false;

    dayList.removeAt(index);
    // Renumber periods
    final renumbered = [
      for (int i = 0; i < dayList.length; i++)
        dayList[i].copyWith(period: i + 1),
    ];

    final newState = Map<int, List<ClassEntry>>.from(state);
    newState[day] = renumbered;
    state = newState;
    await _saveCache();

    final ok = await _apiService.saveDay(day, renumbered);
    return ok;
  }

  /// Reorders lessons for a day and updates their period numbers
  Future<bool> reorderLessons(int day, int oldIndex, int newIndex) async {
    final dayList = List<ClassEntry>.from(state[day] ?? []);
    if (oldIndex < 0 || oldIndex >= dayList.length) return false;

    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final item = dayList.removeAt(oldIndex);
    dayList.insert(newIndex, item);

    // Renumber periods (1, 2, 3, 4...)
    final renumbered = [
      for (int i = 0; i < dayList.length; i++)
        dayList[i].copyWith(period: i + 1),
    ];

    final newState = Map<int, List<ClassEntry>>.from(state);
    newState[day] = renumbered;
    state = newState;
    await _saveCache();

    final ok = await _apiService.saveDay(day, renumbered);
    return ok;
  }
}

final timetableProvider =
    StateNotifierProvider<TimetableNotifier, Map<int, List<ClassEntry>>>((ref) {
  final apiService = ref.watch(timetableApiServiceProvider);
  return TimetableNotifier(apiService);
});
