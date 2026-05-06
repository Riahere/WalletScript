import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';
import 'app_top_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _balanceHidden = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // -- TOP BAR --
              const AppTopBar(),
              const SizedBox(height: 16),

              // -- REMINDER CARD --
              _infoCard(
                color: AppTheme.primary,
                icon: Icons.notifications_active_rounded,
                title: 'Reminder',
                subtitle: 'Catat pengeluaran harianmu sekarang.',
              ),
              const SizedBox(height: 10),

              // -- INSIGHT CARD --
              _infoCard(
                color: const Color(0xFF1E293B),
                icon: Icons.bar_chart_rounded,
                title: 'Insight',
                subtitle: 'Pengeluaran makan 45% lebih tinggi dari biasanya.',
              ),
              const SizedBox(height: 16),

              // -- TOTAL SALDO CARD --
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                  boxShadow: [
                    BoxShadow(color: AppTheme.onSurface.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4)),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Saldo',
                            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14, fontWeight: FontWeight.w500)),
                        GestureDetector(
                          onTap: () => setState(() => _balanceHidden = !_balanceHidden),
                          child: Icon(
                            _balanceHidden ? Icons.visibility_off_outlined : Icons.info_outline_rounded,
                            color: AppTheme.onSurfaceVariant, size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _balanceHidden ? 'Rp ••••••••' : formatter.format(txProvider.balance),
                      style: const TextStyle(color: AppTheme.onSurface, fontSize: 32, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.trending_up_rounded, color: AppTheme.primary, size: 14),
                          SizedBox(width: 4),
                          Text('+2.4% last 30d',
                              style: TextStyle(color: AppTheme.primary, fontSize: 12, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -- BALANCE TREND --
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Balance Trend',
                                style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 15)),
                            Text('Past 30 days activity',
                                style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                          ],
                        ),
                        Row(children: [
                          _chipStatic('ALL', false),
                          const SizedBox(width: 6),
                          _chipStatic('30D', true),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 90,
                      child: CustomPaint(
                        size: const Size(double.infinity, 90),
                        painter: _MiniChartPainter(),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('1 Oct', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10)),
                        Text('15 Oct', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10)),
                        Text('Today', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -- SPENDING OVERVIEW --
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: const [
                        Text('Spending Overview',
                            style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 15)),
                        Icon(Icons.more_vert, color: AppTheme.onSurfaceVariant, size: 20),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        SizedBox(
                          width: 110, height: 110,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              SizedBox(
                                width: 110, height: 110,
                                child: CircularProgressIndicator(
                                  value: txProvider.totalIncome > 0
                                      ? (txProvider.totalExpense / txProvider.totalIncome).clamp(0, 1)
                                      : 0.65,
                                  strokeWidth: 14,
                                  backgroundColor: AppTheme.surfaceContainer,
                                  valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                                ),
                              ),
                              Column(mainAxisSize: MainAxisSize.min, children: [
                                const Text('SPENT',
                                    style: TextStyle(fontSize: 9, color: AppTheme.onSurfaceVariant, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                                const SizedBox(height: 2),
                                Text(
                                  formatter.format(txProvider.totalExpense),
                                  style: const TextStyle(fontSize: 12, color: AppTheme.onSurface, fontWeight: FontWeight.w800),
                                  textAlign: TextAlign.center,
                                ),
                              ]),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(children: [
                            _spendingRow('Food & Dining', AppTheme.primary, '45%'),
                            const Divider(height: 20, color: AppTheme.outline),
                            _spendingRow('Transport', const Color(0xFF1E293B), '30%'),
                            const Divider(height: 20, color: AppTheme.outline),
                            _spendingRow('Rent', AppTheme.error, '25%'),
                          ]),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.add, size: 14, color: AppTheme.onSurfaceVariant),
                        label: const Text('ADD CATEGORY',
                            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // -- MY WALLETS --
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('My Wallets',
                      style: TextStyle(color: AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                  TextButton(
                    onPressed: () {},
                    child: const Row(children: [
                      Text('View All', style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right_rounded, color: AppTheme.primary, size: 16),
                    ]),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 130,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _walletCard('Visa Gold', 'Rp 12.450.000', 'BALANCE', const Color(0xFF1E293B), Colors.white),
                    const SizedBox(width: 12),
                    _walletCard('Tabungan', 'Rp 8.000.000', 'SAVED', AppTheme.primary, Colors.white),
                    const SizedBox(width: 12),
                    _walletCard('Cash', 'Rp 500.000', 'CASH', AppTheme.surfaceContainer, AppTheme.onSurface),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // -- FLOW HISTORY --
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Flow History',
                      style: TextStyle(color: AppTheme.onSurface, fontSize: 16, fontWeight: FontWeight.w700)),
                  Row(children: [
                    Icon(Icons.tune_rounded, color: AppTheme.onSurfaceVariant, size: 20),
                    SizedBox(width: 12),
                    Icon(Icons.search_rounded, color: AppTheme.onSurfaceVariant, size: 20),
                  ]),
                ],
              ),
              const SizedBox(height: 12),

              if (txProvider.transactions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(children: [
                      Icon(Icons.receipt_long_outlined, size: 48, color: AppTheme.onSurfaceVariant),
                      const SizedBox(height: 12),
                      const Text('Belum ada transaksi',
                          style: TextStyle(color: AppTheme.onSurfaceVariant)),
                    ]),
                  ),
                )
              else
                ...txProvider.transactions.take(5).map((t) => _buildTxTile(t, formatter)),

              if (txProvider.transactions.length > 5)
                Center(
                  child: TextButton(
                    onPressed: () {},
                    child: const Text('SHOW OLDER TRANSACTIONS',
                        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _infoCard({required Color color, required IconData icon, required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(children: [
        Container(
          width: 38, height: 38,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(subtitle, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
          ]),
        ),
      ]),
    );
  }

  static Widget _chipStatic(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            fontSize: 12, fontWeight: FontWeight.w600,
          )),
    );
  }

  static Widget _spendingRow(String label, Color color, String percent) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(color: AppTheme.onSurface, fontSize: 13))),
      Text(percent, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _walletCard(String name, String amount, String label, Color bgColor, Color textColor) {
    return Container(
      width: 160,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Icon(Icons.account_balance_rounded, color: textColor.withOpacity(0.7), size: 20),
            Text(name.toUpperCase(),
                style: TextStyle(color: textColor.withOpacity(0.7), fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
          ]),
          const Spacer(),
          Text(label, style: TextStyle(color: textColor.withOpacity(0.6), fontSize: 10, fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(amount, style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildTxTile(AppTransaction t, NumberFormat formatter) {
    final isIncome = t.type == 'income';
    final Map<String, Map<String, dynamic>> categoryIcons = {
      'Makanan': {'icon': Icons.restaurant_rounded, 'color': const Color(0xFFD1FAE5)},
      'Transport': {'icon': Icons.directions_car_rounded, 'color': const Color(0xFFDBEAFE)},
      'Belanja': {'icon': Icons.shopping_bag_rounded, 'color': const Color(0xFFEDE9FE)},
      'Hiburan': {'icon': Icons.gamepad_rounded, 'color': const Color(0xFFFEF3C7)},
      'Kesehatan': {'icon': Icons.health_and_safety_rounded, 'color': const Color(0xFFFFE4E6)},
      'Gaji': {'icon': Icons.account_balance_wallet_rounded, 'color': const Color(0xFFD1FAE5)},
      'Travel': {'icon': Icons.flight_takeoff_rounded, 'color': const Color(0xFFE0F2FE)},
    };
    final cat = categoryIcons[t.category] ?? {'icon': Icons.receipt_rounded, 'color': AppTheme.surfaceContainer};

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(color: cat['color'] as Color, borderRadius: BorderRadius.circular(14)),
          child: Icon(cat['icon'] as IconData, color: AppTheme.onSurface, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(t.title, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 14)),
            Text(
              '${t.category.toUpperCase()} • ${_timeAgo(t.date)}',
              style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w500),
            ),
          ]),
        ),
        Text(
          '${isIncome ? '+' : '-'}${formatter.format(t.amount)}',
          style: TextStyle(
            color: isIncome ? AppTheme.primary : AppTheme.error,
            fontWeight: FontWeight.w700, fontSize: 14,
          ),
        ),
      ]),
    );
  }

  static String _timeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}

class _MiniChartPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppTheme.primary
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [AppTheme.primary.withOpacity(0.25), AppTheme.primary.withOpacity(0.0)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    final points = [
      Offset(0, size.height * 0.65),
      Offset(size.width * 0.15, size.height * 0.45),
      Offset(size.width * 0.3, size.height * 0.25),
      Offset(size.width * 0.45, size.height * 0.55),
      Offset(size.width * 0.6, size.height * 0.7),
      Offset(size.width * 0.75, size.height * 0.4),
      Offset(size.width, size.height * 0.15),
    ];

    final path = Path()..moveTo(points[0].dx, points[0].dy);
    for (int i = 0; i < points.length - 1; i++) {
      final cp1 = Offset((points[i].dx + points[i+1].dx) / 2, points[i].dy);
      final cp2 = Offset((points[i].dx + points[i+1].dx) / 2, points[i+1].dy);
      path.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, points[i+1].dx, points[i+1].dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
