
import 'dart:typed_data';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../model/mail_analysis.dart';
import '../utils/app_palette.dart';
import '../utils/mail_report_generator.dart';
import '../utils/pdf_saver.dart';
import '../variables.dart';
import 'discussion_page.dart';
import 'settings_page.dart';
import 'widgets/primary_navigation.dart';

class MailsPage extends StatelessWidget {
  const MailsPage({super.key, this.onStartConversation, this.onOpenChat, this.onOpenSettings});

  final void Function(BuildContext context, MailAnalysis mail)? onStartConversation;
  final VoidCallback? onOpenChat;
  final VoidCallback? onOpenSettings;

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
    final palette = AppPalette.of(context);
    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bool isWide = constraints.maxWidth >= 900;
            final mailContent = _buildMailContent(palette, isWide);

            if (isWide) {
              return Row(
                children: [
                  PrimaryNavigation(
                    palette: palette,
                    activeIndex: 1,
                    onChatPressed: onOpenChat ?? () => Navigator.of(context).maybePop(),
                    onMailsPressed: null,
                    onSettingsPressed: () => _openSettings(context),
                  ),
                  Expanded(child: mailContent),
                ],
              );
            }

            return Column(
              children: [
                PrimaryNavigation(
                  palette: palette,
                  activeIndex: 1,
                  isHorizontal: true,
                  onChatPressed: onOpenChat ?? () => Navigator.of(context).maybePop(),
                  onMailsPressed: null,
                  onSettingsPressed: () => _openSettings(context),
                ),
                Expanded(child: mailContent),
              ],
            );
          },
        ),
      ),
    );
  }

  void _openSettings(BuildContext context) {
    if (onOpenSettings != null) {
      onOpenSettings!();
      return;
    }
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => SettingsPage(
          onChatRequested: () {
            Navigator.of(context).pushAndRemoveUntil(
              PageRouteBuilder(
                transitionDuration: Duration.zero,
                reverseTransitionDuration: Duration.zero,
                pageBuilder: (_, __, ___) => DiscussionPage.empty(),
              ),
              (route) => route.isFirst,
            );
          },
        ),
      ),
    );
  }

  Widget _buildMailContent(AppPalette palette, bool isWide) {
    return Container(
      color: palette.background,
      padding: EdgeInsets.symmetric(
        horizontal: isWide ? 48 : 24,
        vertical: isWide ? 48 : 28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mails analysés récemment',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Consultez les derniers rapports générés par le serveur.',
            style: TextStyle(
              color: palette.textSecondary,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 32),
          Expanded(
            child: ListView.separated(
              physics: const BouncingScrollPhysics(),
              itemCount: _recentMails.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final mail = _recentMails[index];
                return _MailCard(
                  mail: mail,
                  palette: palette,
                  isWide: isWide,
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

class _MailCard extends StatelessWidget {
  const _MailCard({
    required this.mail,
    required this.palette,
    required this.onOpenReport,
    required this.isWide,
    this.onStartConversation,
  });

  final MailAnalysis mail;
  final AppPalette palette;
  final VoidCallback onOpenReport;
  final bool isWide;
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
            color: palette.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: palette.border),
            boxShadow: [
              BoxShadow(
                color: palette.shadow,
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: palette.mutedSurface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.mail_outline, color: palette.textMuted),
                  ),
                  const SizedBox(width: 18),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mail.subject,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontSize: 17,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Date d\'analyse : $formattedDate',
                          style: TextStyle(
                            color: palette.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Expéditeur : ${mail.sender}',
                          style: TextStyle(
                            color: palette.textMuted,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                mail.summary,
                                style: TextStyle(
                                  color: palette.textSecondary,
                                  fontSize: 13.5,
                                  height: 1.35,
                                ),
                              ),
                            ),
                            if (isWide && onStartConversation != null) ...[
                              const SizedBox(width: 16),
                              _ConversationButton(
                                palette: palette,
                                onPressed: onStartConversation!,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Align(
                    alignment: Alignment.topRight,
                    child: _ScoreBadge(palette: palette, score: mail.maliciousnessScore),
                  ),
                ],
              ),
              if (!isWide && onStartConversation != null) ...[
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.bottomRight,
                  child: _ConversationButton(
                    palette: palette,
                    onPressed: onStartConversation!,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ConversationButton extends StatelessWidget {
  const _ConversationButton({required this.palette, required this.onPressed});

  final AppPalette palette;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: palette.primary,
        foregroundColor: palette.accentTextOnPrimary,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      icon: const Icon(Icons.forum_outlined),
      label: const Text('Nouvelle conversation'),
    );
  }
}

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.palette, required this.score});

  final AppPalette palette;
  final int score;

  @override
  Widget build(BuildContext context) {
    final Color color = score >= 60
        ? palette.danger
        : score >= 30
            ? palette.warning
            : palette.success;
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
          color: palette.textPrimary,
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
  late final PdfViewerController _pdfController;

  static const double _minZoom = 1.0;
  static const double _maxZoom = 3.0;
  static const double _zoomStep = 0.2;

  @override
  void initState() {
    super.initState();
    _pdfController = PdfViewerController();
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
    final palette = AppPalette.of(context);
    final media = MediaQuery.of(context);
    final bool isCompact = media.size.width < 700;
    final EdgeInsets inset = isCompact
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 24)
        : const EdgeInsets.all(32);
    final double maxDialogWidth = isCompact ? media.size.width : media.size.width * 0.82;
    final double maxDialogHeight = isCompact ? media.size.height : media.size.height * 0.88;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: inset,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: maxDialogWidth,
          maxHeight: maxDialogHeight,
        ),
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: palette.dialogSurface.withOpacity(0.92),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: palette.border.withOpacity(0.8)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: Column(
              children: [
                Container(
                  color: palette.mutedSurface,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.mail.subject,
                              style: TextStyle(
                                color: palette.textPrimary,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rapport PDF',
                              style: TextStyle(color: palette.textSecondary, fontSize: 13),
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
                        icon: Icon(Icons.download_rounded, color: palette.textPrimary),
                      ),
                      IconButton(
                        tooltip: 'Fermer',
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(Icons.close_rounded, color: palette.textPrimary),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    color: palette.background,
                    child: _buildBody(palette),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppPalette palette) {
    if (_loading) {
      return Center(
        child: CircularProgressIndicator(color: palette.primary),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _error!,
            style: TextStyle(color: palette.textSecondary),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Listener(
      onPointerSignal: _handlePointerSignal,
      child: SfPdfViewer.memory(
        _pdfBytes!,
        controller: _pdfController,
        canShowPaginationDialog: false,
        enableDoubleTapZooming: true,
        interactionMode: PdfInteractionMode.pan,
        maxZoomLevel: _maxZoom,
        pageLayoutMode: PdfPageLayoutMode.single,
      ),
    );
  }

  String _buildFileName(String subject) {
    final sanitized = subject.replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '-').replaceAll(RegExp(r'-{2,}'), '-');
    return '${sanitized.toLowerCase()}-rapport.pdf';
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    final pressedKeys = HardwareKeyboard.instance.logicalKeysPressed;
    final hasModifier = pressedKeys.contains(LogicalKeyboardKey.controlLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.controlRight) ||
        pressedKeys.contains(LogicalKeyboardKey.metaLeft) ||
        pressedKeys.contains(LogicalKeyboardKey.metaRight);
    if (!hasModifier) return;

    final currentZoom = _pdfController.zoomLevel;
    final direction = event.scrollDelta.dy;
    double targetZoom = direction > 0 ? currentZoom - _zoomStep : currentZoom + _zoomStep;
    targetZoom = targetZoom.clamp(_minZoom, _maxZoom);
    if ((targetZoom - currentZoom).abs() < 0.01) return;
    _pdfController.zoomLevel = targetZoom;
  }
}
