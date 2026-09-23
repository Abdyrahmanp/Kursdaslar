import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/subject_model.dart';
import '../models/topic_model.dart';
import '../services/subject_api_service.dart';

final subjectApiServiceProvider = Provider<SubjectApiService>((ref) {
  final service = SubjectApiService();
  ref.onDispose(() => service.dispose());
  return service;
});

class SubjectsState {
  final List<Subject> subjects;
  final List<Topic> topics;
  final String? selectedSubjectId; // null = all subjects
  final bool isLoading;

  const SubjectsState({
    required this.subjects,
    required this.topics,
    this.selectedSubjectId,
    this.isLoading = false,
  });

  List<Topic> get filteredTopics {
    if (selectedSubjectId == null) return topics;
    return topics.where((t) => t.subjectId == selectedSubjectId).toList();
  }

  SubjectsState copyWith({
    List<Subject>? subjects,
    List<Topic>? topics,
    String? selectedSubjectId,
    bool clearSelected = false,
    bool? isLoading,
  }) {
    return SubjectsState(
      subjects: subjects ?? this.subjects,
      topics: topics ?? this.topics,
      selectedSubjectId: clearSelected
          ? null
          : (selectedSubjectId ?? this.selectedSubjectId),
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class SubjectsNotifier extends StateNotifier<SubjectsState> {
  final SubjectApiService _apiService;
  static const String _prefKeyTopics = 'topar115_cached_topics_v1';

  SubjectsNotifier(this._apiService)
      : super(const SubjectsState(
          subjects: _initialSubjects,
          topics: _initialTopics,
        )) {
    _initData();
  }

  /// 6 sany esasy ders (Ulanyjynyň talaby boýunça)
  static const List<Subject> _initialSubjects = [
    Subject(
      id: '1',
      name: 'Iňlis dili',
      code: 'ENG',
      teacherName: '',
      iconName: 'language',
    ),
    Subject(
      id: '2',
      name: 'Ýapon dili',
      code: 'JPN',
      teacherName: '',
      iconName: 'translate',
    ),
    Subject(
      id: '3',
      name: 'Türkmen dili',
      code: 'TKM',
      teacherName: '',
      iconName: 'menu_book',
    ),
    Subject(
      id: '4',
      name: 'Informatika',
      code: 'INF',
      teacherName: '',
      iconName: 'computer',
    ),
    Subject(
      id: '5',
      name: 'Matematika',
      code: 'MAT',
      teacherName: '',
      iconName: 'calculate',
    ),
    Subject(
      id: '6',
      name: 'Fizika',
      code: 'FIZ',
      teacherName: '',
      iconName: 'science',
    ),
  ];

  static const List<Topic> _initialTopics = [];

  Future<void> _initData() async {
    await _loadCachedTopics();
    await loadData();
  }

  Future<void> _loadCachedTopics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKeyTopics);
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw);
        if (decoded is List) {
          final list = decoded
              .map((e) => Topic.fromJson(e as Map<String, dynamic>))
              .toList();
          if (list.isNotEmpty && state.topics.isEmpty) {
            state = state.copyWith(topics: list);
          }
        }
      }
    } catch (e) {
      debugPrint('[SubjectsNotifier] Load cached topics error: $e');
    }
  }

  Future<void> _saveCachedTopics(List<Topic> topics) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = jsonEncode(topics.map((t) => t.toJson()).toList());
      await prefs.setString(_prefKeyTopics, raw);
    } catch (e) {
      debugPrint('[SubjectsNotifier] Save cached topics error: $e');
    }
  }

  void selectSubject(String? subjectId) {
    if (subjectId == null || state.selectedSubjectId == subjectId) {
      state = state.copyWith(clearSelected: true);
    } else {
      state = state.copyWith(selectedSubjectId: subjectId);
    }
  }

  Future<void> loadData() async {
    state = state.copyWith(isLoading: true);
    try {
      final remoteSubs = await _apiService.fetchSubjects();
      final remoteTopics = await _apiService.fetchAllTopics();

      // Remote temalar gelende, eger boş gelmese täzele.
      // Eger boş gelse, öňki bar bolan temalary sakla (pozma).
      final newTopics = remoteTopics.isNotEmpty ? remoteTopics : state.topics;

      state = state.copyWith(
        subjects: remoteSubs.isNotEmpty ? remoteSubs : state.subjects,
        topics: newTopics,
        isLoading: false,
      );

      if (remoteTopics.isNotEmpty) {
        await _saveCachedTopics(remoteTopics);
      }
    } catch (e) {
      debugPrint('[SubjectsNotifier] loadData error: $e');
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> addTopic({
    required String subjectId,
    required String title,
    required String content,
    String? homework,
    required String createdBy,
  }) async {
    // Look up subject details
    final sub = state.subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => Subject(
        id: subjectId,
        name: 'Ders',
        code: 'DERS',
        teacherName: '',
      ),
    );

    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}.${now.month.toString().padLeft(2, '0')}.${now.year}';

    final localTopic = Topic(
      id: 'tmp_${now.millisecondsSinceEpoch}',
      subjectId: subjectId,
      subjectName: sub.name,
      subjectCode: sub.code,
      title: title,
      content: content,
      homework: homework ?? '',
      date: dateStr,
      createdBy: createdBy,
    );

    // Ekrana derrew goş (optimistic update)
    final updatedList = [localTopic, ...state.topics.where((t) => t.id != localTopic.id)];
    state = state.copyWith(topics: updatedList);
    await _saveCachedTopics(updatedList);

    // Serwere ugrat
    final ok = await _apiService.createTopic(
      subjectId: subjectId,
      title: title,
      content: content,
      homework: homework ?? '',
      createdBy: createdBy,
    );

    if (ok) {
      // Serwerden iň soňky ID-li temalary gaýtadan çek
      final remoteTopics = await _apiService.fetchAllTopics();
      if (remoteTopics.isNotEmpty) {
        state = state.copyWith(topics: remoteTopics);
        await _saveCachedTopics(remoteTopics);
      }
      return true;
    }

    // Eger serwer ugratmak başartmadyk hem bolsa, localTopic saklanyp galýar (ýitmeyär!)
    return false;
  }

  /// Temany poz (lokal + server)
  Future<void> deleteTopic(String topicId) async {
    // Hemen lokal listeden çıkar
    final updatedList = state.topics.where((t) => t.id != topicId).toList();
    state = state.copyWith(topics: updatedList);
    await _saveCachedTopics(updatedList);

    // Server'dan da sil (tmp_ id'ler server'da yok, atla)
    if (!topicId.startsWith('tmp_')) {
      await _apiService.deleteTopic(topicId);
    }
  }

  /// Temany üýtget (lokal + server)
  Future<void> editTopic({
    required String topicId,
    required String title,
    required String content,
    String homework = '',
  }) async {
    // Hemen lokal listede güncelle
    final updatedList = state.topics.map((t) {
      if (t.id != topicId) return t;
      return Topic(
        id: t.id,
        subjectId: t.subjectId,
        subjectName: t.subjectName,
        subjectCode: t.subjectCode,
        title: title,
        content: content,
        homework: homework,
        date: t.date,
        createdBy: t.createdBy,
      );
    }).toList();
    state = state.copyWith(topics: updatedList);
    await _saveCachedTopics(updatedList);

    // Server'da güncelle
    if (!topicId.startsWith('tmp_')) {
      await _apiService.editTopic(
        topicId: topicId,
        title: title,
        content: content,
        homework: homework,
      );
    }
  }
}

final subjectsProvider =
    StateNotifierProvider<SubjectsNotifier, SubjectsState>((ref) {
  final apiService = ref.watch(subjectApiServiceProvider);
  return SubjectsNotifier(apiService);
});
