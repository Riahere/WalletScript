import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  WalletScript — Onboarding Screen (Editorial)
//  Design: 3-slide editorial layout with hero headline + frosted bottom card
//  Animations: staggered entrance, parallax float, particle shimmer, page wipe
// ─────────────────────────────────────────────────────────────────────────────

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  // ── Page state ──────────────────────────────────────────────────────────────
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // ── Animation controllers ───────────────────────────────────────────────────

  // Headline stagger: tag fades up, then headline letters drop in
  late AnimationController _headlineCtrl;
  late Animation<double> _tagFade;
  late Animation<Offset> _tagSlide;
  late Animation<double> _headlineFade;
  late Animation<Offset> _headlineSlide;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  // Continuous float for the illustration
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;

  // Particle shimmer (floating coins/dots)
  late AnimationController _particleCtrl;

  // Background color tween between slides
  late AnimationController _bgCtrl;
  late Animation<Color?> _bgAnim;
  Color _fromBg = const Color(0xFFEEF4FF);
  Color _toBg = const Color(0xFFEEF4FF);

  // ── Slide definitions ───────────────────────────────────────────────────────
  final List<_SlideData> _slides = const [
    _SlideData(
      tag: '01 — WEALTH',
      headline: 'Script\nYour\nWealth.',
      subtitle:
          'Catat setiap transaksi, kelola budget, dan raih kebebasan finansial kamu.',
      bg: Color(0xFFEEF4FF),
      headlineColor: Color(0xFF0D1B3E),
      cardBg: Color(0xFF0D1B3E),
      cardTextColor: Color(0xCCFFFFFF),
      accentColor: Color(0xFFF5C842),
      nextBg: Color(0xFFF5C842),
      nextFg: Color(0xFF0D1B3E),
      illus: _IllusType.wallet,
    ),
    _SlideData(
      tag: '02 — TRACK',
      headline: 'Track\nEvery\nCent.',
      subtitle:
          'Pantau pemasukan & pengeluaran real-time. Tidak ada yang lolos dari script-mu.',
      bg: Color(0xFF0D1B3E),
      headlineColor: Color(0xFFFFFFFF),
      cardBg: Color(0xFFF5C842),
      cardTextColor: Color(0xFF412402),
      accentColor: Color(0xFFF5C842),
      nextBg: Color(0xFF0D1B3E),
      nextFg: Color(0xFFF5C842),
      illus: _IllusType.chart,
    ),
    _SlideData(
      tag: '03 — GROW',
      headline: 'Grow\nYour\nFuture.',
      subtitle:
          'Analisis keuanganmu dan buat keputusan lebih cerdas setiap harinya.',
      bg: Color(0xFFF5C842),
      headlineColor: Color(0xFF0D1B3E),
      cardBg: Color(0xFF0D1B3E),
      cardTextColor: Color(0xCCFFFFFF),
      accentColor: Color(0xFF0D1B3E),
      nextBg: Color(0xFFF5C842),
      nextFg: Color(0xFF0D1B3E),
      illus: _IllusType.grow,
      isLast: true,
    ),
  ];

  // ── Particles ───────────────────────────────────────────────────────────────
  late List<_Particle> _particles;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));

    _particles = List.generate(14, (i) => _Particle.random(i));

    // ── Entrance animation ──────────────────────────────────────────────────
    _headlineCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _tagFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _headlineCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeOut),
      ),
    );
    _tagSlide = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero)
        .animate(CurvedAnimation(
      parent: _headlineCtrl,
      curve: const Interval(0.0, 0.45, curve: Curves.easeOutCubic),
    ));

    _headlineFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _headlineCtrl,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOut),
      ),
    );
    _headlineSlide =
        Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _headlineCtrl,
        curve: const Interval(0.2, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _cardFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _headlineCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
      ),
    );
    _cardSlide =
        Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _headlineCtrl,
        curve: const Interval(0.5, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    // ── Float (continuous) ──────────────────────────────────────────────────
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );

    // ── Particle shimmer ────────────────────────────────────────────────────
    _particleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // ── Background tween ────────────────────────────────────────────────────
    _bgCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _bgAnim = ColorTween(begin: _fromBg, end: _toBg).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut),
    );

    // Kick off entrance
    _headlineCtrl.forward();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _headlineCtrl.dispose();
    _floatCtrl.dispose();
    _particleCtrl.dispose();
    _bgCtrl.dispose();
    super.dispose();
  }

  // ── Navigation ──────────────────────────────────────────────────────────────

  void _goToPage(int index) {
    if (index == _currentPage) return;

    // Animate background
    _fromBg = _slides[_currentPage].bg;
    _toBg = _slides[index].bg;
    _bgAnim = ColorTween(begin: _fromBg, end: _toBg).animate(
      CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut),
    );
    _bgCtrl.forward(from: 0);

    // Animate entrance
    _headlineCtrl.forward(from: 0);

    setState(() => _currentPage = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
  }

  void _next() {
    if (_currentPage < _slides.length - 1) {
      _goToPage(_currentPage + 1);
    } else {
      _completeOnboarding();
    }
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionDuration: const Duration(milliseconds: 700),
        transitionsBuilder: (_, anim, __, child) => FadeTransition(
          opacity: anim,
          child: child,
        ),
      ),
    );
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_currentPage];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedBuilder(
        animation: Listenable.merge([_bgCtrl, _floatCtrl, _particleCtrl]),
        builder: (context, _) {
          final bg =
              _bgCtrl.isAnimating ? (_bgAnim.value ?? slide.bg) : slide.bg;

          return Container(
            color: bg,
            child: Stack(
              children: [
                // ── Particles ─────────────────────────────────────────────
                ..._particles.map((p) => _ParticleWidget(
                      particle: p,
                      progress: _particleCtrl.value,
                      accentColor: slide.accentColor,
                      bgIsDark: slide.bg == const Color(0xFF0D1B3E),
                    )),

                // ── Illustration (floating) ───────────────────────────────
                Positioned(
                  top: size.height * 0.06,
                  left: 0,
                  right: 0,
                  child: Transform.translate(
                    offset: Offset(0, _floatAnim.value),
                    child: SizedBox(
                      height: size.height * 0.40,
                      child: _IllusWidget(
                        type: slide.illus,
                        accent: slide.accentColor,
                        size: size,
                      ),
                    ),
                  ),
                ),

                // ── Top bar ───────────────────────────────────────────────
                Positioned(
                  top: MediaQuery.of(context).padding.top + 16,
                  left: 24,
                  right: 24,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      AnimatedDefaultTextStyle(
                        duration: const Duration(milliseconds: 400),
                        style: TextStyle(
                          fontFamily: 'Georgia',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: slide.headlineColor,
                          letterSpacing: -0.3,
                        ),
                        child: const Text('WalletScript'),
                      ),
                      if (_currentPage < _slides.length - 1)
                        GestureDetector(
                          onTap: _completeOnboarding,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            style: TextStyle(
                              fontSize: 12,
                              color: slide.headlineColor.withOpacity(0.45),
                              letterSpacing: 0.5,
                            ),
                            child: const Text('Lewati'),
                          ),
                        ),
                    ],
                  ),
                ),

                // ── Headline area ─────────────────────────────────────────
                Positioned(
                  top: size.height * 0.36,
                  left: 28,
                  right: 28,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Tag line
                      FadeTransition(
                        opacity: _tagFade,
                        child: SlideTransition(
                          position: _tagSlide,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            style: TextStyle(
                              fontFamily: 'Courier',
                              fontSize: 10,
                              letterSpacing: 3,
                              color: slide.accentColor ==
                                      const Color(0xFF0D1B3E)
                                  ? const Color(0xFF0D1B3E).withOpacity(0.55)
                                  : slide.accentColor.withOpacity(0.7),
                              fontWeight: FontWeight.w700,
                            ),
                            child: Text(slide.tag),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Big headline
                      FadeTransition(
                        opacity: _headlineFade,
                        child: SlideTransition(
                          position: _headlineSlide,
                          child: AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 400),
                            style: TextStyle(
                              fontFamily: 'Georgia',
                              fontSize: 58,
                              fontWeight: FontWeight.w900,
                              color: slide.headlineColor,
                              height: 0.94,
                              letterSpacing: -2,
                            ),
                            child: Text(slide.headline),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom card ───────────────────────────────────────────
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: FadeTransition(
                    opacity: _cardFade,
                    child: SlideTransition(
                      position: _cardSlide,
                      child: _BottomCard(
                        slide: slide,
                        currentPage: _currentPage,
                        totalPages: _slides.length,
                        onNext: _next,
                        onDotTap: _goToPage,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Bottom Card
// ─────────────────────────────────────────────────────────────────────────────

class _BottomCard extends StatelessWidget {
  final _SlideData slide;
  final int currentPage;
  final int totalPages;
  final VoidCallback onNext;
  final ValueChanged<int> onDotTap;

  const _BottomCard({
    required this.slide,
    required this.currentPage,
    required this.totalPages,
    required this.onNext,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 28),
      padding: const EdgeInsets.fromLTRB(26, 24, 26, 26),
      decoration: BoxDecoration(
        color: slide.cardBg,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: slide.cardBg.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Subtitle
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 400),
            style: TextStyle(
              fontSize: 14,
              color: slide.cardTextColor,
              height: 1.6,
              letterSpacing: 0.1,
            ),
            child: Text(slide.subtitle),
          ),
          const SizedBox(height: 24),

          // Dots + button row
          Row(
            children: [
              // Dots
              Row(
                children: List.generate(totalPages, (i) {
                  final active = i == currentPage;
                  return GestureDetector(
                    onTap: () => onDotTap(i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      margin: const EdgeInsets.only(right: 6),
                      width: active ? 22 : 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: active
                            ? slide.accentColor
                            : slide.cardTextColor.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  );
                }),
              ),

              const Spacer(),

              // Next / Get Started
              _NextButton(
                slide: slide,
                isLast: slide.isLast,
                onTap: onNext,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Next Button with press animation
// ─────────────────────────────────────────────────────────────────────────────

class _NextButton extends StatefulWidget {
  final _SlideData slide;
  final bool isLast;
  final VoidCallback onTap;

  const _NextButton({
    required this.slide,
    required this.isLast,
    required this.onTap,
  });

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressCtrl.forward(),
      onTapUp: (_) {
        _pressCtrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressCtrl.reverse(),
      child: ScaleTransition(
        scale: _scaleAnim,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 400),
          padding: EdgeInsets.symmetric(
            horizontal: widget.isLast ? 22 : 18,
            vertical: 14,
          ),
          decoration: BoxDecoration(
            color: widget.slide.nextBg,
            borderRadius: BorderRadius.circular(50),
            boxShadow: [
              BoxShadow(
                color: widget.slide.nextBg.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 400),
                style: TextStyle(
                  color: widget.slide.nextFg,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  letterSpacing: 0.4,
                ),
                child: Text(widget.isLast ? 'Get Started' : 'Next'),
              ),
              const SizedBox(width: 6),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  widget.isLast
                      ? Icons.check_rounded
                      : Icons.arrow_forward_rounded,
                  key: ValueKey(widget.isLast),
                  size: 16,
                  color: widget.slide.nextFg,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Illustration Widget
// ─────────────────────────────────────────────────────────────────────────────

enum _IllusType { wallet, chart, grow }

class _IllusWidget extends StatelessWidget {
  final _IllusType type;
  final Color accent;
  final Size size;

  const _IllusWidget({
    required this.type,
    required this.accent,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeIn,
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0).animate(anim), child: child),
      ),
      child: CustomPaint(
        key: ValueKey(type),
        size: Size(size.width, size.height * 0.40),
        painter: _IllusPainter(type: type, accent: accent),
      ),
    );
  }
}

class _IllusPainter extends CustomPainter {
  final _IllusType type;
  final Color accent;

  _IllusPainter({required this.type, required this.accent});

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case _IllusType.wallet:
        _drawWallet(canvas, size);
        break;
      case _IllusType.chart:
        _drawChart(canvas, size);
        break;
      case _IllusType.grow:
        _drawGrow(canvas, size);
        break;
    }
  }

  void _drawWallet(Canvas canvas, Size size) {
    final cx = size.width * 0.55;
    final cy = size.height * 0.52;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      130,
      Paint()
        ..color = accent.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 55),
    );

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx + 6, cy + 16), width: 190, height: 120),
          const Radius.circular(20)),
      Paint()
        ..color = Colors.black.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 20),
    );

    // Wallet body
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy + 10), width: 190, height: 120),
          const Radius.circular(18)),
      Paint()..color = const Color(0xFF1A3060),
    );

    // Flap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx, cy - 28), width: 190, height: 55),
          const Radius.circular(18)),
      Paint()..color = const Color(0xFF233D7A),
    );

    // Card inside
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx + 28, cy + 10), width: 88, height: 52),
          const Radius.circular(9)),
      Paint()..color = accent.withOpacity(0.92),
    );
    // Card stripe
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx + 28, cy + 4), width: 88, height: 10),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF0D1B3E).withOpacity(0.25),
    );
    // Chip
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(cx - 8, cy + 16), width: 22, height: 16),
          const Radius.circular(3)),
      Paint()..color = const Color(0xFF0D1B3E).withOpacity(0.35),
    );

    // Coin
    canvas.drawCircle(
      Offset(cx - 62, cy - 52),
      30,
      Paint()..color = accent,
    );
    canvas.drawCircle(
      Offset(cx - 62, cy - 52),
      22,
      Paint()..color = accent.withOpacity(0.6),
    );
    final tp = TextPainter(
      text: TextSpan(
        text: 'Rp',
        style: TextStyle(
          color: const Color(0xFF0D1B3E),
          fontSize: 15,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - 62 - tp.width / 2, cy - 52 - tp.height / 2));

    // Floating mini coin
    canvas.drawCircle(
      Offset(cx + 80, cy - 65),
      12,
      Paint()..color = accent.withOpacity(0.5),
    );
    canvas.drawCircle(
      Offset(cx - 90, cy + 40),
      8,
      Paint()..color = accent.withOpacity(0.3),
    );
  }

  void _drawChart(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      130,
      Paint()
        ..color = accent.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );

    final bars = [0.38, 0.62, 0.48, 0.82, 0.68, 0.95];
    const barW = 22.0;
    const barGap = 13.0;
    const maxH = 125.0;
    final totalW = bars.length * (barW + barGap) - barGap;
    final startX = cx - totalW / 2;
    final baseY = cy + 65.0;

    for (var i = 0; i < bars.length; i++) {
      final h = maxH * bars[i];
      final x = startX + i * (barW + barGap);

      // Bar shadow
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x + 2, baseY - h + 4, barW, h),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
      );

      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(x, baseY - h, barW, h),
          topLeft: const Radius.circular(6),
          topRight: const Radius.circular(6),
        ),
        Paint()
          ..color =
              i == bars.length - 1 ? accent : accent.withOpacity(0.2 + i * 0.1),
      );
    }

    // Trend line
    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path();
    for (var i = 0; i < bars.length; i++) {
      final h = maxH * bars[i];
      final x = startX + i * (barW + barGap) + barW / 2;
      final y = baseY - h - 14;
      i == 0 ? path.moveTo(x, y) : path.lineTo(x, y);
    }
    canvas.drawPath(path, linePaint);

    // Dot at end of line
    final lastX = startX + (bars.length - 1) * (barW + barGap) + barW / 2;
    final lastY = baseY - maxH * bars.last - 14;
    canvas.drawCircle(Offset(lastX, lastY), 5, Paint()..color = accent);
    canvas.drawCircle(
        Offset(lastX, lastY),
        9,
        Paint()
          ..color = accent.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);
  }

  void _drawGrow(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      120,
      Paint()
        ..color = const Color(0xFF0D1B3E).withOpacity(0.1)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 60),
    );

    // Outer ring
    canvas.drawCircle(
      Offset(cx, cy),
      105,
      Paint()
        ..color = const Color(0xFF0D1B3E).withOpacity(0.12)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
    canvas.drawCircle(
      Offset(cx, cy),
      75,
      Paint()
        ..color = const Color(0xFF0D1B3E).withOpacity(0.1)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );

    // Progress arc
    canvas.drawArc(
      Rect.fromCenter(center: Offset(cx, cy), width: 210, height: 210),
      -math.pi / 2,
      math.pi * 1.7,
      false,
      Paint()
        ..color = const Color(0xFF0D1B3E)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // Center: +42%
    final pct = TextPainter(
      text: const TextSpan(
        text: '+42%',
        style: TextStyle(
          color: Color(0xFF0D1B3E),
          fontSize: 30,
          fontWeight: FontWeight.w900,
          letterSpacing: -1,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    pct.paint(canvas, Offset(cx - pct.width / 2, cy - pct.height / 2 - 8));

    final label = TextPainter(
      text: TextSpan(
        text: 'savings growth',
        style: TextStyle(
          color: const Color(0xFF0D1B3E).withOpacity(0.55),
          fontSize: 10,
          letterSpacing: 1.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    label.paint(canvas, Offset(cx - label.width / 2, cy + 14));

    // Corner coins
    canvas.drawCircle(Offset(cx + 95, cy - 45), 18,
        Paint()..color = const Color(0xFF0D1B3E).withOpacity(0.18));
    canvas.drawCircle(Offset(cx - 92, cy + 25), 12,
        Paint()..color = const Color(0xFF0D1B3E).withOpacity(0.14));
    canvas.drawCircle(Offset(cx + 70, cy + 78), 9,
        Paint()..color = const Color(0xFF0D1B3E).withOpacity(0.12));
  }

  @override
  bool shouldRepaint(covariant _IllusPainter old) =>
      old.type != type || old.accent != accent;
}

// ─────────────────────────────────────────────────────────────────────────────
//  Floating Particle
// ─────────────────────────────────────────────────────────────────────────────

class _Particle {
  final double x; // 0–1 relative to screen width
  final double y; // 0–1
  final double radius;
  final double speed; // phase offset
  final double opacity;
  final double amplitude;

  const _Particle({
    required this.x,
    required this.y,
    required this.radius,
    required this.speed,
    required this.opacity,
    required this.amplitude,
  });

  factory _Particle.random(int seed) {
    final rng = math.Random(seed * 7919);
    return _Particle(
      x: rng.nextDouble(),
      y: rng.nextDouble() * 0.75,
      radius: 2 + rng.nextDouble() * 5,
      speed: rng.nextDouble(),
      opacity: 0.08 + rng.nextDouble() * 0.18,
      amplitude: 12 + rng.nextDouble() * 20,
    );
  }
}

class _ParticleWidget extends StatelessWidget {
  final _Particle particle;
  final double progress;
  final Color accentColor;
  final bool bgIsDark;

  const _ParticleWidget({
    required this.particle,
    required this.progress,
    required this.accentColor,
    required this.bgIsDark,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final phase = (progress + particle.speed) % 1.0;
    final dy = math.sin(phase * math.pi * 2) * particle.amplitude;

    return Positioned(
      left: particle.x * size.width,
      top: particle.y * size.height + dy,
      child: Container(
        width: particle.radius * 2,
        height: particle.radius * 2,
        decoration: BoxDecoration(
          color: accentColor.withOpacity(particle.opacity),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Data Model
// ─────────────────────────────────────────────────────────────────────────────

class _SlideData {
  final String tag;
  final String headline;
  final String subtitle;
  final Color bg;
  final Color headlineColor;
  final Color cardBg;
  final Color cardTextColor;
  final Color accentColor;
  final Color nextBg;
  final Color nextFg;
  final _IllusType illus;
  final bool isLast;

  const _SlideData({
    required this.tag,
    required this.headline,
    required this.subtitle,
    required this.bg,
    required this.headlineColor,
    required this.cardBg,
    required this.cardTextColor,
    required this.accentColor,
    required this.nextBg,
    required this.nextFg,
    required this.illus,
    this.isLast = false,
  });
}
