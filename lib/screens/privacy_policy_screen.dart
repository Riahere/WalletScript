import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const Color _navy = Color(0xFF0D1B3E);
  static const Color _yellow = Color(0xFFF5C842);
  static const Color _green = Color(0xFF1DB87A);
  static const Color _white = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _white,
      appBar: AppBar(
        backgroundColor: _white,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_rounded, color: _navy, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Privacy Policy',
          style: TextStyle(
            color: _navy,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header Banner ────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _yellow.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.privacy_tip_rounded,
                        color: _yellow, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Your Privacy Matters',
                    style: TextStyle(
                      color: _white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Last updated: June 2025',
                    style: TextStyle(
                      color: _white.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'WalletScript is built with your financial privacy as the top priority. '
                    'This policy explains how your data is collected, used, and protected.',
                    style: TextStyle(
                      color: _white.withOpacity(0.8),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Sections ─────────────────────────────────────────────
            _buildSection(
              icon: Icons.storage_rounded,
              iconColor: _green,
              title: '1. Data We Collect',
              content:
                  'We collect only the information necessary to provide our services:\n\n'
                  '• Account info: name, email address\n'
                  '• Financial data: transactions, categories, account balances\n'
                  '• Device info: OS version, app version (for crash reports)\n'
                  '• Usage data: features used, session duration (anonymized)',
            ),
            _buildSection(
              icon: Icons.settings_applications_rounded,
              iconColor: _navy,
              title: '2. How We Use Your Data',
              content:
                  'Your data is used solely to provide and improve WalletScript:\n\n'
                  '• Sync your financial data across devices via Supabase\n'
                  '• Send budget alerts and reminders you configure\n'
                  '• Generate your financial reports and export files\n'
                  '• Fix bugs and improve app performance\n\n'
                  'We do NOT use your data for advertising or sell it to third parties.',
            ),
            _buildSection(
              icon: Icons.share_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: '3. Data Sharing',
              content:
                  'We share your data only with trusted service providers:\n\n'
                  '• Supabase — database and authentication (servers located in Singapore)\n'
                  '• No data is sold, rented, or shared with advertisers\n'
                  '• We may disclose data if required by law',
            ),
            _buildSection(
              icon: Icons.lock_rounded,
              iconColor: _yellow,
              title: '4. Data Security',
              content: 'We implement industry-standard security measures:\n\n'
                  '• All data transmitted over HTTPS/TLS encryption\n'
                  '• Passwords hashed with bcrypt (never stored in plain text)\n'
                  '• Supabase Row Level Security (RLS) ensures you only see your own data\n'
                  '• Regular security audits',
            ),
            _buildSection(
              icon: Icons.person_rounded,
              iconColor: _green,
              title: '5. Your Rights',
              content: 'You have full control over your data:\n\n'
                  '• Access: export all your data anytime via Settings → Export\n'
                  '• Correction: edit your profile and transactions at any time\n'
                  '• Deletion: delete all transaction history via Settings → Clear History\n'
                  '• Account deletion: contact us to permanently delete your account\n'
                  '• Portability: your exported CSV can be used in any spreadsheet app',
            ),
            _buildSection(
              icon: Icons.child_care_rounded,
              iconColor: _navy,
              title: '6. Children\'s Privacy',
              content:
                  'WalletScript is not intended for users under 13 years of age. '
                  'We do not knowingly collect personal information from children. '
                  'If you believe a child has provided us with personal data, '
                  'please contact us immediately.',
            ),
            _buildSection(
              icon: Icons.update_rounded,
              iconColor: const Color(0xFFEF4444),
              title: '7. Policy Updates',
              content: 'We may update this Privacy Policy from time to time. '
                  'When we make significant changes, we will notify you via:\n\n'
                  '• In-app notification\n'
                  '• Email to your registered address\n\n'
                  'Continued use of WalletScript after changes constitutes acceptance of the updated policy.',
            ),

            // ── Contact Card ─────────────────────────────────────────
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.07),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _green.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        const Icon(Icons.mail_rounded, color: _green, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Questions about privacy?',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact us at privacy@walletscript.app\n'
                          'We respond within 48 hours.',
                          style: TextStyle(
                            color: _navy.withOpacity(0.6),
                            fontSize: 13,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Center(
              child: Text(
                '© 2025 WalletScript. All rights reserved.',
                style: TextStyle(
                  color: _navy.withOpacity(0.35),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
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
        child: Theme(
          data: ThemeData().copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            leading: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            title: Text(
              title,
              style: const TextStyle(
                color: _navy,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
            iconColor: _navy,
            collapsedIconColor: _navy.withOpacity(0.4),
            children: [
              Text(
                content,
                style: TextStyle(
                  color: _navy.withOpacity(0.7),
                  fontSize: 13,
                  height: 1.7,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
