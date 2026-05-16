// lib/screens/login_screen.dart

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;
  String? _errorMsg;

  late AnimationController _cardCtrl;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;
  late AnimationController _floatCtrl;

  static const _navy = Color(0xFF0D1B3E);
  static const _yellow = Color(0xFFF5C842);

  @override
  void initState() {
    super.initState();
    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _cardFade = CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));

    _floatCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 4000))
      ..repeat(reverse: true);

    _cardCtrl.forward();
  }

  @override
  void dispose() {
    _cardCtrl.dispose();
    _floatCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _googleSignIn() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await _auth.signInWithGoogle();
      if (!mounted) return;
      if (res == null) {
        setState(() => _loading = false);
        return;
      }
      await SyncService().pullFromCloud();
      if (mounted) _goToHome();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = 'Google sign-in failed. Please try again.';
      });
    }
  }

  Future<void> _emailAuth() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Email and password are required.');
      return;
    }
    if (!_isLogin && _confirmPassCtrl.text.trim() != password) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      if (_isLogin) {
        debugPrint('>>> LOGIN: $email');
        final result = await _auth.signInWithEmail(email, password);
        if (!mounted) return;
        debugPrint('>>> LOGIN SUCCESS: ${result.user}');
        await SyncService().pullFromCloud();
        if (mounted) _goToHome();
      } else {
        debugPrint('>>> SIGNUP: $email');
        final result = await _auth.signUpWithEmail(
          email,
          password,
          fullName: _nameCtrl.text.trim(),
        );
        if (!mounted) return;
        debugPrint('>>> SIGNUP USER: ${result.user}');
        debugPrint('>>> SIGNUP SESSION: ${result.session}');
        if (mounted) _goToHome();
      }
    } catch (e) {
      debugPrint('>>> AUTH ERROR: $e');
      if (!mounted) return;
      setState(() {
        _loading = false;
        _errorMsg = e.toString();
      });
    }
  }

  void _switchMode() {
    if (!mounted) return;
    setState(() {
      _isLogin = !_isLogin;
      _errorMsg = null;
      _emailCtrl.clear();
      _passwordCtrl.clear();
      _nameCtrl.clear();
      _confirmPassCtrl.clear();
    });
    _cardCtrl.forward(from: 0);
  }

  // FIX: pakai pushNamedAndRemoveUntil supaya tidak ada duplicate LoginScreen di stack
  void _goToHome() {
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  Future<void> _forgotPassword() async {
    if (!mounted) return;
    final prefillEmail = _emailCtrl.text.trim();
    final emailCtrl = TextEditingController(text: prefillEmail);
    bool sending = false;
    bool sent = false;
    String? dialogError;

    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          backgroundColor: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _navy,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.lock_reset_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Reset Password',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: _navy,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(ctx).pop(),
                      child: Icon(Icons.close_rounded,
                          color: Colors.grey[400], size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (sent) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.3)),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.mark_email_read_rounded,
                            color: Color(0xFF10B981), size: 36),
                        const SizedBox(height: 10),
                        Text(
                          'Email sent!',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Check your inbox at\n${emailCtrl.text.trim()}\nand click the reset link.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: Text(
                        'Close',
                        style: GoogleFonts.dmSans(
                            color: _navy, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ] else ...[
                  Text(
                    "Enter your email and we'll send you a reset link.",
                    style: GoogleFonts.dmSans(
                        fontSize: 13, color: Colors.grey[500]),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: TextField(
                      controller: emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      style: GoogleFonts.dmSans(
                          fontSize: 14,
                          color: _navy,
                          fontWeight: FontWeight.w500),
                      decoration: InputDecoration(
                        hintText: 'your@email.com',
                        hintStyle: GoogleFonts.dmSans(
                            color: Colors.grey[400], fontSize: 13),
                        prefixIcon: Icon(Icons.email_outlined,
                            color: Colors.grey[400], size: 18),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 15),
                      ),
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: Colors.redAccent, size: 14),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              dialogError!,
                              style: GoogleFonts.dmSans(
                                  color: Colors.redAccent, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: sending
                          ? null
                          : () async {
                              final email = emailCtrl.text.trim();
                              if (email.isEmpty) {
                                setDialogState(() =>
                                    dialogError = 'Please enter your email.');
                                return;
                              }
                              setDialogState(() {
                                sending = true;
                                dialogError = null;
                              });
                              try {
                                await _auth.resetPassword(email);
                                setDialogState(() {
                                  sending = false;
                                  sent = true;
                                });
                              } catch (e) {
                                setDialogState(() {
                                  sending = false;
                                  dialogError =
                                      'Failed to send email. Try again.';
                                });
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _yellow,
                        foregroundColor: _navy,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: sending
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: _navy, strokeWidth: 2.5),
                            )
                          : Text(
                              'Send Reset Link',
                              style: GoogleFonts.dmSans(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: _navy,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );

    emailCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      body: AnimatedBuilder(
        animation: _floatCtrl,
        builder: (_, __) => Stack(
          children: [
            ..._buildFinanceIcons(size),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 36),
                    Image.asset(
                      'assets/images/logo.png',
                      width: 110,
                      height: 100,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => SizedBox(
                        width: 110,
                        height: 100,
                        child: CustomPaint(painter: _FallbackWalletPainter()),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'WalletScript',
                      style: GoogleFonts.dmSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: _navy,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SCRIPT YOUR WEALTH.',
                      style: GoogleFonts.dmMono(
                        fontSize: 9,
                        letterSpacing: 3.0,
                        color: _yellow,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 28),
                    FadeTransition(
                      opacity: _cardFade,
                      child: SlideTransition(
                        position: _cardSlide,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 22),
                          decoration: BoxDecoration(
                            color: _navy,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: _navy.withOpacity(0.28),
                                blurRadius: 48,
                                offset: const Offset(0, 18),
                              ),
                            ],
                          ),
                          child: Stack(
                            children: [
                              ..._buildCardIcons(),
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(24, 28, 24, 28),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isLogin ? 'Log in' : 'Sign up',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 26,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.1,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _isLogin
                                          ? 'Welcome back'
                                          : 'Create a new account',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 13,
                                        color: Colors.white.withOpacity(0.45),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    if (!_isLogin) ...[
                                      _field(
                                        ctrl: _nameCtrl,
                                        label: 'Full Name',
                                        hint: 'e.g. Budi Santoso',
                                        icon: Icons.person_outline_rounded,
                                      ),
                                      const SizedBox(height: 14),
                                    ],
                                    _field(
                                      ctrl: _emailCtrl,
                                      label: 'Email',
                                      hint: 'example@gmail.com',
                                      icon: Icons.email_outlined,
                                      type: TextInputType.emailAddress,
                                    ),
                                    const SizedBox(height: 14),
                                    _field(
                                      ctrl: _passwordCtrl,
                                      label: 'Password',
                                      hint: '••••••••••••',
                                      icon: Icons.lock_outline_rounded,
                                      obscure: _obscure,
                                      onToggle: () =>
                                          setState(() => _obscure = !_obscure),
                                    ),
                                    if (!_isLogin) ...[
                                      const SizedBox(height: 14),
                                      _field(
                                        ctrl: _confirmPassCtrl,
                                        label: 'Confirm Password',
                                        hint: '••••••••••••',
                                        icon: Icons.lock_outline_rounded,
                                        obscure: _obscureConfirm,
                                        onToggle: () => setState(() =>
                                            _obscureConfirm = !_obscureConfirm),
                                      ),
                                    ],
                                    if (_isLogin) ...[
                                      const SizedBox(height: 10),
                                      Align(
                                        alignment: Alignment.centerRight,
                                        child: GestureDetector(
                                          onTap: _forgotPassword,
                                          child: Text(
                                            'Forgot your password?',
                                            style: GoogleFonts.dmSans(
                                              color: _yellow,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 22),
                                    if (_errorMsg != null) _buildError(),
                                    _buildSubmitBtn(),
                                    const SizedBox(height: 16),
                                    Row(children: [
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white
                                                  .withOpacity(0.12))),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 12),
                                        child: Text(
                                          'OR',
                                          style: GoogleFonts.dmMono(
                                            color:
                                                Colors.white.withOpacity(0.35),
                                            fontSize: 10,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                          child: Divider(
                                              color: Colors.white
                                                  .withOpacity(0.12))),
                                    ]),
                                    const SizedBox(height: 16),
                                    _buildGoogleBtn(),
                                    const SizedBox(height: 22),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          _isLogin
                                              ? "Don't have an account? "
                                              : 'Already have an account? ',
                                          style: GoogleFonts.dmSans(
                                              color: Colors.white
                                                  .withOpacity(0.45),
                                              fontSize: 13),
                                        ),
                                        GestureDetector(
                                          onTap: _switchMode,
                                          child: Text(
                                            _isLogin
                                                ? 'Register here!'
                                                : 'Log in here!',
                                            style: GoogleFonts.dmSans(
                                              color: _yellow,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                              decoration:
                                                  TextDecoration.underline,
                                              decorationColor: _yellow,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    GestureDetector(
                      onTap: _goToHome,
                      child: Text(
                        'Continue without account →',
                        style: GoogleFonts.dmSans(
                            color: Colors.grey[400], fontSize: 13),
                      ),
                    ),
                    const SizedBox(height: 36),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? type,
    bool obscure = false,
    VoidCallback? onToggle,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 7),
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.07),
              borderRadius: BorderRadius.circular(26),
              border:
                  Border.all(color: Colors.white.withOpacity(0.14), width: 1),
            ),
            child: TextField(
              controller: ctrl,
              keyboardType: type,
              obscureText: obscure,
              style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: Colors.white,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.dmSans(
                    color: Colors.white.withOpacity(0.28), fontSize: 13),
                prefixIcon:
                    Icon(icon, color: Colors.white.withOpacity(0.38), size: 18),
                suffixIcon: onToggle != null
                    ? GestureDetector(
                        onTap: onToggle,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: Icon(
                            obscure
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white.withOpacity(0.38),
                            size: 18,
                          ),
                        ),
                      )
                    : null,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _emailAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: _yellow,
          foregroundColor: _navy,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          elevation: 0,
        ),
        child: _loading
            ? SizedBox(
                width: 22,
                height: 22,
                child:
                    CircularProgressIndicator(color: _navy, strokeWidth: 2.5),
              )
            : Text(
                _isLogin ? 'Log in' : 'Sign up',
                style: GoogleFonts.dmSans(
                    fontWeight: FontWeight.w800, fontSize: 15, color: _navy),
              ),
      ),
    );
  }

  Widget _buildGoogleBtn() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: _loading ? null : _googleSignIn,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withOpacity(0.18), width: 1.5),
          backgroundColor: Colors.white.withOpacity(0.05),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        ),
        child: _loading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white.withOpacity(0.5)),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CustomPaint(painter: _GoogleLogoPainter()),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _isLogin ? 'Log in with Google' : 'Sign up with Google',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      color: Colors.white.withOpacity(0.82),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMsg!,
              style: GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildFinanceIcons(Size size) {
    final items = [
      [Icons.bar_chart_rounded, 0.05, 0.03, 30.0, 0.0],
      [Icons.savings_outlined, 0.78, 0.05, 24.0, 0.5],
      [Icons.account_balance_outlined, 0.40, 0.02, 22.0, 0.1],
      [Icons.trending_up_rounded, 0.88, 0.14, 28.0, 0.2],
      [Icons.monetization_on_outlined, 0.12, 0.16, 20.0, 0.8],
      [Icons.credit_card_rounded, 0.02, 0.35, 22.0, 0.3],
      [Icons.show_chart_rounded, 0.88, 0.40, 28.0, 0.9],
      [Icons.receipt_long_outlined, 0.03, 0.55, 20.0, 0.6],
      [Icons.pie_chart_outline_rounded, 0.86, 0.60, 22.0, 0.7],
      [Icons.account_balance_wallet_outlined, 0.10, 0.88, 22.0, 0.4],
      [Icons.currency_exchange_rounded, 0.75, 0.85, 20.0, 0.65],
      [Icons.attach_money_rounded, 0.45, 0.92, 24.0, 0.35],
      [Icons.wallet_outlined, 0.60, 0.78, 20.0, 0.55],
    ];

    return items.map((d) {
      final dy =
          math.sin((_floatCtrl.value + (d[4] as double)) * math.pi * 2) * 5;
      return Positioned(
        left: (d[1] as double) * size.width,
        top: (d[2] as double) * size.height + dy,
        child: Icon(
          d[0] as IconData,
          size: d[3] as double,
          color: _navy.withOpacity(0.055),
        ),
      );
    }).toList();
  }

  List<Widget> _buildCardIcons() {
    final items = [
      [Icons.bar_chart_rounded, 0.78, 0.04, 28.0],
      [Icons.show_chart_rounded, 0.04, 0.06, 26.0],
      [Icons.savings_outlined, 0.82, 0.82, 22.0],
      [Icons.pie_chart_outline_rounded, 0.02, 0.85, 20.0],
    ];

    return items.map((d) {
      return Positioned(
        left: (d[1] as double) * 350,
        top: (d[2] as double) * 500,
        child: Icon(
          d[0] as IconData,
          size: d[3] as double,
          color: Colors.white.withOpacity(0.05),
        ),
      );
    }).toList();
  }
}

class _FallbackWalletPainter extends CustomPainter {
  static const _gold = Color(0xFFF5C842);
  static const _navy = Color(0xFF0D1B3E);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.42, w * 0.80, h * 0.54),
          const Radius.circular(9)),
      Paint()..color = _navy,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(0, h * 0.42, w * 0.80, h * 0.18),
          const Radius.circular(9)),
      Paint()..color = const Color(0xFF162B5E),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.72, h * 0.54, w * 0.20, h * 0.20),
          const Radius.circular(5)),
      Paint()..color = const Color(0xFF162B5E),
    );
    canvas.drawCircle(
        Offset(w * 0.86, h * 0.64), w * 0.060, Paint()..color = _navy);
    canvas.drawCircle(Offset(w * 0.86, h * 0.64), w * 0.036,
        Paint()..color = const Color(0xFF162B5E));
    canvas.drawCircle(
        Offset(w * 0.48, h * 0.20), w * 0.26, Paint()..color = _gold);
    canvas.drawCircle(Offset(w * 0.48, h * 0.20), w * 0.26 * 0.60,
        Paint()..color = const Color(0xFFFFCC00));
    canvas.drawCircle(
        Offset(w * 0.48, h * 0.20),
        w * 0.26,
        Paint()
          ..color = const Color(0xFFCC9900)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

class _GoogleLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.38;
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        -0.52, 1.57, false, paint);
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        1.05, 1.15, false, paint);
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        2.20, 0.95, false, paint);
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: Offset(cx, cy), radius: r * 0.78),
        3.15, 1.00, false, paint);
    canvas.drawLine(
      Offset(cx, cy),
      Offset(cx + r * 0.72, cy),
      Paint()
        ..color = const Color(0xFF4285F4)
        ..strokeWidth = r * 0.38
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}
