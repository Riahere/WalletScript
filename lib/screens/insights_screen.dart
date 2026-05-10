import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../services/market_service.dart';
import 'app_top_bar.dart';
import 'market_detail_screen.dart';

const _cPrimary = Color(0xFF10B981);
const _cBackground = Color(0xFFF1F5F9);
const _cSurface = Color(0xFFF8FAFC);
const _cBorder = Color(0xFFE2E8F0);
const _cText = Color(0xFF1E293B);
const _cTextSub = Color(0xFF64748B);
const _cExpense = Color(0xFFFC7C78);
const _cChipOff = Color(0xFFE2E8F0);
const _cGold = Color(0xFFF59E0B);

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({super.key});
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen>
    with SingleTickerProviderStateMixin {
  int _mainTab = 0; // 0=Crypto, 1=Saham, 2=Forex, 3=Gainers
  int _sahamTab = 0; // 0=IDX, 1=US

  List<MarketPrice> _cryptoPrices = [];
  List<MarketPrice> _stocksUS = [];
  List<MarketPrice> _stocksIDX = [];
  List<MarketPrice> _forexPrices = [];
  List<MarketPrice> _gainers = [];
  List<MarketPrice> _losers = [];
  List<NewsItem> _news = [];
  Map<String, dynamic> _fearGreed = {'value': 50, 'classification': 'Neutral'};

  // Watchlist
  final Set<String> _watchlist = {};

  // Price Alerts
  final Map<String, Map<String, double?>> _priceAlerts = {};

  // Search
  bool _searching = false;
  final _searchCtrl = TextEditingController();
  MarketPrice? _searchResult;
  bool _searchLoading = false;
  String? _searchError;

  // Ticker scroll controller
  late final ScrollController _tickerScrollCtrl;
  bool _loadingMarket = true;
  bool _loadingNews = true;
  DateTime? _lastUpdated;

  @override
  void initState() {
    super.initState();
    _tickerScrollCtrl = ScrollController();
    _loadAll();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tickerScrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loadingMarket = true;
      _loadingNews = true;
    });
    final results = await Future.wait([
      MarketService.fetchCrypto(),
      MarketService.fetchStocks(),
      MarketService.fetchIDX(),
      MarketService.fetchForex(),
      MarketService.fetchFearGreed(),
    ]);
    if (mounted) {
      setState(() {
        _cryptoPrices = results[0] as List<MarketPrice>;
        _stocksUS = results[1] as List<MarketPrice>;
        _stocksIDX = results[2] as List<MarketPrice>;
        _forexPrices = results[3] as List<MarketPrice>;
        _fearGreed = results[4] as Map<String, dynamic>;
        _loadingMarket = false;
        _lastUpdated = DateTime.now();
      });
      _buildGainersLosers();
    }
    final news = await MarketService.fetchNews();
    if (mounted) {
      setState(() {
        _news = news;
        _loadingNews = false;
      });
    }
  }

  void _buildGainersLosers() {
    final all = [..._cryptoPrices, ..._stocksUS, ..._stocksIDX];
    all.sort((a, b) => b.changePercent.compareTo(a.changePercent));
    setState(() {
      _gainers = all.where((p) => p.changePercent > 0).take(5).toList();
      _losers = all
          .where((p) => p.changePercent < 0)
          .toList()
          .reversed
          .take(5)
          .toList();
    });
  }

  Future<void> _doSearch(String ticker) async {
    if (ticker.trim().isEmpty) return;
    setState(() {
      _searchLoading = true;
      _searchResult = null;
      _searchError = null;
    });
    final result = await MarketService.searchStock(ticker);
    if (mounted) {
      setState(() {
        _searchLoading = false;
        if (result != null) {
          _searchResult = result;
        } else {
          _searchError = 'Ticker "$ticker" tidak ditemukan.';
        }
      });
    }
  }

  List<MarketPrice> get _currentPrices {
    List<MarketPrice> base;
    switch (_mainTab) {
      case 0:
        base = _cryptoPrices;
        break;
      case 1:
        base = _sahamTab == 0 ? _stocksIDX : _stocksUS;
        break;
      case 2:
        base = _forexPrices;
        break;
      default:
        base = _cryptoPrices;
    }
    final wl = base.where((p) => _watchlist.contains(_watchKey(p))).toList();
    final rest = base.where((p) => !_watchlist.contains(_watchKey(p))).toList();
    return [...wl, ...rest];
  }

  String _watchKey(MarketPrice p) => '${p.type}:${p.symbol}';

  String _formatPrice(MarketPrice p) {
    if (p.type == 'crypto' || p.type == 'forex' || p.type == 'idx') {
      return 'Rp ${NumberFormat('#,###', 'id').format(p.price.toInt())}';
    }
    return '\$${NumberFormat('#,##0.00').format(p.price)}';
  }

  Color _fgColor(int v) {
    if (v <= 25) return const Color(0xFFEF4444);
    if (v <= 45) return const Color(0xFFF97316);
    if (v <= 55) return const Color(0xFFEAB308);
    return _cPrimary;
  }

  String _fearGreedLabel(int v) {
    if (v <= 25) return 'Extreme Fear';
    if (v <= 45) return 'Fear';
    if (v <= 55) return 'Neutral';
    if (v <= 75) return 'Greed';
    return 'Extreme Greed';
  }

  String _sentimentTitle(int v) {
    if (v <= 25) return 'Extreme Fear';
    if (v <= 45) return 'Market Fear';
    if (v <= 55) return 'Neutral Market';
    if (v <= 75) return 'Bullish Momentum';
    return 'Extreme Greed';
  }

  String _sentimentDesc(int v) {
    if (v <= 25)
      return 'Pasar sangat ketakutan. Potensi peluang beli bagi investor jangka panjang.';
    if (v <= 45)
      return 'Sentimen negatif mendominasi. Investor cenderung berhati-hati.';
    if (v <= 55)
      return 'Pasar dalam kondisi netral. Tidak ada tren kuat yang mendominasi.';
    if (v <= 75)
      return 'Momentum bullish kuat. Pasar menunjukkan kepercayaan diri investor.';
    return 'Euforia sangat tinggi. Waspadai potensi koreksi jangka pendek.';
  }

  void _openDetail(MarketPrice p) {
    Navigator.push(context,
        MaterialPageRoute(builder: (_) => MarketDetailScreen(asset: p)));
  }

  // ── Open News Full Page WebView ────────────────────────────────────────────
  void _openNewsWebView(NewsItem n) {
    if (n.url.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _NewsWebViewScreen(news: n)),
    );
  }

  // ── Open Converter Bottom Sheet ────────────────────────────────────────────
  void _openConverterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ConverterSheet(
        forexPrices: _forexPrices,
        cryptoPrices: _cryptoPrices,
        loadingMarket: _loadingMarket,
      ),
    );
  }

  // ── Price Alert Dialog ─────────────────────────────────────────────────────
  void _showAlertDialog(MarketPrice p) {
    final key = _watchKey(p);
    final existing = _priceAlerts[key];
    final aboveCtrl =
        TextEditingController(text: existing?['above']?.toString() ?? '');
    final belowCtrl =
        TextEditingController(text: existing?['below']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _cSurface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(children: [
          Icon(Icons.notifications_active_rounded, color: _cPrimary, size: 20),
          const SizedBox(width: 8),
          Text('Price Alert — ${p.symbol}',
              style: const TextStyle(
                  color: _cText, fontWeight: FontWeight.w700, fontSize: 15)),
        ]),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Harga sekarang: ${_formatPrice(p)}',
              style: const TextStyle(color: _cTextSub, fontSize: 12)),
          const SizedBox(height: 16),
          _alertField(aboveCtrl, 'Alert jika NAIK di atas...',
              Icons.arrow_upward_rounded, _cPrimary),
          const SizedBox(height: 10),
          _alertField(belowCtrl, 'Alert jika TURUN di bawah...',
              Icons.arrow_downward_rounded, _cExpense),
        ]),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => _priceAlerts.remove(key));
              Navigator.pop(ctx);
            },
            child: const Text('Hapus', style: TextStyle(color: _cExpense)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: _cTextSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: _cPrimary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              final above = double.tryParse(aboveCtrl.text);
              final below = double.tryParse(belowCtrl.text);
              setState(() {
                _priceAlerts[key] = {'above': above, 'below': below};
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Alert untuk ${p.symbol} disimpan'),
                  backgroundColor: _cPrimary,
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Simpan', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _alertField(
      TextEditingController ctrl, String hint, IconData icon, Color color) {
    return TextField(
      controller: ctrl,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _cTextSub, fontSize: 12),
        prefixIcon: Icon(icon, color: color, size: 18),
        filled: true,
        fillColor: _cBackground,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _cBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: color)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      ),
      style: const TextStyle(color: _cText, fontSize: 13),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fgVal = _fearGreed['value'] as int;
    final fgColor = _fgColor(fgVal);

    final tickerItems = [
      ..._cryptoPrices,
      ..._stocksUS.take(5),
      ..._stocksIDX.take(4),
    ];

    return Scaffold(
      backgroundColor: _cBackground,
      // ── Floating Converter Button ────────────────────────────────────────
      floatingActionButton: FloatingActionButton(
        onPressed: _openConverterSheet,
        backgroundColor: _cPrimary,
        elevation: 4,
        tooltip: 'Currency Converter',
        child:
            const Icon(Icons.calculate_rounded, color: Colors.white, size: 26),
      ),
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          color: _cPrimary,
          onRefresh: _loadAll,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppTopBar(),
                const SizedBox(height: 24),

                // ── Sentiment Card ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _cSurface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _cBorder),
                  ),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(children: [
                          const Text('MARKET SENTIMENT',
                              style: TextStyle(
                                  color: _cTextSub,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8)),
                          const Spacer(),
                          if (_lastUpdated != null)
                            Text(
                                'Updated ${DateFormat('HH:mm').format(_lastUpdated!)}',
                                style: const TextStyle(
                                    color: _cTextSub, fontSize: 10)),
                        ]),
                        const SizedBox(height: 4),
                        _loadingMarket
                            ? _shimLine(140, 22)
                            : Text(_sentimentTitle(fgVal),
                                style: const TextStyle(
                                    color: _cText,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800)),
                        const SizedBox(height: 6),
                        _loadingMarket
                            ? _shimLine(double.infinity, 14)
                            : Text(_sentimentDesc(fgVal),
                                style: const TextStyle(
                                    color: _cTextSub, fontSize: 13)),
                        const SizedBox(height: 14),
                        Row(children: [
                          Icon(
                            fgVal > 50
                                ? Icons.trending_up_rounded
                                : fgVal < 50
                                    ? Icons.trending_down_rounded
                                    : Icons.trending_flat_rounded,
                            color: fgColor,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _loadingMarket ? 0.5 : fgVal / 100,
                                minHeight: 8,
                                backgroundColor: const Color(0xFFEAEEF2),
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(fgColor),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_loadingMarket ? '...' : _fearGreedLabel(fgVal),
                              style: const TextStyle(
                                  color: _cTextSub, fontSize: 12)),
                        ]),
                        if (!_loadingMarket) ...[
                          const SizedBox(height: 8),
                          Center(
                            child: Text('Fear & Greed Index: $fgVal / 100',
                                style: TextStyle(
                                    color: fgColor,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ]),
                ),
                const SizedBox(height: 12),

                // ── Market Ticker Scroll ───────────────────────────────
                if (!_loadingMarket && tickerItems.isNotEmpty) ...[
                  Container(
                    height: 38,
                    decoration: BoxDecoration(
                      color: _cSurface,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _cBorder),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: ListView.separated(
                        controller: _tickerScrollCtrl,
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        itemCount: tickerItems.length,
                        separatorBuilder: (_, __) => Container(
                          width: 1,
                          margin: const EdgeInsets.symmetric(vertical: 10),
                          color: _cBorder,
                        ),
                        itemBuilder: (_, i) {
                          final p = tickerItems[i];
                          final isUp = p.changePercent >= 0;
                          return GestureDetector(
                            onTap: () => _openDetail(p),
                            child: Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 10),
                              child: Row(children: [
                                Text(p.symbol,
                                    style: const TextStyle(
                                        color: _cText,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 11)),
                                const SizedBox(width: 4),
                                Text(
                                  '${isUp ? '+' : ''}${p.changePercent.toStringAsFixed(2)}%',
                                  style: TextStyle(
                                      color: isUp ? _cPrimary : _cExpense,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ]),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── Main Tabs (no emoji) ───────────────────────────────
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(children: [
                    _tab(
                        'Crypto',
                        0,
                        _mainTab,
                        (i) => setState(() {
                              _mainTab = i;
                              _searching = false;
                            })),
                    const SizedBox(width: 8),
                    _tab(
                        'Saham',
                        1,
                        _mainTab,
                        (i) => setState(() {
                              _mainTab = i;
                              _searching = false;
                            })),
                    const SizedBox(width: 8),
                    _tab(
                        'Forex',
                        2,
                        _mainTab,
                        (i) => setState(() {
                              _mainTab = i;
                              _searching = false;
                            })),
                    const SizedBox(width: 8),
                    _tab(
                        'Gainers',
                        3,
                        _mainTab,
                        (i) => setState(() {
                              _mainTab = i;
                              _searching = false;
                            })),
                  ]),
                ),
                const SizedBox(height: 12),

                // ── Saham Subtabs ──────────────────────────────────────
                if (_mainTab == 1) ...[
                  Row(children: [
                    _subtab('IDX', 0, _sahamTab,
                        (i) => setState(() => _sahamTab = i)),
                    const SizedBox(width: 8),
                    _subtab('US', 1, _sahamTab,
                        (i) => setState(() => _sahamTab = i)),
                  ]),
                  const SizedBox(height: 12),
                ],

                // ── Gainers & Losers Tab ───────────────────────────────
                if (_mainTab == 3) ...[
                  _buildGainersLosersSection(),
                  const SizedBox(height: 20),
                ],

                // ── Search Bar (tab 0,1,2) ─────────────────────────────
                if (_mainTab < 3) ...[
                  GestureDetector(
                    onTap: () => setState(() {
                      _searching = !_searching;
                      _searchResult = null;
                      _searchError = null;
                      _searchCtrl.clear();
                    }),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: _cSurface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: _searching ? _cPrimary : _cBorder),
                      ),
                      child: Row(children: [
                        Icon(Icons.search_rounded,
                            color: _searching ? _cPrimary : _cTextSub,
                            size: 18),
                        const SizedBox(width: 8),
                        if (_searching)
                          Expanded(
                            child: TextField(
                              controller: _searchCtrl,
                              autofocus: true,
                              decoration: const InputDecoration(
                                hintText:
                                    'Cari ticker... (AAPL, BBCA, BTC-USD)',
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: EdgeInsets.zero,
                              ),
                              style:
                                  const TextStyle(color: _cText, fontSize: 13),
                              onSubmitted: _doSearch,
                              textInputAction: TextInputAction.search,
                            ),
                          )
                        else
                          const Text('Cari saham, crypto, forex...',
                              style: TextStyle(color: _cTextSub, fontSize: 13)),
                        if (_searching) ...[
                          _searchLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: _cPrimary))
                              : GestureDetector(
                                  onTap: () => _doSearch(_searchCtrl.text),
                                  child: const Icon(Icons.send_rounded,
                                      color: _cPrimary, size: 18),
                                ),
                        ],
                      ]),
                    ),
                  ),

                  if (_searching && _searchResult != null) ...[
                    const SizedBox(height: 8),
                    _marketItem(_searchResult!, isSearchResult: true),
                  ],
                  if (_searching && _searchError != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: _cSurface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: _cBorder)),
                      child: Row(children: [
                        const Icon(Icons.info_outline_rounded,
                            color: _cExpense, size: 16),
                        const SizedBox(width: 8),
                        Text(_searchError!,
                            style: const TextStyle(
                                color: _cTextSub, fontSize: 13)),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 12),

                  // ── Live Market header ─────────────────────────────
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(children: [
                          const Text('Live Market Data',
                              style: TextStyle(
                                  color: _cText,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          if (_watchlist.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                  color: _cPrimary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('${_watchlist.length} ★',
                                  style: const TextStyle(
                                      color: _cPrimary,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700)),
                            ),
                          ],
                        ]),
                        _loadingMarket
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: _cPrimary))
                            : GestureDetector(
                                onTap: _loadAll,
                                child: const Text('Refresh',
                                    style: TextStyle(
                                        color: _cPrimary,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600)),
                              ),
                      ]),
                  const SizedBox(height: 12),

                  if (_loadingMarket)
                    ...List.generate(5, (_) => _shimCard())
                  else
                    ..._currentPrices.map((p) => _marketItem(p)),

                  const SizedBox(height: 20),
                ],

                // ── News ───────────────────────────────────────────────
                if (_mainTab < 3) ...[
                  Row(children: [
                    const Icon(Icons.newspaper_rounded,
                        color: _cPrimary, size: 18),
                    const SizedBox(width: 6),
                    const Text('Market News',
                        style: TextStyle(
                            color: _cText,
                            fontWeight: FontWeight.w700,
                            fontSize: 15)),
                  ]),
                  const SizedBox(height: 4),
                  const Text('Tap berita untuk membaca langsung.',
                      style: TextStyle(color: _cTextSub, fontSize: 12)),
                  const SizedBox(height: 12),
                  if (_loadingNews)
                    ...List.generate(3, (_) => _shimCard())
                  else if (_news.isEmpty)
                    _emptyNews()
                  else
                    ..._news.take(8).map(_newsItem),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Gainers & Losers ───────────────────────────────────────────────────────
  Widget _buildGainersLosersSection() {
    if (_loadingMarket) {
      return Column(children: List.generate(6, (_) => _shimCard()));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: _cPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child:
              const Icon(Icons.trending_up_rounded, color: _cPrimary, size: 16),
        ),
        const SizedBox(width: 8),
        const Text('Top Gainers',
            style: TextStyle(
                color: _cText, fontWeight: FontWeight.w700, fontSize: 15)),
        const Spacer(),
        const Text('Naik terbesar hari ini',
            style: TextStyle(color: _cTextSub, fontSize: 11)),
      ]),
      const SizedBox(height: 10),
      if (_gainers.isEmpty)
        _emptyState('Tidak ada data gainers')
      else
        ..._gainers.map((p) => _marketItem(p)),
      const SizedBox(height: 20),
      Row(children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
              color: _cExpense.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8)),
          child: const Icon(Icons.trending_down_rounded,
              color: _cExpense, size: 16),
        ),
        const SizedBox(width: 8),
        const Text('Top Losers',
            style: TextStyle(
                color: _cText, fontWeight: FontWeight.w700, fontSize: 15)),
        const Spacer(),
        const Text('Turun terbesar hari ini',
            style: TextStyle(color: _cTextSub, fontSize: 11)),
      ]),
      const SizedBox(height: 10),
      if (_losers.isEmpty)
        _emptyState('Tidak ada data losers')
      else
        ..._losers.map((p) => _marketItem(p)),
    ]);
  }

  // ── Widgets ────────────────────────────────────────────────────────────────
  Widget _tab(String label, int index, int current, ValueChanged<int> onTap) {
    final sel = current == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
            color: sel ? _cPrimary : _cChipOff,
            borderRadius: BorderRadius.circular(30)),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : _cTextSub,
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }

  Widget _subtab(
      String label, int index, int current, ValueChanged<int> onTap) {
    final sel = current == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
            color: sel ? _cText : _cChipOff,
            borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: sel ? Colors.white : _cTextSub,
                fontWeight: FontWeight.w600,
                fontSize: 12)),
      ),
    );
  }

  Widget _marketItem(MarketPrice p, {bool isSearchResult = false}) {
    final isUp = p.changePercent >= 0;
    final color = isUp ? _cPrimary : _cExpense;
    final bgMap = {
      'crypto': const Color(0xFFFFF7ED),
      'stock': const Color(0xFFF0F4F8),
      'idx': const Color(0xFFECFDF5),
      'forex': const Color(0xFFEFF6FF),
    };
    final bg = bgMap[p.type] ?? const Color(0xFFF0F4F8);
    final wKey = _watchKey(p);
    final inWatchlist = _watchlist.contains(wKey);
    final hasAlert = _priceAlerts.containsKey(wKey);

    return GestureDetector(
      onTap: () => _openDetail(p),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _cSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: isSearchResult ? _cPrimary.withOpacity(0.4) : _cBorder),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(12)),
            child: Center(
              child: Text(
                p.symbol.length > 4 ? p.symbol.substring(0, 4) : p.symbol,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, fontSize: 10, color: _cText),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(p.name,
                  style: const TextStyle(
                      color: _cText,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Text(p.sub,
                  style: const TextStyle(color: _cTextSub, fontSize: 11)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_formatPrice(p),
                style: const TextStyle(
                    color: _cText, fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${isUp ? '+' : ''}${p.changePercent.toStringAsFixed(2)}%',
                style: TextStyle(
                    color: color, fontWeight: FontWeight.w600, fontSize: 12)),
          ]),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _showAlertDialog(p),
            child: Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(
                hasAlert
                    ? Icons.notifications_active_rounded
                    : Icons.notifications_none_rounded,
                color: hasAlert ? _cGold : _cTextSub,
                size: 18,
              ),
            ),
          ),
          GestureDetector(
            onTap: () {
              setState(() {
                if (inWatchlist)
                  _watchlist.remove(wKey);
                else
                  _watchlist.add(wKey);
              });
            },
            child: Icon(
              inWatchlist ? Icons.star_rounded : Icons.star_outline_rounded,
              color: inWatchlist ? _cGold : _cTextSub,
              size: 20,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _newsItem(NewsItem n) => GestureDetector(
        onTap: () => _openNewsWebView(n),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: _cSurface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cBorder)),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                    color: _cPrimary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(n.source,
                    style: const TextStyle(
                        color: _cPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 10)),
              ),
              const Spacer(),
              Text(DateFormat('dd MMM').format(n.datetime),
                  style: const TextStyle(color: _cTextSub, fontSize: 10)),
              const SizedBox(width: 6),
              const Icon(Icons.open_in_new_rounded, color: _cTextSub, size: 14),
            ]),
            const SizedBox(height: 8),
            Text(n.headline,
                style: const TextStyle(
                    color: _cText, fontWeight: FontWeight.w600, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
            if (n.summary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(n.summary,
                  style: const TextStyle(color: _cTextSub, fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
      );

  Widget _emptyNews() => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: _cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cBorder)),
        child: const Center(
            child: Text('Berita tidak tersedia saat ini.',
                style: TextStyle(color: _cTextSub))),
      );

  Widget _emptyState(String msg) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: _cSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cBorder)),
        child: Center(
            child: Text(msg,
                style: const TextStyle(color: _cTextSub, fontSize: 13))),
      );

  Widget _shimCard() => Container(
        margin: const EdgeInsets.only(bottom: 8),
        height: 70,
        decoration: BoxDecoration(
            color: _cBorder, borderRadius: BorderRadius.circular(14)),
      );

  Widget _shimLine(double width, double height) => Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
            color: _cBorder, borderRadius: BorderRadius.circular(6)),
      );
}

// ── News Full Page WebView ────────────────────────────────────────────────────
class _NewsWebViewScreen extends StatefulWidget {
  final NewsItem news;
  const _NewsWebViewScreen({required this.news});

  @override
  State<_NewsWebViewScreen> createState() => _NewsWebViewScreenState();
}

class _NewsWebViewScreenState extends State<_NewsWebViewScreen> {
  late final WebViewController _controller;
  bool _loading = true;
  int _loadingProgress = 0;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) => setState(() => _loading = true),
        onProgress: (p) => setState(() => _loadingProgress = p),
        onPageFinished: (_) => setState(() => _loading = false),
      ))
      ..loadRequest(Uri.parse(widget.news.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF8FAFC),
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded,
              color: Color(0xFF1E293B), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.news.source,
              style: const TextStyle(
                  color: Color(0xFF10B981),
                  fontSize: 13,
                  fontWeight: FontWeight.w700),
            ),
            Text(
              widget.news.headline,
              style: const TextStyle(color: Color(0xFF64748B), fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded,
                color: Color(0xFF64748B), size: 20),
            onPressed: () => _controller.reload(),
          ),
        ],
        bottom: _loading
            ? PreferredSize(
                preferredSize: const Size.fromHeight(3),
                child: LinearProgressIndicator(
                  value: _loadingProgress / 100,
                  backgroundColor: const Color(0xFFE2E8F0),
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  minHeight: 3,
                ),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}

// ── Currency Converter Bottom Sheet ──────────────────────────────────────────
class _ConverterSheet extends StatefulWidget {
  final List<MarketPrice> forexPrices;
  final List<MarketPrice> cryptoPrices;
  final bool loadingMarket;

  const _ConverterSheet({
    required this.forexPrices,
    required this.cryptoPrices,
    required this.loadingMarket,
  });

  @override
  State<_ConverterSheet> createState() => _ConverterSheetState();
}

class _ConverterSheetState extends State<_ConverterSheet> {
  final _amountCtrl = TextEditingController();
  String _fromCurrency = 'USD';
  String _toCurrency = 'IDR';
  double? _convertedResult;
  Map<String, double> _rates = {};
  bool _loadingRates = true;

  final List<String> _currencies = [
    'IDR',
    'USD',
    'EUR',
    'GBP',
    'JPY',
    'SGD',
    'AUD',
    'MYR',
    'THB',
    'CNY',
    'KRW',
    'HKD',
    'CAD',
    'CHF',
    'NZD',
    'BTC',
    'ETH',
  ];

  @override
  void initState() {
    super.initState();
    _loadRates();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    final rates = await MarketService.fetchExchangeRates();
    // Tambah crypto: harga IDR → rate vs USD
    final usdToIDR = rates['IDR'] ?? 17450.0;
    for (final p in widget.cryptoPrices) {
      rates[p.symbol] = p.price / usdToIDR;
    }
    if (mounted) {
      setState(() {
        _rates = rates;
        _loadingRates = false;
      });
      _doConvert();
    }
  }

  void _doConvert() {
    final input = double.tryParse(_amountCtrl.text.replaceAll(',', ''));
    if (input == null || input == 0 || _rates.isEmpty) {
      setState(() => _convertedResult = null);
      return;
    }
    final fromRate = _rates[_fromCurrency];
    final toRate = _rates[_toCurrency];
    if (fromRate == null || toRate == null) {
      setState(() => _convertedResult = null);
      return;
    }
    // rates = berapa unit currency per 1 USD
    // FROM → USD → TO
    final inUSD = input / fromRate;
    setState(() => _convertedResult = inUSD * toRate);
  }

  String _formatConverted(double v, String currency) {
    if (currency == 'IDR') {
      return 'Rp ${NumberFormat('#,###', 'id').format(v.toInt())}';
    }
    if (['BTC', 'ETH'].contains(currency)) {
      return '${v.toStringAsFixed(8)} $currency';
    }
    if (currency == 'JPY') {
      return '¥${NumberFormat('#,###').format(v.toInt())}';
    }
    return '${NumberFormat('#,##0.00').format(v)} $currency';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Handle
        Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
              color: const Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(height: 16),

        Row(children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.calculate_rounded,
                color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 10),
          const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Currency Converter',
                style: TextStyle(
                    color: Color(0xFF1E293B),
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            Text('Rate live dari pasar',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
          ]),
        ]),
        const SizedBox(height: 20),

        // Amount input
        TextField(
          controller: _amountCtrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Masukkan jumlah...',
            hintStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
            filled: true,
            fillColor: const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF10B981))),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
          style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 15,
              fontWeight: FontWeight.w600),
          onChanged: (_) => _doConvert(),
        ),
        const SizedBox(height: 12),

        // From / To dropdowns
        Row(children: [
          Expanded(
              child: _currencyDropdown(_fromCurrency, (v) {
            setState(() => _fromCurrency = v!);
            _doConvert();
          })),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  final tmp = _fromCurrency;
                  _fromCurrency = _toCurrency;
                  _toCurrency = tmp;
                });
                _doConvert();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.swap_horiz_rounded,
                    color: Color(0xFF10B981), size: 20),
              ),
            ),
          ),
          Expanded(
              child: _currencyDropdown(_toCurrency, (v) {
            setState(() => _toCurrency = v!);
            _doConvert();
          })),
        ]),
        const SizedBox(height: 16),

        // Result
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withOpacity(0.06),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.2)),
          ),
          child: _convertedResult != null
              ? Column(children: [
                  Text(
                    '${_amountCtrl.text} $_fromCurrency =',
                    style:
                        const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatConverted(_convertedResult!, _toCurrency),
                    style: const TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 22,
                        fontWeight: FontWeight.w800),
                  ),
                  if (widget.loadingMarket) ...[
                    const SizedBox(height: 4),
                    const Text('Menggunakan rate estimasi',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 10)),
                  ],
                ])
              : const Text(
                  'Masukkan jumlah untuk melihat konversi',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child:
              const Text('Tutup', style: TextStyle(color: Color(0xFF64748B))),
        ),
      ]),
    );
  }

  Widget _currencyDropdown(String value, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: Color(0xFF64748B), size: 18),
          style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w600),
          items: _currencies
              .map((c) => DropdownMenuItem(value: c, child: Text(c)))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
