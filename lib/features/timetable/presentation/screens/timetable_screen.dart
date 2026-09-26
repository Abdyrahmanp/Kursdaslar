import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/app/app.dart';

// ── Data Models ──────────────────────────────────────────────────────────────

class ClassEntry {
  final int period;     // 1, 2, 3
  final String subject;
  final String teacher;
  final String room;

  const ClassEntry({
    required this.period,
    required this.subject,
    required this.teacher,
    required this.room,
  });
}

// ── Static Timetable Data ────────────────────────────────────────────────────

const _periods = [
  ('1', '09:00', '10:20'),
  ('2', '10:30', '11:50'),
  ('3', '12:20', '13:40'),
];

const _schedule = {
  1: [ // Monday
    ClassEntry(period: 1, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 2, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
    ClassEntry(period: 3, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
  ],
  2: [ // Tuesday
    ClassEntry(period: 1, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 2, subject: 'Matematika', teacher: 'Bonjakowa Ogultuwak', room: '3136'),
    ClassEntry(period: 3, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
  ],
  3: [ // Wednesday
    ClassEntry(period: 1, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 2, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 3, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
  ],
  4: [ // Thursday
    ClassEntry(period: 1, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
    ClassEntry(period: 2, subject: 'Fizika', teacher: 'Amanmammedowa Maýsagül', room: '3119'),
    ClassEntry(period: 3, subject: 'Iňlis dili', teacher: 'Berdinazarow Altymyrat', room: '3341'),
  ],
  5: [ // Friday
    ClassEntry(period: 1, subject: 'Informatika', teacher: 'Başymow Serdar', room: '3136'),
    ClassEntry(period: 2, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
    ClassEntry(period: 3, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
  ],
  6: [ // Saturday
    ClassEntry(period: 1, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
    ClassEntry(period: 2, subject: 'Türkmen dili', teacher: 'Ýoldaşowa Zylyha', room: '3341'),
    ClassEntry(period: 3, subject: 'Ýapon dili', teacher: 'Nuryyewa Amanbike', room: '3341'),
  ],
};

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

// Subject color mapping
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

// ── Active Day Provider ──────────────────────────────────────────────────────
final _selectedDayProvider = StateProvider<int>((ref) {
  // 1=Mon ... 6=Sat, 7=Sun → if Sunday, default to Monday
  final w = DateTime.now().weekday;
  return w <= 6 ? w : 1;
});

// ── Screen ───────────────────────────────────────────────────────────────────
class TimetableScreen extends ConsumerWidget {
  const TimetableScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isEn = currentLocale.languageCode == 'en';
    final selectedDay = ref.watch(_selectedDayProvider);
    final todayWeekday = DateTime.now().weekday;
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final classes = _schedule[selectedDay] ?? [];

    // Current period detection
    int _currentPeriod() {
      final now = TimeOfDay.now();
      final mins = now.hour * 60 + now.minute;
      if (mins >= 9 * 60 && mins <= 10 * 60 + 20) return 1;
      if (mins >= 10 * 60 + 30 && mins <= 11 * 60 + 50) return 2;
      if (mins >= 12 * 60 + 20 && mins <= 13 * 60 + 40) return 3;
      return -1;
    }

    final currentPeriod = (selectedDay == todayWeekday) ? _currentPeriod() : -1;

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerScrolled) => [
          // ── AppBar ──────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 140,
            pinned: true,
            backgroundColor: cs.primary,
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
                    'ETUT • 115-topar',
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
                    // Decorative circles
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
                    // Info row
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.calendar_month_rounded,
                                    size: 13, color: Colors.white),
                                const Gap(5),
                                Text(
                                  '2026-2027 • I trimester',
                                  style: const TextStyle(
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
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    size: 13, color: Colors.white),
                                const Gap(5),
                                const Text(
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
                          ref.read(_selectedDayProvider.notifier).state = day;
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
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
                                    color: isSelected
                                        ? Colors.white
                                        : cs.primary,
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
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 3),
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
        body: classes.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.weekend_rounded,
                        size: 64, color: cs.outlineVariant),
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
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                children: [
                  // Time legend
                  _TimeLegend(currentPeriod: currentPeriod),
                  const Gap(16),

                  // Class cards
                  ...classes.map((c) => _ClassCard(
                        entry: c,
                        isCurrentPeriod: currentPeriod == c.period,
                        isToday: selectedDay == todayWeekday,
                      )),
                  const Gap(16),

                  // Footer note
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
    );
  }
}

// ── Time Legend Widget ───────────────────────────────────────────────────────
class _TimeLegend extends StatelessWidget {
  final int currentPeriod;
  const _TimeLegend({required this.currentPeriod});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withAlpha(100),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withAlpha(60)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: _periods.map((p) {
          final isActive = currentPeriod.toString() == p.$1;
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
                    p.$1,
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
                p.$2,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                  color: isActive ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
              Text(
                p.$3,
                style: TextStyle(
                  fontSize: 10,
                  color: isActive ? cs.primary : cs.onSurfaceVariant.withAlpha(160),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

// ── Class Card Widget ────────────────────────────────────────────────────────
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
    final period = _periods[entry.period - 1];

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
                    '${period.$2}',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  Text(
                    '${period.$3}',
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
                    // Subject name + period badge
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
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: color.withAlpha(20),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${entry.period}-nji',
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

                    // Teacher
                    Row(
                      children: [
                        Icon(Icons.person_rounded,
                            size: 13, color: cs.onSurfaceVariant),
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

                    // Room
                    Row(
                      children: [
                        Icon(Icons.meeting_room_rounded,
                            size: 13, color: cs.onSurfaceVariant),
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
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.circle,
                                    size: 7, color: Colors.white),
                                const Gap(4),
                                const Text(
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
