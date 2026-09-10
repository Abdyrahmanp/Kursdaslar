import 'package:flutter/material.dart';
import 'package:topar_115/features/announcements/data/models/student_model.dart';

/// A warm, animated list tile for a single SMS recipient.
///
/// Displays:
///   • Circular avatar with initials + HSL-based per-student colour.
///   • Full name + shortened phone number.
///   • Smooth animated checkbox with haptic feedback (handled by the controller).
///   • Subtle warm selection highlight using [AnimatedContainer].
class RecipientListTile extends StatelessWidget {
  final Student student;
  final bool isSelected;
  final VoidCallback onTap;

  const RecipientListTile({
    super.key,
    required this.student,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          color: isSelected
              ? cs.primaryContainer.withAlpha(120)
              : cs.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? cs.primary.withAlpha(80) : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20),
            splashColor: cs.primary.withAlpha(30),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  // ── Avatar ──────────────────────────────────────────────
                  _StudentAvatar(student: student, isSelected: isSelected),
                  const SizedBox(width: 12),

                  // ── Name + Phone ─────────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          student.name,
                          style: tt.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isSelected ? cs.primary : cs.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _maskPhone(student.phone),
                          style: tt.bodySmall?.copyWith(
                            color: cs.onSurfaceVariant,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // ── Animated Checkbox ────────────────────────────────────
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected ? cs.primary : Colors.transparent,
                      border: Border.all(
                        color: isSelected ? cs.primary : cs.outline,
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, size: 14, color: Colors.white)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Shows first 6 digits + *** mask for privacy in the UI.
  String _maskPhone(String phone) {
    if (phone.length <= 6) return phone;
    final visible = phone.substring(0, phone.length - 4);
    return '$visible••••';
  }
}

// ── Avatar Widget ─────────────────────────────────────────────────────────────

class _StudentAvatar extends StatelessWidget {
  final Student student;
  final bool isSelected;

  const _StudentAvatar({required this.student, required this.isSelected});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : student.avatarBg,
        boxShadow: [
          BoxShadow(
            color: student.avatarBg.withAlpha(80),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSelected
              ? const Icon(Icons.check_rounded, color: Colors.white, size: 20, key: ValueKey('check'))
              : Text(
                  student.initials,
                  key: ValueKey(student.initials),
                  style: TextStyle(
                    color: student.avatarFg,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
        ),
      ),
    );
  }
}
