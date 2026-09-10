import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/core/constants/app_constants.dart';
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
///   • Centre-docked "Send SMS Alert" FAB.
class AnnouncementsScreen extends ConsumerStatefulWidget {
  const AnnouncementsScreen({super.key});

  @override
  ConsumerState<AnnouncementsScreen> createState() =>
      _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends ConsumerState<AnnouncementsScreen> {
  final TextEditingController _msgCtrl = TextEditingController();
  bool _dialogOpen = false;

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
    super.dispose();
  }

  // ── Dispatch Handler ──────────────────────────────────────────────────────

  Future<void> _handleDispatch() async {
    if (_dialogOpen) return;
    _dialogOpen = true;
    await ref.read(smsDispatcherProvider.notifier).dispatch();
    // Note: the state listener below handles showing the modal and sheet.
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
        if (context.mounted) {
          Navigator.of(context, rootNavigator: true).maybePop();
          await Future.delayed(const Duration(milliseconds: 200));
          if (context.mounted) {
            await showDispatchSummarySheet(
              context,
              result: next.status as DispatchDone,
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
            'Fifteen 🎓',
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
                        'Fifteen ',
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
                      _OfflineBadge(),
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
                    'Duyuru / Announcement',
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
                      'Type your announcement here…\n(e.g. "Şu gün sapak 10:00-da başlayar.")',
                  hintStyle: tt.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant.withAlpha(140),
                  ),
                  border: InputBorder.none,
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
            ],
          ),
        ),
      ),
    );
  }

  // ── Student List ──────────────────────────────────────────────────────────

  Widget _buildStudentList(BuildContext context, SmsDispatcherState state) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
      itemCount: state.students.length,
      itemBuilder: (ctx, index) {
        final student = state.students[index];
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
    final can = state.canDispatch;

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
                const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
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
                  Icons.send_rounded,
                  color: can ? Colors.white : cs.onSurfaceVariant,
                  size: 20,
                ),
                const Gap(10),
                Text(
                  can
                      ? 'Send to ${state.selectedIds.length} students'
                      : 'Select recipients & type message',
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

// ── Offline Badge ─────────────────────────────────────────────────────────────

class _OfflineBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
            decoration: const BoxDecoration(
              color: Color(0xFFFFA726),
              shape: BoxShape.circle,
            ),
          ),
          const Gap(5),
          const Text(
            'GSM Offline',
            style: TextStyle(
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
