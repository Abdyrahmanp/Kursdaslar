import 'package:flutter/material.dart';
import 'package:topar_115/shared/widgets/fifteen_scaffold.dart';

export 'package:topar_115/shared/widgets/fifteen_scaffold.dart' show activeTabProvider;

/// Normal Student View Scaffold — unified with [FifteenScaffold] for consistent
/// horizontal swipe navigation and rich role-based features.
class NormalStudentScreen extends StatelessWidget {
  const NormalStudentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const FifteenScaffold();
  }
}
