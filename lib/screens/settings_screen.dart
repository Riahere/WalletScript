import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  Color _accent = AppTheme.primary;
  final _auth = AuthService();

  final List<Color> _accents = [
    AppTheme.primary,
    const Color(0xFF3B82F6),
    const Color(0xFF1E293B),
    const Color(0xFF8B5CF6),
  ];

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Keluar'),
        content: const Text('Yakin mau keluar dari akun?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Keluar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm != true) return;
    await _auth.signOut();
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
    final name = _auth.userName ?? 'Pengguna WalletScript';
    final email = _auth.userEmail ?? '-';
    final avatar = _auth.userAvatar;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(),
              const SizedBox(height: 24),

              // Profile Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
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
                            border:
                                Border.all(color: AppTheme.primary, width: 3),
                            color: AppTheme.surfaceContainer,
                          ),
                          child: ClipOval(
                            child: avatar != null
                                ? Image.network(avatar,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                        Icons.person_rounded,
                                        color: AppTheme.primary,
                                        size: 44))
                                : const Icon(Icons.person_rounded,
                                    color: AppTheme.primary, size: 44),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            width: 26,
                            height: 26,
                            decoration: const BoxDecoration(
                                color: AppTheme.primary,
                                shape: BoxShape.circle),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(name,
                        style: const TextStyle(
                            color: AppTheme.onSurface,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text(email,
                        style: const TextStyle(
                            color: AppTheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Edit Profile',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _sectionLabel('ACCOUNT SETTINGS'),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(Icons.security_rounded, 'Security & Privacy',
                    trailing: const Icon(Icons.chevron_right_rounded,
                        color: AppTheme.onSurfaceVariant)),
                const Divider(height: 1, color: AppTheme.outline),
                _settingsRow(Icons.notifications_rounded, 'Notifications',
                    trailing: Switch(
                      value: _notificationsOn,
                      onChanged: (v) => setState(() => _notificationsOn = v),
                      activeColor: AppTheme.primary,
                    )),
              ]),
              const SizedBox(height: 16),

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
                            color: AppTheme.primary, size: 20),
                        const SizedBox(width: 12),
                        const Text('Theme',
                            style: TextStyle(
                                color: AppTheme.onSurface,
                                fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceContainer,
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
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: isSelected
                                        ? [
                                            BoxShadow(
                                                color: Colors.black
                                                    .withOpacity(0.08),
                                                blurRadius: 4)
                                          ]
                                        : [],
                                  ),
                                  child: Text(t,
                                      style: TextStyle(
                                        color: isSelected
                                            ? AppTheme.onSurface
                                            : AppTheme.onSurfaceVariant,
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
                              color: AppTheme.onSurface,
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
                                  color: isSelected
                                      ? AppTheme.onSurface
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check,
                                      color: Colors.white, size: 18)
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

              _sectionLabel('DATA MANAGEMENT'),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(Icons.download_rounded, 'Export Financial Data',
                    trailing: const Icon(Icons.download_rounded,
                        color: AppTheme.onSurfaceVariant, size: 18)),
                const Divider(height: 1, color: AppTheme.outline),
                _settingsRow(
                    Icons.delete_outline_rounded, 'Clear Transaction History',
                    textColor: AppTheme.error, iconColor: AppTheme.error),
              ]),
              const SizedBox(height: 16),

              _sectionLabel('ABOUT & SUPPORT'),
              const SizedBox(height: 8),
              _settingsCard([
                _settingsRow(Icons.help_outline_rounded, 'Help Center',
                    trailing: const Icon(Icons.open_in_new_rounded,
                        color: AppTheme.onSurfaceVariant, size: 16)),
                const Divider(height: 1, color: AppTheme.outline),
                _settingsRow(Icons.privacy_tip_outlined, 'Privacy Policy'),
              ]),
              const SizedBox(height: 16),

              // Logout button
              _settingsCard([
                _settingsRow(Icons.logout_rounded, 'Keluar',
                    textColor: Colors.red,
                    iconColor: Colors.red,
                    onTap: _logout),
              ]),
              const SizedBox(height: 16),

              Center(
                child: Text('WalletScript v1.0.0',
                    style: TextStyle(
                        color: AppTheme.onSurfaceVariant, fontSize: 13)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(label,
        style: const TextStyle(
            color: AppTheme.onSurfaceVariant,
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8));
  }

  Widget _settingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
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
            Icon(icon, color: iconColor ?? AppTheme.primary, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      color: textColor ?? AppTheme.onSurface,
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
