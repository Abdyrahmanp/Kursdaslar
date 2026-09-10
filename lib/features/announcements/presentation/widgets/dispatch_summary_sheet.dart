import 'package:flutter/material.dart';
import 'package:topar_115/features/announcements/presentation/controllers/sms_dispatcher_controller.dart';

/// Celebratory bottom sheet displayed after the SMS batch dispatch completes.
///
/// Shows:
///   • Animated checkmark (custom Flutter animation — no external Lottie file).
///   • Sent / Failed counts with clear iconography.
///   • List of failed recipients (if any) in a scrollable chip row.
///   • A warm "Done" action button that resets the dispatcher to idle.
class DispatchSummarySheet extends StatefulWidget {
  final DispatchDone result;
  final VoidCallback onDismiss;

  const DispatchSummarySheet({
    super.key,
    required this.result,
    required this.onDismiss,
  });

  @override
  State<DispatchSummarySheet> createState() => _DispatchSummarySheetState();
}

class _DispatchSummarySheetState extends State<DispatchSummarySheet>
    with SingleTickerProviderStateMixin {
  late final AnimationController _iconController;
  late final Animation<double> _iconScale;
  late final Animation<double> _iconOpacity;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _iconScale = CurvedAnimation(
      parent: _iconController,
      curve: Curves.elasticOut,
    );
    _iconOpacity = CurvedAnimation(
      parent: _iconController,
      curve: const Interval(0, 0.5, curve: Curves.easeIn),
    );
    // Kick off icon entrance after a short delay.
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _iconController.forward();
    });
  }

  @override
  void dispose() {
    _iconController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final result = widget.result;

    final bool allSuccess = result.allSuccess;
    final Color accentColor = allSuccess ? const Color(0xFF4CAF50) : cs.error;
    final IconData accentIcon =
        allSuccess ? Icons.check_circle_rounded : Icons.warning_rounded;
    final String headline = allSuccess ? 'All messages sent! 🎉' : 'Dispatch complete';
    final String subline = allSuccess
        ? '${result.sentCount} students notified via GSM SMS.'
        : '${result.sentCount} sent · ${result.failedCount} failed';

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 8,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 36,
            height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withAlpha(60),
              borderRadius: BorderRadius.circular(4),
            ),
          ),

          // ── Animated Icon ───────────────────────────────────────────────
          FadeTransition(
            opacity: _iconOpacity,
            child: ScaleTransition(
              scale: _iconScale,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accentColor.withAlpha(25),
                ),
                child: Icon(accentIcon, size: 44, color: accentColor),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Headline ────────────────────────────────────────────────────
          Text(
            headline,
            style: tt.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subline,
            style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),

          // ── Stats Row ───────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatBadge(
                icon: Icons.check_rounded,
                label: 'Sent',
                value: result.sentCount.toString(),
                color: const Color(0xFF4CAF50),
              ),
              if (result.failedCount > 0) ...[
                const SizedBox(width: 16),
                _StatBadge(
                  icon: Icons.close_rounded,
                  label: 'Failed',
                  value: result.failedCount.toString(),
                  color: cs.error,
                ),
              ],
            ],
          ),

          // ── Failed Names ────────────────────────────────────────────────
          if (result.failedNames.isNotEmpty) ...[
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Could not reach:',
                style: tt.labelMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: result.failedNames.map((name) {
                return Chip(
                  label: Text(name),
                  avatar: Icon(Icons.person_off_outlined, size: 16, color: cs.error),
                  backgroundColor: cs.errorContainer.withAlpha(80),
                  labelStyle: tt.labelSmall?.copyWith(color: cs.onErrorContainer),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 28),

          // ── Done Button ─────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: widget.onDismiss,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Done'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                backgroundColor: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Badge ────────────────────────────────────────────────────────────────

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}

// ── Helper: Show the sheet ────────────────────────────────────────────────────

Future<void> showDispatchSummarySheet(
  BuildContext context, {
  required DispatchDone result,
  required VoidCallback onDismiss,
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => DispatchSummarySheet(
      result: result,
      onDismiss: onDismiss,
    ),
  );
}
