// lib/screens/app_top_bar.dart
// Colors match mockup: white avatar border, white app name, white icons — all on navy bg

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'notification_screen.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final name = AuthService().userName ?? 'User';
    final avatar = AuthService().userAvatar;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Row(
      children: [
        // ── Avatar ────────────────────────────────────────────────────────
        // mockup: rgba(255,255,255,0.12) bg, border rgba(255,255,255,0.22)
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.12),
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1.5),
            ),
            child: avatar != null
                ? ClipOval(
                    child: Image.network(avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                              child: Text(initial,
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12)),
                            )),
                  )
                : Center(
                    child: Text(initial,
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  ),
          ),
        ),
        const SizedBox(width: 7),

        // ── App name — WHITE (on navy bg) ─────────────────────────────────
        // mockup: font-size:15px, font-weight:800, color:#fff
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
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),

        const Spacer(),

        // ── Icon buttons — white icons on rgba(255,255,255,0.1) bg ──────
        // mockup: width:30px, height:30px, background:rgba(255,255,255,0.1), border-radius:8px
        _iconBtn(
          icon: Icons.sticky_note_2_outlined,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NotesScreen())),
        ),
        const SizedBox(width: 6),

        _iconBtn(
          icon: Icons.calendar_month_outlined,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CalendarScreen())),
        ),
        const SizedBox(width: 6),

        // Notification with red dot badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            _iconBtn(
              icon: Icons.notifications_outlined,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotificationScreen())),
            ),
            // red dot badge — mockup: top:5px, right:5px, width:6px, height:6px
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
    );
  }

  static Widget _iconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          // mockup: rgba(255,255,255,0.1)
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon,
            // mockup: color:rgba(255,255,255,0.7)
            color: Colors.white.withOpacity(0.7),
            size: 15),
      ),
    );
  }
}
