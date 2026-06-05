import 'package:flutter/material.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

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
          'Terms of Service',
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
            // ── Header Banner ─────────────────────────────────────────
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
                    child: const Icon(Icons.gavel_rounded,
                        color: _yellow, size: 28),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Terms of Service',
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
                    'Please read these terms carefully before using WalletScript. '
                    'By using the app, you agree to be bound by these terms.',
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

            // ── Sections ──────────────────────────────────────────────
            _buildSection(
              icon: Icons.check_circle_outline_rounded,
              iconColor: _green,
              title: '1. Acceptance of Terms',
              content:
                  'By downloading, installing, or using WalletScript ("the App"), '
                  'you agree to be bound by these Terms of Service. '
                  'If you do not agree to these terms, please do not use the App.\n\n'
                  'We reserve the right to update these terms at any time. '
                  'Continued use of the App after changes are posted constitutes your acceptance of the revised terms.',
            ),
            _buildSection(
              icon: Icons.person_outline_rounded,
              iconColor: _navy,
              title: '2. Eligibility',
              content:
                  'You must be at least 13 years of age to use WalletScript. '
                  'By using the App, you represent and warrant that you meet this requirement.\n\n'
                  'If you are using the App on behalf of an organization, '
                  'you represent that you have the authority to bind that organization to these terms.',
            ),
            _buildSection(
              icon: Icons.account_circle_outlined,
              iconColor: const Color(0xFF8B5CF6),
              title: '3. Your Account',
              content:
                  'You are responsible for maintaining the confidentiality of your account credentials. '
                  'You agree to:\n\n'
                  '• Provide accurate and complete registration information\n'
                  '• Keep your password secure and not share it with others\n'
                  '• Notify us immediately of any unauthorized use of your account\n'
                  '• Be responsible for all activity that occurs under your account\n\n'
                  'We reserve the right to suspend or terminate accounts that violate these terms.',
            ),
            _buildSection(
              icon: Icons.thumb_up_alt_outlined,
              iconColor: _green,
              title: '4. Acceptable Use',
              content:
                  'You agree to use WalletScript only for lawful personal finance management. '
                  'You must not:\n\n'
                  '• Use the App for any illegal or fraudulent purpose\n'
                  '• Attempt to gain unauthorized access to our systems\n'
                  '• Reverse engineer, decompile, or disassemble the App\n'
                  '• Upload malicious code or interfere with the App\'s functionality\n'
                  '• Use the App to store or transmit unlawful content',
            ),
            _buildSection(
              icon: Icons.storage_outlined,
              iconColor: _yellow,
              title: '5. Data & Financial Information',
              content:
                  'WalletScript is a personal finance tracking tool. Please note:\n\n'
                  '• The App does not connect to your bank accounts directly\n'
                  '• All financial data you enter is manually recorded by you\n'
                  '• We are not responsible for errors in your manually entered data\n'
                  '• Financial reports and insights are for informational purposes only\n'
                  '• We do not provide financial advice — consult a qualified advisor for financial decisions',
            ),
            _buildSection(
              icon: Icons.copyright_outlined,
              iconColor: _navy,
              title: '6. Intellectual Property',
              content:
                  'WalletScript and all its content, features, and functionality are owned by '
                  'WalletScript and are protected by intellectual property laws.\n\n'
                  'You are granted a limited, non-exclusive, non-transferable license to use the App '
                  'for personal, non-commercial purposes. '
                  'You may not copy, modify, distribute, or create derivative works based on the App '
                  'without our prior written consent.',
            ),
            _buildSection(
              icon: Icons.warning_amber_rounded,
              iconColor: const Color(0xFFEF4444),
              title: '7. Disclaimer of Warranties',
              content:
                  'WalletScript is provided "as is" and "as available" without warranties of any kind. '
                  'We do not warrant that:\n\n'
                  '• The App will be uninterrupted or error-free\n'
                  '• Any errors in the App will be corrected\n'
                  '• The App is free from viruses or other harmful components\n\n'
                  'Your use of the App is at your sole risk.',
            ),
            _buildSection(
              icon: Icons.shield_outlined,
              iconColor: _green,
              title: '8. Limitation of Liability',
              content:
                  'To the fullest extent permitted by law, WalletScript shall not be liable for:\n\n'
                  '• Any indirect, incidental, or consequential damages\n'
                  '• Loss of data, profits, or business opportunities\n'
                  '• Damages resulting from unauthorized access to your account\n'
                  '• Any financial decisions made based on data or insights from the App\n\n'
                  'Our total liability shall not exceed the amount you paid for the App in the last 12 months.',
            ),
            _buildSection(
              icon: Icons.cancel_outlined,
              iconColor: const Color(0xFFEF4444),
              title: '9. Termination',
              content:
                  'You may stop using the App at any time by deleting your account. '
                  'We may suspend or terminate your account if you:\n\n'
                  '• Violate these Terms of Service\n'
                  '• Engage in fraudulent or illegal activity\n'
                  '• Abuse or misuse the App\n\n'
                  'Upon termination, your right to use the App will immediately cease. '
                  'We recommend exporting your data before deleting your account.',
            ),
            _buildSection(
              icon: Icons.update_rounded,
              iconColor: const Color(0xFF8B5CF6),
              title: '10. Changes to Terms',
              content:
                  'We reserve the right to modify these Terms of Service at any time. '
                  'When we make material changes, we will notify you via:\n\n'
                  '• In-app notification\n'
                  '• Email to your registered address\n\n'
                  'Your continued use of the App after the effective date of any changes '
                  'constitutes your acceptance of the revised terms.',
            ),

            // ── Contact Card ──────────────────────────────────────────
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
                          'Questions about our terms?',
                          style: TextStyle(
                            color: _navy,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Contact us at legal@walletscript.app\n'
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
