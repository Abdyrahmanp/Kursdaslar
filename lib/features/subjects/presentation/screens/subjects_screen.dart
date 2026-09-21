import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import '../../data/models/topic_model.dart';
import '../../data/repositories/subject_repository.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  void _showAddTopicDialog(BuildContext context, WidgetRef ref) {
    final state = ref.read(subjectsProvider);
    final authState = ref.read(authProvider);

    if (state.subjects.isEmpty) return;

    String selectedSubjectId = state.selectedSubjectId ?? state.subjects.first.id;
    final titleCtrl = TextEditingController();
    final contentCtrl = TextEditingController();
    final homeworkCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const Gap(16),
                    Text(
                      'Täze Sapak Temasyny Goşmak 📝',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const Gap(16),

                    // Subject dropdown
                    DropdownButtonFormField<String>(
                      initialValue: selectedSubjectId,
                      decoration: InputDecoration(
                        labelText: 'Sapagy saýlaň',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      items: state.subjects.map((s) {
                        return DropdownMenuItem(
                          value: s.id,
                          child: Text('${s.code} — ${s.name}'),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setModalState(() => selectedSubjectId = val);
                        }
                      },
                    ),
                    const Gap(12),

                    // Topic Title
                    TextField(
                      controller: titleCtrl,
                      decoration: InputDecoration(
                        labelText: 'Tema ady (Mysal: 1-nji Tema: ...)',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const Gap(12),

                    // Topic Description
                    TextField(
                      controller: contentCtrl,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Ders barada maglumat / konspekt',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const Gap(12),

                    // Homework
                    TextField(
                      controller: homeworkCtrl,
                      decoration: InputDecoration(
                        labelText: 'Öý işi / Ýumuş (Hökmany däl)',
                        prefixIcon: const Icon(Icons.assignment_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                    const Gap(20),

                    // Save button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded),
                        label: Text(isSubmitting ? 'Ýüklenýär…' : 'Temany Ýatda Sakla'),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (titleCtrl.text.trim().isEmpty) return;
                                setModalState(() => isSubmitting = true);

                                try {
                                  final creator = authState.currentStudent?.name ??
                                      'Tuşiýewa Abadan (Starşy)';

                                  final ok = await ref.read(subjectsProvider.notifier).addTopic(
                                        subjectId: selectedSubjectId,
                                        title: titleCtrl.text.trim(),
                                        content: contentCtrl.text.trim(),
                                        homework: homeworkCtrl.text.trim(),
                                        createdBy: creator,
                                      );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    HapticUtils.medium();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                          ok
                                              ? '🎉 Täze tema serwere üstünlikli goşuldy!'
                                              : '💾 Tema goşuldy we telefonyňyzda saklandy!',
                                        ),
                                        backgroundColor: ok ? const Color(0xFF059669) : Colors.orange.shade800,
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                      ),
                                    );
                                  }
                                } finally {
                                  setModalState(() => isSubmitting = false);
                                }
                              },
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(subjectsProvider);
    final authState = ref.watch(authProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final topics = state.filteredTopics;
    // Diňe Starşy we Döwletgulyýew Abdyrahman tema goşup biler
    final canManage = authState.canManageTopics;

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          SliverAppBar(
            expandedHeight: 120,
            pinned: true,
            backgroundColor: cs.primary,
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                tooltip: 'Temalary täzele',
                onPressed: () {
                  HapticUtils.light();
                  ref.read(subjectsProvider.notifier).loadData();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: Text(
                'Sapak Temalary 📚',
                style: tt.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [cs.primary, const Color(0xFF6366F1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
              ),
            ),
          ),

          // Subject filter chips row (ChoiceChip bilen arassa we bökdençsiz)
          SliverToBoxAdapter(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Ähli Sapaklar'),
                    selected: state.selectedSubjectId == null,
                    onSelected: (selected) {
                      HapticUtils.light();
                      ref.read(subjectsProvider.notifier).selectSubject(null);
                    },
                  ),
                  const Gap(8),
                  ...state.subjects.map((sub) {
                    final isSelected = state.selectedSubjectId == sub.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(sub.name),
                        selected: isSelected,
                        onSelected: (selected) {
                          HapticUtils.light();
                          ref.read(subjectsProvider.notifier).selectSubject(
                                selected ? sub.id : null,
                              );
                        },
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
        body: state.isLoading && state.topics.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : topics.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.menu_book_outlined,
                              size: 64, color: cs.outlineVariant),
                          const Gap(16),
                          Text(
                            'Bu sapak boýunça entek tema goşulmady.',
                            textAlign: TextAlign.center,
                            style: tt.bodyLarge?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                          if (canManage) ...[
                            const Gap(12),
                            FilledButton.tonalIcon(
                              onPressed: () => _showAddTopicDialog(context, ref),
                              icon: const Icon(Icons.add_rounded),
                              label: const Text('Ilkinji temany goş'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 80),
                    itemCount: topics.length,
                    itemBuilder: (ctx, index) {
                      final topic = topics[index];
                      return _TopicCard(topic: topic);
                    },
                  ),
      ),
      floatingActionButton: canManage
          ? FloatingActionButton.extended(
              onPressed: () {
                HapticUtils.light();
                _showAddTopicDialog(context, ref);
              },
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Tema Goş'),
            )
          : null,
    );
  }
}

class _TopicCard extends StatelessWidget {
  final Topic topic;

  const _TopicCard({required this.topic});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: cs.outlineVariant.withAlpha(70)),
      ),
      color: cs.surfaceContainerLow,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          HapticUtils.light();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (ctx) => TopicDetailScreen(topic: topic),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Subject Code Badge + Date
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cs.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      topic.subjectCode.isNotEmpty ? topic.subjectCode : 'DERS',
                      style: tt.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onPrimaryContainer,
                      ),
                    ),
                  ),
                  const Gap(8),
                  if (topic.subjectName.isNotEmpty)
                    Expanded(
                      child: Text(
                        topic.subjectName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: tt.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                  Text(
                    topic.date,
                    style: tt.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant.withAlpha(140),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              const Gap(10),

              // Topic Title
              Text(
                topic.title,
                style: tt.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  height: 1.3,
                ),
              ),
              const Gap(6),

              // Topic Content Preview (maksimum 3 setir)
              if (topic.content.isNotEmpty)
                Text(
                  topic.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(
                    color: cs.onSurface.withAlpha(220),
                    height: 1.4,
                  ),
                ),

              // Homework preview if present
              if (topic.hasHomework) ...[
                const Gap(12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withAlpha(90),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.assignment_rounded,
                        size: 16,
                        color: Color(0xFFB45309),
                      ),
                      const Gap(8),
                      Expanded(
                        child: Text(
                          'Öý işi: ${topic.homework}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const Gap(12),

              // Footer: Creator & "Doly oka →"
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 14, color: cs.onSurfaceVariant.withAlpha(140)),
                      const Gap(4),
                      Text(
                        topic.createdBy,
                        style: tt.labelSmall?.copyWith(
                          color: cs.onSurfaceVariant.withAlpha(160),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Text(
                        'Doly oka',
                        style: tt.labelSmall?.copyWith(
                          color: cs.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(2),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: 10, color: cs.primary),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ── Tema Doly Okama Ekrany (Full-screen Topic Reader) ─────────────────────────
class TopicDetailScreen extends StatelessWidget {
  final Topic topic;

  const TopicDetailScreen({super.key, required this.topic});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          topic.subjectName.isNotEmpty ? topic.subjectName : 'Tema Jikme-jigi',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Teksti göçürip al',
            onPressed: () {
              HapticUtils.light();
              final fullText = '''
${topic.title} (${topic.subjectName})
Sene: ${topic.date} | Goşan: ${topic.createdBy}

${topic.content}

${topic.hasHomework ? 'Öý işi:\n${topic.homework}' : ''}
''';
              Clipboard.setData(ClipboardData(text: fullText.trim()));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Tema teksti kopyalandy! 📋'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subject & Date Row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: cs.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    topic.subjectCode.isNotEmpty ? topic.subjectCode : 'DERS',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const Gap(10),
                if (topic.subjectName.isNotEmpty)
                  Expanded(
                    child: Text(
                      topic.subjectName,
                      style: tt.titleSmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    topic.date,
                    style: tt.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Title
            SelectableText(
              topic.title,
              style: tt.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                height: 1.3,
              ),
            ),
            const Gap(12),

            // Author credit
            Row(
              children: [
                Icon(Icons.edit_note_rounded, size: 18, color: cs.primary),
                const Gap(6),
                Text(
                  'Goşan: ${topic.createdBy}',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const Gap(20),
            const Divider(),
            const Gap(16),

            // Main Content (Conspectus)
            Text(
              'Konspekt / Mazmuny:',
              style: tt.labelLarge?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(8),
            SelectableText(
              topic.content.isNotEmpty
                  ? topic.content
                  : 'Bu tema üçin giňişleýin konspekt ýazylmandyr.',
              style: tt.bodyLarge?.copyWith(
                height: 1.6,
                letterSpacing: 0.2,
                color: cs.onSurface,
              ),
            ),

            // Homework section (if present)
            if (topic.hasHomework) ...[
              const Gap(28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFF59E0B).withAlpha(30),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.assignment_turned_in_rounded,
                          color: Color(0xFFB45309),
                          size: 20,
                        ),
                        Gap(8),
                        Text(
                          'Öý Işi / Ýumuş 📝',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    SelectableText(
                      topic.homework,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFF78350F),
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
