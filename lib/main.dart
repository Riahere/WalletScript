// lib/main.dart

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
import 'screens/add_transaction_screen.dart';
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

// Navigator key untuk navigasi dari luar widget tree
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

      // Saat user klik link reset password dari email → event PASSWORD_RECOVERY
      if (event == AuthChangeEvent.passwordRecovery) {
        debugPrint('>>> PASSWORD_RECOVERY event — navigating to reset screen');
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

// Global key to control MainShell from anywhere
final mainShellKey = GlobalKey<MainShellState>();

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void goHome() => setState(() => _currentIndex = 0);
  void goTo(int index) => setState(() => _currentIndex = index);

  final List<Widget> _screens = const [
    HomeScreen(),
    HistoryScreen(),
    BudgetScreen(),
    InsightsScreen(),
    SettingsScreen(),
  ];

  void _openAddTransaction() {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => const AddTransactionScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _currentIndex, children: _screens),
      extendBody: true,
      bottomNavigationBar: _buildFloatingNav(),
    );
  }

  Widget _buildFloatingNav() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      height: 68,
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(36),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF1E293B).withOpacity(0.4),
              blurRadius: 24,
              offset: const Offset(0, 8))
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.history_rounded, 'History', 1),
          _navItem(Icons.account_balance_wallet_rounded, 'Budget', 2),
          GestureDetector(
            onTap: _openAddTransaction,
            child: Container(
              width: 52,
              height: 52,
              decoration: const BoxDecoration(
                  color: AppTheme.primary, shape: BoxShape.circle),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
            ),
          ),
          _navItem(Icons.show_chart_rounded, 'Insights', 3),
          _navItem(Icons.settings_rounded, 'Settings', 4),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                color: isSelected ? AppTheme.primary : Colors.white38,
                size: 22),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                  color: isSelected ? AppTheme.primary : Colors.white38,
                  fontSize: 10,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                )),
          ],
        ),
      ),
    );
  }
}
