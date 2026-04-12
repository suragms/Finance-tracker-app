import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/money_flow_tokens.dart';

/// Dark, minimal send-money flow: recipient, large amount, custom keypad, lime CTA.
class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

// Screen-specific palette (dark canvas + lime accent).
const Color _kCanvas = Color(0xFF0A0A0C);
const Color _kElevated = Color(0xFF141418);
const Color _kKeyFill = Color(0xFF1C1C22);
const Color _kKeyBorder = Color(0xFF2A2A32);

class _Recipient {
  const _Recipient({
    required this.id,
    required this.name,
    required this.detail,
    required this.avatarColor,
  });

  final String id;
  final String name;
  final String detail;
  final Color avatarColor;
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  static const List<_Recipient> _recipients = [
    _Recipient(
      id: '1',
      name: 'Ananya Sharma',
      detail: 'ananya@okaxis',
      avatarColor: Color(0xFF5B7CFA),
    ),
    _Recipient(
      id: '2',
      name: 'Rahul Verma',
      detail: 'rahul.verma@ybl',
      avatarColor: Color(0xFF10B981),
    ),
    _Recipient(
      id: '3',
      name: 'Priya Nair',
      detail: 'priya.nair@ibl',
      avatarColor: Color(0xFFEC4899),
    ),
    _Recipient(
      id: '4',
      name: 'Vikram Singh',
      detail: 'VK****12 · HDFC',
      avatarColor: Color(0xFFF59E0B),
    ),
  ];

  late _Recipient _selected;
  String _amountRaw = '';

  @override
  void initState() {
    super.initState();
    _selected = _recipients.first;
  }

  double get _amountValue {
    if (_amountRaw.isEmpty || _amountRaw == '.') return 0;
    return double.tryParse(_amountRaw) ?? 0;
  }

  String get _amountDisplay {
    if (_amountRaw.isEmpty) {
      return '${MfCurrency.symbol}0';
    }
    final v = _amountValue;
    if (_amountRaw.endsWith('.')) {
      final whole = _amountRaw.substring(0, _amountRaw.length - 1);
      final n = double.tryParse(whole.isEmpty ? '0' : whole) ?? 0;
      return '${MfCurrency.formatInr(n).replaceAll(RegExp(r'\.00$'), '')}.';
    }
    return MfCurrency.formatInr(v);
  }

  void _onDigit(String d) {
    HapticFeedback.lightImpact();
    if (_amountRaw.contains('.')) {
      final parts = _amountRaw.split('.');
      if (parts.length == 2 && parts[1].length >= 2) return;
    }
    if (_amountRaw == '0' && d != '.') {
      setState(() => _amountRaw = d);
      return;
    }
    final next = _amountRaw + d;
    if (next.replaceAll('.', '').length > 10) return;
    setState(() => _amountRaw = next);
  }

  void _onDecimal() {
    HapticFeedback.lightImpact();
    if (_amountRaw.contains('.')) return;
    setState(() {
      _amountRaw = _amountRaw.isEmpty ? '0.' : '$_amountRaw.';
    });
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_amountRaw.isEmpty) return;
    setState(() => _amountRaw = _amountRaw.substring(0, _amountRaw.length - 1));
  }

  void _openRecipientPicker() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: _kElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(MfRadius.xl)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              MfSpace.xxl,
              MfSpace.md,
              MfSpace.xxl,
              MfSpace.xxl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Send to',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: MfSpace.lg),
                ..._recipients.map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: _Avatar(
                      label: r.name.isNotEmpty ? r.name[0].toUpperCase() : '?',
                      color: r.avatarColor,
                      size: 44,
                    ),
                    title: Text(
                      r.name,
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        fontSize: 15,
                      ),
                    ),
                    subtitle: Text(
                      r.detail,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                    ),
                    onTap: () {
                      setState(() => _selected = r);
                      Navigator.pop(ctx);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _send() {
    if (_amountValue <= 0) return;
    HapticFeedback.mediumImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kElevated,
        content: Text(
          'Sent $_amountDisplay to ${_selected.name}',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final canSend = _amountValue > 0;

    return Scaffold(
      backgroundColor: _kCanvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white.withValues(alpha: 0.9),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          'Send money',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: MfSpace.xxl),
            child: _RecipientRow(
              recipient: _selected,
              onTap: _openRecipientPicker,
            ),
          ),
          const SizedBox(height: MfSpace.xl),
          Expanded(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: MfSpace.lg),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _amountDisplay,
                    style: GoogleFonts.manrope(
                      fontSize: 56,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -1.2,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              MfSpace.xxl,
              MfSpace.md,
              MfSpace.xxl,
              MfSpace.lg + bottom,
            ),
            child: Column(
              children: [
                _KeypadGrid(
                  onDigit: _onDigit,
                  onDecimal: _onDecimal,
                  onBackspace: _onBackspace,
                ),
                const SizedBox(height: MfSpace.lg),
                _SendMoneyCta(
                  enabled: canSend,
                  onPressed: canSend ? _send : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({
    required this.label,
    required this.color,
    this.size = 48,
  });

  final String label;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(size * 0.32),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: size * 0.38,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
    );
  }
}

class _RecipientRow extends StatelessWidget {
  const _RecipientRow({
    required this.recipient,
    required this.onTap,
  });

  final _Recipient recipient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MfRadius.lg),
        child: Ink(
          decoration: BoxDecoration(
            color: _kElevated,
            borderRadius: BorderRadius.circular(MfRadius.lg),
            border: Border.all(color: _kKeyBorder.withValues(alpha: 0.6)),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: MfSpace.lg,
            vertical: MfSpace.md,
          ),
          child: Row(
            children: [
              _Avatar(
                label: recipient.name.isNotEmpty
                    ? recipient.name[0].toUpperCase()
                    : '?',
                color: recipient.avatarColor,
              ),
              const SizedBox(width: MfSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'To',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.6,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                    const SizedBox(height: MfSpace.xs),
                    Text(
                      recipient.name,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      recipient.detail,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.white.withValues(alpha: 0.5),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Colors.white.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeypadGrid extends StatelessWidget {
  const _KeypadGrid({
    required this.onDigit,
    required this.onDecimal,
    required this.onBackspace,
  });

  final void Function(String) onDigit;
  final VoidCallback onDecimal;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    Widget row(List<Widget> cells) {
      return Padding(
        padding: const EdgeInsets.only(bottom: MfSpace.sm),
        child: Row(
          children: [
            for (var i = 0; i < cells.length; i++) ...[
              if (i > 0) const SizedBox(width: MfSpace.sm),
              Expanded(child: cells[i]),
            ],
          ],
        ),
      );
    }

    return Column(
      children: [
        row([
          _KeypadKey(label: '1', onTap: () => onDigit('1')),
          _KeypadKey(label: '2', onTap: () => onDigit('2')),
          _KeypadKey(label: '3', onTap: () => onDigit('3')),
        ]),
        row([
          _KeypadKey(label: '4', onTap: () => onDigit('4')),
          _KeypadKey(label: '5', onTap: () => onDigit('5')),
          _KeypadKey(label: '6', onTap: () => onDigit('6')),
        ]),
        row([
          _KeypadKey(label: '7', onTap: () => onDigit('7')),
          _KeypadKey(label: '8', onTap: () => onDigit('8')),
          _KeypadKey(label: '9', onTap: () => onDigit('9')),
        ]),
        row([
          _KeypadKey(label: '.', onTap: onDecimal),
          _KeypadKey(label: '0', onTap: () => onDigit('0')),
          _KeypadKey(
            icon: Icons.backspace_outlined,
            onTap: onBackspace,
          ),
        ]),
      ],
    );
  }
}

class _KeypadKey extends StatefulWidget {
  const _KeypadKey({this.label, this.icon, required this.onTap})
      : assert(label != null || icon != null);

  final String? label;
  final IconData? icon;
  final VoidCallback onTap;

  @override
  State<_KeypadKey> createState() => _KeypadKeyState();
}

class _KeypadKeyState extends State<_KeypadKey>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 90),
    );
    _scale = Tween<double>(begin: 1, end: 0.94).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scale,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          onTapDown: (_) => _c.forward(),
          onTapUp: (_) => _c.reverse(),
          onTapCancel: () => _c.reverse(),
          borderRadius: BorderRadius.circular(MfRadius.md),
          child: Ink(
            height: 56,
            decoration: BoxDecoration(
              color: _kKeyFill,
              borderRadius: BorderRadius.circular(MfRadius.md),
              border: Border.all(color: _kKeyBorder.withValues(alpha: 0.85)),
            ),
            child: Center(
              child: widget.label != null
                  ? Text(
                      widget.label!,
                      style: GoogleFonts.manrope(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      widget.icon,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 22,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SendMoneyCta extends StatefulWidget {
  const _SendMoneyCta({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback? onPressed;

  @override
  State<_SendMoneyCta> createState() => _SendMoneyCtaState();
}

class _SendMoneyCtaState extends State<_SendMoneyCta>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: MfMotion.fast,
      reverseDuration: MfMotion.fast,
    );
    _scale = Tween<double>(begin: 1, end: 0.97).animate(
      CurvedAnimation(parent: _c, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onPressed == null;

    return ScaleTransition(
      scale: _scale,
      child: AnimatedOpacity(
        duration: MfMotion.fast,
        opacity: disabled ? 0.45 : 1,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            onTapDown: disabled ? null : (_) => _c.forward(),
            onTapUp: disabled ? null : (_) => _c.reverse(),
            onTapCancel: disabled ? null : () => _c.reverse(),
            borderRadius: BorderRadius.circular(MfRadius.xl),
            child: Ink(
              height: 56,
              decoration: BoxDecoration(
                color: MfPalette.neonGreen,
                borderRadius: BorderRadius.circular(MfRadius.xl),
                boxShadow: [
                  BoxShadow(
                    color: MfPalette.neonGreen.withValues(alpha: 0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Send Money',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                    color: MfPalette.onNeonGreen,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
