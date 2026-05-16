// lib/screens/reset_password_screen.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String? _errorMsg;
  bool _success = false;

  static const _navy = Color(0xFF0D1B3E);
  static const _yellow = Color(0xFFF5C842);

  @override
  void dispose() {
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _updatePassword() async {
    final newPass = _newPassCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMsg = 'Please fill in all fields.');
      return;
    }
    if (newPass.length < 6) {
      setState(() => _errorMsg = 'Password must be at least 6 characters.');
      return;
    }
    if (newPass != confirmPass) {
      setState(() => _errorMsg = 'Passwords do not match.');
      return;
    }

    setState(() {
      _loading = true;
      _errorMsg = null;
    });

    try {
      await Supabase.instance.client.auth.updateUser(
        UserAttributes(password: newPass),
      );
      setState(() {
        _loading = false;
        _success = true;
      });
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) _goToLogin();
    } catch (e) {
      setState(() {
        _loading = false;
        _errorMsg = 'Failed to update password. Please try again.';
      });
    }
  }

  void _goToLogin() {
    Supabase.instance.client.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {},
      child: Scaffold(
        backgroundColor: _navy,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top white section ──────────────────────────────────
              Container(
                color: Colors.white,
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Back button
                    GestureDetector(
                      onTap: _goToLogin,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: _navy.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.arrow_back_rounded,
                            color: _navy, size: 20),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Icon + judul
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: _navy,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Icon(Icons.lock_reset_rounded,
                              color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Set new password',
                              style: GoogleFonts.dmSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: _navy,
                              ),
                            ),
                            Text(
                              'SCRIPT YOUR WEALTH.',
                              style: GoogleFonts.dmMono(
                                fontSize: 8,
                                letterSpacing: 2.5,
                                color: _yellow,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // ── Navy card section (fills rest of screen) ───────────
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: _navy,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: _success ? _buildSuccess() : _buildForm(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'New Password',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 8),
        _field(
          ctrl: _newPassCtrl,
          hint: '••••••••••••',
          obscure: _obscureNew,
          onToggle: () => setState(() => _obscureNew = !_obscureNew),
        ),
        const SizedBox(height: 20),
        Text(
          'Confirm Password',
          style: GoogleFonts.dmSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Colors.white.withOpacity(0.75),
          ),
        ),
        const SizedBox(height: 8),
        _field(
          ctrl: _confirmPassCtrl,
          hint: '••••••••••••',
          obscure: _obscureConfirm,
          onToggle: () => setState(() => _obscureConfirm = !_obscureConfirm),
        ),
        if (_errorMsg != null) ...[
          const SizedBox(height: 16),
          _buildError(),
        ],
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _loading ? null : _updatePassword,
            style: ElevatedButton.styleFrom(
              backgroundColor: _yellow,
              foregroundColor: _navy,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26)),
              elevation: 0,
            ),
            child: _loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: _navy, strokeWidth: 2.5),
                  )
                : Text(
                    'Update Password',
                    style: GoogleFonts.dmSans(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: _navy,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _field({
    required TextEditingController ctrl,
    required String hint,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.07),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: Colors.white.withOpacity(0.14), width: 1),
      ),
      child: TextField(
        controller: ctrl,
        obscureText: obscure,
        style: GoogleFonts.dmSans(
            fontSize: 14, color: Colors.white, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.dmSans(
              color: Colors.white.withOpacity(0.28), fontSize: 13),
          prefixIcon: Icon(Icons.lock_outline_rounded,
              color: Colors.white.withOpacity(0.38), size: 18),
          suffixIcon: GestureDetector(
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
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 8, vertical: 15),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Container(
      width: double.infinity,
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
            child: Text(_errorMsg!,
                style:
                    GoogleFonts.dmSans(color: Colors.redAccent, fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      children: [
        const SizedBox(height: 32),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.12),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: Color(0xFF10B981), size: 52),
              const SizedBox(height: 14),
              Text(
                'Password updated!',
                style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
              const SizedBox(height: 6),
              Text(
                'Redirecting you to login...',
                style: GoogleFonts.dmSans(
                    fontSize: 13, color: Colors.white.withOpacity(0.55)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
