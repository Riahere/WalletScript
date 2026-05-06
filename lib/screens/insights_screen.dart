import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'app_top_bar.dart';

class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppTopBar(),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MARKET SENTIMENT',
                        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 4),
                    const Text('Bullish Momentum',
                        style: TextStyle(color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    const Text('Pasar global menunjukkan pemulihan kuat dipimpin teknologi dan sektor energi hijau.',
                        style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 13)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        const Icon(Icons.trending_up_rounded, color: AppTheme.primary, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: const LinearProgressIndicator(
                              value: 0.74,
                              minHeight: 8,
                              backgroundColor: Color(0xFFEAEEF2),
                              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text('Greed', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PORTFOLIO INSIGHT',
                        style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.8)),
                    const SizedBox(height: 6),
                    const Text('Pengeluaran kamu 8.4% di bawah rata-rata. Bagus!',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30)),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('View Analysis',
                              style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
                          SizedBox(width: 4),
                          Icon(Icons.arrow_forward_rounded, color: AppTheme.primary, size: 16),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  _tab('Saham', true),
                  const SizedBox(width: 8),
                  _tab('Crypto', false),
                  const SizedBox(width: 8),
                  _tab('Forex', false),
                ],
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: const [
                  Text('Live Market Data',
                      style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('See all >',
                      style: TextStyle(color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 12),

              _marketItem('BTC', 'Bitcoin', 'BTC / USDT', 'Rp 1.045.320.000', '+4.2%', true, const Color(0xFFFFF7ED)),
              _marketItem('AAPL', 'Apple Inc.', 'AAPL', r'$189.43', '-1.15%', false, const Color(0xFFF0F4F8)),
              _marketItem('GOLD', 'Gold Spot', 'XAU / USD', r'$2,341.20', '+0.8%', true, const Color(0xFFFEF3C7)),
              _marketItem('FX', 'USD / IDR', 'FOREX', 'Rp 16.215', '0.0%', true, const Color(0xFFEFF6FF)),

              const SizedBox(height: 20),
              const Row(children: [
                Icon(Icons.auto_awesome_rounded, color: AppTheme.primary, size: 18),
                SizedBox(width: 6),
                Text('Smart Picks',
                    style: TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 15)),
              ]),
              const Text('AI-driven analysis dan probability scores.',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 12),

              _smartPick('Clean Tech ETF', 'High Conviction', '+15.4%',
                  'Meningkatnya dukungan legislatif untuk energi terbarukan mendorong pertumbuhan kuartal yang kuat.'),
              const SizedBox(height: 10),
              _smartPick('Ethereum (ETH)', 'Accumulate', '+9.2%',
                  'Data historis setelah network upgrade menunjukkan konsolidasi konsisten.'),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _tab(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primary : AppTheme.surfaceContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppTheme.onSurfaceVariant,
            fontWeight: FontWeight.w600, fontSize: 13,
          )),
    );
  }

  static Widget _marketItem(String symbol, String name, String sub, String price, String change, bool isUp, Color bg) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Center(child: Text(symbol, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(name, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w600, fontSize: 13)),
              Text(sub, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(price, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 13)),
            Text(change, style: TextStyle(
              color: isUp ? AppTheme.primary : AppTheme.error,
              fontWeight: FontWeight.w600, fontSize: 12,
            )),
          ]),
        ],
      ),
    );
  }

  static Widget _smartPick(String name, String badge, String prediction, String desc) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text(name, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w700, fontSize: 14)),
            const Spacer(),
            const Text('Prediction', style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11)),
          ]),
          Row(children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(badge,
                  style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700, fontSize: 11)),
            ),
            const Spacer(),
            Text(prediction,
                style: const TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w800, fontSize: 18)),
          ]),
          const SizedBox(height: 8),
          Text(desc, style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ],
      ),
    );
  }
}
