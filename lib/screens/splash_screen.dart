import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'onboarding_screen.dart';
import 'login_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  WalletScript — Splash Screen (Simple White, Logo Animation)
//  Animasi:
//    1. Icon group (wallet + coin + brace) slide masuk dari kanan
//    2. Teks "WalletScript" reveal/wipe keluar setelah icon berhenti
//    3. Tagline fade up
//    4. Coin float loop setelah masuk
// ─────────────────────────────────────────────────────────────────────────────

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Icon slide-in ───────────────────────────────────────────────────────────
  late AnimationController _iconCtrl;
  late Animation<Offset> _iconSlide;
  late Animation<double> _iconFade;

  // ── Text reveal (width wipe) ────────────────────────────────────────────────
  late AnimationController _textCtrl;
  late Animation<double> _textReveal;
  late Animation<double> _textFade;

  // ── Tagline ─────────────────────────────────────────────────────────────────
  late AnimationController _tagCtrl;
  late Animation<double> _tagFade;
  late Animation<Offset> _tagSlide;

  // ── Coin float loop ─────────────────────────────────────────────────────────
  late AnimationController _floatCtrl;
  late Animation<double> _floatY;

  bool _navDone = false;

  static const _navy = Color(0xFF0D1B4B);
  static const _navyMid = Color(0xFF1A2D6E);
  static const _gold = Color(0xFFF5C842);
  static const _goldLight = Color(0xFFFFE066);

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _setupAnimations();
    _startSequence();
    _checkAuthAndNavigate();
  }

  void _setupAnimations() {
    // Icon slide-in (elastic, from right)
    _iconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750),
    );
    _iconSlide = Tween<Offset>(
      begin: const Offset(3.0, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _iconCtrl, curve: Curves.elasticOut));
    _iconFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _iconCtrl,
        curve: const Interval(0.0, 0.25, curve: Curves.easeIn),
      ),
    );

    // Text wipe reveal
    _textCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );
    _textReveal = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic),
    );
    _textFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _textCtrl,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    // Tagline
    _tagCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _tagFade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOut),
    );
    _tagSlide = Tween<Offset>(
      begin: const Offset(0, 0.8),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _tagCtrl, curve: Curves.easeOutCubic));

    // Coin float (continuous after everything settles)
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _floatY = Tween<double>(begin: -3, end: 3).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOut),
    );
  }

  Future<void> _startSequence() async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;

    // 1. Icon slides in
    _iconCtrl.forward();

    // 2. Text reveals after icon arrives (~900ms total from start)
    await Future.delayed(const Duration(milliseconds: 950));
    if (!mounted) return;
    _textCtrl.forward();

    // 3. Tagline fades up
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    _tagCtrl.forward();

    // 4. Coin starts floating
    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    _floatCtrl.repeat(reverse: true);
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 2800));
    if (!mounted || _navDone) return;
    _navDone = true;

    final prefs = await SharedPreferences.getInstance();
    final onboardingDone = prefs.getBool('onboarding_complete') ?? false;
    if (!mounted) return;

    Widget destination;
    try {
      final session = Supabase.instance.client.auth.currentSession;
      destination = session != null
          ? const LoginScreen()
          : (onboardingDone ? const LoginScreen() : const OnboardingScreen());
    } catch (_) {
      destination =
          onboardingDone ? const LoginScreen() : const OnboardingScreen();
    }

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 600),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  void dispose() {
    _iconCtrl.dispose();
    _textCtrl.dispose();
    _tagCtrl.dispose();
    _floatCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation:
            Listenable.merge([_iconCtrl, _textCtrl, _tagCtrl, _floatCtrl]),
        builder: (context, _) {
          return Stack(
            alignment: Alignment.center,
            children: [
              // ── Logo row ──────────────────────────────────────────────────
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildIconGroup(),
                        _buildTextReveal(),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Tagline ───────────────────────────────────────────────────
              Positioned(
                bottom: 72,
                child: FadeTransition(
                  opacity: _tagFade,
                  child: SlideTransition(
                    position: _tagSlide,
                    child: const Text(
                      'SCRIPT YOUR WEALTH.',
                      style: TextStyle(
                        fontFamily: 'Courier',
                        fontSize: 11,
                        letterSpacing: 2.5,
                        color: _navy,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildIconGroup() {
    return FadeTransition(
      opacity: _iconFade,
      child: SlideTransition(
        position: _iconSlide,
        child: SizedBox(
          width: 110,
          height: 90,
          child: CustomPaint(
            painter: _LogoIconPainter(coinFloatY: _floatY.value),
          ),
        ),
      ),
    );
  }

  Widget _buildTextReveal() {
    return ClipRect(
      child: Align(
        alignment: Alignment.centerLeft,
        widthFactor: _textReveal.value,
        child: FadeTransition(
          opacity: _textFade,
          child: const Padding(
            padding: EdgeInsets.only(left: 4),
            child: Text(
              'WalletScript',
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: _navy,
                letterSpacing: -0.5,
                height: 1.0,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Logo Icon Painter — Wallet + Coin + Curly Brace }
// ─────────────────────────────────────────────────────────────────────────────

class _LogoIconPainter extends CustomPainter {
  final double coinFloatY;

  const _LogoIconPainter({required this.coinFloatY});

  static const _navy = Color(0xFF0D1B4B);
  static const _navyMid = Color(0xFF1A2D6E);
  static const _gold = Color(0xFFF5C842);
  static const _goldLight = Color(0xFFFFE066);
  static const _goldBorder = Color(0xFFD4A017);

  @override
  void paint(Canvas canvas, Size size) {
    _drawWallet(canvas, size);
    _drawCoin(canvas, size);
    _drawBrace(canvas, size);
  }

  void _drawWallet(Canvas canvas, Size size) {
    final cx = size.width * 0.37;
    final cy = size.height * 0.68;

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx + 3, cy + 6), width: 72, height: 50),
        const Radius.circular(10),
      ),
      Paint()
        ..color = Colors.black.withOpacity(0.12)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10),
    );

    // Wallet body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(cx, cy), width: 72, height: 50),
      const Radius.circular(8),
    );
    canvas.drawRRect(bodyRect, Paint()..color = _navy);

    // Flap top
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, cy - 14), width: 72, height: 24),
        const Radius.circular(8),
      ),
      Paint()..color = _navyMid,
    );

    // Snap button
    canvas.drawCircle(Offset(cx + 30, cy), 5, Paint()..color = _navyMid);
    canvas.drawCircle(Offset(cx + 30, cy), 3, Paint()..color = _navy);

    // Card slots
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 4, cy + 7), width: 44, height: 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = Colors.white.withOpacity(0.15),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 4, cy + 14), width: 30, height: 3),
        const Radius.circular(1.5),
      ),
      Paint()..color = Colors.white.withOpacity(0.10),
    );

    // Coin slot opening
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx - 10, cy - 25), width: 20, height: 7),
        const Radius.circular(3.5),
      ),
      Paint()..color = _navy,
    );
  }

  void _drawCoin(Canvas canvas, Size size) {
    final cx = size.width * 0.37 - 10;
    final cy = size.height * 0.22 + coinFloatY;
    const r = 17.0;

    // Glow
    canvas.drawCircle(
      Offset(cx, cy),
      r + 4,
      Paint()
        ..color = _gold.withOpacity(0.25)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // Outer coin
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = _gold);

    // Inner highlight
    canvas.drawCircle(Offset(cx, cy), r - 5, Paint()..color = _goldLight);

    // Border
    canvas.drawCircle(
      Offset(cx, cy),
      r,
      Paint()
        ..color = _goldBorder
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // "Rp" text
    final tp = TextPainter(
      text: const TextSpan(
        text: 'Rp',
        style: TextStyle(
          color: Color(0xFF7A4800),
          fontSize: 9,
          fontWeight: FontWeight.w900,
          fontFamily: 'Arial',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));
  }

  void _drawBrace(Canvas canvas, Size size) {
    // Curly brace "}" using TextPainter for clean rendering
    final tp = TextPainter(
      text: const TextSpan(
        text: '}',
        style: TextStyle(
          color: _navy,
          fontSize: 52,
          fontWeight: FontWeight.w900,
          fontFamily: 'Georgia',
          height: 1.0,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(
      canvas,
      Offset(size.width * 0.70, size.height * 0.28),
    );
  }

  @override
  bool shouldRepaint(covariant _LogoIconPainter old) =>
      old.coinFloatY != coinFloatY;
}
