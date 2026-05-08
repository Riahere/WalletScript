import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/transaction_provider.dart';
import '../theme/app_theme.dart';
import '../models/transaction_model.dart';

class SpendingDetailScreen extends StatefulWidget {
  const SpendingDetailScreen({super.key});
  @override
  State<SpendingDetailScreen> createState() => _SpendingDetailScreenState();
}

class _SpendingDetailScreenState extends State<SpendingDetailScreen> {
  String _filter = 'Bulan Ini';

  static const List<Color> _catColors = [
    AppTheme.primary,
    Color(0xFF6C63FF),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF0EA5E9),
    Color(0xFF10B981),
    Color(0xFFEC4899),
  ];

  Color _colorForIndex(int i) => _catColors[i % _catColors.length];

  List<AppTransaction> _applyFilter(List<AppTransaction> all) {
    final now = DateTime.now();
    if (_filter == 'Bulan Ini') {
      return all
          .where((t) => t.date.year == now.year && t.date.month == now.month)
          .toList();
    } else if (_filter == '3 Bulan') {
      final cutoff = DateTime(now.year, now.month - 2, 1);
      return all.where((t) => t.date.isAfter(cutoff)).toList();
    }
    return all;
  }

  Map<String, double> _categoryTotals(List<AppTransaction> txs) {
    final Map<String, double> map = {};
    for (final t in txs) {
      if (t.type == 'expense') {
        map[t.category] = (map[t.category] ?? 0) + t.amount;
      }
    }
    return map;
  }

  List<_DailyData> _dailySeries(List<AppTransaction> txs) {
    final Map<String, double> map = {};
    for (final t in txs) {
      if (t.type == 'expense') {
        final key = DateFormat('dd/MM').format(t.date);
        map[key] = (map[key] ?? 0) + t.amount;
      }
    }
    return (map.entries.map((e) => _DailyData(e.key, e.value)).toList())
      ..sort((a, b) => a.label.compareTo(b.label));
  }

  @override
  Widget build(BuildContext context) {
    final txProvider = context.watch<TransactionProvider>();
    final fmt =
        NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    final filtered = _applyFilter(txProvider.transactions);
    final catTotals = _categoryTotals(filtered);
    final totalExpense = catTotals.values.fold(0.0, (a, b) => a + b);
    final catList = catTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final dailySeries = _dailySeries(filtered);
    final expenseTxs = filtered.where((t) => t.type == 'expense').toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Spending Detail',
            style: TextStyle(
                color: AppTheme.onSurface,
                fontWeight: FontWeight.w800,
                fontSize: 20)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Row(
              children: ['Bulan Ini', '3 Bulan', 'Semua'].map((f) {
                final sel = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: () => setState(() => _filter = f),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: sel ? AppTheme.primary : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: sel ? AppTheme.primary : AppTheme.outline),
                      ),
                      child: Text(f,
                          style: TextStyle(
                              color: sel
                                  ? Colors.white
                                  : AppTheme.onSurfaceVariant,
                              fontSize: 11,
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          // ── Summary chips ───────────────────────────────────────────────────
          Row(children: [
            Expanded(
                child: _summaryChip('Total Pengeluaran',
                    fmt.format(totalExpense), AppTheme.error)),
            const SizedBox(width: 10),
            Expanded(
                child: _summaryChip(
                    'Kategori', '${catList.length}', AppTheme.primary)),
          ]),
          const SizedBox(height: 20),

          // ── Bar chart ───────────────────────────────────────────────────────
          _card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Pengeluaran Harian',
                  style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 4),
              Text('${expenseTxs.length} transaksi',
                  style: const TextStyle(
                      color: AppTheme.onSurfaceVariant, fontSize: 12)),
              const SizedBox(height: 20),
              dailySeries.isEmpty
                  ? const _EmptyState(label: 'Tidak ada data pengeluaran')
                  : Column(children: [
                      SizedBox(
                        height: 120,
                        child: CustomPaint(
                          size: const Size(double.infinity, 120),
                          painter: _BarChartPainter(dailySeries),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _axisLabel(dailySeries.first.label),
                          if (dailySeries.length > 2)
                            _axisLabel(
                                dailySeries[dailySeries.length ~/ 2].label),
                          _axisLabel(dailySeries.last.label),
                        ],
                      ),
                    ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Donut + breakdown ───────────────────────────────────────────────
          _card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Breakdown Kategori',
                  style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 20),
              catList.isEmpty
                  ? const _EmptyState(label: 'Belum ada pengeluaran')
                  : Column(children: [
                      // donut
                      Center(
                        child: SizedBox(
                          width: 140,
                          height: 140,
                          child: Stack(alignment: Alignment.center, children: [
                            CustomPaint(
                              size: const Size(140, 140),
                              painter: _DonutPainter(
                                catList.map((e) => e.value).toList(),
                                totalExpense,
                                List.generate(
                                    catList.length, (i) => _colorForIndex(i)),
                                strokeWidth: 18,
                              ),
                            ),
                            Column(mainAxisSize: MainAxisSize.min, children: [
                              const Text('TOTAL',
                                  style: TextStyle(
                                      fontSize: 9,
                                      color: AppTheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 0.5)),
                              const SizedBox(height: 2),
                              Text(fmt.format(totalExpense),
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: AppTheme.onSurface,
                                      fontWeight: FontWeight.w800),
                                  textAlign: TextAlign.center),
                            ]),
                          ]),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // rows
                      for (int i = 0; i < catList.length; i++) ...[
                        if (i > 0) const Divider(color: AppTheme.outline),
                        _catDetailRow(
                          color: _colorForIndex(i),
                          label: catList[i].key,
                          amount: fmt.format(catList[i].value),
                          percent: totalExpense > 0
                              ? (catList[i].value / totalExpense * 100)
                                  .toStringAsFixed(1)
                              : '0',
                          ratio: totalExpense > 0
                              ? catList[i].value / totalExpense
                              : 0,
                        ),
                      ],
                    ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Transactions list ───────────────────────────────────────────────
          _card(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Transaksi Pengeluaran',
                  style: TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 16),
              expenseTxs.isEmpty
                  ? const _EmptyState(label: 'Tidak ada transaksi')
                  : Column(
                      children: expenseTxs
                          .take(20)
                          .map((t) => _txRow(t, fmt))
                          .toList()),
            ]),
          ),
        ],
      ),
    );
  }

  // ── helper widgets ────────────────────────────────────────────────────────

  static Widget _card({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.outline),
        ),
        child: child,
      );

  static Widget _axisLabel(String text) => Text(text,
      style: const TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 10));

  Widget _summaryChip(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label,
            style: const TextStyle(
                color: AppTheme.onSurfaceVariant, fontSize: 12)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: color, fontWeight: FontWeight.w800, fontSize: 18)),
      ]),
    );
  }

  Widget _catDetailRow({
    required Color color,
    required String label,
    required String amount,
    required String percent,
    required double ratio,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 10),
          Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 13))),
          Text('$percent%',
              style: TextStyle(
                  color: color, fontWeight: FontWeight.w700, fontSize: 13)),
          const SizedBox(width: 8),
          Text(amount,
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 12)),
        ]),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 5,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ]),
    );
  }

  Widget _txRow(AppTransaction t, NumberFormat fmt) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
              color: AppTheme.error.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12)),
          child: const Icon(Icons.arrow_upward_rounded,
              color: AppTheme.error, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(t.title,
              style: const TextStyle(
                  color: AppTheme.onSurface,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
          Text('${t.category} · ${DateFormat('d MMM').format(t.date)}',
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 11)),
        ])),
        Text('-${fmt.format(t.amount)}',
            style: const TextStyle(
                color: AppTheme.error,
                fontWeight: FontWeight.w700,
                fontSize: 13)),
      ]),
    );
  }
}

// ── Models & Painters ─────────────────────────────────────────────────────────

class _DailyData {
  final String label;
  final double value;
  const _DailyData(this.label, this.value);
}

class _EmptyState extends StatelessWidget {
  final String label;
  const _EmptyState({required this.label});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(label,
              style: const TextStyle(
                  color: AppTheme.onSurfaceVariant, fontSize: 13)),
        ),
      );
}

class _BarChartPainter extends CustomPainter {
  final List<_DailyData> data;
  const _BarChartPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.map((d) => d.value).reduce((a, b) => a > b ? a : b);
    if (maxVal == 0) return;
    final barW = (size.width / data.length) * 0.55;
    final gap = size.width / data.length;
    for (int i = 0; i < data.length; i++) {
      final h = (data[i].value / maxVal) * size.height * 0.85;
      final x = gap * i + gap / 2 - barW / 2;
      canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x, size.height - h, barW, h),
            const Radius.circular(4)),
        Paint()
          ..color = AppTheme.primary.withOpacity(0.75)
          ..style = PaintingStyle.fill,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter old) => old.data != data;
}

class _DonutPainter extends CustomPainter {
  final List<double> values;
  final double total;
  final List<Color> colors;
  final double strokeWidth;
  const _DonutPainter(this.values, this.total, this.colors,
      {this.strokeWidth = 14});

  @override
  void paint(Canvas canvas, Size size) {
    if (total == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - strokeWidth / 2;
    double start = -1.5708;
    for (int i = 0; i < values.length; i++) {
      final sweep = (values[i] / total) * 6.2832;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        sweep - 0.05,
        false,
        Paint()
          ..color = colors[i]
          ..strokeWidth = strokeWidth
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
      );
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutPainter old) => true;
}
