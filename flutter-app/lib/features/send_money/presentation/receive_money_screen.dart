import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/money_flow_tokens.dart';

/// Request / receive flow — share UPI handle (demo). Pairs with [SendMoneyScreen].
class ReceiveMoneyScreen extends StatefulWidget {
  const ReceiveMoneyScreen({super.key});

  @override
  State<ReceiveMoneyScreen> createState() => _ReceiveMoneyScreenState();
}

const Color _rxBg = Color(0xFF0A0A0C);
const Color _rxElevated = Color(0xFF141418);
const Color _rxBorder = Color(0xFF2A2A32);

class _ReceiveMoneyScreenState extends State<ReceiveMoneyScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  static const _upiDemo = 'you@okmoneyflow';

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Future<void> _copyUpi() async {
    await Clipboard.setData(const ClipboardData(text: _upiDemo));
    HapticFeedback.lightImpact();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _rxElevated,
        content: Text(
          'UPI ID copied',
          style: GoogleFonts.inter(color: Colors.white),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _rxBg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: Text(
          'Receive money',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w700,
            fontSize: 17,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          MfSpace.xxl,
          MfSpace.lg,
          MfSpace.xxl,
          MfSpace.xxxl,
        ),
        children: [
          Text(
            'Share your UPI',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: MfSpace.xl),
          ScaleTransition(
            scale: Tween<double>(begin: 0.98, end: 1).animate(
              CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
            ),
            child: Container(
              padding: const EdgeInsets.all(MfSpace.xxxl),
              decoration: BoxDecoration(
                color: _rxElevated,
                borderRadius: BorderRadius.circular(MfRadius.xl),
                border: Border.all(
                  color: MfPalette.neonGreen.withValues(alpha: 0.35),
                ),
                boxShadow: [
                  BoxShadow(
                    color: MfPalette.neonGreen.withValues(alpha: 0.15),
                    blurRadius: 32,
                    spreadRadius: -4,
                  ),
                ],
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 120,
                    color: MfPalette.neonGreen.withValues(alpha: 0.9),
                  ),
                  const SizedBox(height: MfSpace.lg),
                  Text(
                    'QR placeholder',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white.withValues(alpha: 0.4),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: MfSpace.xxxl),
          Text(
            'UPI ID',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
          const SizedBox(height: MfSpace.sm),
          Material(
            color: _rxElevated,
            borderRadius: BorderRadius.circular(MfRadius.md),
            child: InkWell(
              onTap: _copyUpi,
              borderRadius: BorderRadius.circular(MfRadius.md),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: MfSpace.lg,
                  vertical: MfSpace.lg,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(MfRadius.md),
                  border: Border.all(color: _rxBorder),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        _upiDemo,
                        style: GoogleFonts.manrope(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.copy_rounded,
                      color: MfPalette.neonGreen,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: MfSpace.xl),
          SizedBox(
            height: 54,
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                HapticFeedback.mediumImpact();
                _copyUpi();
              },
              style: FilledButton.styleFrom(
                backgroundColor: MfPalette.neonGreen,
                foregroundColor: MfPalette.onNeonGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(MfRadius.lg),
                ),
              ),
              child: Text(
                'Copy & share',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: MfSpace.lg),
          Text(
            'Connect a real UPI ID in settings when payments go live.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: Colors.white.withValues(alpha: 0.38),
            ),
          ),
        ],
      ),
    );
  }
}
