import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/money_flow_tokens.dart';

/// Premium card: soft glass, layered highlights, optional tap state.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(MfSpace.lg),
    this.onTap,
    this.glass = true,
    this.margin = EdgeInsets.zero,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool glass;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final background = cs.surfaceContainerHigh;

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(MfRadius.md),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: MfShadow.card,
      ),
      child: Padding(padding: padding, child: child),
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(MfRadius.lg),
          splashColor: cs.primary.withValues(alpha: 0.06),
          highlightColor: Colors.transparent,
          child: card,
        ),
      );
    }

    return card;
  }
}
