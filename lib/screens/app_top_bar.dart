// lib/screens/app_top_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'notification_screen.dart';

class AppTopBar extends StatefulWidget implements PreferredSizeWidget {
  /// [isDark] true  → white text/icons (for dark/navy background, e.g. Home)
  /// [isDark] false → dark text/icons (for white/light background, e.g. Settings, etc.)
  final bool isDark;

  const AppTopBar({super.key, this.isDark = true});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  State<AppTopBar> createState() => _AppTopBarState();
}

class _AppTopBarState extends State<AppTopBar> {
  String? _avatarUrl;
  String _initial = 'U';
  String _name = 'User';

  late final RealtimeChannel _authSubscription;

  @override
  void initState() {
    super.initState();
    _loadUser();

    // Listen to auth state changes so avatar updates across all screens
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (mounted) _loadUser();
    });
  }

  void _loadUser() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final meta = user.userMetadata ?? {};
    final name = (meta['full_name'] as String? ??
        meta['name'] as String? ??
        user.email ??
        'User');
    final avatar = meta['avatar_url'] as String?;

    if (mounted) {
      setState(() {
        _name = name;
        _initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        _avatarUrl = (avatar != null && avatar.isNotEmpty) ? avatar : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // ── Adaptive colors ──────────────────────────────────────────────────
    final Color foreground =
        widget.isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color avatarBg = widget.isDark
        ? Colors.white.withOpacity(0.12)
        : const Color(0xFF1A1A2E).withOpacity(0.08);
    final Color avatarBorder = widget.isDark
        ? Colors.white.withOpacity(0.22)
        : const Color(0xFF1A1A2E).withOpacity(0.18);
    final Color iconBg = widget.isDark
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFF1A1A2E).withOpacity(0.07);
    final Color iconColor = widget.isDark
        ? Colors.white.withOpacity(0.85)
        : const Color(0xFF1A1A2E).withOpacity(0.75);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // ── Avatar ────────────────────────────────────────────────────
            GestureDetector(
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                );
                // Refresh after returning from ProfileScreen
                _loadUser();
              },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarBg,
                  border: Border.all(color: avatarBorder, width: 1.5),
                ),
                child: ClipOval(
                  child: _avatarUrl != null
                      ? Image.network(
                          // Cache-bust so latest photo appears immediately
                          '$_avatarUrl?t=${DateTime.now().millisecondsSinceEpoch}',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              _initialWidget(foreground),
                        )
                      : _initialWidget(foreground),
                ),
              ),
            ),
            const SizedBox(width: 7),

            // ── App name ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () {
                final shell = context.findAncestorStateOfType<MainShellState>();
                if (shell != null) {
                  shell.goHome();
                } else {
                  Navigator.popUntil(context, (route) => route.isFirst);
                }
              },
              child: Text(
                'WalletScript',
                style: GoogleFonts.dmSans(
                  color: foreground,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
              ),
            ),

            const Spacer(),

            // ── Notes icon ────────────────────────────────────────────────
            _iconBtn(
              icon: Icons.sticky_note_2_outlined,
              iconBg: iconBg,
              iconColor: iconColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => NotesScreen()),
              ),
            ),
            const SizedBox(width: 6),

            // ── Calendar icon ─────────────────────────────────────────────
            _iconBtn(
              icon: Icons.calendar_month_outlined,
              iconBg: iconBg,
              iconColor: iconColor,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()),
              ),
            ),
            const SizedBox(width: 6),

            // ── Notification icon with red dot badge ──────────────────────
            Stack(
              clipBehavior: Clip.none,
              children: [
                _iconBtn(
                  icon: Icons.notifications_outlined,
                  iconBg: iconBg,
                  iconColor: iconColor,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()),
                  ),
                ),
                Positioned(
                  top: 5,
                  right: 5,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Initial letter fallback ───────────────────────────────────────────────
  Widget _initialWidget(Color foreground) {
    return Center(
      child: Text(
        _initial,
        style: GoogleFonts.dmSans(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  static Widget _iconBtn({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 15),
      ),
    );
  }
}
