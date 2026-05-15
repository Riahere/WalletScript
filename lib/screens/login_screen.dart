// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../services/sync_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _auth = AuthService();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  bool _obscure = true;
  String? _errorMsg;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  Future<void> _googleSignIn() async {
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      final res = await _auth.signInWithGoogle();
      if (res == null) {
        setState(() => _loading = false);
        return; // user batal
      }
      await SyncService().pullFromCloud();
      if (mounted) _goToHome();
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Login Google gagal. Coba lagi.';
      });
    }
  }

  Future<void> _emailAuth() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMsg = 'Email dan password tidak boleh kosong.');
      return;
    }
    setState(() {
      _loading = true;
      _errorMsg = null;
    });
    try {
      if (_isLogin) {
        await _auth.signInWithEmail(email, password);
        await SyncService().pullFromCloud();
      } else {
        final name = _nameCtrl.text.trim();
        await _auth.signUpWithEmail(email, password, fullName: name);
      }
      if (mounted) _goToHome();
    } catch (e) {
      String msg = _isLogin
          ? 'Email atau password salah.'
          : 'Pendaftaran gagal. Email mungkin sudah terdaftar.';
      setState(() {
        _loading = false;
        _errorMsg = msg;
      });
    }
  }

  void _skipLogin() => _goToHome();

  void _goToHome() {
    Navigator.pushReplacementNamed(context, '/home');
  }

  // ─── UI ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F4FF),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              children: [
                const SizedBox(height: 52),
                _buildHeader(),
                const SizedBox(height: 40),
                _buildGoogleButton(),
                const SizedBox(height: 20),
                _buildDivider(),
                const SizedBox(height: 20),
                if (!_isLogin) _buildNameField(),
                _buildEmailField(),
                const SizedBox(height: 12),
                _buildPasswordField(),
                const SizedBox(height: 8),
                if (_isLogin) _buildForgotPassword(),
                const SizedBox(height: 20),
                if (_errorMsg != null) _buildError(),
                _buildSubmitButton(),
                const SizedBox(height: 16),
                _buildToggleMode(),
                const SizedBox(height: 24),
                _buildSkipButton(),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF9B8FFF), Color(0xFF7C6EE8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF9B8FFF).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              )
            ],
          ),
          child: const Icon(
            Icons.account_balance_wallet_rounded,
            color: Colors.white,
            size: 36,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'WalletScript',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _isLogin ? 'Selamat datang kembali 👋' : 'Buat akun baru',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: Colors.grey[500],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: _loading ? null : _googleSignIn,
        icon: _loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Image.network(
                'https://www.gstatic.com/firebasejs/ui/2.0.0/images/auth/google.svg',
                width: 20,
                height: 20,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.g_mobiledata, size: 24),
              ),
        label: Text(
          _isLogin ? 'Lanjutkan dengan Google' : 'Daftar dengan Google',
          style: GoogleFonts.plusJakartaSans(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1E1B4B),
          ),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFDDD6FE), width: 1.5),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.grey[300])),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'atau',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.grey[400],
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: Colors.grey[300])),
      ],
    );
  }

  Widget _buildNameField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _inputField(
        controller: _nameCtrl,
        label: 'Nama lengkap',
        icon: Icons.person_outline_rounded,
      ),
    );
  }

  Widget _buildEmailField() {
    return _inputField(
      controller: _emailCtrl,
      label: 'Email',
      icon: Icons.email_outlined,
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField() {
    return _inputField(
      controller: _passwordCtrl,
      label: 'Password',
      icon: Icons.lock_outline_rounded,
      obscure: _obscure,
      suffix: IconButton(
        icon: Icon(
          _obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
          color: Colors.grey[400],
          size: 20,
        ),
        onPressed: () => setState(() => _obscure = !_obscure),
      ),
    );
  }

  Widget _inputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscure = false,
    Widget? suffix,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        obscureText: obscure,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: const Color(0xFF1E1B4B),
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.plusJakartaSans(
            color: Colors.grey[400],
            fontSize: 13,
          ),
          prefixIcon: Icon(icon, color: const Color(0xFF9B8FFF), size: 20),
          suffixIcon: suffix,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildForgotPassword() {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton(
        onPressed: () async {
          final email = _emailCtrl.text.trim();
          if (email.isEmpty) {
            setState(() => _errorMsg = 'Isi email dulu untuk reset password.');
            return;
          }
          await _auth.resetPassword(email);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content: Text('Email reset password sudah dikirim!')),
            );
          }
        },
        child: Text(
          'Lupa password?',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF9B8FFF),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEDED),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _errorMsg!,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.red[700],
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _loading ? null : _emailAuth,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF7C6EE8),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2))
            : Text(
                _isLogin ? 'Masuk' : 'Daftar',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
      ),
    );
  }

  Widget _buildToggleMode() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          _isLogin ? 'Belum punya akun? ' : 'Sudah punya akun? ',
          style: GoogleFonts.plusJakartaSans(
            color: Colors.grey[500],
            fontSize: 13,
          ),
        ),
        GestureDetector(
          onTap: () => setState(() {
            _isLogin = !_isLogin;
            _errorMsg = null;
          }),
          child: Text(
            _isLogin ? 'Daftar' : 'Masuk',
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF7C6EE8),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSkipButton() {
    return GestureDetector(
      onTap: _skipLogin,
      child: Text(
        'Lanjutkan tanpa akun →',
        style: GoogleFonts.plusJakartaSans(
          color: Colors.grey[400],
          fontSize: 13,
        ),
      ),
    );
  }
}
