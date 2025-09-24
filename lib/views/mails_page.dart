import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../model/mail_analysis.dart';
import '../utils/mail_report_generator.dart';
import '../utils/pdf_saver.dart';
import '../variables.dart';

class MailsPage extends StatelessWidget {
  const MailsPage({super.key, this.onStartConversation});

  final void Function(BuildContext context, MailAnalysis mail)? onStartConversation;

  Color get _backgroundColor => const Color(0xFF0B101A);
  Color get _panelColor => const Color(0xFF111827);

  static final List<MailAnalysis> _recentMails = [
    MailAnalysis(
      subject: 'Connexion suspecte détectée',
      analyzedAt: DateTime(2025, 1, 12, 9, 24),
      maliciousnessScore: 78,
      sender: 'security@acme.inc',
      summary: 'Connexion suspecte détectée depuis un appareil non reconnu avec tentative de contournement MFA.',
    ),
    MailAnalysis(
      subject: 'Facture n°54213 en pièce jointe',
      analyzedAt: DateTime(2025, 1, 12, 8, 55),
      maliciousnessScore: 22,
      sender: 'billing@trusted-supplier.com',
      summary: 'Facture routinière détectée. Pièce jointe PDF vérifiée, aucun comportement malveillant observé.',
    ),
    MailAnalysis(
      subject: 'Confirmation de réinitialisation de mot de passe',
      analyzedAt: DateTime(2025, 1, 11, 19, 41),
      maliciousnessScore: 12,
      sender: 'no-reply@company.com',
      summary: 'Confirmation standard de réinitialisation de mot de passe sans contenu dynamique ou scripts.',
    ),
    MailAnalysis(
      subject: 'Alerte sécurité de l\'équipe IT',
      analyzedAt: DateTime(2025, 1, 11, 18, 2),
      maliciousnessScore: 65,
      sender: 'soc@company.com',
      summary: 'Notification d\'alerte interne contenant des liens vers le portail sécurisé et instructions de mitigation.',
    ),
    MailAnalysis(
      subject: 'Rapport marketing quotidien',
      analyzedAt: DateTime(2025, 1, 11, 16, 45),
      maliciousnessScore: 8,
      sender: 'insights@marketingtools.io',
      summary: 'Rapport automatisé quotidien. Contenu HTML léger sans redirections externes.',
    ),
    MailAnalysis(
      subject: 'Vérifiez votre nouvel appareil',
      analyzedAt: DateTime(2025, 1, 11, 15, 12),
      maliciousnessScore: 48,
      sender: 'alerts@cloudmailbox.net',
      summary: 'Demande de validation d\'un nouvel appareil. Lien raccourci pointant vers un domaine tiers.',
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
                  onOpenReport: () => _showReportDialog(context, mail),
                  onStartConversation: onStartConversation == null
                      ? null
                      : () => onStartConversation!(context, mail),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showReportDialog(BuildContext context, MailAnalysis mail) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (_) => _MailReportDialog(mail: mail, rootContext: context),
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
      _SidebarIcon(icon: Icons.settings_outlined),
      const Spacer(),
      Container(
        margin: const EdgeInsets.only(bottom: 12, top: 12),
        child: CircleAvatar(
          radius: 22,
          backgroundColor: const Color(0xFF1F2937),
          child: Text(
            user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
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
  const _MailCard({
    required this.mail,
    required this.panelColor,
    required this.onOpenReport,
    this.onStartConversation,
  });

  final MailAnalysis mail;
  final Color panelColor;
  final VoidCallback onOpenReport;
  final VoidCallback? onStartConversation;

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
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onOpenReport,
        child: Container(
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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
                    const SizedBox(height: 6),
                    Text(
                      'Date d\'analyse : $formattedDate',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Expéditeur : ${mail.sender}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.6),
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      mail.summary,
                      style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _ScoreBadge(score: mail.maliciousnessScore),
                  if (onStartConversation != null) ...[
                    const SizedBox(height: 12),
                    FilledButton.icon(
                      onPressed: onStartConversation,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF2563EB),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.forum_outlined),
                      label: const Text('Nouvelle conversation'),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final Color color = score >= 60
        ? const Color(0xFFB91C1C)
        : score >= 30
            ? const Color(0xFFF59E0B)
            : const Color(0xFF22C55E);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        border: Border.all(color: color.withOpacity(0.6)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'Score : $score%',
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _MailReportDialog extends StatefulWidget {
  const _MailReportDialog({required this.mail, required this.rootContext});

  final MailAnalysis mail;
  final BuildContext rootContext;

  @override
  State<_MailReportDialog> createState() => _MailReportDialogState();
}

class _MailReportDialogState extends State<_MailReportDialog> {
  Uint8List? _pdfBytes;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPdf();
  }

  Future<void> _loadPdf() async {
    try {
      final bytes = await MailReportGenerator.buildReport(widget.mail);
      if (!mounted) return;
      setState(() {
        _pdfBytes = bytes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Impossible de charger le rapport : $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(32),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xF0111827),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.35)),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Column(
            children: [
              Container(
                color: const Color(0xFF1F2937),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.mail.subject,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rapport PDF',
                            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Télécharger le rapport',
                      onPressed: _pdfBytes == null
                          ? null
                          : () => savePdf(
                                _pdfBytes!,
                                _buildFileName(widget.mail.subject),
                                widget.rootContext,
                              ),
                      icon: const Icon(Icons.download_rounded, color: Colors.white),
                    ),
                    IconButton(
                      tooltip: 'Fermer',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  color: const Color(0xFF0B101A),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white70),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: const TextStyle(color: Colors.white70),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SfPdfViewer.memory(
      _pdfBytes!,
      canShowPaginationDialog: false,
      maxZoomLevel: 3,
      minZoomLevel: 1,
      pageLayoutMode: PdfPageLayoutMode.single,
    );
  }

  String _buildFileName(String subject) {
    final sanitized = subject.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-').replaceAll(RegExp(r'-{2,}'), '-');
    return '${sanitized.toLowerCase()}-rapport.pdf';
  }
}
