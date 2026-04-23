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
    final background = glass
        ? Colors.white.withValues(alpha: 0.07)
        : cs.surfaceContainerLowest.withValues(alpha: 0.92);

    Widget card = Container(
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(MfRadius.lg),
        boxShadow: [
          if (glass)
            BoxShadow(
              color: MfPalette.accentSoftPurple.withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          BoxShadow(
            color: cs.shadow.withValues(alpha: glass ? 0.14 : 0.08),
            blurRadius: glass ? 22 : 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: cs.shadow.withValues(alpha: glass ? 0.07 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(MfRadius.lg),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: glass ? 8 : 0,
            sigmaY: glass ? 8 : 0,
          ),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(MfRadius.lg),
              border: Border.all(
                color: glass
                    ? Colors.white.withValues(alpha: 0.16)
                    : cs.outlineVariant.withValues(alpha: 0.08),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: glass ? 0.06 : 0.08),
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
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
