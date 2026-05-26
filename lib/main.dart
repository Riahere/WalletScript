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

      // Hanya handle password recovery
      // signedOut TIDAK trigger navigasi otomatis —
      // login_screen dan settings_screen yang handle navigate secara eksplisit
      if (event == AuthChangeEvent.passwordRecovery) {
        _navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
          (route) => false,
        );
      }
      // signedIn dan signedOut: dibiarkan — masing-masing flow handle sendiri
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
    // ── TIDAK pakai extendBody supaya tidak ada overlap ──────────────────
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
// FLOATING NAV — animasi bounce + ripple tiap tombol
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
      // Padding bawah = safe area, jadi tidak pernah overlap
      padding: EdgeInsets.only(bottom: bottomPad),
      color: Colors.transparent,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        height: 68,
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(36),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.40),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
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
// ANIMATED NAV ITEM — bounce scale + ripple
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
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 140),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(
          tween: Tween(begin: 1.0, end: 0.82)
              .chain(CurveTween(curve: Curves.easeIn)),
          weight: 40),
      TweenSequenceItem(
          tween: Tween(begin: 0.82, end: 1.08)
              .chain(CurveTween(curve: Curves.easeOut)),
          weight: 35),
      TweenSequenceItem(
          tween: Tween(begin: 1.08, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 25),
    ]).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    _ctrl.forward(from: 0);
    widget.onTap(widget.index);
  }

  @override
  Widget build(BuildContext context) {
    final isCenter = widget.item.isCenter;
    final isSelected = widget.isSelected;

    return GestureDetector(
      onTap: _handleTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (_, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCenter ? 6 : 10,
            vertical: isCenter ? 4 : 8,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Center (Home) — lingkaran tanpa label ─────────────────
              if (isCenter)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  curve: Curves.easeOutCubic,
                  width: isSelected ? 52 : 46,
                  height: isSelected ? 52 : 46,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary
                        : Colors.white.withOpacity(0.12),
                    shape: BoxShape.circle,
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.50),
                              blurRadius: 16,
                              offset: const Offset(0, 5),
                            )
                          ]
                        : [],
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: isSelected ? Colors.white : Colors.white54,
                    size: isSelected ? 26 : 23,
                  ),
                )
              // ── Regular items ──────────────────────────────────────────
              else ...[
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutCubic,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primary.withOpacity(0.18)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    widget.item.icon,
                    color: isSelected ? AppTheme.primary : Colors.white38,
                    size: 22,
                  ),
                ),
                const SizedBox(height: 2),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 200),
                  style: TextStyle(
                    color: isSelected ? AppTheme.primary : Colors.white38,
                    fontSize: 10,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                  ),
                  child: Text(widget.item.label),
                ),
              ],
            ],
          ),
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
