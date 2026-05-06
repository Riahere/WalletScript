import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import '../main.dart';
import 'notification_screen.dart';

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Avatar - tap = Profile
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ProfileScreen()),
          ),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.primary, width: 2),
              color: AppTheme.surfaceContainer,
            ),
            child: const Icon(Icons.person_rounded,
                color: AppTheme.primary, size: 26),
          ),
        ),
        const SizedBox(width: 10),

        // WalletScript - tap = Home
        GestureDetector(
          onTap: () {
            final shell = context.findAncestorStateOfType<MainShellState>();
            if (shell != null) {
              shell.goHome();
            } else {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
          child: const Text(
            'WalletScript',
            style: TextStyle(
                color: AppTheme.primary,
                fontSize: 20,
                fontWeight: FontWeight.w800),
          ),
        ),

        const Spacer(),

        // Notes
        _iconBtn(
          context,
          Icons.sticky_note_2_outlined,
          onTap: () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const NotesScreen())),
        ),
        const SizedBox(width: 6),

        // Calendar
        _iconBtn(
          context,
          Icons.calendar_month_outlined,
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const CalendarScreen())),
        ),
        const SizedBox(width: 6),

        // Notification
        Stack(
          children: [
            _iconBtn(
              context,
              Icons.notifications_outlined,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationScreen()),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _iconBtn(BuildContext context, IconData icon,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: AppTheme.outline),
        ),
        child: Icon(icon, color: AppTheme.onSurface, size: 19),
      ),
    );
  }
}
