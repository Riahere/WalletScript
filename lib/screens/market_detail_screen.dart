import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/market_service.dart';

const _cPrimary = Color(0xFF10B981);
const _cBackground = Color(0xFFF1F5F9);
const _cSurface = Color(0xFFF8FAFC);
const _cBorder = Color(0xFFE2E8F0);
const _cText = Color(0xFF1E293B);
const _cTextSub = Color(0xFF64748B);
const _cExpense = Color(0xFFFC7C78);

class MarketDetailScreen extends StatefulWidget {
  final MarketPrice asset;
  const MarketDetailScreen({super.key, required this.asset});

  @override
  State<MarketDetailScreen> createState() => _MarketDetailScreenState();
}

class _MarketDetailScreenState extends State<MarketDetailScreen> {
  String _range = '1M';
  List<ChartPoint> _points = [];
  bool _loading = true;
  String? _error;

  // Tooltip state
  int? _hoverIndex;

  @override
  void initState() {
    super.initState();
    _loadChart();
  }

  Future<void> _loadChart() async {
    setState(() {
      _loading = true;
      _error = null;
      _hoverIndex = null;
    });
    try {
      final data = await MarketService.fetchChartData(widget.asset, _range);
      if (mounted) {
        setState(() {
          _points = data;
          _loading = false;
          if (data.isEmpty) _error = 'Data tidak tersedia untuk periode ini.';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Gagal memuat data chart.';
        });
      }
    }
  }

  String _formatPrice(double price) {
    final p = widget.asset;
    if (p.type == 'crypto' || p.type == 'forex' || p.type == 'idx') {
      return 'Rp ${NumberFormat('#,###', 'id').format(price.toInt())}';
    }
    return '\$${NumberFormat('#,##0.00').format(price)}';
  }

  void _onTouch(Offset localPos, double chartWidth) {
    const padding = 16.0;
    final usableWidth = chartWidth - padding * 2;
    final x = (localPos.dx - padding).clamp(0.0, usableWidth);
    final idx = ((x / usableWidth) * (_points.length - 1))
        .round()
        .clamp(0, _points.length - 1);
    setState(() => _hoverIndex = idx);
  }

  @override
  Widget build(BuildContext context) {
    final isUp = widget.asset.changePercent >= 0;
    final accentColor = isUp ? _cPrimary : _cExpense;

    double? minVal, maxVal, firstVal, lastVal;
    if (_points.isNotEmpty) {
      final prices = _points.map((p) => p.close).toList();
      minVal = prices.reduce((a, b) => a < b ? a : b);
      maxVal = prices.reduce((a, b) => a > b ? a : b);
      firstVal = prices.first;
      lastVal = prices.last;
    }

    final periodChange = (firstVal != null && lastVal != null && firstVal != 0)
        ? ((lastVal - firstVal) / firstVal) * 100
        : null;

    final chartColor =
        (periodChange != null && periodChange < 0) ? _cExpense : _cPrimary;

    final hoveredPoint = (_hoverIndex != null && _points.isNotEmpty)
        ? _points[_hoverIndex!]
        : null;

    return Scaffold(
      backgroundColor: _cBackground,
      appBar: AppBar(
        backgroundColor: _cSurface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          color: _cText,
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.asset.name,
                style: TextStyle(
                    color: _cText, fontWeight: FontWeight.w700, fontSize: 15)),
            Text(widget.asset.sub,
                style: TextStyle(color: _cTextSub, fontSize: 11)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatPrice(widget.asset.price),
                    style: TextStyle(
                        color: _cText,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text(
                    '${isUp ? '+' : ''}${widget.asset.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                        color: accentColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ── Range Selector ─────────────────────────────────────────
            Container(
              color: _cSurface,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: ['1W', '1M', '3M', '1Y'].map((r) {
                  final sel = _range == r;
                  return GestureDetector(
                    onTap: () {
                      setState(() => _range = r);
                      _loadChart();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: sel ? _cPrimary : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(r,
                          style: TextStyle(
                              color: sel ? Colors.white : _cTextSub,
                              fontWeight: FontWeight.w600,
                              fontSize: 13)),
                    ),
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Price display — updates live saat hover ────────
                    _buildPriceHeader(
                        hoveredPoint, lastVal, periodChange, chartColor),
                    const SizedBox(height: 12),

                    // ── Chart ──────────────────────────────────────────
                    Container(
                      height: 220,
                      decoration: BoxDecoration(
                        color: _cSurface,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: _cBorder),
                      ),
                      child: _loading
                          ? const Center(
                              child:
                                  CircularProgressIndicator(color: _cPrimary))
                          : _error != null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.bar_chart_rounded,
                                          color: _cBorder, size: 40),
                                      const SizedBox(height: 8),
                                      Text(_error!,
                                          style: TextStyle(
                                              color: _cTextSub, fontSize: 13)),
                                    ],
                                  ),
                                )
                              : _points.isEmpty
                                  ? Center(
                                      child: Text('Tidak ada data.',
                                          style: TextStyle(color: _cTextSub)))
                                  : ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: LayoutBuilder(
                                        builder: (ctx, constraints) {
                                          return GestureDetector(
                                            onTapDown: (d) => _onTouch(
                                                d.localPosition,
                                                constraints.maxWidth),
                                            onTapUp: (_) => setState(
                                                () => _hoverIndex = null),
                                            onHorizontalDragUpdate: (d) =>
                                                _onTouch(d.localPosition,
                                                    constraints.maxWidth),
                                            onHorizontalDragEnd: (_) =>
                                                setState(
                                                    () => _hoverIndex = null),
                                            child: CustomPaint(
                                              size: Size(constraints.maxWidth,
                                                  constraints.maxHeight),
                                              painter: _InteractiveLinePainter(
                                                points: _points,
                                                color: chartColor,
                                                hoverIndex: _hoverIndex,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                    ),

                    if (!_loading && _error == null && _points.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded,
                              color: _cTextSub, size: 13),
                          const SizedBox(width: 4),
                          Text('Tap atau geser untuk lihat detail harga',
                              style: TextStyle(color: _cTextSub, fontSize: 11)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 20),

                    // ── Stats ──────────────────────────────────────────
                    if (!_loading && _error == null && _points.isNotEmpty) ...[
                      Text('Statistik $_range',
                          style: TextStyle(
                              color: _cText,
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 12),
                      Row(children: [
                        Expanded(
                            child: _statCard(
                                'Tertinggi', _formatPrice(maxVal!), _cPrimary)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _statCard(
                                'Terendah', _formatPrice(minVal!), _cExpense)),
                      ]),
                      const SizedBox(height: 10),
                      Row(children: [
                        Expanded(
                            child: _statCard('Awal Periode',
                                _formatPrice(firstVal!), _cTextSub)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statCard(
                            'Perubahan',
                            '${periodChange! >= 0 ? '+' : ''}${periodChange.toStringAsFixed(2)}%',
                            periodChange >= 0 ? _cPrimary : _cExpense,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          '${DateFormat('dd MMM yyyy').format(_points.first.date)}'
                          ' — '
                          '${DateFormat('dd MMM yyyy').format(_points.last.date)}',
                          style: TextStyle(color: _cTextSub, fontSize: 12),
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPriceHeader(ChartPoint? hovered, double? lastVal,
      double? periodChange, Color chartColor) {
    final showHover = hovered != null;
    final displayPrice = showHover ? hovered.close : lastVal;
    final displayLabel = showHover
        ? DateFormat('dd MMM yyyy').format(hovered.date)
        : 'Harga Terakhir';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(displayLabel,
                style: TextStyle(color: _cTextSub, fontSize: 11)),
            const SizedBox(height: 2),
            Text(
              displayPrice != null ? _formatPrice(displayPrice) : '—',
              style: TextStyle(
                  color: _cText, fontWeight: FontWeight.w800, fontSize: 22),
            ),
          ]),
          const Spacer(),
          if (!showHover && periodChange != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                '${periodChange >= 0 ? '+' : ''}${periodChange.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: chartColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
          if (showHover)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                  color: chartColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20)),
              child: Row(children: [
                Icon(Icons.radio_button_checked, color: chartColor, size: 10),
                const SizedBox(width: 4),
                Text('Live',
                    style: TextStyle(
                        color: chartColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 12)),
              ]),
            ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color valueColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: _cSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _cBorder)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: _cTextSub, fontSize: 11)),
        const SizedBox(height: 4),
        Text(value,
            style: TextStyle(
                color: valueColor, fontWeight: FontWeight.w700, fontSize: 13)),
      ]),
    );
  }
}

// ── Interactive Line Chart Painter ────────────────────────────────────────────
class _InteractiveLinePainter extends CustomPainter {
  final List<ChartPoint> points;
  final Color color;
  final int? hoverIndex;

  static const double _padH = 16;
  static const double _padV = 16;

  _InteractiveLinePainter({
    required this.points,
    required this.color,
    this.hoverIndex,
  });

  Offset _toOffset(int i, Size size) {
    final prices = points.map((p) => p.close).toList();
    final minP = prices.reduce((a, b) => a < b ? a : b);
    final maxP = prices.reduce((a, b) => a > b ? a : b);
    final range = maxP - minP == 0 ? 1.0 : maxP - minP;
    final usableW = size.width - _padH * 2;
    final usableH = size.height - _padV * 2;
    final x = _padH + (i / (points.length - 1)) * usableW;
    final y = _padV + usableH - ((points[i].close - minP) / range) * usableH;
    return Offset(x, y);
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (points.length < 2) return;

    // Gradient fill
    final fillPath = Path();
    fillPath.moveTo(_toOffset(0, size).dx, size.height);
    for (int i = 0; i < points.length; i++) {
      fillPath.lineTo(_toOffset(i, size).dx, _toOffset(i, size).dy);
    }
    fillPath.lineTo(_toOffset(points.length - 1, size).dx, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [color.withOpacity(0.18), color.withOpacity(0.0)],
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
    );

    // Line
    final linePath = Path();
    linePath.moveTo(_toOffset(0, size).dx, _toOffset(0, size).dy);
    for (int i = 1; i < points.length; i++) {
      linePath.lineTo(_toOffset(i, size).dx, _toOffset(i, size).dy);
    }
    canvas.drawPath(
      linePath,
      Paint()
        ..color = color
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // Hover crosshair
    if (hoverIndex != null) {
      final hPt = _toOffset(hoverIndex!, size);

      // Vertical dashed line
      final dashPaint = Paint()
        ..color = color.withOpacity(0.35)
        ..strokeWidth = 1.2;
      const dashLen = 5.0;
      const dashGap = 4.0;
      double y = _padV;
      while (y < size.height - _padV) {
        final end = (y + dashLen).clamp(0.0, size.height - _padV);
        canvas.drawLine(Offset(hPt.dx, y), Offset(hPt.dx, end), dashPaint);
        y += dashLen + dashGap;
      }

      // Glow
      canvas.drawCircle(hPt, 12, Paint()..color = color.withOpacity(0.12));

      // Dot
      canvas.drawCircle(hPt, 5, Paint()..color = color);
      canvas.drawCircle(
        hPt,
        5,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0,
      );
    }
  }

  @override
  bool shouldRepaint(_InteractiveLinePainter old) =>
      old.points != points ||
      old.color != color ||
      old.hoverIndex != hoverIndex;
}
