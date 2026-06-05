import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'providers/transaction_provider.dart';
import 'providers/budget_provider.dart';
import 'providers/settings_provider.dart';
import 'providers/note_provider.dart';
import 'providers/account_provider.dart';
import 'providers/notification_provider.dart'; // ← TAMBAH
import 'theme/app_theme.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/budget_screen.dart';
import 'screens/insights_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/splash_screen.dart';
import 'screens/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  debugPrint('>>> Initializing Supabase...');
  try {
    await Supabase.initialize(
      url: 'https://ckhsjlvhuqijuxsiwxwi.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImNraHNqbHZodXFpanV4c2l3eHdpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg2ODYyNjgsImV4cCI6MjA5NDI2MjI2OH0.NQo0tIE5M7C9D25tAJxbZgvvIeaXxJPkoRbvJvUp9FE',
    );
    debugPrint('>>> Supabase initialized successfully!');
  } catch (e) {
    debugPrint('>>> Supabase initialization FAILED: $e');
  }

  await NotificationService().init();
  await initializeDateFormatting('id', null);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const WalletScriptApp());
}

final _navigatorKey = GlobalKey<NavigatorState>();

class WalletScriptApp extends StatefulWidget {
  const WalletScriptApp({super.key});

  @override
  State<WalletScriptApp> createState() => _WalletScriptAppState();
}

class _WalletScriptAppState extends State<WalletScriptApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final event = data.event;
      debugPrint('>>> Auth event: $event');

      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          (route) => false,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => TransactionProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => NoteProvider()),
        ChangeNotifierProvider(create: (_) => AccountProvider()),
        // ← TAMBAH: NotificationProvider dengan load() otomatis saat init
        ChangeNotifierProvider(
          create: (_) => NotificationProvider()..load(),
        ),
      ],
      child: MaterialApp(
        navigatorKey: _navigatorKey,
        title: 'WalletScript',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: const SplashScreen(),
        routes: {
          '/home': (_) => const MainShell(),
          '/reset-password': (_) => const ResetPasswordScreen(),
        },
      ),
    );
  }
}

final mainShellKey = GlobalKey<MainShellState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 2; // default Home (tengah)

  void goHome() => setState(() => _currentIndex = 2);
  void goTo(int index) => setState(() => _currentIndex = index);

  final List<Widget> _screens = const [
    HistoryScreen(),
    BudgetScreen(),
    HomeScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: false,
      bottomNavigationBar: _FloatingNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FLOATING NAV — pill expand animation on selected item
// ─────────────────────────────────────────────────────────────────────────────
class _FloatingNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _FloatingNav({required this.currentIndex, required this.onTap});

  static const _items = [
    _NavItem(icon: Icons.history_rounded, label: 'History'),
    _NavItem(icon: Icons.account_balance_wallet_rounded, label: 'Budget'),
    _NavItem(icon: Icons.home_rounded, label: '', isCenter: true),
    _NavItem(icon: Icons.show_chart_rounded, label: 'Insights'),
    _NavItem(icon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding: EdgeInsets.only(bottom: bottomPad),
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(36),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(
            _items.length,
            (i) => _AnimatedNavItem(
              item: _items[i],
              index: i,
              isSelected: currentIndex == i,
              onTap: onTap,
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED NAV ITEM
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedNavItem extends StatefulWidget {
  final _NavItem item;
  final int index;
  final bool isSelected;
  final ValueChanged<int> onTap;

  const _AnimatedNavItem({
    required this.item,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_AnimatedNavItem> createState() => _AnimatedNavItemState();
}

class _AnimatedNavItemState extends State<_AnimatedNavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _expandAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _expandAnim = CurvedAnimation(
      parent: _ctrl,
      curve: Curves.easeOutCubic,
    );
    _fadeAnim = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 1.0, curve: Curves.easeOut),
    );

    if (widget.isSelected) _ctrl.value = 1.0;
  }

  @override
  void didUpdateWidget(_AnimatedNavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _ctrl.forward();
    } else if (!widget.isSelected && oldWidget.isSelected) {
      _ctrl.reverse();
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final isCenter = widget.item.isCenter;

    if (isCenter) {
      return GestureDetector(
        onTap: _handleTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: AnimatedBuilder(
            animation: _expandAnim,
            builder: (_, __) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: widget.isSelected ? 52 : 46,
              height: widget.isSelected ? 52 : 46,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppTheme.primary
                    : Colors.white.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                widget.item.icon,
                color: widget.isSelected ? Colors.white : Colors.white54,
                size: widget.isSelected ? 26 : 23,
              ),
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        child: AnimatedBuilder(
          animation: _expandAnim,
          builder: (_, __) {
            final t = _expandAnim.value;

            final pillColor = Color.lerp(Colors.transparent, Colors.white, t)!;
            final iconColor = Color.lerp(
              Colors.white38,
              const Color(0xFF1E293B),
              t,
            )!;
            final labelColor = Color.lerp(
              Colors.transparent,
              const Color(0xFF1E293B),
              _fadeAnim.value,
            )!;

            return Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10 + (6 * t),
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: pillColor,
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.item.icon, color: iconColor, size: 20),
                  if (_fadeAnim.value > 0.01) ...[
                    SizedBox(width: 6 * t),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        widthFactor: t,
                        child: Text(
                          widget.item.label,
                          style: TextStyle(
                            color: labelColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _NavItem {
  final IconData icon;
  final String label;
  final bool isCenter;
  const _NavItem({
    required this.icon,
    required this.label,
    this.isCenter = false,
  });
}
