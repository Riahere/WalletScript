import 'package:flutter/material.dart';
import '../main.dart';
import 'profile_screen.dart';
import 'notes_screen.dart';
import 'calendar_screen.dart';
import 'notification_screen.dart';

const _cPrimary = Color(0xFF10B981);
const _cSurface = Color(0xFFF8FAFC);
const _cBorder = Color(0xFFE2E8F0);
const _cText = Color(0xFF1E293B);

class AppTopBar extends StatelessWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ProfileScreen())),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _cPrimary, width: 2),
              color: _cSurface,
            ),
            child: Icon(Icons.person_rounded, color: _cPrimary, size: 26),
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: () {
            final shell = context.findAncestorStateOfType<MainShellState>();
            if (shell != null) {
              shell.goHome();
            } else {
              Navigator.popUntil(context, (route) => route.isFirst);
            }
          },
          child: Text('WalletScript',
              style: TextStyle(
                  color: _cPrimary, fontSize: 20, fontWeight: FontWeight.w800)),
        ),
        const Spacer(),
        _iconBtn(context, Icons.sticky_note_2_outlined,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const NotesScreen()))),
        const SizedBox(width: 6),
        _iconBtn(context, Icons.calendar_month_outlined,
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const CalendarScreen()))),
        const SizedBox(width: 6),
        Stack(
          children: [
            _iconBtn(context, Icons.notifications_outlined,
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const NotificationScreen()))),
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

  static Widget _iconBtn(BuildContext context, IconData icon,
      {required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: _cSurface,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: _cBorder),
        ),
        child: Icon(icon, color: _cText, size: 19),
      ),
    );
  }
}
