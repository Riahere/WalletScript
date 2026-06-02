import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'app_top_bar.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsOn = true;
  String _theme = 'Light';

  // ── Color palette ─────────────────────────────────────────────────────────
  static const Color _navy = Color(0xFF0D1B3E);
  static const Color _yellow = Color(0xFFF5C842);
  static const Color _green = Color(0xFF1DB87A);
  static const Color _white = Colors.white;

  // Accent stays navy as primary; user can pick from all four brand colors
  Color _accent = _navy;

  // ── Lazy auth — only accessed once Supabase is ready ─────────────────────
  AuthService? _auth;
  bool _supabaseReady = false;

  final List<Color> _accents = [
    _navy,
    _yellow,
    _green,
    const Color(0xFF8B5CF6), // kept as additional option
  ];

  @override
  void initState() {
    super.initState();
    _initAuth();
  }

  void _initAuth() {
    try {
      // Check whether Supabase has been initialized
      Supabase.instance.client; // throws if not yet initialized
      _auth = AuthService();
      if (mounted) setState(() => _supabaseReady = true);
    } catch (_) {
      // Supabase not ready yet, retry after current frame
      WidgetsBinding.instance.addPostFrameCallback((_) => _initAuth());
    }
  }

  Future<void> _logout() async {
    if (_auth == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child:
                  const Text('Sign Out', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await _auth!.signOut();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('is_logged_in');
    if (mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Access user info only when Supabase is ready
    final name = _supabaseReady
        ? (_auth?.userName ?? 'WalletScript User')
        : 'WalletScript User';
    final email = _supabaseReady ? (_auth?.userEmail ?? '-') : '-';
    final avatar = _supabaseReady ? _auth?.userAvatar : null;

    return Scaffold(
      backgroundColor: _white,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(isDark: false),
              const SizedBox(height: 24),

              // ── Profile Card ───────────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: _white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _navy.withOpacity(0.15)),
                  boxShadow: [
                    BoxShadow(
                      color: _navy.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: _navy, width: 3),
                            color: _navy.withOpacity(0.08),
                          ),
                          child: ClipOval(
                            child: avatar != null
                                ? Image.network(avatar,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Icon(
                                        Icons.person_rounded,
                                        color: _navy,
                                        size: 44))
                                : Icon(Icons.person_rounded,
                                    color: _navy, size: 44),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                                color: _yellow, shape: BoxShape.circle),
                            child:
                                const Icon(Icons.edit, color: _navy, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(name,
                        style: const TextStyle(
                            color: _navy,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(email,
                        style: TextStyle(
                            color: _navy.withOpacity(0.55), fontSize: 13)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _navy,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Edit Profile',
                            style: TextStyle(
                                color: _white, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Account Settings ───────────────────────────────────────────
              _sectionLabel('ACCOUNT SETTINGS'),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(Icons.security_rounded, 'Security & Privacy',
                    trailing: Icon(Icons.chevron_right_rounded,
                        color: _navy.withOpacity(0.4))),
                Divider(height: 1, color: _navy.withOpacity(0.1)),
                _settingsRow(Icons.notifications_rounded, 'Notifications',
                    trailing: Switch(
                      value: _notificationsOn,
                      onChanged: (v) => setState(() => _notificationsOn = v),
                      activeColor: _green,
                    )),
              ]),
              const SizedBox(height: 16),

              // ── App Customization ──────────────────────────────────────────
              _sectionLabel('APP CUSTOMIZATION'),
              const SizedBox(height: 8),
              _settingsCard([
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.dark_mode_rounded,
                            color: _navy, size: 20),
                        const SizedBox(width: 12),
                        const Text('Theme',
                            style: TextStyle(
                                color: _navy, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: _navy.withOpacity(0.07),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: ['Light', 'Dark', 'System'].map((t) {
                              final isSelected = _theme == t;
                              return GestureDetector(
                                onTap: () => setState(() => _theme = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color:
                                        isSelected ? _navy : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: _navy.withOpacity(0.18),
                                                blurRadius: 4)
                                          ]
                                        : [],
                                  ),
                                  child: Text(t,
                                      style: TextStyle(
                                        color: isSelected
                                            ? _white
                                            : _navy.withOpacity(0.55),
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        fontSize: 12,
                                      )),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      const Text('Accent Color',
                          style: TextStyle(
                              color: _navy,
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 10),
                      Row(
                        children: _accents.map((c) {
                          final isSelected = _accent == c;
                          return GestureDetector(
                            onTap: () => setState(() => _accent = c),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              margin: const EdgeInsets.only(right: 12),
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color:
                                      isSelected ? _navy : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? Icon(Icons.check,
                                      color: c == _yellow ? _navy : _white,
                                      size: 18)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ]),
              const SizedBox(height: 16),

              // ── Data Management ────────────────────────────────────────────
              _sectionLabel('DATA MANAGEMENT'),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(Icons.download_rounded, 'Export Financial Data',
                    trailing: Icon(Icons.download_rounded,
                        color: _navy.withOpacity(0.4), size: 18)),
                Divider(height: 1, color: _navy.withOpacity(0.1)),
                _settingsRow(
                    Icons.delete_outline_rounded, 'Clear Transaction History',
                    textColor: Colors.red, iconColor: Colors.red),
              ]),
              const SizedBox(height: 16),

              // ── About & Support ────────────────────────────────────────────
              _sectionLabel('ABOUT & SUPPORT'),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(Icons.help_outline_rounded, 'Help Center',
                    trailing: Icon(Icons.open_in_new_rounded,
                        color: _navy.withOpacity(0.4), size: 16)),
                Divider(height: 1, color: _navy.withOpacity(0.1)),
                _settingsRow(Icons.privacy_tip_outlined, 'Privacy Policy'),
              ]),
              const SizedBox(height: 16),

              // ── Sign Out ───────────────────────────────────────────────────
              _settingsCard([
                _settingsRow(Icons.logout_rounded, 'Sign Out',
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: _logout),
              ]),
              const SizedBox(height: 16),

              Center(
                child: Text('WalletScript v1.0.0',
                    style:
                        TextStyle(color: _navy.withOpacity(0.4), fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Helper Widgets ─────────────────────────────────────────────────────────

  Widget _sectionLabel(String label) {
    return Text(label,
        style: TextStyle(
            color: _navy.withOpacity(0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: _white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _navy.withOpacity(0.12)),
        boxShadow: [
          BoxShadow(
            color: _navy.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _settingsRow(IconData icon, String label,
      {Widget? trailing,
      Color? textColor,
      Color? iconColor,
      VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? _navy, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: textColor ?? _navy,
                      fontWeight: FontWeight.w500,
                      fontSize: 14)),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }
}
