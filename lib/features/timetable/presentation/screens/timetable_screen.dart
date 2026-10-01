import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/app/app.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import 'package:topar_115/features/timetable/data/models/timetable_model.dart';
import 'package:topar_115/features/timetable/data/repositories/timetable_repository.dart';

const _dayNames = {
  1: 'Duşenbe',
  2: 'Sişenbe',
  3: 'Çarşenbe',
  4: 'Penşenbe',
  5: 'Anna',
  6: 'Şenbe',
};

const _enDayNames = {
  1: 'Monday',
  2: 'Tuesday',
  3: 'Wednesday',
  4: 'Thursday',
  5: 'Friday',
  6: 'Saturday',
};

const _dayShort = {
  1: 'Duş',
  2: 'Siş',
  3: 'Çar',
  4: 'Penş',
  5: 'Ann',
  6: 'Şen',
};

const _enDayShort = {
  1: 'Mon',
  2: 'Tue',
  3: 'Wed',
  4: 'Thu',
  5: 'Fri',
  6: 'Sat',
};

Color _subjectColor(String subject) {
  if (subject.contains('Iňlis')) return const Color(0xFF3B82F6);
  if (subject.contains('Ýapon')) return const Color(0xFF8B5CF6);
  if (subject.contains('Matema')) return const Color(0xFF0D9488);
  if (subject.contains('Fizika')) return const Color(0xFFF97316);
  if (subject.contains('Informatika')) return const Color(0xFF10B981);
  if (subject.contains('Türkmen')) return const Color(0xFFEF4444);
  return const Color(0xFF6366F1);
}

IconData _subjectIcon(String subject) {
  if (subject.contains('Iňlis')) return Icons.language_rounded;
  if (subject.contains('Ýapon')) return Icons.translate_rounded;
  if (subject.contains('Matema')) return Icons.calculate_rounded;
  if (subject.contains('Fizika')) return Icons.science_rounded;
  if (subject.contains('Informatika')) return Icons.computer_rounded;
  if (subject.contains('Türkmen')) return Icons.menu_book_rounded;
  return Icons.school_rounded;
}

final _selectedDayProvider = StateProvider<int>((ref) {
  final w = DateTime.now().weekday;
  return w <= 6 ? w : 1;
});

final _isEditingTimetableProvider = StateProvider<bool>((ref) => false);

class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  void _showAddLessonDialog(BuildContext context, WidgetRef ref, int day, int nextPeriod) {
    final defaultTimes = ClassEntry.defaultTimesForPeriod(nextPeriod);
    final subjectCtrl = TextEditingController();
    final teacherCtrl = TextEditingController();
    final roomCtrl = TextEditingController(text: '3341');
    final startCtrl = TextEditingController(text: defaultTimes.$1);
    final endCtrl = TextEditingController(text: defaultTimes.$2);

    final popularSubjects = [
      'Iňlis dili',
      'Ýapon dili',
      'Matematika',
      'Fizika',
      'Informatika',
      'Türkmen dili',
    ];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_rounded, color: Color(0xFF6366F1)),
              const Gap(10),
              Text('$nextPeriod-nji Dersi Goşmak'),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Quick subject chip picker
                const Text(
                  'Dersi saýlaň ýa-da ýazyň:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                const Gap(6),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: popularSubjects.map((s) {
                    final isSel = subjectCtrl.text == s;
                    return ChoiceChip(
                      label: Text(s, style: const TextStyle(fontSize: 11)),
                      selected: isSel,
                      onSelected: (selected) {
                        setModalState(() {
                          subjectCtrl.text = selected ? s : '';
                          if (s == 'Iňlis dili') teacherCtrl.text = 'Berdinazarow Altymyrat';
                          if (s == 'Ýapon dili') teacherCtrl.text = 'Nuryyewa Amanbike';
                          if (s == 'Matematika') {
                            teacherCtrl.text = 'Bonjakowa Ogultuwak';
                            roomCtrl.text = '3136';
                          }
                          if (s == 'Fizika') {
                            teacherCtrl.text = 'Amanmammedowa Maýsagül';
                            roomCtrl.text = '3119';
                          }
                          if (s == 'Informatika') {
                            teacherCtrl.text = 'Başymow Serdar';
                            roomCtrl.text = '3136';
                          }
                          if (s == 'Türkmen dili') teacherCtrl.text = 'Ýoldaşowa Zylyha';
                        });
                      },
                    );
                  }).toList(),
                ),
                const Gap(12),
                TextField(
                  controller: subjectCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Dersiň Ady (Subject)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(10),
                TextField(
                  controller: teacherCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Mugallymyň Ady (Teacher)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(10),
                TextField(
                  controller: roomCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Otag / Kabinet (Room)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const Gap(10),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Başlanýan wagty',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: TextField(
                        controller: endCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Gutarýan wagty',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Ýatyr'),
            ),
            FilledButton(
              onPressed: () async {
                final subj = subjectCtrl.text.trim();
                if (subj.isEmpty) return;
                Navigator.pop(ctx);
                HapticUtils.medium();

                final entry = ClassEntry(
                  period: nextPeriod,
                  subject: subj,
                  teacher: teacherCtrl.text.trim(),
                  room: roomCtrl.text.trim(),
                  startTime: startCtrl.text.trim(),
                  endTime: endCtrl.text.trim(),
                );

                final ok = await ref.read(timetableProvider.notifier).addLesson(day, entry);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        ok ? '🎉 Täze ders goşuldy we serwerde saklandy!' : '💾 Täze ders goşuldy.',
                      ),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Goş'),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditLessonDialog(BuildContext context, WidgetRef ref, int day, int index, ClassEntry entry) {
    final subjectCtrl = TextEditingController(text: entry.subject);
    final teacherCtrl = TextEditingController(text: entry.teacher);
    final roomCtrl = TextEditingController(text: entry.room);
    final startCtrl = TextEditingController(text: entry.effectiveStartTime);
    final endCtrl = TextEditingController(text: entry.effectiveEndTime);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.edit_rounded, color: Color(0xFF6366F1)),
            const Gap(10),
            Text('${entry.period}-nji Dersi Düzetmek'),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: subjectCtrl,
                decoration: const InputDecoration(
                  labelText: 'Dersiň Ady (Subject)',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(10),
              TextField(
                controller: teacherCtrl,
                decoration: const InputDecoration(
                  labelText: 'Mugallym (Teacher)',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(10),
              TextField(
                controller: roomCtrl,
                decoration: const InputDecoration(
                  labelText: 'Otag (Room)',
                  border: OutlineInputBorder(),
                ),
              ),
              const Gap(10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: startCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Başlanýan wagty',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: TextField(
                      controller: endCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Gutarýan wagty',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýatyr'),
          ),
          FilledButton(
            onPressed: () async {
              final subj = subjectCtrl.text.trim();
              if (subj.isEmpty) return;
              Navigator.pop(ctx);
              HapticUtils.medium();

              final updated = entry.copyWith(
                subject: subj,
                teacher: teacherCtrl.text.trim(),
                room: roomCtrl.text.trim(),
                startTime: startCtrl.text.trim(),
                endTime: endCtrl.text.trim(),
              );

              final ok = await ref.read(timetableProvider.notifier).updateLesson(day, index, updated);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Ders täzelendi! ✅' : 'Ders ýerli täzelendi.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Ýatda sakla'),
          ),
        ],
      ),
    );
  }

  void _showDeleteLessonDialog(BuildContext context, WidgetRef ref, int day, int index, ClassEntry entry) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Colors.red),
            Gap(10),
            Text('Dersi Pozmak'),
          ],
        ),
        content: Text(
          'Hakykatdan hem ${entry.period}-nji dersi (${entry.subject}) bu günki tertipden aýyrmak isleýärsiňizmi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýatyr'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(ctx);
              HapticUtils.medium();
              final ok = await ref.read(timetableProvider.notifier).deleteLesson(day, index);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(ok ? 'Ders pozuldy! 🗑️' : 'Ders aýryldy.'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            child: const Text('Hawa, Poz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isEn = currentLocale.languageCode == 'en';
    final selectedDay = ref.watch(_selectedDayProvider);
    final todayWeekday = DateTime.now().weekday;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final canManage = authState.canManageTimetable;
    final isEditing = ref.watch(_isEditingTimetableProvider);

    final schedule = ref.watch(timetableProvider);
    final classes = schedule[selectedDay] ?? [];

    int currentPeriodDetection() {
      final now = TimeOfDay.now();
      final mins = now.hour * 60 + now.minute;
      for (final c in classes) {
        final startParts = c.effectiveStartTime.split(':');
        final endParts = c.effectiveEndTime.split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final sMin = (int.tryParse(startParts[0]) ?? 0) * 60 + (int.tryParse(startParts[1]) ?? 0);
          final eMin = (int.tryParse(endParts[0]) ?? 0) * 60 + (int.tryParse(endParts[1]) ?? 0);
          if (mins >= sMin && mins <= eMin) {
            return c.period;
          }
        }
      }
      return -1;
    }

    final currentPeriod = (selectedDay == todayWeekday) ? currentPeriodDetection() : -1;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerScrolled) => [
          // ── AppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: cs.primary,
            actions: [
              if (canManage)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      isEditing ? Icons.check_circle_rounded : Icons.edit_note_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                    tooltip: isEditing ? 'Düzetmegi tamamla' : 'Tertibi düzet',
                    onPressed: () {
                      HapticUtils.light();
                      ref.read(_isEditingTimetableProvider.notifier).state = !isEditing;
                    },
                  ),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Täzele',
                onPressed: () {
                  HapticUtils.light();
                  ref.read(timetableProvider.notifier).syncWithServer();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEn ? 'Timetable 📅' : 'Raspisanie 📅',
                    style: tt.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    isEditing ? 'Düzetmek Režimi • Çalyşmak we Goşmak' : 'ETUT • 115-topar',
                    style: tt.bodySmall?.copyWith(
                      color: Colors.white.withAlpha(200),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      top: -20,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(20),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 60,
                      bottom: 10,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withAlpha(15),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 50,
                      left: 16,
                      right: 16,
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_month_rounded, size: 13, color: Colors.white),
                                Gap(5),
                                Text(
                                  '2026-2027 • I trimester',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(30),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_on_rounded, size: 13, color: Colors.white),
                                Gap(5),
                                Text(
                                  'Oguzhan ETUT',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Day Selector ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              color: cs.surface,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 10),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(6, (i) {
                    final day = i + 1;
                    final isSelected = selectedDay == day;
                    final isToday = todayWeekday == day;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () {
                          HapticUtils.light();
                          ref.read(_selectedDayProvider.notifier).state = day;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? cs.primary
                                : isToday
                                    ? cs.primaryContainer
                                    : cs.surfaceContainerHighest.withAlpha(180),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: cs.primary.withAlpha(70),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    )
                                  ]
                                : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                isEn ? _enDayShort[day]! : _dayShort[day]!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : isToday
                                          ? cs.onPrimaryContainer
                                          : cs.onSurfaceVariant,
                                ),
                              ),
                              if (isToday) ...[
                                const Gap(3),
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: isSelected ? Colors.white : cs.primary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // ── Day Header ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Row(
                children: [
                  Text(
                    isEn ? _enDayNames[selectedDay]! : _dayNames[selectedDay]!,
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (selectedDay == todayWeekday) ...[
                    const Gap(10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                      decoration: BoxDecoration(
                        color: cs.primaryContainer,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isEn ? 'Today' : 'Şu gün',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: cs.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    isEn ? '${classes.length} classes' : '${classes.length} sapak',
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],

        // ── Class List ───────────────────────────────────────────
        body: RefreshIndicator(
          onRefresh: () async {
            HapticUtils.light();
            await ref.read(timetableProvider.notifier).syncWithServer();
          },
          child: classes.isEmpty && !isEditing
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.weekend_rounded, size: 64, color: cs.outlineVariant),
                      const Gap(16),
                      Text(
                        'Bu gün sapak ýok! 🎉',
                        style: tt.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Dynç al, güýç topla!',
                        style: tt.bodyMedium?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      if (canManage) ...[
                        const Gap(16),
                        FilledButton.icon(
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Ders goş'),
                          onPressed: () => _showAddLessonDialog(context, ref, selectedDay, 1),
                        ),
                      ],
                    ],
                  ),
                )
              : (isEditing && canManage)
                  // ── Reorderable Edit Mode ───────────────────────────
                  ? ReorderableListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: classes.length + 1,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex >= classes.length || newIndex > classes.length) return;
                      HapticUtils.light();
                      ref.read(timetableProvider.notifier).reorderLessons(selectedDay, oldIndex, newIndex);
                    },
                    itemBuilder: (ctx, index) {
                      if (index == classes.length) {
                        return Container(
                          key: const ValueKey('add_new_lesson_btn'),
                          margin: const EdgeInsets.only(top: 8),
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: Text(
                              '+ Täze ${classes.length + 1}-nji Dersi Goş',
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            onPressed: () {
                              _showAddLessonDialog(context, ref, selectedDay, classes.length + 1);
                            },
                          ),
                        );
                      }

                      final c = classes[index];
                      return _EditableClassCard(
                        key: ValueKey('lesson_${c.period}_${c.subject}_$index'),
                        index: index,
                        entry: c,
                        onEdit: () => _showEditLessonDialog(context, ref, selectedDay, index, c),
                        onDelete: () => _showDeleteLessonDialog(context, ref, selectedDay, index, c),
                      );
                    },
                  )
                  // ── Standard Student View ──────────────────────────
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                      children: [
                        _TimeLegend(
                          classes: classes,
                          currentPeriod: currentPeriod,
                        ),
                        const Gap(16),
                        ...classes.map((c) => _ClassCard(
                              entry: c,
                              isCurrentPeriod: currentPeriod == c.period,
                              isToday: selectedDay == todayWeekday,
                            )),
                        const Gap(16),
                        Center(
                          child: Text(
                            'Oguzhan ETUT • ETUT 115 topar\n2026-2027 okuw ýyly • I trimester',
                            textAlign: TextAlign.center,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant.withAlpha(120),
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
        ),
      ),
      floatingActionButton: (canManage && !isEditing)
          ? FloatingActionButton.extended(
              icon: const Icon(Icons.add_rounded),
              label: Text('${classes.length + 1}-nji Dersi Goş'),
              onPressed: () {
                _showAddLessonDialog(context, ref, selectedDay, classes.length + 1);
              },
            )
          : null,
    );
  }
}

// ── Time Legend Widget (Dynamic Periods) ──────────────────────────────────────
class _TimeLegend extends StatelessWidget {
  final List<ClassEntry> classes;
  final int currentPeriod;

  const _TimeLegend({
    required this.classes,
    required this.currentPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final periodCount = math.max(3, classes.length);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: List.generate(periodCount, (i) {
          final period = i + 1;
          final isActive = currentPeriod == period;

          final existingClass = classes.cast<ClassEntry?>().firstWhere(
                (c) => c?.period == period,
                orElse: () => null,
              );
          final startTime = existingClass?.effectiveStartTime ??
              ClassEntry.defaultTimesForPeriod(period).$1;
          final endTime = existingClass?.effectiveEndTime ??
              ClassEntry.defaultTimesForPeriod(period).$2;

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: isActive ? cs.primary : cs.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$period',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.white : cs.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              const Gap(4),
              Text(
                startTime,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              Text(
                endTime,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? cs.primary : cs.onSurfaceVariant.withAlpha(160),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Standard Class Card Widget ───────────────────────────────────────────────
class _ClassCard extends StatelessWidget {
  final ClassEntry entry;
  final bool isCurrentPeriod;
  final bool isToday;

  const _ClassCard({
    required this.entry,
    required this.isCurrentPeriod,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = _subjectColor(entry.subject);
    final icon = _subjectIcon(entry.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrentPeriod ? color : cs.outlineVariant.withAlpha(60),
          width: isCurrentPeriod ? 2 : 1,
        ),
        boxShadow: isCurrentPeriod
            ? [
                BoxShadow(
                  color: color.withAlpha(40),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                )
              ]
            : [
                BoxShadow(
                  color: Colors.black.withAlpha(5),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Left period stripe + number
            Container(
              width: 56,
              decoration: BoxDecoration(
                color: color.withAlpha(isCurrentPeriod ? 50 : 25),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 17),
                  ),
                  const Gap(6),
                  Text(
                    entry.effectiveStartTime,
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    entry.effectiveEndTime,
                    style: TextStyle(
                      fontSize: 9,
                      color: color.withAlpha(180),
                    ),
                  ),
                ],
              ),
            ),

            // Main content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            entry.subject,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isCurrentPeriod ? color : cs.onSurface,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.period}-nji ders',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(6),
                    Row(
                      children: [
                        Icon(Icons.person_rounded, size: 13, color: cs.onSurfaceVariant),
                        const Gap(5),
                        Expanded(
                          child: Text(
                            entry.teacher,
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Row(
                      children: [
                        Icon(Icons.meeting_room_rounded, size: 13, color: cs.onSurfaceVariant),
                        const Gap(5),
                        Text(
                          '${entry.room} otag',
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        if (isCurrentPeriod && isToday) ...[
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.circle, size: 7, color: Colors.white),
                                Gap(4),
                                Text(
                                  'Häzir',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Editable Class Card Widget (With Reorder Handle, Edit & Delete) ───────────
class _EditableClassCard extends StatelessWidget {
  final int index;
  final ClassEntry entry;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EditableClassCard({
    super.key,
    required this.index,
    required this.entry,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = _subjectColor(entry.subject);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cs.outlineVariant.withAlpha(90)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            // Drag handle
            ReorderableDragStartListener(
              index: index,
              child: Container(
                width: 48,
                decoration: BoxDecoration(
                  color: color.withAlpha(25),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    bottomLeft: Radius.circular(20),
                  ),
                ),
                child: Center(
                  child: Icon(Icons.drag_indicator_rounded, color: color, size: 24),
                ),
              ),
            ),

            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '${entry.period}-nji ders',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Gap(8),
                        Expanded(
                          child: Text(
                            entry.subject,
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: cs.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(4),
                    Text(
                      '${entry.teacher} • ${entry.room} otag',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                    const Gap(2),
                    Text(
                      '${entry.effectiveStartTime} – ${entry.effectiveEndTime}',
                      style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),

            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                  tooltip: 'Düzet',
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  tooltip: 'Poz',
                  onPressed: onDelete,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
