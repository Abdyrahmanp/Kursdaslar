import 'package:flutter/material.dart';
import 'package:topar_115/core/constants/app_constants.dart';

/// Displays three live-updated metric chips: char count, SMS parts, total SMS.
///
/// All values animate with [AnimatedSwitcher] so transitions feel snappy and
/// responsive as the user types in the compose field.
class SmsMetricsCard extends StatelessWidget {
  final int charCount;
  final int smsParts;
  final int totalSmsCount;
  final int selectedCount;

  const SmsMetricsCard({
    super.key,
    required this.charCount,
    required this.smsParts,
    required this.totalSmsCount,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: cs.surfaceContainerLow,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            Expanded(
              child: _MetricChip(
                icon: Icons.text_fields_rounded,
                label: 'Characters',
                valueWidget: _AnimatedValue(
                  value: '$charCount / ${AppConstants.smsMaxSinglePart}',
                ),
                accent: _charColor(charCount, cs),
                context: context,
              ),
            ),
            _Divider(),
            Expanded(
              child: _MetricChip(
                icon: Icons.message_outlined,
                label: 'SMS / person',
                valueWidget: _AnimatedValue(value: smsParts.toString()),
                accent: smsParts > 1 ? cs.error : cs.tertiary,
                context: context,
              ),
            ),
            _Divider(),
            Expanded(
              child: _MetricChip(
                icon: Icons.send_rounded,
                label: 'Total SMS',
                valueWidget: _AnimatedValue(value: totalSmsCount.toString()),
                accent: cs.primary,
                context: context,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _charColor(int count, ColorScheme cs) {
    if (count == 0) return cs.onSurfaceVariant;
    if (count > AppConstants.smsMaxSinglePart) return cs.error;
    if (count > 120) return cs.tertiary;
    return cs.primary;
  }
}

// ── Individual Metric Chip ────────────────────────────────────────────────────

class _MetricChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget valueWidget;
  final Color accent;
  final BuildContext context;

  const _MetricChip({
    required this.icon,
    required this.label,
    required this.valueWidget,
    required this.accent,
    required this.context,
  });

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: accent),
          const SizedBox(height: 4),
          DefaultTextStyle(
            style: tt.titleSmall!.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
            child: valueWidget,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _AnimatedValue extends StatelessWidget {
  final String value;
  const _AnimatedValue({required this.value});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) => ScaleTransition(
        scale: animation,
        child: FadeTransition(opacity: animation, child: child),
      ),
      child: Text(value, key: ValueKey(value), textAlign: TextAlign.center),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 40,
      color: Theme.of(context).colorScheme.outlineVariant,
    );
  }
}
