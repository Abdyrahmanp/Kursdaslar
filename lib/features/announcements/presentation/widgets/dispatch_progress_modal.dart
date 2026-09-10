import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:topar_115/features/announcements/presentation/controllers/sms_dispatcher_controller.dart';

/// Shows a blurred backdrop dialog with an animated progress bar while
/// the batch SMS dispatch is in progress.
///
/// This widget is shown imperatively via [showDispatchProgressDialog] and
/// watches [smsDispatcherProvider] to auto-reflect progress updates
/// without requiring explicit state passing.
class DispatchProgressModal extends ConsumerWidget {
  const DispatchProgressModal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(
      smsDispatcherProvider.select((s) => s.status),
    );

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final sending = status is DispatchSending ? status : null;
    final progress = sending?.progress ?? 0.0;
    final current = sending?.current ?? 0;
    final total = sending?.total ?? 0;
    final name = sending?.currentStudentName ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(40),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Animated Icon ───────────────────────────────────────────────
            _PulsingIcon(color: cs.primary),
            const SizedBox(height: 24),

            // ── Title ────────────────────────────────────────────────────────
            Text(
              'Sending SMS...',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),

            // ── Current Recipient ─────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Text(
                name.isEmpty ? 'Preparing...' : '📱  $name',
                key: ValueKey(name),
                style: tt.bodyMedium?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 20),

            // ── Progress Bar ──────────────────────────────────────────────────
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: value,
                        minHeight: 10,
                        backgroundColor: cs.surfaceContainerHighest,
                        valueColor: AlwaysStoppedAnimation<Color>(cs.primary),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$current / $total sent',
                      style: tt.labelMedium?.copyWith(
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),

            // ── Subtle cancel note ────────────────────────────────────────────
            Text(
              'Please keep the app open…',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pulsing Icon Animation ────────────────────────────────────────────────────

class _PulsingIcon extends StatefulWidget {
  final Color color;
  const _PulsingIcon({required this.color});

  @override
  State<_PulsingIcon> createState() => _PulsingIconState();
}

class _PulsingIconState extends State<_PulsingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.color.withAlpha(25),
        ),
        child: Icon(Icons.sms_rounded, size: 36, color: widget.color),
      ),
    );
  }
}

// ── Helper: Show the dialog ───────────────────────────────────────────────────

/// Imperatively shows the dispatch progress dialog.
///
/// The dialog auto-dismisses when [smsDispatcherProvider] transitions to
/// [DispatchDone] — the caller listens for that in [AnnouncementsScreen].
Future<void> showDispatchProgressDialog(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    barrierColor: Colors.black54,
    builder: (_) => const DispatchProgressModal(),
  );
}
