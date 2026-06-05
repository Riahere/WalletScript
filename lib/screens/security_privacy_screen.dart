import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/notification_service.dart';
import 'privacy_policy_screen.dart';
import 'terms_of_service_screen.dart';

class _C {
  static const navy = Color(0xFF0D1B3E);
  static const yellow = Color(0xFFF5C842);
  static const green = Color(0xFF1DB87A);
  static const white = Color(0xFFFFFFFF);
  static const grey = Color(0xFF6B7280);
  static const cardBg = Color(0xFFF9FAFB);
  static const border = Color(0xFFE5E7EB);
  static const red = Color(0xFFEF4444);
}

class SecurityPrivacyScreen extends StatefulWidget {
  const SecurityPrivacyScreen({super.key});

  @override
  State<SecurityPrivacyScreen> createState() => _SecurityPrivacyScreenState();
}

class _SecurityPrivacyScreenState extends State<SecurityPrivacyScreen> {
  bool _biometric = false;
  bool _loginAlert = true;
  bool _twoFactor = false;
  bool _loadingSessions = false;
  bool _loadingPrefs = true;

  List<Map<String, dynamic>> _sessions = [];

  static const _keyBiometric = 'sec_biometric';
  static const _keyLoginAlert = 'sec_login_alert';
  static const _keyTwoFactor = 'sec_two_factor';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
    _loadSessions();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _biometric = prefs.getBool(_keyBiometric) ?? false;
        _loginAlert = prefs.getBool(_keyLoginAlert) ?? true;
        _twoFactor = prefs.getBool(_keyTwoFactor) ?? false;
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _savePref(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _loadSessions() async {
    setState(() => _loadingSessions = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        _sessions = [
          {
            'device': 'This Device',
            'last_active': 'Active now',
            'current': true
          },
        ];
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingSessions = false);
  }

  Future<void> _sendPasswordReset() async {
    final email = Supabase.instance.client.auth.currentUser?.email ?? '';
    if (email.isEmpty) return;
    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      _snack('Password reset email sent to $email');
    } on AuthException catch (e) {
      _snack(e.message, isError: true);
    }
  }

  Future<void> _onLoginAlertChanged(bool v) async {
    setState(() => _loginAlert = v);
    await _savePref(_keyLoginAlert, v);

    if (v) {
      final now = DateTime.now();
      var scheduled = DateTime(now.year, now.month, now.day, 20, 0);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 1));
      }

      await NotificationService().scheduleReminder(
        id: 1,
        title: '💰 WalletScript Reminder',
        body: "Jangan lupa catat transaksi hari ini!",
        scheduledDate: scheduled,
      );

      if (mounted) _snack('Daily reminder aktif — jam 20:00');
    } else {
      await NotificationService().cancelReminder(1);
      if (mounted) _snack('Daily reminder dimatikan');
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? _C.red : _C.green,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _C.white,
      appBar: AppBar(
        backgroundColor: _C.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: _C.navy),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Security & Privacy',
          style: TextStyle(
              color: _C.navy, fontWeight: FontWeight.w700, fontSize: 18),
        ),
      ),
      body: _loadingPrefs
          ? const Center(child: CircularProgressIndicator(color: _C.navy))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Authentication ─────────────────────────────────────
                  _sectionLabel('Authentication'),
                  _card([
                    _switchRow(
                      icon: Icons.fingerprint_rounded,
                      label: 'Biometric Login',
                      subtitle: 'Use fingerprint or Face ID to unlock',
                      value: _biometric,
                      onChanged: (v) {
                        setState(() => _biometric = v);
                        _savePref(_keyBiometric, v);
                      },
                    ),
                    _divider(),
                    _switchRow(
                      icon: Icons.verified_user_rounded,
                      label: 'Two-Factor Authentication',
                      subtitle: 'Extra layer of account security',
                      value: _twoFactor,
                      onChanged: (v) {
                        setState(() => _twoFactor = v);
                        _savePref(_keyTwoFactor, v);
                      },
                    ),
                    _divider(),
                    _tappableRow(
                      icon: Icons.lock_reset_rounded,
                      label: 'Send Password Reset Email',
                      onTap: _sendPasswordReset,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Alerts ────────────────────────────────────────────
                  _sectionLabel('Alerts'),
                  _card([
                    _switchRow(
                      icon: Icons.notifications_active_rounded,
                      label: 'Login Alerts',
                      subtitle: 'Get notified on new sign-ins',
                      value: _loginAlert,
                      onChanged: _onLoginAlertChanged,
                    ),
                  ]),
                  const SizedBox(height: 20),

                  // ── Active Sessions ───────────────────────────────────
                  _sectionLabel('Active Sessions'),
                  _card([
                    if (_loadingSessions)
                      const Padding(
                        padding: EdgeInsets.all(20),
                        child: Center(
                            child: CircularProgressIndicator(color: _C.navy)),
                      )
                    else
                      ..._sessions.asMap().entries.map((e) {
                        final s = e.value;
                        return Column(children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                            child: Row(children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: _C.navy.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.phone_android_rounded,
                                    color: _C.navy, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(s['device'],
                                        style: const TextStyle(
                                            color: _C.navy,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 14)),
                                    const SizedBox(height: 2),
                                    Text(s['last_active'],
                                        style: const TextStyle(
                                            color: _C.grey, fontSize: 12)),
                                  ],
                                ),
                              ),
                              if (s['current'] == true)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: _C.green.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Text('Current',
                                      style: TextStyle(
                                          color: _C.green,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700)),
                                )
                              else
                                TextButton(
                                  onPressed: () {},
                                  child: const Text('Revoke',
                                      style: TextStyle(
                                          color: _C.red, fontSize: 12)),
                                ),
                            ]),
                          ),
                          if (e.key < _sessions.length - 1) _divider(),
                        ]);
                      }),
                  ]),
                  const SizedBox(height: 20),

                  // ── Privacy ───────────────────────────────────────────
                  _sectionLabel('Privacy'),
                  _card([
                    _tappableRow(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Privacy Policy',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: _C.grey),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PrivacyPolicyScreen(),
                        ),
                      ),
                    ),
                    _divider(),
                    _tappableRow(
                      icon: Icons.description_outlined,
                      label: 'Terms of Service',
                      trailing: const Icon(Icons.chevron_right_rounded,
                          color: _C.grey),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const TermsOfServiceScreen(),
                        ),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _sectionLabel(String t) => Padding(
        padding: const EdgeInsets.only(bottom: 8, left: 2),
        child: Text(
          t.toUpperCase(),
          style: TextStyle(
            color: _C.grey.withOpacity(0.7),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.7,
          ),
        ),
      );

  Widget _card(List<Widget> children) => Container(
        decoration: BoxDecoration(
          color: _C.cardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _C.border),
        ),
        child: Column(children: children),
      );

  Widget _divider() =>
      const Divider(height: 1, indent: 16, endIndent: 16, color: _C.border);

  Widget _switchRow({
    required IconData icon,
    required String label,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Icon(icon, color: _C.navy, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label,
                style: const TextStyle(
                    color: _C.navy, fontWeight: FontWeight.w600, fontSize: 14)),
            if (subtitle != null)
              Text(subtitle,
                  style: const TextStyle(color: _C.grey, fontSize: 12)),
          ]),
        ),
        Switch(value: value, onChanged: onChanged, activeColor: _C.green),
      ]),
    );
  }

  Widget _tappableRow({
    required IconData icon,
    required String label,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(children: [
          Icon(icon, color: _C.navy, size: 22),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: _C.navy,
                      fontWeight: FontWeight.w600,
                      fontSize: 14))),
          trailing ??
              Icon(Icons.chevron_right_rounded,
                  color: _C.grey.withOpacity(0.5)),
        ]),
      ),
    );
  }
}
