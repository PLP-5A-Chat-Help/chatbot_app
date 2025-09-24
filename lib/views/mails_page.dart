import 'package:flutter/material.dart';

import '../variables.dart';

/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  mails_page.dart
---------------------------------- */

class MailsPage extends StatelessWidget {
  const MailsPage({super.key});

  Color get _backgroundColor => const Color(0xFF0B101A);
  Color get _panelColor => const Color(0xFF111827);

  static final List<_MailAnalysis> _recentMails = [
        _MailAnalysis(
          subject: 'Suspicious login detected',
          analyzedAt: DateTime(2025, 1, 12, 9, 24),
          maliciousnessScore: 78,
        ),
        _MailAnalysis(
          subject: 'Invoice #54213 attached',
          analyzedAt: DateTime(2025, 1, 12, 8, 55),
          maliciousnessScore: 22,
        ),
        _MailAnalysis(
          subject: 'Password reset confirmation',
          analyzedAt: DateTime(2025, 1, 11, 19, 41),
          maliciousnessScore: 12,
        ),
        _MailAnalysis(
          subject: 'Security alert from IT team',
          analyzedAt: DateTime(2025, 1, 11, 18, 2),
          maliciousnessScore: 65,
        ),
        _MailAnalysis(
          subject: 'Daily marketing report',
          analyzedAt: DateTime(2025, 1, 11, 16, 45),
          maliciousnessScore: 8,
        ),
        _MailAnalysis(
          subject: 'Verify your new device',
          analyzedAt: DateTime(2025, 1, 11, 15, 12),
          maliciousnessScore: 48,
        ),
      ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 900;
            final mailContent = _buildMailContent(isWide);

            if (isWide) {
              return Row(
                children: [
                  _PrimarySidebar(
                    activeIndex: 1,
                    onChatPressed: () => Navigator.of(context).maybePop(),
                    onMailsPressed: null,
                  ),
                  Expanded(child: mailContent),
                ],
              );
            }

            return Column(
              children: [
                _PrimarySidebar(
                  activeIndex: 1,
                  isHorizontal: true,
                  onChatPressed: () => Navigator.of(context).maybePop(),
                  onMailsPressed: null,
                ),
                Expanded(child: mailContent),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildMailContent(bool isWide) {
    return Container(
      color: _backgroundColor,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: isWide ? 48 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mails analysés récemment',
            style: TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Consultez les derniers rapports générés par le serveur.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _recentMails.length,
              separatorBuilder: (_, __) => const SizedBox(height: 18),
              itemBuilder: (context, index) {
                final mail = _recentMails[index];
                return _MailCard(
                  mail: mail,
                  panelColor: _panelColor,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimarySidebar extends StatelessWidget {
  const _PrimarySidebar({
    required this.activeIndex,
    this.isHorizontal = false,
    this.onChatPressed,
    this.onMailsPressed,
  });

  final int activeIndex;
  final bool isHorizontal;
  final VoidCallback? onChatPressed;
  final VoidCallback? onMailsPressed;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      _SidebarIcon(
        icon: Icons.chat_bubble_outline,
        active: activeIndex == 0,
        onTap: onChatPressed,
      ),
      _SidebarIcon(
        icon: Icons.folder_copy_outlined,
        active: activeIndex == 1,
        onTap: onMailsPressed,
      ),
      _SidebarIcon(icon: Icons.analytics_outlined),
      _SidebarIcon(icon: Icons.settings_outlined),
      const Spacer(),
      Container(
        margin: const EdgeInsets.only(bottom: 12, top: 12),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF1F2937),
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    ];

    if (isHorizontal) {
      return Container(
        height: 88,
        decoration: const BoxDecoration(color: Color(0xFF0F172A)),
        child: Row(
          children: [
            const SizedBox(width: 24),
            _buildLogo(),
            const SizedBox(width: 24),
            ...children,
            const SizedBox(width: 24),
          ],
        ),
      );
    }

    return Container(
      width: 88,
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        border: Border(
          right: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 24),
          _buildLogo(),
          const SizedBox(height: 32),
          ...children,
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF1F2937),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Image.asset('assets/logo.png', fit: BoxFit.contain),
      ),
    );
  }
}

class _SidebarIcon extends StatelessWidget {
  const _SidebarIcon({
    required this.icon,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: active ? const Color(0xFF1F2937) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: active ? Colors.white.withOpacity(0.25) : Colors.white.withOpacity(0.06),
            ),
          ),
          child: Icon(icon, color: active ? Colors.white : Colors.white60),
        ),
      ),
    );
  }
}

class _MailCard extends StatelessWidget {
  const _MailCard({required this.mail, required this.panelColor});

  final _MailAnalysis mail;
  final Color panelColor;

  String get formattedDate {
    final day = mail.analyzedAt.day.toString().padLeft(2, '0');
    final month = mail.analyzedAt.month.toString().padLeft(2, '0');
    final year = mail.analyzedAt.year.toString();
    final hour = mail.analyzedAt.hour.toString().padLeft(2, '0');
    final minute = mail.analyzedAt.minute.toString().padLeft(2, '0');
    return '$day/$month/$year à $hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1F2937),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.mail_outline, color: Colors.white70),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  mail.subject,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Date d\'analyse : $formattedDate',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1F2937),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white.withOpacity(0.08)),
                  ),
                  child: Text(
                    'Score of maliciousness : ${mail.maliciousnessScore}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MailAnalysis {
  const _MailAnalysis({
    required this.subject,
    required this.analyzedAt,
    required this.maliciousnessScore,
  });

  final String subject;
  final DateTime analyzedAt;
  final int maliciousnessScore;
}
