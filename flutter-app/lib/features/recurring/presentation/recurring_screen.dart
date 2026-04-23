import 'package:flutter/material.dart';
import 'recurring_list_screen.dart';

/// Backward-compatible entry point used by existing navigation links.
class RecurringScreen extends StatelessWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context) => const RecurringListScreen();
}
