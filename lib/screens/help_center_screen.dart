import 'package:flutter/material.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({super.key});

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  static const Color _navy = Color(0xFF0D1B3E);
  static const Color _yellow = Color(0xFFF5C842);
  static const Color _green = Color(0xFF1DB87A);
  static const Color _white = Colors.white;

  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  int? _expandedIndex;

  // ── FAQ Data ────────────────────────────────────────────────────────────────
  static const List<Map<String, String>> _faqs = [
    // Account
    {
      'category': 'Account',
      'q': 'How do I change my password?',
      'a': 'Go to Settings → Security & Privacy → Send Password Reset Email. '
          'A reset link will be sent to your registered email address. '
          'Follow the link to set a new password.',
    },
    {
      'category': 'Account',
      'q': 'How do I update my profile photo?',
      'a':
          'Go to Settings → Edit Profile, then tap the camera icon on your profile picture. '
              'Choose a photo from your gallery or take a new one. '
              'Your photo will be saved automatically.',
    },
    {
      'category': 'Account',
      'q': 'What should I do if I forget my password?',
      'a': 'On the Login screen, tap "Forgot Password". '
          'Enter your registered email address and we will send you a password reset link. '
          'Check your spam folder if it does not arrive within a few minutes.',
    },
    // Transactions
    {
      'category': 'Transactions',
      'q': 'How do I add a new transaction?',
      'a': 'Tap the + button at the bottom of the screen. '
          'Select the type (Income / Expense / Transfer), fill in the amount, category, '
          'date, and an optional note. Tap Save to record the transaction.',
    },
    {
      'category': 'Transactions',
      'q': 'Can I edit or delete a transaction?',
      'a': 'Yes. Tap the transaction you want to modify on the History screen. '
          'Edit and Delete buttons are available in the transaction detail view. '
          'Deletion is permanent and cannot be undone.',
    },
    {
      'category': 'Transactions',
      'q': 'What is the difference between Income, Expense, and Transfer?',
      'a': 'Income = money coming into an account (salary, bonus, etc). '
          'Expense = money going out of an account (shopping, bills, etc). '
          'Transfer = moving money between your own accounts.',
    },
    // Export & Data
    {
      'category': 'Export & Data',
      'q': 'Why can\'t I open the CSV file in Excel?',
      'a': 'Make sure you open the file with UTF-8 encoding. '
          'In Excel: Data → From Text/CSV → select the file → set encoding to UTF-8. '
          'The latest version of WalletScript includes a BOM so the file opens correctly by default.',
    },
    {
      'category': 'Export & Data',
      'q': 'Where is the CSV file saved after downloading?',
      'a': 'The file is saved to your device\'s Downloads folder '
          '(/storage/emulated/0/Download/) with the filename format '
          'WalletScript_YYYY-MM-DD_HHMM.csv.',
    },
    {
      'category': 'Export & Data',
      'q': 'Does Clear History delete my account balances?',
      'a': 'No. Clear Transaction History only removes transaction records. '
          'Balances in each of your accounts are not affected. '
          'We recommend exporting your data before clearing history.',
    },
    // Financial Accounts
    {
      'category': 'Financial Accounts',
      'q': 'How many accounts can I add?',
      'a': 'There is no limit on the number of accounts. You can add '
          'bank accounts, e-wallets (GoPay, OVO, etc), credit cards, '
          'or cash accounts as many as you need.',
    },
    {
      'category': 'Financial Accounts',
      'q': 'Is my data safe in WalletScript?',
      'a': 'Your data is stored on Supabase with industry-standard encryption. '
          'We never sell or share your personal data with third parties. '
          'See our Privacy Policy for full details.',
    },
    // Budget
    {
      'category': 'Budget',
      'q': 'How do budget alerts work?',
      'a': 'WalletScript monitors your spending against your set budget limits. '
          'You will receive a notification when you reach 80% of a budget category, '
          'and another when you exceed it.',
    },
    {
      'category': 'Budget',
      'q': 'Can I set different budgets for each category?',
      'a': 'Yes. Go to the Budget screen and tap the + button to create a budget '
          'for any spending category. You can set a monthly limit for each category independently.',
    },
  ];

  List<Map<String, String>> get _filtered {
    if (_query.isEmpty) return _faqs;
    final q = _query.toLowerCase();
    return _faqs.where((f) {
      return f['q']!.toLowerCase().contains(q) ||
          f['a']!.toLowerCase().contains(q) ||
          f['category']!.toLowerCase().contains(q);
    }).toList();
  }

  Map<String, List<Map<String, String>>> get _grouped {
    final map = <String, List<Map<String, String>>>{};
    for (final f in _filtered) {
      map.putIfAbsent(f['category']!, () => []).add(f);
    }
    return map;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _grouped;

    return Scaffold(
      backgroundColor: _white,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: _navy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Help Center',
          style: TextStyle(
              color: _navy, fontSize: 17, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ── Hero banner ────────────────────────────────────────────────
          Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            decoration: BoxDecoration(
              color: _navy,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'How can we\nhelp you?',
                        style: TextStyle(
                            color: _white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.3),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Find answers to common questions below',
                        style: TextStyle(
                            color: _white.withOpacity(0.6), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: _yellow,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.support_agent_rounded,
                      color: _navy, size: 28),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Search bar ─────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() {
                _query = v;
                _expandedIndex = null;
              }),
              style: const TextStyle(color: _navy, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search questions...',
                hintStyle:
                    TextStyle(color: _navy.withOpacity(0.4), fontSize: 14),
                prefixIcon: Icon(Icons.search_rounded,
                    color: _navy.withOpacity(0.5), size: 20),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded,
                            color: _navy.withOpacity(0.4), size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {
                            _query = '';
                            _expandedIndex = null;
                          });
                        },
                      )
                    : null,
                filled: true,
                fillColor: _navy.withOpacity(0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── FAQ list ───────────────────────────────────────────────────
          Expanded(
            child: grouped.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.search_off_rounded,
                            size: 48, color: _navy.withOpacity(0.2)),
                        const SizedBox(height: 12),
                        Text(
                          'No results for "$_query"',
                          style: TextStyle(
                              color: _navy.withOpacity(0.45), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    children: [
                      for (final category in grouped.keys) ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 8, bottom: 8),
                          child: Row(
                            children: [
                              Container(
                                width: 4,
                                height: 16,
                                decoration: BoxDecoration(
                                  color: _yellow,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                category,
                                style: const TextStyle(
                                    color: _navy,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: _white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: _navy.withOpacity(0.1)),
                            boxShadow: [
                              BoxShadow(
                                color: _navy.withOpacity(0.04),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              for (int i = 0;
                                  i < grouped[category]!.length;
                                  i++) ...[
                                _FaqTile(
                                  faq: grouped[category]![i],
                                  isExpanded: _expandedIndex ==
                                      _globalIndex(category, i, grouped),
                                  onTap: () {
                                    final idx =
                                        _globalIndex(category, i, grouped);
                                    setState(() {
                                      _expandedIndex =
                                          _expandedIndex == idx ? null : idx;
                                    });
                                  },
                                ),
                                if (i < grouped[category]!.length - 1)
                                  Divider(
                                      height: 1,
                                      color: _navy.withOpacity(0.08)),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                      ],

                      // ── Contact support banner ──────────────────────
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: _green.withOpacity(0.25)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: _green.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.mail_outline_rounded,
                                  color: _green, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Still have questions?',
                                    style: TextStyle(
                                        color: _navy,
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13),
                                  ),
                                  Text(
                                    'Contact us at support@walletscript.app',
                                    style: TextStyle(
                                        color: _navy.withOpacity(0.55),
                                        fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  int _globalIndex(
    String category,
    int localIndex,
    Map<String, List<Map<String, String>>> grouped,
  ) {
    int base = 0;
    for (final key in grouped.keys) {
      if (key == category) return base + localIndex;
      base += grouped[key]!.length;
    }
    return base + localIndex;
  }
}

// ── FAQ Tile widget ────────────────────────────────────────────────────────────
class _FaqTile extends StatelessWidget {
  const _FaqTile({
    required this.faq,
    required this.isExpanded,
    required this.onTap,
  });

  final Map<String, String> faq;
  final bool isExpanded;
  final VoidCallback onTap;

  static const Color _navy = Color(0xFF0D1B3E);
  static const Color _green = Color(0xFF1DB87A);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    faq['q']!,
                    style: TextStyle(
                      color: _navy,
                      fontWeight:
                          isExpanded ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 13.5,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                AnimatedRotation(
                  duration: const Duration(milliseconds: 200),
                  turns: isExpanded ? 0.5 : 0,
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: isExpanded ? _green : _navy.withOpacity(0.4),
                    size: 22,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: Text(
                        faq['a']!,
                        style: TextStyle(
                          color: _navy.withOpacity(0.65),
                          fontSize: 13,
                          height: 1.55,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
