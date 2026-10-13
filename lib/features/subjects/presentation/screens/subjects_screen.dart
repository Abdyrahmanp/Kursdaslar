import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/app/app.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/auth/presentation/controllers/auth_controller.dart';
import '../../data/models/topic_model.dart';
import '../../data/repositories/subject_repository.dart';
import 'attachment_viewer_screen.dart';
import 'package:topar_115/core/utils/device_file_picker.dart';

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
    final List<TopicAttachment> attachments = [];
    String? inlineError; // Shown inside the dialog instead of snackbar

    // Capture the outer scaffold messenger before opening the dialog
    final outerMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cs = Theme.of(context).colorScheme;
            final tt = Theme.of(context).textTheme;

            Future<void> pickFromDevice() async {
              HapticUtils.light();
              try {
                final picked = await DeviceFilePicker.pickFileFromDevice(filterType: '*/*');
                if (picked != null) {
                  setModalState(() {
                    attachments.add(picked);
                    inlineError = null;
                  });
                  HapticUtils.medium();
                }
              } catch (e) {
                setModalState(() => inlineError = 'Faýl açylanda ýalňyşlyk: $e');
              }
            }

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit_note_rounded, color: cs.primary, size: 22),
                              ),
                              const Gap(10),
                              Text(
                                'Täze Sapak Temasy 📝',
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => Navigator.pop(ctx),
                          ),
                        ],
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
                        onChanged: (_) {
                          if (inlineError != null) setModalState(() => inlineError = null);
                        },
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
                      const Gap(14),

                      // ── Attachments Section ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.attachment_rounded, size: 18, color: cs.primary),
                              const Gap(6),
                              Text(
                                'Faýl & Resminama goşmak',
                                style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          if (attachments.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: cs.primaryContainer,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${attachments.length} faýl',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: cs.onPrimaryContainer,
                                ),
                              ),
                            ),
                        ],
                      ),
                      const Gap(8),

                      // ── Single "Faýl ýükle" Button ──
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.tonalIcon(
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          icon: const Icon(Icons.file_upload_rounded, size: 20),
                          label: const Text('Faýl ýükle'),
                          onPressed: pickFromDevice,
                        ),
                      ),

                      // Attachments preview list
                      if (attachments.isNotEmpty) ...[
                        const Gap(10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerHighest.withAlpha(90),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: cs.outlineVariant.withAlpha(50)),
                          ),
                          child: Column(
                            children: attachments.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final att = entry.value;
                              Color iconColor = att.isPptx
                                  ? const Color(0xFFEA580C)
                                  : att.isPdf
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF059669);
                              IconData iconData = att.isPptx
                                  ? Icons.slideshow_rounded
                                  : att.isPdf
                                      ? Icons.picture_as_pdf_rounded
                                      : Icons.image_rounded;

                              return Container(
                                margin: EdgeInsets.only(bottom: idx == attachments.length - 1 ? 0 : 8),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: cs.surface,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: cs.outlineVariant.withAlpha(40)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(iconData, color: iconColor, size: 22),
                                    const Gap(10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            att.name,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            '${att.type.toUpperCase()} • ${att.size} • ✓ Taýýar',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: Color(0xFF059669),
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.close_rounded, size: 16, color: Colors.redAccent),
                                      onPressed: () {
                                        HapticUtils.light();
                                        setModalState(() => attachments.removeAt(idx));
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],

                      // ── Inline error message ──
                      if (inlineError != null) ...[
                        const Gap(10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.red.shade200),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: Colors.red.shade700, size: 18),
                              const Gap(8),
                              Expanded(
                                child: Text(
                                  inlineError!,
                                  style: TextStyle(fontSize: 13, color: Colors.red.shade800),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      const Gap(20),

                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Ýatyr'),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            flex: 2,
                            child: FilledButton.icon(
                              icon: const Icon(Icons.check_rounded),
                              label: const Text('Temany Ýatda Sakla'),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: () async {
                                final titleText = titleCtrl.text.trim();
                                if (titleText.isEmpty) {
                                  HapticUtils.medium();
                                  setModalState(() => inlineError = '⚠️ Haýyş, ilki bilen Tema adyny ýazyň!');
                                  return;
                                }

                                HapticUtils.medium();
                                // Close popup instantly as requested
                                Navigator.pop(ctx);

                                final creator = authState.currentStudent?.name ??
                                    'Tuşiýewa Abadan (Starşy)';

                                ref.read(subjectsProvider.notifier).addTopic(
                                      subjectId: selectedSubjectId,
                                      title: titleText,
                                      content: contentCtrl.text.trim(),
                                      homework: homeworkCtrl.text.trim(),
                                      createdBy: creator,
                                      attachments: List.from(attachments),
                                    ).then((ok) {
                                      outerMessenger.showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            ok
                                                ? '🎉 Täze tema serwere üstünlikli goşuldy!'
                                                : '💾 Tema telefonyňyzda saklandy!',
                                          ),
                                          backgroundColor:
                                              ok ? const Color(0xFF059669) : Colors.orange.shade800,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                        ),
                                      );
                                    });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
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
    final currentLocale = ref.watch(localeProvider);
    final isEn = currentLocale.languageCode == 'en';
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
                tooltip: isEn ? 'Refresh topics' : 'Temalary täzele',
                onPressed: () {
                  HapticUtils.light();
                  ref.read(subjectsProvider.notifier).loadData();
                },
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.only(left: 16, bottom: 14),
              title: Text(
                isEn ? 'Subject Topics 📚' : 'Sapak Temalary 📚',
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
                    label: Text(isEn ? 'All Subjects' : 'Ähli Sapaklar'),
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
                            isEn
                                ? 'No topics added for this subject yet.'
                                : 'Bu sapak boýunça entek tema goşulmady.',
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
                              label: Text(isEn ? 'Add first topic' : 'Ilkinji temany goş'),
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
                      return _TopicCard(
                        topic: topic,
                        canManage: canManage,
                      );
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
              label: Text(isEn ? 'Add Topic' : 'Tema Goş'),
            )
          : null,
    );
  }
}



class _TopicCard extends ConsumerWidget {
  final Topic topic;
  final bool canManage;

  const _TopicCard({required this.topic, this.canManage = false});

  void _showTopicMenu(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                child: Text(
                  topic.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blue),
                title: const Text('Temany üýtget'),
                onTap: () {
                  Navigator.pop(ctx);
                  _showEditTopicDialog(context, ref);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: Colors.red),
                title: const Text('Temany poz', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  _confirmDeleteTopic(context, ref);
                },
              ),
              const Gap(8),
            ],
          ),
        );
      },
    );
  }

  void _showEditTopicDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController(text: topic.title);
    final contentCtrl = TextEditingController(text: topic.content);
    final homeworkCtrl = TextEditingController(text: topic.homework);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cs = Theme.of(context).colorScheme;
            final tt = Theme.of(context).textTheme;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit_rounded, color: cs.primary, size: 22),
                              ),
                              const Gap(10),
                              Text(
                                'Temany Üýtget ✏️',
                                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Gap(16),
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Tema ady',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const Gap(12),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Ders barada maglumat / konspekt',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const Gap(12),
                      TextField(
                        controller: homeworkCtrl,
                        decoration: InputDecoration(
                          labelText: 'Öý işi / Ýumuş (Hökmany däl)',
                          prefixIcon: const Icon(Icons.assignment_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const Gap(20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                              child: const Text('Ýatyr'),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            flex: 2,
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
                              label: Text(isSubmitting ? 'Ýüklenýär…' : 'Üýtgetmeleri Sakla'),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (titleCtrl.text.trim().isEmpty) return;
                                      setModalState(() => isSubmitting = true);
                                      try {
                                        await ref.read(subjectsProvider.notifier).editTopic(
                                              topicId: topic.id,
                                              title: titleCtrl.text.trim(),
                                              content: contentCtrl.text.trim(),
                                              homework: homeworkCtrl.text.trim(),
                                            );
                                        if (context.mounted) {
                                          Navigator.pop(ctx);
                                          HapticUtils.medium();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('✅ Tema üstünlikli üýtgedildi!'),
                                              backgroundColor: const Color(0xFF059669),
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDeleteTopic(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Temany pozmak'),
        content: Text(
          '"${topic.title}" temasyny pozmak isleýärsiňizmi? Bu amal yza gaýtaryp bolmaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýok'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(subjectsProvider.notifier).deleteTopic(topic.id);
              Navigator.pop(ctx);
              HapticUtils.medium();
            },
            child: const Text('Hawa, poz'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        onLongPress: canManage ? () => _showTopicMenu(context, ref) : null,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Subject Code Badge + Date + Manage indicator
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
                  if (canManage) ...[
                    const Gap(2),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticUtils.light();
                          _showTopicMenu(context, ref);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(4),
                          child: Icon(
                            Icons.more_vert_rounded,
                            size: 20,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  ],
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
              // Attachments preview if present
              if (topic.hasAttachments) ...[
                const Gap(10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: topic.attachments.map((att) {
                    final isPptx = att.isPptx;
                    final isPdf = att.isPdf;
                    final chipColor = isPptx
                        ? const Color(0xFFEA580C)
                        : isPdf
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669);
                    final icon = isPptx
                        ? Icons.slideshow_rounded
                        : isPdf
                            ? Icons.picture_as_pdf_rounded
                            : Icons.image_rounded;

                    return InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        HapticUtils.light();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => AttachmentViewerScreen(
                              attachment: att,
                              topicTitle: topic.title,
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: chipColor.withAlpha(30),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: chipColor.withAlpha(76)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: chipColor),
                            const Gap(5),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 160),
                              child: Text(
                                att.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: chipColor,
                                ),
                              ),
                            ),
                            const Gap(4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                              decoration: BoxDecoration(
                                color: chipColor.withAlpha(51),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                att.size,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: chipColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
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
class TopicDetailScreen extends ConsumerWidget {
  final Topic topic;

  const TopicDetailScreen({super.key, required this.topic});

  void _showEditDialog(BuildContext context, WidgetRef ref, Topic currentTopic) {
    final titleCtrl = TextEditingController(text: currentTopic.title);
    final contentCtrl = TextEditingController(text: currentTopic.content);
    final homeworkCtrl = TextEditingController(text: currentTopic.homework);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setModalState) {
            final cs = Theme.of(context).colorScheme;
            final tt = Theme.of(context).textTheme;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 520),
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: cs.primaryContainer,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.edit_rounded, color: cs.primary, size: 22),
                              ),
                              const Gap(10),
                              Text(
                                'Temany Üýtget ✏️',
                                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                          ),
                        ],
                      ),
                      const Gap(16),
                      TextField(
                        controller: titleCtrl,
                        decoration: InputDecoration(
                          labelText: 'Tema ady',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const Gap(12),
                      TextField(
                        controller: contentCtrl,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Ders barada maglumat / konspekt',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const Gap(12),
                      TextField(
                        controller: homeworkCtrl,
                        decoration: InputDecoration(
                          labelText: 'Öý işi / Ýumuş (Hökmany däl)',
                          prefixIcon: const Icon(Icons.assignment_outlined),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                      ),
                      const Gap(20),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSubmitting ? null : () => Navigator.pop(ctx),
                              child: const Text('Ýatyr'),
                            ),
                          ),
                          const Gap(12),
                          Expanded(
                            flex: 2,
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
                              label: Text(isSubmitting ? 'Ýüklenýär…' : 'Üýtgetmeleri Sakla'),
                              style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              onPressed: isSubmitting
                                  ? null
                                  : () async {
                                      if (titleCtrl.text.trim().isEmpty) return;
                                      setModalState(() => isSubmitting = true);
                                      try {
                                        await ref.read(subjectsProvider.notifier).editTopic(
                                              topicId: currentTopic.id,
                                              title: titleCtrl.text.trim(),
                                              content: contentCtrl.text.trim(),
                                              homework: homeworkCtrl.text.trim(),
                                            );
                                        if (context.mounted) {
                                          Navigator.pop(ctx);
                                          HapticUtils.medium();
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: const Text('✅ Tema üstünlikli üýtgedildi!'),
                                              backgroundColor: const Color(0xFF059669),
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
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Topic currentTopic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Temany pozmak'),
        content: Text(
          '"${currentTopic.title}" temasyny pozmak isleýärsiňizmi? Bu amal yza gaýtaryp bolmaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Ýok'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(subjectsProvider.notifier).deleteTopic(currentTopic.id);
              Navigator.pop(ctx);
              Navigator.pop(context);
              HapticUtils.medium();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🗑️ Tema pozuldy!'),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Hawa, poz'),
          ),
        ],
      ),
    );
  }


  /// Builds a full-width image thumbnail for image attachments in the detail screen.
  Widget _buildImageThumbnail(TopicAttachment att, BuildContext context, String topicTitle) {
    final raw = att.urlOrData.trim();
    Widget imgWidget;
    if (raw.startsWith('data:image') && raw.contains('base64,')) {
      try {
        final bytes = base64Decode(raw.split('base64,').last);
        imgWidget = Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: 200,
            errorBuilder: (context, error, stackTrace) => _imgError());
      } catch (_) {
        imgWidget = _imgError();
      }
    } else if (raw.startsWith('http://') || raw.startsWith('https://')) {
      imgWidget = Image.network(raw, fit: BoxFit.cover, width: double.infinity, height: 200,
          loadingBuilder: (ctx, child, progress) {
            if (progress == null) return child;
            return SizedBox(height: 200, child: Center(child: CircularProgressIndicator(
                value: progress.expectedTotalBytes != null
                    ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes! : null)));
          },
          errorBuilder: (context, error, stackTrace) => _imgError());
    } else {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () {
        HapticUtils.light();
        Navigator.push(context, MaterialPageRoute(
            builder: (ctx) => AttachmentViewerScreen(attachment: att, topicTitle: topicTitle)));
      },
      child: Stack(children: [
        imgWidget,
        Positioned(bottom: 8, right: 8,
            child: Container(padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.fullscreen_rounded, color: Colors.white, size: 18))),
      ]),
    );
  }

  Widget _imgError() => Container(height: 100, color: const Color(0xFF1E293B),
      child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white30, size: 40)));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final authState = ref.watch(authProvider);
    final canManage = authState.canManageTopics;
    final state = ref.watch(subjectsProvider);

    // Live updated topic from state
    final liveTopic = state.topics.firstWhere(
      (t) => t.id == topic.id,
      orElse: () => topic,
    );

    return Scaffold(
      backgroundColor: cs.surface,
      appBar: AppBar(
        title: Text(
          liveTopic.subjectName.isNotEmpty ? liveTopic.subjectName : 'Tema Jikme-jigi',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (canManage) ...[
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Colors.blue),
              tooltip: 'Temany üýtget',
              onPressed: () {
                HapticUtils.light();
                _showEditDialog(context, ref, liveTopic);
              },
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              tooltip: 'Temany poz',
              onPressed: () {
                HapticUtils.light();
                _confirmDelete(context, ref, liveTopic);
              },
            ),
          ],
          IconButton(
            icon: const Icon(Icons.copy_rounded),
            tooltip: 'Teksti göçürip al',
            onPressed: () {
              HapticUtils.light();
              final fullText = '''
${liveTopic.title} (${liveTopic.subjectName})
Sene: ${liveTopic.date} | Goşan: ${liveTopic.createdBy}

${liveTopic.content}

${liveTopic.hasHomework ? 'Öý işi:\n${liveTopic.homework}' : ''}
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
                    liveTopic.subjectCode.isNotEmpty ? liveTopic.subjectCode : 'DERS',
                    style: tt.labelMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: cs.onPrimaryContainer,
                    ),
                  ),
                ),
                const Gap(10),
                if (liveTopic.subjectName.isNotEmpty)
                  Expanded(
                    child: Text(
                      liveTopic.subjectName,
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
                    liveTopic.date,
                    style: tt.bodySmall?.copyWith(fontSize: 12),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Title
            SelectableText(
              liveTopic.title,
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
                  'Goşan: ${liveTopic.createdBy}',
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
              liveTopic.content.isNotEmpty
                  ? liveTopic.content
                  : 'Bu tema üçin giňişleýin konspekt ýazylmandyr.',
              style: tt.bodyLarge?.copyWith(
                height: 1.6,
                letterSpacing: 0.2,
                color: cs.onSurface,
              ),
            ),

            // ── Attachments Section (PDF, PPTX, Images) ──
            if (liveTopic.hasAttachments) ...[
              const Gap(24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.folder_special_rounded, color: cs.primary, size: 20),
                      const Gap(8),
                      Text(
                        'Ders Faýllary & Slaýdlar',
                        style: tt.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withAlpha(38),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                        Gap(4),
                        Text(
                          'Awto-taýyn',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF059669),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
               const Gap(10),
              Column(
                children: liveTopic.attachments.map((att) {
                  final isPptx = att.isPptx;
                  final isPdf = att.isPdf;
                  final isImg = att.isImage;
                  final itemColor = isPptx
                      ? const Color(0xFFEA580C)
                      : isPdf
                          ? const Color(0xFFDC2626)
                          : const Color(0xFF059669);
                  final itemIcon = isPptx
                      ? Icons.slideshow_rounded
                      : isPdf
                          ? Icons.picture_as_pdf_rounded
                          : Icons.image_rounded;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: cs.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: itemColor.withAlpha(64), width: 1.2),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () {
                        HapticUtils.light();
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (ctx) => AttachmentViewerScreen(
                              attachment: att,
                              topicTitle: liveTopic.title,
                            ),
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── Inline image thumbnail ──────────────────────
                          if (isImg) _buildImageThumbnail(att, context, liveTopic.title),

                          // ── File info row ────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                if (!isImg)
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: itemColor.withAlpha(30),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(itemIcon, color: itemColor, size: 28),
                                  ),
                                if (!isImg) const Gap(14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        att.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const Gap(4),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: itemColor.withAlpha(25),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              att.type.toUpperCase(),
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: itemColor,
                                              ),
                                            ),
                                          ),
                                          const Gap(6),
                                          Text(
                                            '• ${att.size}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: cs.onSurfaceVariant,
                                            ),
                                          ),
                                          if (att.pageCount > 1) ...[
                                            const Gap(6),
                                            Text(
                                              '• ${att.pageCount} sahypa',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: cs.onSurfaceVariant,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isImg) ...[
                                  const Gap(8),
                                  FilledButton.tonal(
                                    style: FilledButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onPressed: () {
                                      HapticUtils.light();
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (ctx) => AttachmentViewerScreen(
                                            attachment: att,
                                            topicTitle: liveTopic.title,
                                          ),
                                        ),
                                      );
                                    },
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text('Aç'),
                                        Gap(4),
                                        Icon(Icons.arrow_forward_rounded, size: 14),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  Icon(
                                    Icons.zoom_in_rounded,
                                    color: itemColor,
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),

            ],

            // Homework section (if present)
            if (liveTopic.hasHomework) ...[
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
                      liveTopic.homework,
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

            // Prominent Management Action Card (Starşy & Döwletgulyýew)
            if (canManage) ...[
              const Gap(36),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: cs.outlineVariant.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Temany Dolandyrmak',
                      style: tt.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded, color: Colors.blue),
                            label: const Text('Üýtget'),
                            onPressed: () {
                              HapticUtils.light();
                              _showEditDialog(context, ref, liveTopic);
                            },
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.red.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.delete_outline_rounded),
                            label: const Text('Poz'),
                            onPressed: () {
                              HapticUtils.light();
                              _confirmDelete(context, ref, liveTopic);
                            },
                          ),
                        ),
                      ],
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

