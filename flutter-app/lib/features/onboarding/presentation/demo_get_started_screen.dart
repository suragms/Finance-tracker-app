import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/api_config.dart';
import '../../../core/storage/demo_get_started_storage.dart';
import '../../../core/theme/money_flow_tokens.dart';

/// Shows the demo onboarding once (unless skipped earlier). No-op when not in demo mode.
Future<void> showDemoGetStartedIfNeeded(BuildContext context) async {
  if (!kNoApiMode) return;
  final done = await DemoGetStartedStorage.hasCompleted();
  if (!context.mounted || done) return;
  await Navigator.of(context).push<void>(
    PageRouteBuilder<void>(
      opaque: true,
      barrierDismissible: false,
      pageBuilder: (ctx, _, __) =>
          const DemoGetStartedScreen(markCompleteOnExit: true),
      transitionsBuilder: (ctx, anim, _, child) {
        return FadeTransition(opacity: anim, child: child);
      },
    ),
  );
}

/// Re-open tips from Profile (demo mode only). Does not change completion flag.
Future<void> openDemoGetStartedFromProfile(BuildContext context) async {
  if (!kNoApiMode) return;
  if (!context.mounted) return;
  await Navigator.of(context).push<void>(
    MaterialPageRoute<void>(
      fullscreenDialog: true,
      builder: (_) => const DemoGetStartedScreen(markCompleteOnExit: false),
    ),
  );
}

class DemoGetStartedScreen extends StatefulWidget {
  const DemoGetStartedScreen({super.key, required this.markCompleteOnExit});

  final bool markCompleteOnExit;

  @override
  State<DemoGetStartedScreen> createState() => _DemoGetStartedScreenState();
}

class _DemoGetStartedScreenState extends State<DemoGetStartedScreen> {
  final _pageController = PageController();
  int _page = 0;
  static const _slides = <_OnboardSlide>[
    _OnboardSlide(
      title: 'Track Expenses',
      description:
          'Capture every spend in seconds with clean categories and instant balance updates.',
      accent: Color(0xFF6366F1),
      icon: Icons.receipt_long_rounded,
      secondaryIcon: Icons.pie_chart_rounded,
    ),
    _OnboardSlide(
      title: 'Smart Insights',
      description:
          'See weekly trends, category breakdowns, and practical guidance for better decisions.',
      accent: Color(0xFF4DB5FF),
      icon: Icons.auto_graph_rounded,
      secondaryIcon: Icons.insights_rounded,
    ),
    _OnboardSlide(
      title: 'Recurring Automation',
      description:
          'Automate repeated bills and incomes so your budget stays accurate without extra effort.',
      accent: Color(0xFF10B981),
      icon: Icons.autorenew_rounded,
      secondaryIcon: Icons.event_repeat_rounded,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _exit() async {
    if (widget.markCompleteOnExit) {
      await DemoGetStartedStorage.setCompleted();
    }
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_page < _slides.length - 1) {
      _pageController.nextPage(
        duration: MfMotion.medium,
        curve: Curves.easeInOutCubic,
      );
    } else {
      _exit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1A1038), Color(0xFF050507)],
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MfSpace.lg,
                  MfSpace.md,
                  MfSpace.lg,
                  MfSpace.md,
                ),
                child: Row(
                  children: [
                    Text(
                      'MoneyFlow AI',
                      style: GoogleFonts.manrope(
                        fontWeight: FontWeight.w800,
                        fontSize: 20,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _exit,
                      child: Text(
                        'Skip',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Colors.white.withValues(alpha: 0.62),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) => setState(() => _page = i),
                  itemCount: _slides.length,
                  itemBuilder: (context, index) => _PageSlideTransition(
                    controller: _pageController,
                    index: index,
                    child: Padding(
                      padding:
                          const EdgeInsets.symmetric(horizontal: MfSpace.xl),
                      child: _OnboardPage(slide: _slides[index]),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  MfSpace.xl,
                  MfSpace.md,
                  MfSpace.xl,
                  MfSpace.xl,
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_slides.length, (i) {
                        final active = i == _page;
                        final activeColor = _slides[_page].accent;
                        return AnimatedContainer(
                          duration: MfMotion.fast,
                          curve: Curves.easeOut,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: active ? 22 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: active
                                ? activeColor
                                : Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(99),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: MfSpace.lg),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: _next,
                        style: FilledButton.styleFrom(
                          backgroundColor: _slides[_page].accent,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: MfSpace.lg),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          'Get Started',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardSlide {
  const _OnboardSlide({
    required this.title,
    required this.description,
    required this.accent,
    required this.icon,
    required this.secondaryIcon,
  });

  final String title;
  final String description;
  final Color accent;
  final IconData icon;
  final IconData secondaryIcon;
}

class _OnboardPage extends StatelessWidget {
  const _OnboardPage({required this.slide});

  final _OnboardSlide slide;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: MfSpace.md),
        _FintechIllustration(
          accent: slide.accent,
          primaryIcon: slide.icon,
          secondaryIcon: slide.secondaryIcon,
        ),
        const SizedBox(height: MfSpace.xxxl),
        Text(
          slide.title,
          textAlign: TextAlign.center,
          style: GoogleFonts.manrope(
            fontWeight: FontWeight.w800,
            fontSize: 31,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: MfSpace.md),
        Text(
          slide.description,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w500,
            fontSize: 15,
            height: 1.45,
            color: Colors.white.withValues(alpha: 0.68),
          ),
        ),
      ],
    );
  }
}

class _FintechIllustration extends StatelessWidget {
  const _FintechIllustration({
    required this.accent,
    required this.primaryIcon,
    required this.secondaryIcon,
  });

  final Color accent;
  final IconData primaryIcon;
  final IconData secondaryIcon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 230,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedContainer(
            duration: MfMotion.medium,
            curve: Curves.easeOutCubic,
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.18),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.2),
                  blurRadius: 26,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
          ),
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
            ),
            child: Icon(primaryIcon, size: 64, color: accent),
          ),
          Positioned(
            right: 32,
            top: 20,
            child: _MiniIconBubble(icon: secondaryIcon, color: accent),
          ),
          Positioned(
            left: 28,
            bottom: 16,
            child: _MiniIconBubble(
              icon: Icons.trending_up_rounded,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniIconBubble extends StatelessWidget {
  const _MiniIconBubble({required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.2),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      alignment: Alignment.center,
      child: Icon(icon, size: 22, color: color),
    );
  }
}

class _PageSlideTransition extends StatelessWidget {
  const _PageSlideTransition({
    required this.child,
    required this.controller,
    required this.index,
  });

  final Widget child;
  final PageController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final page = controller.hasClients && controller.page != null
            ? controller.page!
            : controller.initialPage.toDouble();
        final delta = (page - index).clamp(-1.0, 1.0);
        final opacity = 1 - (delta.abs() * 0.35);
        return Transform.translate(
          offset: Offset(delta * 28, 0),
          child: Opacity(opacity: opacity, child: child),
        );
      },
    );
  }
}
