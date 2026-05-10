import 'dart:convert';
import 'package:http/http.dart' as http;

class MarketPrice {
  final String symbol;
  final String name;
  final String sub;
  final double price;
  final double changePercent;
  final String type;
  final String? yahooSym;

  MarketPrice({
    required this.symbol,
    required this.name,
    required this.sub,
    required this.price,
    required this.changePercent,
    required this.type,
    this.yahooSym,
  });
}

class ChartPoint {
  final DateTime date;
  final double close;
  ChartPoint(this.date, this.close);
}

class NewsItem {
  final String headline;
  final String source;
  final String summary;
  final String url;
  final DateTime datetime;

  NewsItem({
    required this.headline,
    required this.source,
    required this.summary,
    required this.url,
    required this.datetime,
  });
}

class MarketService {
  static const _finnhubKey = 'd80chg1r01qq9ln3cca0d80chg1r01qq9ln3ccag';
  static const _finnhubBase = 'https://finnhub.io/api/v1';
  static const _coinGeckoBase = 'https://api.coingecko.com/api/v3';

  // ── CRYPTO ─────────────────────────────────────────────────────────────────
  static Future<List<MarketPrice>> fetchCrypto() async {
    try {
      final uri = Uri.parse(
        '$_coinGeckoBase/coins/markets'
        '?vs_currency=idr'
        '&ids=bitcoin,ethereum,binancecoin,solana,ripple'
        '&order=market_cap_desc&per_page=5&page=1'
        '&price_change_percentage=24h',
      );
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return _fallbackCrypto();
      final List data = jsonDecode(res.body);
      return data.map((c) {
        final sym = (c['symbol'] as String).toUpperCase();
        return MarketPrice(
          symbol: sym,
          name: c['name'],
          sub: '$sym / IDR',
          price: (c['current_price'] as num).toDouble(),
          changePercent:
              (c['price_change_percentage_24h'] as num?)?.toDouble() ?? 0,
          type: 'crypto',
          yahooSym: c['id'],
        );
      }).toList();
    } catch (_) {
      return _fallbackCrypto();
    }
  }

  // ── SAHAM US ───────────────────────────────────────────────────────────────
  static Future<List<MarketPrice>> fetchStocks() async {
    final symbols = [
      {'sym': 'AAPL', 'name': 'Apple Inc.'},
      {'sym': 'GOOGL', 'name': 'Alphabet'},
      {'sym': 'MSFT', 'name': 'Microsoft'},
      {'sym': 'NVDA', 'name': 'NVIDIA'},
      {'sym': 'TSLA', 'name': 'Tesla'},
      {'sym': 'META', 'name': 'Meta'},
      {'sym': 'AMZN', 'name': 'Amazon'},
      {'sym': 'NFLX', 'name': 'Netflix'},
      {'sym': 'AMD', 'name': 'AMD'},
      {'sym': 'BABA', 'name': 'Alibaba'},
    ];
    try {
      final futures = symbols.map((s) async {
        final uri = Uri.parse(
            '$_finnhubBase/quote?symbol=${s['sym']}&token=$_finnhubKey');
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) return null;
        final d = jsonDecode(res.body);
        final price = (d['c'] as num?)?.toDouble() ?? 0;
        final prev = (d['pc'] as num?)?.toDouble() ?? 1;
        if (price == 0) return null;
        final change = prev != 0 ? ((price - prev) / prev) * 100 : 0.0;
        return MarketPrice(
          symbol: s['sym']!,
          name: s['name']!,
          sub: s['sym']!,
          price: price,
          changePercent: change,
          type: 'stock',
          yahooSym: s['sym'],
        );
      });
      final results = await Future.wait(futures);
      final valid = results.whereType<MarketPrice>().toList();
      return valid.isEmpty ? _fallbackStocks() : valid;
    } catch (_) {
      return _fallbackStocks();
    }
  }

  // ── SAHAM IDX ──────────────────────────────────────────────────────────────
  static Future<List<MarketPrice>> fetchIDX() async {
    final stocks = [
      {'sym': 'BBCA.JK', 'name': 'Bank BCA', 'code': 'BBCA'},
      {'sym': 'BBRI.JK', 'name': 'Bank BRI', 'code': 'BBRI'},
      {'sym': 'TLKM.JK', 'name': 'Telkom', 'code': 'TLKM'},
      {'sym': 'ASII.JK', 'name': 'Astra', 'code': 'ASII'},
      {'sym': 'BMRI.JK', 'name': 'Bank Mandiri', 'code': 'BMRI'},
      {'sym': 'GOTO.JK', 'name': 'GoTo', 'code': 'GOTO'},
      {'sym': 'UNVR.JK', 'name': 'Unilever Indonesia', 'code': 'UNVR'},
      {'sym': 'BYAN.JK', 'name': 'Bayan Resources', 'code': 'BYAN'},
    ];
    try {
      final futures = stocks.map((s) async {
        try {
          final uri = Uri.parse(
            'https://query1.finance.yahoo.com/v8/finance/chart/${s['sym']}?interval=1d&range=2d',
          );
          final res = await http.get(uri, headers: {
            'User-Agent': 'Mozilla/5.0',
            'Accept': 'application/json',
          }).timeout(const Duration(seconds: 12));
          if (res.statusCode != 200) return null;
          final d = jsonDecode(res.body);
          final result = d['chart']['result'];
          if (result == null || result.isEmpty) return null;
          final meta = result[0]['meta'];
          final price = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0;
          final prevClose =
              (meta['chartPreviousClose'] as num?)?.toDouble() ?? price;
          if (price == 0) return null;
          final change =
              prevClose != 0 ? ((price - prevClose) / prevClose) * 100 : 0.0;
          return MarketPrice(
            symbol: s['code']!,
            name: s['name']!,
            sub: 'IDX',
            price: price,
            changePercent: change,
            type: 'idx',
            yahooSym: s['sym'],
          );
        } catch (_) {
          return null;
        }
      });
      final results = await Future.wait(futures);
      final valid = results.whereType<MarketPrice>().toList();
      return valid.isEmpty ? _fallbackIDX() : valid;
    } catch (_) {
      return _fallbackIDX();
    }
  }

  // ── FOREX ──────────────────────────────────────────────────────────────────
  static Future<List<MarketPrice>> fetchForex() async {
    final pairs = [
      {
        'sym': 'OANDA:USD_IDR',
        'name': 'USD / IDR',
        'code': 'USD',
        'yahoo': 'USDIDR=X'
      },
      {
        'sym': 'OANDA:EUR_IDR',
        'name': 'EUR / IDR',
        'code': 'EUR',
        'yahoo': 'EURIDR=X'
      },
      {
        'sym': 'OANDA:GBP_IDR',
        'name': 'GBP / IDR',
        'code': 'GBP',
        'yahoo': 'GBPIDR=X'
      },
      {
        'sym': 'OANDA:JPY_IDR',
        'name': 'JPY / IDR',
        'code': 'JPY',
        'yahoo': 'JPYIDR=X'
      },
      {
        'sym': 'OANDA:SGD_IDR',
        'name': 'SGD / IDR',
        'code': 'SGD',
        'yahoo': 'SGDIDR=X'
      },
      {
        'sym': 'OANDA:AUD_IDR',
        'name': 'AUD / IDR',
        'code': 'AUD',
        'yahoo': 'AUDIDR=X'
      },
    ];
    try {
      final futures = pairs.map((p) async {
        final uri = Uri.parse(
            '$_finnhubBase/quote?symbol=${p['sym']}&token=$_finnhubKey');
        final res = await http.get(uri).timeout(const Duration(seconds: 10));
        if (res.statusCode != 200) return null;
        final d = jsonDecode(res.body);
        final price = (d['c'] as num?)?.toDouble() ?? 0;
        final prev = (d['pc'] as num?)?.toDouble() ?? 1;
        if (price == 0) return null;
        final change = prev != 0 ? ((price - prev) / prev) * 100 : 0.0;
        return MarketPrice(
          symbol: p['code']!,
          name: p['name']!,
          sub: 'FOREX',
          price: price,
          changePercent: change,
          type: 'forex',
          yahooSym: p['yahoo'],
        );
      });
      final results = await Future.wait(futures);
      final valid = results.whereType<MarketPrice>().toList();
      return valid.isEmpty ? _fallbackForex() : valid;
    } catch (_) {
      return _fallbackForex();
    }
  }

  // ── EXCHANGE RATES (untuk Converter) ───────────────────────────────────────
  // Coba 3 API secara berurutan, fallback ke hardcode jika semua gagal
  static Future<Map<String, double>> fetchExchangeRates() async {
    // API 1: open.er-api.com
    try {
      final res = await http
          .get(Uri.parse('https://open.er-api.com/v6/latest/USD'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        if (data['result'] == 'success') {
          final rates = data['rates'] as Map<String, dynamic>;
          return rates.map((k, v) => MapEntry(k, (v as num).toDouble()));
        }
      }
    } catch (_) {}

    // API 2: frankfurter.app
    try {
      final res = await http
          .get(Uri.parse('https://api.frankfurter.app/latest?from=USD'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final rates = Map<String, double>.from(
          (data['rates'] as Map)
              .map((k, v) => MapEntry(k, (v as num).toDouble())),
        );
        rates['USD'] = 1.0;
        return rates;
      }
    } catch (_) {}

    // API 3: USD/IDR live dari Finnhub sebagai minimum
    try {
      final res = await http
          .get(Uri.parse(
              'https://finnhub.io/api/v1/quote?symbol=OANDA:USD_IDR&token=d80chg1r01qq9ln3cca0d80chg1r01qq9ln3ccag'))
          .timeout(const Duration(seconds: 8));
      if (res.statusCode == 200) {
        final d = jsonDecode(res.body);
        final usdIdr = (d['c'] as num?)?.toDouble() ?? 17450.0;
        if (usdIdr > 0) {
          final rates = _fallbackRates();
          rates['IDR'] = usdIdr;
          return rates;
        }
      }
    } catch (_) {}

    return _fallbackRates();
  }

  // Konversi langsung antar dua currency menggunakan fetchExchangeRates
  // Semua dihitung via USD sebagai perantara (akurat, bukan via IDR)
  static Future<double?> convert({
    required double amount,
    required String from,
    required String to,
    Map<String, double>? rates, // opsional: pass rates yang sudah di-fetch
  }) async {
    final r = rates ?? await fetchExchangeRates();
    if (r.isEmpty) return null;

    // Crypto: ambil harga dalam IDR dari CoinGecko, lalu convert via IDR→USD
    // Untuk BTC/ETH, harga dalam IDR tersedia dari fetchCrypto()
    // Tapi di sini kita handle via rates saja kalau ada
    final fromRate = r[from];
    final toRate = r[to];
    if (fromRate == null || toRate == null) return null;

    // Convert: amount in FROM → USD → TO
    final inUSD = amount / fromRate;
    return inUSD * toRate;
  }

  // ── GAINERS & LOSERS ───────────────────────────────────────────────────────
  static Future<Map<String, List<MarketPrice>>> fetchGainersLosers() async {
    try {
      final results = await Future.wait([
        fetchCrypto(),
        fetchStocks(),
        fetchIDX(),
      ]);
      final all = [
        ...results[0],
        ...results[1],
        ...results[2],
      ];
      all.sort((a, b) => b.changePercent.compareTo(a.changePercent));
      final gainers = all.where((p) => p.changePercent > 0).take(5).toList();
      final losers = all
          .where((p) => p.changePercent < 0)
          .toList()
          .reversed
          .take(5)
          .toList();
      return {'gainers': gainers, 'losers': losers};
    } catch (_) {
      return {'gainers': [], 'losers': []};
    }
  }

  // ── SEARCH ─────────────────────────────────────────────────────────────────
  static Future<MarketPrice?> searchStock(String ticker) async {
    final sym = ticker.trim().toUpperCase();
    final candidates = <String>[];

    if (sym.contains('.') || sym.contains('-') || sym.contains('=')) {
      candidates.add(sym);
    } else {
      candidates.add('$sym.JK');
      candidates.add(sym);
      candidates.add('$sym-USD');
    }

    for (final s in candidates) {
      final result = await _fetchYahooQuote(s);
      if (result != null) return result;
    }
    return null;
  }

  static Future<MarketPrice?> _fetchYahooQuote(String sym) async {
    try {
      final uri = Uri.parse(
        'https://query1.finance.yahoo.com/v8/finance/chart/$sym?interval=1d&range=2d',
      );
      final res = await http.get(uri, headers: {
        'User-Agent': 'Mozilla/5.0',
        'Accept': 'application/json',
      }).timeout(const Duration(seconds: 12));
      if (res.statusCode != 200) return null;
      final d = jsonDecode(res.body);
      final result = d['chart']['result'];
      if (result == null || result.isEmpty) return null;
      final meta = result[0]['meta'];
      final price = (meta['regularMarketPrice'] as num?)?.toDouble() ?? 0;
      final prevClose =
          (meta['chartPreviousClose'] as num?)?.toDouble() ?? price;
      if (price == 0) return null;
      final change =
          prevClose != 0 ? ((price - prevClose) / prevClose) * 100 : 0.0;
      final longName = meta['longName'] ?? meta['shortName'] ?? sym;
      final currency = meta['currency'] ?? 'USD';
      final exchg = meta['exchangeName'] ?? '';

      String type;
      if (currency == 'IDR') {
        type = 'idx';
      } else if (exchg == 'CCC') {
        type = 'crypto';
      } else {
        type = 'stock';
      }

      final displaySym = sym.replaceAll('.JK', '').replaceAll('-USD', '');

      return MarketPrice(
        symbol: displaySym,
        name: longName,
        sub: exchg.isNotEmpty ? exchg : currency,
        price: price,
        changePercent: change,
        type: type,
        yahooSym: sym,
      );
    } catch (_) {
      return null;
    }
  }

  // ── CHART DATA ─────────────────────────────────────────────────────────────
  static Future<List<ChartPoint>> fetchChartData(
      MarketPrice p, String range) async {
    try {
      if (p.type == 'crypto') {
        return _fetchCryptoChart(p.yahooSym ?? p.symbol.toLowerCase(), range);
      } else {
        return _fetchYahooChart(p.yahooSym ?? p.symbol, range);
      }
    } catch (_) {
      return [];
    }
  }

  static Future<List<ChartPoint>> _fetchYahooChart(
      String sym, String range) async {
    final rangeMap = {'1W': '5d', '1M': '1mo', '3M': '3mo', '1Y': '1y'};
    final intervalMap = {'1W': '1d', '1M': '1d', '3M': '1d', '1Y': '1wk'};
    final r = rangeMap[range] ?? '1mo';
    final i = intervalMap[range] ?? '1d';
    final uri = Uri.parse(
      'https://query1.finance.yahoo.com/v8/finance/chart/$sym?interval=$i&range=$r',
    );
    final res = await http.get(uri, headers: {
      'User-Agent': 'Mozilla/5.0',
      'Accept': 'application/json',
    }).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];
    final d = jsonDecode(res.body);
    final result = d['chart']['result'];
    if (result == null || result.isEmpty) return [];
    final timestamps = result[0]['timestamp'] as List?;
    final closes = result[0]['indicators']['quote'][0]['close'] as List?;
    if (timestamps == null || closes == null) return [];
    final points = <ChartPoint>[];
    for (int idx = 0; idx < timestamps.length; idx++) {
      final ts = timestamps[idx];
      final cl = closes[idx];
      if (ts == null || cl == null) continue;
      points.add(ChartPoint(
        DateTime.fromMillisecondsSinceEpoch((ts as int) * 1000),
        (cl as num).toDouble(),
      ));
    }
    return points;
  }

  static Future<List<ChartPoint>> _fetchCryptoChart(
      String coinId, String range) async {
    final daysMap = {'1W': '7', '1M': '30', '3M': '90', '1Y': '365'};
    final days = daysMap[range] ?? '30';
    final uri = Uri.parse(
      '$_coinGeckoBase/coins/$coinId/market_chart?vs_currency=idr&days=$days&interval=daily',
    );
    final res = await http.get(uri).timeout(const Duration(seconds: 15));
    if (res.statusCode != 200) return [];
    final d = jsonDecode(res.body);
    final prices = d['prices'] as List?;
    if (prices == null) return [];
    return prices
        .map((p) => ChartPoint(
              DateTime.fromMillisecondsSinceEpoch((p[0] as num).toInt()),
              (p[1] as num).toDouble(),
            ))
        .toList();
  }

  // ── NEWS ───────────────────────────────────────────────────────────────────
  static Future<List<NewsItem>> fetchNews() async {
    try {
      final uri =
          Uri.parse('$_finnhubBase/news?category=general&token=$_finnhubKey');
      final res = await http.get(uri).timeout(const Duration(seconds: 10));
      if (res.statusCode != 200) return [];
      final List data = jsonDecode(res.body);
      return data
          .take(10)
          .map((n) => NewsItem(
                headline: n['headline'] ?? '',
                source: n['source'] ?? '',
                summary: n['summary'] ?? '',
                url: n['url'] ?? '',
                datetime: DateTime.fromMillisecondsSinceEpoch(
                    (((n['datetime'] as num?) ?? 0).toInt()) * 1000),
              ))
          .where((n) => n.headline.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  // ── FEAR & GREED ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> fetchFearGreed() async {
    try {
      final uri = Uri.parse('https://api.alternative.me/fng/?limit=1');
      final res = await http.get(uri).timeout(const Duration(seconds: 8));
      if (res.statusCode != 200) return _fallbackFearGreed();
      final d = jsonDecode(res.body);
      final item = d['data'][0];
      return {
        'value': int.tryParse(item['value'].toString()) ?? 50,
        'classification': item['value_classification'] ?? 'Neutral',
      };
    } catch (_) {
      return _fallbackFearGreed();
    }
  }

  // ── FALLBACKS ──────────────────────────────────────────────────────────────
  static Map<String, double> _fallbackRates() => {
        'USD': 1.0,
        'IDR': 17450.0,
        'EUR': 0.893,
        'GBP': 0.764,
        'JPY': 155.8,
        'SGD': 1.328,
        'AUD': 1.548,
        'MYR': 4.385,
        'THB': 33.2,
        'CNY': 7.248,
        'KRW': 1378.0,
        'HKD': 7.785,
        'CAD': 1.362,
        'CHF': 0.883,
        'NZD': 1.672,
      };

  static List<MarketPrice> _fallbackCrypto() => [
        MarketPrice(
            symbol: 'BTC',
            name: 'Bitcoin',
            sub: 'BTC / IDR',
            price: 1045320000,
            changePercent: 4.2,
            type: 'crypto',
            yahooSym: 'bitcoin'),
        MarketPrice(
            symbol: 'ETH',
            name: 'Ethereum',
            sub: 'ETH / IDR',
            price: 56800000,
            changePercent: 2.1,
            type: 'crypto',
            yahooSym: 'ethereum'),
        MarketPrice(
            symbol: 'BNB',
            name: 'BNB',
            sub: 'BNB / IDR',
            price: 9250000,
            changePercent: -0.8,
            type: 'crypto',
            yahooSym: 'binancecoin'),
        MarketPrice(
            symbol: 'SOL',
            name: 'Solana',
            sub: 'SOL / IDR',
            price: 2340000,
            changePercent: 5.3,
            type: 'crypto',
            yahooSym: 'solana'),
        MarketPrice(
            symbol: 'XRP',
            name: 'XRP',
            sub: 'XRP / IDR',
            price: 9800,
            changePercent: 1.2,
            type: 'crypto',
            yahooSym: 'ripple'),
      ];

  static List<MarketPrice> _fallbackStocks() => [
        MarketPrice(
            symbol: 'AAPL',
            name: 'Apple Inc.',
            sub: 'AAPL',
            price: 189.43,
            changePercent: -1.15,
            type: 'stock',
            yahooSym: 'AAPL'),
        MarketPrice(
            symbol: 'GOOGL',
            name: 'Alphabet',
            sub: 'GOOGL',
            price: 175.20,
            changePercent: 0.8,
            type: 'stock',
            yahooSym: 'GOOGL'),
        MarketPrice(
            symbol: 'MSFT',
            name: 'Microsoft',
            sub: 'MSFT',
            price: 420.10,
            changePercent: 1.2,
            type: 'stock',
            yahooSym: 'MSFT'),
        MarketPrice(
            symbol: 'NVDA',
            name: 'NVIDIA',
            sub: 'NVDA',
            price: 875.50,
            changePercent: 3.4,
            type: 'stock',
            yahooSym: 'NVDA'),
        MarketPrice(
            symbol: 'TSLA',
            name: 'Tesla',
            sub: 'TSLA',
            price: 172.80,
            changePercent: -2.1,
            type: 'stock',
            yahooSym: 'TSLA'),
      ];

  static List<MarketPrice> _fallbackIDX() => [
        MarketPrice(
            symbol: 'BBCA',
            name: 'Bank BCA',
            sub: 'IDX',
            price: 9450,
            changePercent: 1.2,
            type: 'idx',
            yahooSym: 'BBCA.JK'),
        MarketPrice(
            symbol: 'BBRI',
            name: 'Bank BRI',
            sub: 'IDX',
            price: 4200,
            changePercent: 0.5,
            type: 'idx',
            yahooSym: 'BBRI.JK'),
        MarketPrice(
            symbol: 'TLKM',
            name: 'Telkom',
            sub: 'IDX',
            price: 3180,
            changePercent: -0.3,
            type: 'idx',
            yahooSym: 'TLKM.JK'),
        MarketPrice(
            symbol: 'ASII',
            name: 'Astra',
            sub: 'IDX',
            price: 4890,
            changePercent: 0.8,
            type: 'idx',
            yahooSym: 'ASII.JK'),
        MarketPrice(
            symbol: 'BMRI',
            name: 'Bank Mandiri',
            sub: 'IDX',
            price: 6200,
            changePercent: 1.5,
            type: 'idx',
            yahooSym: 'BMRI.JK'),
      ];

  static List<MarketPrice> _fallbackForex() => [
        MarketPrice(
            symbol: 'USD',
            name: 'USD / IDR',
            sub: 'FOREX',
            price: 16215,
            changePercent: 0.0,
            type: 'forex',
            yahooSym: 'USDIDR=X'),
        MarketPrice(
            symbol: 'EUR',
            name: 'EUR / IDR',
            sub: 'FOREX',
            price: 17850,
            changePercent: 0.3,
            type: 'forex',
            yahooSym: 'EURIDR=X'),
        MarketPrice(
            symbol: 'GBP',
            name: 'GBP / IDR',
            sub: 'FOREX',
            price: 20540,
            changePercent: -0.2,
            type: 'forex',
            yahooSym: 'GBPIDR=X'),
        MarketPrice(
            symbol: 'JPY',
            name: 'JPY / IDR',
            sub: 'FOREX',
            price: 108,
            changePercent: 0.1,
            type: 'forex',
            yahooSym: 'JPYIDR=X'),
        MarketPrice(
            symbol: 'SGD',
            name: 'SGD / IDR',
            sub: 'FOREX',
            price: 12100,
            changePercent: 0.2,
            type: 'forex',
            yahooSym: 'SGDIDR=X'),
      ];

  static Map<String, dynamic> _fallbackFearGreed() =>
      {'value': 74, 'classification': 'Greed'};
}
