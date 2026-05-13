import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  late AnimationController _illustrationController;
  late Animation<double> _floatAnim;

  final List<_OnboardingData> _pages = const [
    _OnboardingData(
      bgColor: Color(0xFFF0EBF8),
      accentColor: Color(0xFF7C5CBF),
      illustrationBg: Color(0xFFE4D9F5),
      icon: Icons.account_balance_wallet_rounded,
      iconColor: Color(0xFF7C5CBF),
      title: 'Catat Setiap\nTransaksi',
      subtitle:
          'Lacak pemasukan dan pengeluaran harianmu dengan mudah dan cepat.',
      tag: 'PENCATATAN',
    ),
    _OnboardingData(
      bgColor: Color(0xFFEBF3F8),
      accentColor: Color(0xFF4A90C4),
      illustrationBg: Color(0xFFD4E8F5),
      icon: Icons.savings_rounded,
      iconColor: Color(0xFF4A90C4),
      title: 'Kelola Budget\n& Tabungan',
      subtitle:
          'Buat target tabungan, pantau progress, dan raih goals finansialmu.',
      tag: 'BUDGET',
    ),
    _OnboardingData(
      bgColor: Color(0xFFEBF8F0),
      accentColor: Color(0xFF3DAE6B),
      illustrationBg: Color(0xFFD4F0E0),
      icon: Icons.insights_rounded,
      iconColor: Color(0xFF3DAE6B),
      title: 'Analisis\nKeuanganmu',
      subtitle:
          'Lihat insight detail pengeluaran dan buat keputusan finansial yang lebih cerdas.',
      tag: 'INSIGHT',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _illustrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _illustrationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _illustrationController.dispose();
    super.dispose();
  }

  Future<void> _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, __) => const LoginScreen(),
        transitionsBuilder: (_, a, __, child) =>
            FadeTransition(opacity: a, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_currentPage];
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      color: page.bgColor,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: Column(
            children: [
              // Skip button
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 16, 24, 0),
                  child: GestureDetector(
                    onTap: _finishOnboarding,
                    child: Text(
                      'Lewati',
                      style: TextStyle(
                        color: page.accentColor.withOpacity(0.6),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),

              // PageView
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (i) => setState(() => _currentPage = i),
                  itemCount: _pages.length,
                  itemBuilder: (_, i) => _buildPage(_pages[i]),
                ),
              ),

              // Bottom controls
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 40),
                child: Column(
                  children: [
                    // Dots
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _pages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: i == _currentPage ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i == _currentPage
                                ? page.accentColor
                                : page.accentColor.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Next / Mulai button
                    GestureDetector(
                      onTap: _nextPage,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          color: page.accentColor,
                          borderRadius: BorderRadius.circular(18),
                          boxShadow: [
                            BoxShadow(
                              color: page.accentColor.withOpacity(0.35),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _currentPage == _pages.length - 1
                                ? 'Mulai Sekarang'
                                : 'Lanjut',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingData data) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // Illustration card
          AnimatedBuilder(
            animation: _floatAnim,
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _floatAnim.value),
              child: Container(
                width: double.infinity,
                height: 260,
                decoration: BoxDecoration(
                  color: data.illustrationBg,
                  borderRadius: BorderRadius.circular(32),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Decorative circles
                    Positioned(
                      top: 20,
                      right: 20,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.accentColor.withOpacity(0.12),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 30,
                      left: 24,
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: data.accentColor.withOpacity(0.1),
                        ),
                      ),
                    ),
                    // Tag
                    Positioned(
                      top: 20,
                      left: 20,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: data.accentColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          data.tag,
                          style: TextStyle(
                            color: data.accentColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
                    ),
                    // Main icon
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: data.accentColor,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: data.accentColor.withOpacity(0.4),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        data.icon,
                        color: Colors.white,
                        size: 50,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          // Title
          Text(
            data.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A1A2E),
              height: 1.15,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),

          // Subtitle
          Text(
            data.subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF6B6B8D),
              height: 1.6,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingData {
  final Color bgColor;
  final Color accentColor;
  final Color illustrationBg;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String tag;

  const _OnboardingData({
    required this.bgColor,
    required this.accentColor,
    required this.illustrationBg,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.tag,
  });
}
