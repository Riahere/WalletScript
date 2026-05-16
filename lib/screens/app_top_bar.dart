// lib/screens/app_top_bar.dart

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../main.dart';
import '../services/auth_service.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'notification_screen.dart';

const _navy = Color(0xFF0D1B3E);
const _yellow = Color(0xFFF5C842);

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    final user = AuthService().currentUser;
    final name = AuthService().userName ?? 'User';
    final avatar = AuthService().userAvatar;
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Row(
      children: [
        // Avatar / profile button
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _yellow, width: 2),
              color: _navy,
            ),
            child: avatar != null
                ? ClipOval(
                    child: Image.network(avatar,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                              child: Text(initial,
                                  style: GoogleFonts.dmSans(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 16)),
                            )),
                  )
                : Center(
                    child: Text(initial,
                        style: GoogleFonts.dmSans(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16)),
                  ),
          ),
        ),
        const SizedBox(width: 10),

        // App name
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
              color: _navy,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),

        const Spacer(),

        // Notes
        _iconBtn(
          icon: Icons.sticky_note_2_outlined,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NotesScreen())),
        ),
        const SizedBox(width: 6),

        // Calendar
        _iconBtn(
          icon: Icons.calendar_month_outlined,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CalendarScreen())),
        ),
        const SizedBox(width: 6),

        // Notification with badge
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
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 1.5),
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
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _navy.withOpacity(0.06),
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _navy.withOpacity(0.1)),
        ),
        child: Icon(icon, color: _navy, size: 19),
      ),
    );
  }
}
