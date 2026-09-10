import 'package:flutter/material.dart';
import 'package:topar_115/app/theme/app_colors.dart';

/// Immutable data model for a class member / SMS recipient.
@immutable
class Student {
  final String id;

  /// Full name in Turkmen format: "FirstName LastName".
  final String name;

  /// Phone number in E.164 format: "+993XXXXXXXX".
  final String phone;

  /// Whether this student holds the Group Leader (Starstwa) role.
  final bool isGroupLeader;

  /// Index within the class list — used for avatar color cycling.
  final int index;

  const Student({
    required this.id,
    required this.name,
    required this.phone,
    required this.index,
    this.isGroupLeader = false,
  });

  // ── Computed Properties ─────────────────────────────────────────────────

  /// Two-letter initials derived from name parts.
  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }

  /// Abbreviated display name: "FirstName L." — for compact list display.
  String get shortName {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0]} ${parts[1][0]}.';
    }
    return name;
  }

  /// Avatar background colour (cycling warm palette based on [index]).
  Color get avatarBg => AppColors.avatarBg(index);

  /// Avatar foreground (initials text) colour.
  Color get avatarFg => AppColors.avatarFg(index);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Student && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Student($id, $name)';
}
