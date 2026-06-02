// lib/screens/app_top_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'notification_screen.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  /// [isDark] true  → white text/icons (for dark/navy background, e.g. Home)
  /// [isDark] false → dark text/icons (for white/light background, e.g. Flow History, etc.)
  final bool isDark;

  const AppTopBar({super.key, this.isDark = true});

  // Implement PreferredSizeWidget so AppTopBar can be used as AppBar directly
  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final name = AuthService().userName ?? 'User';
    final avatar = AuthService().userAvatar;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    // ── Adaptive colors ────────────────────────────────────────────────
    final Color foreground = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final Color avatarBg = isDark
        ? Colors.white.withOpacity(0.12)
        : const Color(0xFF1A1A2E).withOpacity(0.08);
    final Color avatarBorder = isDark
        ? Colors.white.withOpacity(0.22)
        : const Color(0xFF1A1A2E).withOpacity(0.18);
    final Color iconBg = isDark
        ? Colors.white.withOpacity(0.10)
        : const Color(0xFF1A1A2E).withOpacity(0.07);
    final Color iconColor = isDark
        ? Colors.white.withOpacity(0.85)
        : const Color(0xFF1A1A2E).withOpacity(0.75);

    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            // ── Avatar ──────────────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarBg,
                  border: Border.all(color: avatarBorder, width: 1.5),
                ),
                child: avatar != null
                    ? ClipOval(
                        child: Image.network(
                          avatar,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Center(
                            child: Text(
                              initial,
                              style: GoogleFonts.dmSans(
                                color: foreground,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      )
                    : Center(
                        child: Text(
                          initial,
                          style: GoogleFonts.dmSans(
                            color: foreground,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 7),

            // ── App name ─────────────────────────────────────────────────
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

            // ── Notes icon ───────────────────────────────────────────────
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

            // ── Calendar icon ────────────────────────────────────────────
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

            // ── Notification icon with red dot badge ─────────────────────
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
