import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/money_flow_tokens.dart';

enum AppButtonVariant { primary, secondary, ghost }

class AppButton extends StatefulWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.loading = false,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool loading;
  final bool expand;

  @override
  State<AppButton> createState() => _AppButtonState();
}

class _AppButtonState extends State<AppButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MfMotion.fast,
      reverseDuration: MfMotion.fast,
    );
    _scale = Tween<double>(
      begin: 1,
      end: 0.98,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final disabled = widget.onPressed == null || widget.loading;

    return ScaleTransition(
      scale: _scale,
      child: AnimatedOpacity(
        duration: MfMotion.fast,
        opacity: disabled ? 0.55 : 1,
        child: _ButtonFrame(
          variant: widget.variant,
          expand: widget.expand,
          onTap: disabled ? null : widget.onPressed,
          onTapDown: () => _controller.forward(),
          onTapEnd: () => _controller.reverse(),
          child: widget.loading
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: switch (widget.variant) {
                      AppButtonVariant.primary => cs.onPrimary,
                      AppButtonVariant.secondary => cs.primary,
                      AppButtonVariant.ghost => cs.onSurface,
                    },
                  ),
                )
              : Row(
                  mainAxisSize:
                      widget.expand ? MainAxisSize.max : MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.icon != null) ...[
                      Icon(
                        widget.icon,
                        size: 18,
                        color: switch (widget.variant) {
                          AppButtonVariant.primary => cs.onPrimary,
                          AppButtonVariant.secondary => cs.primary,
                          AppButtonVariant.ghost => cs.onSurface,
                        },
                      ),
                      const SizedBox(width: MfSpace.sm),
                    ],
                    Text(
                      widget.label,
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: switch (widget.variant) {
                          AppButtonVariant.primary => cs.onPrimary,
                          AppButtonVariant.secondary => cs.primary,
                          AppButtonVariant.ghost => cs.onSurface,
                        },
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _ButtonFrame extends StatelessWidget {
  const _ButtonFrame({
    required this.variant,
    required this.expand,
    required this.onTap,
    required this.onTapDown,
    required this.onTapEnd,
    required this.child,
  });

  final AppButtonVariant variant;
  final bool expand;
  final VoidCallback? onTap;
  final VoidCallback onTapDown;
  final VoidCallback onTapEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final decoration = switch (variant) {
      AppButtonVariant.primary => BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [MfPalette.heroStart, MfPalette.heroMid, MfPalette.heroEnd],
          ),
          boxShadow: [
            BoxShadow(
              color: cs.primary.withValues(alpha: 0.2),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
      AppButtonVariant.secondary => BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surfaceContainerLowest.withValues(alpha: 0.76),
          border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.18)),
        ),
      AppButtonVariant.ghost => BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: cs.surfaceContainerLow.withValues(alpha: 0.62),
        ),
    };

    return SizedBox(
      width: expand ? double.infinity : null,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onTapDown: (_) => onTapDown(),
          onTapUp: (_) => onTapEnd(),
          onTapCancel: onTapEnd,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            decoration: decoration,
            child: Container(
              constraints: BoxConstraints(
                minHeight: variant == AppButtonVariant.ghost ? 48 : 54,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: MfSpace.lg,
                vertical: MfSpace.md,
              ),
              alignment: Alignment.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
