import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/core/constants/app_constants.dart';
import 'package:topar_115/core/utils/haptic_utils.dart';
import 'package:topar_115/features/announcements/data/repositories/announcement_repository.dart';
import 'package:topar_115/features/announcements/presentation/controllers/sms_dispatcher_controller.dart';
import 'package:topar_115/features/announcements/presentation/widgets/dispatch_progress_modal.dart';
import 'package:topar_115/features/announcements/presentation/widgets/dispatch_summary_sheet.dart';
import 'package:topar_115/features/announcements/presentation/widgets/recipient_list_tile.dart';
import 'package:topar_115/features/announcements/presentation/widgets/sms_metrics_card.dart';

/// The primary screen for composing and dispatching offline GSM SMS alerts.
///
/// Layout (top → bottom):
///   • Gradient SliverAppBar with "Fifteen 🎓" + offline GSM badge.
///   • Compose card — [TextField] + live char counter.
///   • SMS metrics row — characters / SMS parts / total SMS.
///   • Sticky selection header — "Select All" chip + count badge.
///   • Scrollable [RecipientListTile] list (25 students).
/// Dispatch channel options: Alwaysdata Cloud, native GSM SMS, or Dual.
enum DispatchMode {
  online,
  sms,
  dual,
}

/// The primary screen for composing and dispatching offline GSM SMS alerts & online Alwaysdata notices.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();
  bool _dialogOpen = false;
  DispatchMode _dispatchMode = DispatchMode.online;
  bool _isUrgent = false;
  bool _isPostingOnline = false;

  @override
  void initState() {
    super.initState();
    _msgCtrl.addListener(() {
      ref.read(smsDispatcherProvider.notifier).updateMessage(_msgCtrl.text);
    });
  }

  @override
  void dispose() {
    _msgCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Dispatch Handler ──────────────────────────────────────────────────────

  Future<void> _handleDispatch() async {
    final message = _msgCtrl.text.trim();
    if (message.isEmpty) return;

    // ── Mode 1: Online Only (Alwaysdata Cloud Server) ──────────────────────
    if (_dispatchMode == DispatchMode.online) {
      setState(() => _isPostingOnline = true);
      HapticUtils.medium();

      final selectedCount = ref.read(smsDispatcherProvider).selectedIds.length;
      final count = selectedCount == 0 ? 25 : selectedCount;

      final success = await ref
          .read(announcementProvider.notifier)
          .sendOnlineAnnouncement(
            content: message,
            isUrgent: _isUrgent,
            recipientCount: count,
          );

      setState(() => _isPostingOnline = false);

      if (mounted) {
        _msgCtrl.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                  color: Colors.white,
                ),
                const Gap(10),
                Expanded(
                  child: Text(
                    success
                        ? '🌐 Duýduryş onlaýn serwere ugradyldy! Talyplar derrew görer.'
                        : '⚠️ Serwere ugradylmady, emma ýerli ýatda saklandy.',
                  ),
                ),
              ],
            ),
            backgroundColor:
                success ? const Color(0xFF059669) : Colors.orange.shade800,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    // ── Mode 2: Dual Mode (Post Online + SMS Dispatch) ───────────────────────
    if (_dispatchMode == DispatchMode.dual) {
      final selectedCount = ref.read(smsDispatcherProvider).selectedIds.length;
      final count = selectedCount == 0 ? 25 : selectedCount;

      // Asynchronously post to Alwaysdata in the background
      ref.read(announcementProvider.notifier).sendOnlineAnnouncement(
            content: message,
            isUrgent: _isUrgent,
            recipientCount: count,
          );
    }

    // ── SMS Dispatch Loop ───────────────────────────────────────────────────
    if (_dialogOpen) return;
    _dialogOpen = true;
    await ref.read(smsDispatcherProvider.notifier).dispatch();
  }

  // ── Main Build ────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(smsDispatcherProvider);

    // ── State listener: drive modal + sheet ──────────────────────────────
    ref.listen<SmsDispatcherState>(smsDispatcherProvider, (prev, next) async {
      // Show progress dialog when dispatch starts.
      if (next.status is DispatchSending &&
          prev?.status is! DispatchSending &&
          !_dialogOpen) {
        _dialogOpen = true;
        showDispatchProgressDialog(context);
      }

      // Dismiss dialog + show summary when done.
      if (next.status is DispatchDone && prev?.status is! DispatchDone) {
        _dialogOpen = false;
        final result = next.status as DispatchDone;
        if (_msgCtrl.text.trim().isNotEmpty) {
          ref.read(announcementProvider.notifier).addAnnouncement(
                content: _msgCtrl.text.trim(),
                recipientCount: result.sentCount,
              );
          _msgCtrl.clear();
        }
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
          await Future.delayed(const Duration(milliseconds: 200));
          if (context.mounted) {
            await showDispatchSummarySheet(
              context,
              result: result,
              onDismiss: () {
                Navigator.of(context).pop();
                ref.read(smsDispatcherProvider.notifier).resetToIdle();
              },
            );
          }
        }
      }

      // Permission denied snackbar.
      if (next.status is DispatchPermissionDenied &&
          prev?.status is! DispatchPermissionDenied) {
        _dialogOpen = false;
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                '⚠️  SMS permission denied. Please allow it in Settings.',
              ),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              action: SnackBarAction(
                label: 'Settings',
                onPressed: () {
                  // TODO: openAppSettings() from permission_handler
                },
              ),
            ),
          );
          ref.read(smsDispatcherProvider.notifier).resetToIdle();
        }
      }
    });

    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, innerBoxIsScrolled) => [
          // ── Gradient AppBar ──────────────────────────────────────────────
          _buildAppBar(context, innerBoxIsScrolled),

          // ── Compose Card ─────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildComposeCard(context, state)),

          // ── Metrics Row ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: SmsMetricsCard(
                charCount: state.charCount,
                smsParts: state.smsParts,
                totalSmsCount: state.totalSmsCount,
                selectedCount: state.selectedIds.length,
              ),
            ),
          ),

          // ── Search Card ──────────────────────────────────────────────────
          SliverToBoxAdapter(child: _buildSearchCard(context, state)),

          // ── Sticky Selection Header ───────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _SelectionHeaderDelegate(state: state, ref: ref),
          ),
        ],
        body: _buildStudentList(context, state),
      ),
      floatingActionButton: _buildDispatchButton(context, state),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  // ── App Bar ───────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar(BuildContext context, bool collapsed) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return SliverAppBar(
      expandedHeight: 130,
      pinned: true,
      stretch: true,
      elevation: 0,
      backgroundColor: cs.primary,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        titlePadding: const EdgeInsets.only(left: 16, bottom: 14, right: 16),
        title: AnimatedOpacity(
          opacity: collapsed ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 200),
          child: Text(
            'Kursdaşlar 🎓',
            style: tt.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                cs.primary,
                cs.tertiary,
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Text(
                        'Kursdaşlar ',
                        style: tt.headlineMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                      const Text('🎓', style: TextStyle(fontSize: 26)),
                    ],
                  ),
                  const Gap(6),
                  Row(
                    children: [
                      Text(
                        AppConstants.className,
                        style: tt.bodySmall?.copyWith(
                          color: Colors.white.withAlpha(200),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(10),
                      const _ServerStatusBadge(),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Compose Card ──────────────────────────────────────────────────────────

  Widget _buildComposeCard(BuildContext context, SmsDispatcherState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final over160 = state.charCount > AppConstants.smsMaxSinglePart;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withAlpha(15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Label row
              Row(
                children: [
                  Icon(Icons.edit_note_rounded,
                      size: 18, color: cs.primary),
                  const Gap(6),
                  Text(
                    'Habar ýazmak',
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const Gap(10),

              // Text field
              TextField(
                controller: _msgCtrl,
                minLines: 3,
                maxLines: 6,
                textCapitalization: TextCapitalization.sentences,
                style: tt.bodyMedium,
                decoration: InputDecoration(
                  hintText:
                      'Habaryňyzy şu ýere ýazyň…',
                  hintStyle: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withAlpha(140),
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  filled: false,
                ),
              ),
              const Gap(8),

              // Char counter row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Parts pill
                  if (state.smsParts > 1)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: cs.errorContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${state.smsParts} parts',
                        style: tt.labelSmall?.copyWith(
                          color: cs.onErrorContainer,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  // Char count
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: (tt.labelMedium ?? const TextStyle()).copyWith(
                      color: over160 ? cs.error : cs.onSurfaceVariant,
                      fontWeight:
                          over160 ? FontWeight.w700 : FontWeight.w400,
                    ),
                    child: Text('${state.charCount} chars'),
                  ),
                ],
              ),
              const Gap(14),

              // Mode Selector (Internet / SMS / Dual)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: cs.surfaceContainerHighest.withAlpha(120),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    _buildModeChip(
                      mode: DispatchMode.online,
                      icon: Icons.cloud_upload_rounded,
                      label: 'Internet',
                    ),
                    _buildModeChip(
                      mode: DispatchMode.sms,
                      icon: Icons.sms_rounded,
                      label: 'SMS GSM',
                    ),
                    _buildModeChip(
                      mode: DispatchMode.dual,
                      icon: Icons.bolt_rounded,
                      label: 'Dual-Mode',
                    ),
                  ],
                ),
              ),
              const Gap(10),

              // Urgent Switch & Info Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  InkWell(
                    onTap: () {
                      HapticUtils.light();
                      setState(() => _isUrgent = !_isUrgent);
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _isUrgent
                                ? Icons.check_box_rounded
                                : Icons.check_box_outline_blank_rounded,
                            size: 18,
                            color: _isUrgent
                                ? Colors.orange.shade700
                                : cs.onSurfaceVariant,
                          ),
                          const Gap(6),
                          Text(
                            'Gyssagly duýduryş',
                            style: tt.labelMedium?.copyWith(
                              color: _isUrgent
                                  ? Colors.orange.shade700
                                  : cs.onSurfaceVariant,
                              fontWeight: _isUrgent
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_dispatchMode == DispatchMode.online)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF059669).withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.public_rounded,
                              size: 12, color: Color(0xFF059669)),
                          Gap(4),
                          Text(
                            'Onlaýn Bulut',
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModeChip({
    required DispatchMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSelected = _dispatchMode == mode;
    final cs = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticUtils.light();
          setState(() => _dispatchMode = mode);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? cs.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: cs.primary.withAlpha(40),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? Colors.white : cs.onSurfaceVariant,
              ),
              const Gap(6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? Colors.white : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Search Card ───────────────────────────────────────────────────────────

  Widget _buildSearchCard(BuildContext context, SmsDispatcherState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Container(
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cs.outlineVariant.withAlpha(60)),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withAlpha(10),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: TextField(
          controller: _searchCtrl,
          onChanged: (val) {
            ref.read(smsDispatcherProvider.notifier).updateSearchQuery(val);
          },
          style: tt.bodyMedium,
          decoration: InputDecoration(
            hintText: 'Toparadaşlary ady ýa-da nomeri boýunça gözlemek…',
            hintStyle: tt.bodyMedium?.copyWith(
              color: cs.onSurfaceVariant.withAlpha(140),
              fontSize: 14,
            ),
            prefixIcon: Icon(Icons.search_rounded, color: cs.primary, size: 22),
            suffixIcon: state.searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear_rounded, size: 18, color: cs.onSurfaceVariant),
                    onPressed: () {
                      _searchCtrl.clear();
                      ref.read(smsDispatcherProvider.notifier).updateSearchQuery('');
                    },
                  )
                : null,
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
      ),
    );
  }

  // ── Student List ──────────────────────────────────────────────────────────

  Widget _buildStudentList(BuildContext context, SmsDispatcherState state) {
    final list = state.filteredStudents;

    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off_rounded,
                size: 48,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(120),
              ),
              const Gap(12),
              Text(
                'Gözlege laýyk talyp tapylmady',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Gap(4),
              Text(
                'Nomeri ýa-da ady täzeden barlap görüň.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: list.length,
      itemBuilder: (ctx, index) {
        final student = list[index];
        return RecipientListTile(
          key: ValueKey(student.id),
          student: student,
          isSelected: state.selectedIds.contains(student.id),
          onTap: () =>
              ref.read(smsDispatcherProvider.notifier).toggleStudent(student.id),
        );
      },
    );
  }

  // ── Dispatch FAB ──────────────────────────────────────────────────────────

  Widget _buildDispatchButton(
      BuildContext context, SmsDispatcherState state) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final hasMsg = _msgCtrl.text.trim().isNotEmpty;
    final bool can;
    final IconData icon;
    final String label;

    switch (_dispatchMode) {
      case DispatchMode.online:
        can = hasMsg && !_isPostingOnline;
        icon = _isPostingOnline ? Icons.hourglass_top_rounded : Icons.cloud_upload_rounded;
        label = _isPostingOnline
            ? 'Serwere ýüklenýär…'
            : (state.selectedIds.isEmpty
                ? '🌐 Ähli talyplar üçin Internetde paýlaş'
                : '🌐 ${state.selectedIds.length} talyp üçin serwere goý');
        break;
      case DispatchMode.sms:
        can = state.canDispatch && !_isPostingOnline;
        icon = Icons.sms_rounded;
        label = can
            ? '📱 ${state.selectedIds.length} talyba SMS ugrat'
            : 'Talyplary saýlaň we hat ýazyň';
        break;
      case DispatchMode.dual:
        can = state.canDispatch && !_isPostingOnline;
        icon = Icons.bolt_rounded;
        label = can
            ? '⚡ Dual (Internet + ${state.selectedIds.length} SMS)'
            : 'Talyplary saýlaň we hat ýazyň';
        break;
    }

    return AnimatedSlide(
      offset: can ? Offset.zero : const Offset(0, 0.2),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      child: AnimatedOpacity(
        opacity: can ? 1.0 : 0.55,
        duration: const Duration(milliseconds: 300),
        child: GestureDetector(
          onTap: can ? _handleDispatch : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              gradient: can
                  ? LinearGradient(
                      colors: [cs.primary, cs.tertiary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: can ? null : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              boxShadow: can
                  ? [
                      BoxShadow(
                        color: cs.primary.withAlpha(80),
                        blurRadius: 16,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  color: can ? Colors.white : cs.onSurfaceVariant,
                  size: 20,
                ),
                const Gap(10),
                Text(
                  label,
                  style: tt.labelLarge?.copyWith(
                    color: can ? Colors.white : cs.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Server Status Badge ───────────────────────────────────────────────────────

class _ServerStatusBadge extends ConsumerWidget {
  const _ServerStatusBadge();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(announcementSyncStatusProvider);

    Color dotColor;
    String label;

    switch (status) {
      case SyncStatus.online:
        dotColor = const Color(0xFF10B981); // Bright Green
        label = 'Onlaýn Baglanan';
        break;
      case SyncStatus.syncing:
        dotColor = const Color(0xFF3B82F6); // Blue
        label = 'Täzelenýär…';
        break;
      case SyncStatus.offline:
      case SyncStatus.idle:
        dotColor = const Color(0xFFFFA726); // Amber
        label = 'GSM Offline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(35),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withAlpha(60)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const Gap(5),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky Selection Header Delegate ─────────────────────────────────────────

class _SelectionHeaderDelegate extends SliverPersistentHeaderDelegate {
  final SmsDispatcherState state;
  final WidgetRef ref;

  const _SelectionHeaderDelegate({required this.state, required this.ref});

  @override
  double get minExtent => 58;

  @override
  double get maxExtent => 58;

  @override
  bool shouldRebuild(_SelectionHeaderDelegate old) =>
      old.state.selectedIds != state.selectedIds ||
      old.state.allSelected != state.allSelected;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      color: cs.surface,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // ── Select All / None chip ────────────────────────────────────
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: state.allSelected
                  ? cs.primaryContainer
                  : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: InkWell(
              onTap: () =>
                  ref.read(smsDispatcherProvider.notifier).toggleSelectAll(),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        state.allSelected
                            ? Icons.check_box_rounded
                            : Icons.check_box_outline_blank_rounded,
                        key: ValueKey(state.allSelected),
                        size: 18,
                        color: state.allSelected
                            ? cs.primary
                            : cs.onSurfaceVariant,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      state.allSelected ? 'Unselect All' : 'Select All',
                      style: tt.labelMedium?.copyWith(
                        color: state.allSelected
                            ? cs.primary
                            : cs.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Spacer(),

          // ── Count badge ────────────────────────────────────────────────
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) =>
                ScaleTransition(scale: anim, child: child),
            child: Text(
              '${state.selectedIds.length} of ${state.students.length}',
              key: ValueKey(state.selectedIds.length),
              style: tt.labelMedium?.copyWith(
                color: state.selectedIds.isNotEmpty
                    ? cs.primary
                    : cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
