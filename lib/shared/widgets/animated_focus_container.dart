import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A premium, micro-animated container that wraps input fields and textareas.
///
/// Fixes focus border UX issues by providing:
///   1. Smooth path-tracing outer border drawing animation on focus (0% -> 100% path coverage).
///   2. Soft outer glow elevation on focus.
///   3. Perfect alignment that never overlaps, intersects, or cuts across interior text.
class AnimatedFocusContainer extends StatefulWidget {
  final Widget child;
  final FocusNode? focusNode;
  final BorderRadius borderRadius;
  final Color? focusColor;
  final Color? unfocusedBorderColor;
  final Color? backgroundColor;
  final double strokeWidth;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const AnimatedFocusContainer({
    super.key,
    required this.child,
    this.focusNode,
    this.borderRadius = const BorderRadius.all(Radius.circular(24)),
    this.focusColor,
    this.unfocusedBorderColor,
    this.backgroundColor,
    this.strokeWidth = 2.0,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  @override
  State<AnimatedFocusContainer> createState() => _AnimatedFocusContainerState();
}

class _AnimatedFocusContainerState extends State<AnimatedFocusContainer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animProgress;
  FocusNode? _internalFocusNode;

  FocusNode get _effectiveFocusNode =>
      widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _animProgress = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _effectiveFocusNode.addListener(_onFocusChange);

    // Initial state check
    if (_effectiveFocusNode.hasFocus) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(AnimatedFocusContainer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      oldWidget.focusNode?.removeListener(_onFocusChange);
      _effectiveFocusNode.addListener(_onFocusChange);
    }
  }

  @override
  void dispose() {
    _effectiveFocusNode.removeListener(_onFocusChange);
    _internalFocusNode?.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_effectiveFocusNode.hasFocus) {
      HapticFeedback.selectionClick();
      _controller.forward();
    } else {
      _controller.reverse();
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final primaryColor = widget.focusColor ?? cs.primary;
    final tertiaryColor = cs.tertiary;
    final restingBorderColor =
        widget.unfocusedBorderColor ?? cs.outlineVariant.withAlpha(100);
    final bgColor = widget.backgroundColor ?? cs.surfaceContainerLow;

    return AnimatedBuilder(
      animation: _animProgress,
      builder: (context, child) {
        final progress = _animProgress.value;

        return GestureDetector(
          onTap: () {
            if (!_effectiveFocusNode.hasFocus) {
              _effectiveFocusNode.requestFocus();
            }
            widget.onTap?.call();
          },
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: widget.borderRadius,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withAlpha((25 * progress).round() + 10),
                  blurRadius: 12 + (8 * progress),
                  spreadRadius: 1 * progress,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CustomPaint(
              foregroundPainter: _SmoothFocusBorderPainter(
                progress: progress,
                borderRadius: widget.borderRadius,
                strokeWidth: widget.strokeWidth,
                focusedPrimaryColor: primaryColor,
                focusedTertiaryColor: tertiaryColor,
                unfocusedBorderColor: restingBorderColor,
              ),
              child: Padding(
                padding: widget.padding,
                child: widget.child,
              ),
            ),
          ),
        );
      },
    );
  }
}

/// CustomPainter that draws a perfectly aligned, animated path-tracing border
/// around the outer edge of the input container.
class _SmoothFocusBorderPainter extends CustomPainter {
  final double progress;
  final BorderRadius borderRadius;
  final double strokeWidth;
  final Color focusedPrimaryColor;
  final Color focusedTertiaryColor;
  final Color unfocusedBorderColor;

  _SmoothFocusBorderPainter({
    required this.progress,
    required this.borderRadius,
    required this.strokeWidth,
    required this.focusedPrimaryColor,
    required this.focusedTertiaryColor,
    required this.unfocusedBorderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final halfStroke = strokeWidth / 2;

    // Deflate the rect slightly by half the stroke width so that the border
    // stroke stays strictly contained inside the painted bounds without clipping
    // or extending outside.
    final insetRect = rect.deflate(halfStroke);
    final rrect = borderRadius.toRRect(insetRect);

    // 1. Draw subtle unfocused background border
    final baseAlpha = (unfocusedBorderColor.a * 255).round();
    final restingPaint = Paint()
      ..color = unfocusedBorderColor.withAlpha(((1.0 - progress) * baseAlpha).round())
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(rrect, restingPaint);

    if (progress <= 0.001) return;

    // 2. Build full rounded rectangle path
    final path = Path()..addRRect(rrect);

    // 3. Compute animated path tracing (0 -> 100% perimeter)
    final metrics = path.computeMetrics();
    final activePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Use a rich gradient along the active focused border stroke
    final Shader gradientShader = LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        focusedPrimaryColor,
        focusedTertiaryColor,
      ],
    ).createShader(rect);

    activePaint.shader = gradientShader;

    for (final metric in metrics) {
      final extractLength = metric.length * progress;
      final extractPath = metric.extractPath(0, extractLength);
      canvas.drawPath(extractPath, activePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _SmoothFocusBorderPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.focusedPrimaryColor != focusedPrimaryColor ||
        oldDelegate.focusedTertiaryColor != focusedTertiaryColor ||
        oldDelegate.unfocusedBorderColor != unfocusedBorderColor;
  }
}
