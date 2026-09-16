import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:topar_115/shared/widgets/animated_focus_container.dart';

/// Reusable modern text input component for "Kursdaşlar".
///
/// Features:
///   • Smooth outer border trace animation on focus.
///   • Multi-line / single-line mode with clear label and icon header.
///   • Generous padding (18px H / 16px V) guaranteeing 0% text overlap with focus outline.
class FifteenTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final IconData? icon;
  final int minLines;
  final int maxLines;
  final FocusNode? focusNode;
  final Widget? trailing;
  final ValueChanged<String>? onChanged;
  final String? prefixText;
  final TextInputType? keyboardType;

  const FifteenTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hintText,
    this.icon,
    this.minLines = 1,
    this.maxLines = 1,
    this.focusNode,
    this.trailing,
    this.onChanged,
    this.prefixText,
    this.keyboardType,
  });

  @override
  State<FifteenTextField> createState() => _FifteenTextFieldState();
}

class _FifteenTextFieldState extends State<FifteenTextField> {
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
  }

  @override
  void dispose() {
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return AnimatedFocusContainer(
      focusNode: _focusNode,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header row with Icon + Label
          if (widget.label.isNotEmpty) ...[
            Row(
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 18, color: cs.primary),
                  const Gap(8),
                ],
                Expanded(
                  child: Text(
                    widget.label,
                    style: tt.labelLarge?.copyWith(
                      color: cs.primary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
            const Gap(12),
          ],

          // Text Field with generous padding to prevent focus line collision
          TextField(
            controller: widget.controller,
            focusNode: _focusNode,
            minLines: widget.minLines,
            maxLines: widget.maxLines,
            onChanged: widget.onChanged,
            keyboardType: widget.keyboardType,
            textCapitalization: widget.keyboardType == TextInputType.phone
                ? TextCapitalization.none
                : TextCapitalization.sentences,
            style: tt.bodyMedium?.copyWith(
              color: cs.onSurface,
              height: 1.5,
              fontSize: 15,
            ),
            decoration: InputDecoration(
              prefixText: widget.prefixText,
              prefixStyle: tt.bodyMedium?.copyWith(
                color: cs.primary,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
              hintText: widget.hintText,
              hintStyle: tt.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant.withAlpha(140),
                height: 1.5,
                fontSize: 15,
              ),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              errorBorder: InputBorder.none,
              focusedErrorBorder: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
              isDense: false,
              filled: false,
            ),
          ),
        ],
      ),
    );
  }
}
