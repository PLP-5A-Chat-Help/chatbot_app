import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../utils/app_palette.dart';
import '../utils/pdf_saver.dart';
import '../variables.dart';
import 'home_page.dart';
import 'mails_page.dart';
import 'widgets/primary_navigation.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, this.onChatRequested, this.onMailsRequested});

  final VoidCallback? onChatRequested;
  final VoidCallback? onMailsRequested;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _usernameController;
  late final Future<String?> _defaultDownloadDirectoryFuture;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: user.username);
    _defaultDownloadDirectoryFuture = resolveDefaultDownloadDirectory();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  ImageProvider? _buildAvatarImage() {
    final avatarPath = user.avatarPath;
    if (avatarPath == null || avatarPath.isEmpty) {
      return null;
    }
    if (avatarPath.startsWith('http')) {
      return NetworkImage(avatarPath);
    }
    final file = File(avatarPath);
    if (file.existsSync()) {
      return FileImage(file);
    }
    return null;
  }

  Future<void> _pickAvatar() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    if (result != null && result.files.single.path != null) {
      final path = result.files.single.path!;
      user.setAvatarPath(path);
      if (!mounted) return;
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar mis à jour.')),
      );
    }
  }

  Future<void> _saveUsername() async {
    final text = _usernameController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Le nom d\'utilisateur ne peut pas être vide.')),
      );
      return;
    }
    user.setUsername(text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Nom d\'utilisateur mis à jour.')),
    );
    setState(() {});
  }

  Future<void> _pickDownloadDirectory() async {
    final result = await FilePicker.platform.getDirectoryPath();
    if (result != null) {
      appPreferences.setDownloadDirectory(result);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Dossier sélectionné :\n$result')),
      );
    }
  }

  void _toggleTheme(bool value) {
    appPreferences.toggleLightMode(value);
    if (mounted) {
      setState(() {});
    }
  }

  void _logout() {
    user.clear();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final avatarImage = _buildAvatarImage();
    final downloadDirectory = appPreferences.downloadDirectory;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= 900;
            final content = _buildSettingsContent(
              palette: palette,
              avatarImage: avatarImage,
              downloadDirectory: downloadDirectory,
            );

            if (isWide) {
              return Row(
                children: [
                  PrimaryNavigation(
                    palette: palette,
                    activeIndex: 2,
                    onChatPressed: () {
                      if (widget.onChatRequested != null) {
                        widget.onChatRequested!();
                      } else {
                        Navigator.of(context).maybePop();
                      }
                    },
                    onMailsPressed: () {
                      if (widget.onMailsRequested != null) {
                        widget.onMailsRequested!();
                      } else {
                        _openMailsFromSettings(context);
                      }
                    },
                    onSettingsPressed: null,
                  ),
                  Expanded(child: content),
                ],
              );
            }

            return Column(
              children: [
                PrimaryNavigation(
                  palette: palette,
                  activeIndex: 2,
                  isHorizontal: true,
                  onChatPressed: () {
                    if (widget.onChatRequested != null) {
                      widget.onChatRequested!();
                    } else {
                      Navigator.of(context).maybePop();
                    }
                  },
                  onMailsPressed: () {
                    if (widget.onMailsRequested != null) {
                      widget.onMailsRequested!();
                    } else {
                      _openMailsFromSettings(context);
                    }
                  },
                  onSettingsPressed: null,
                ),
                Expanded(child: content),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingsContent({
    required AppPalette palette,
    required ImageProvider? avatarImage,
    required String? downloadDirectory,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Paramètres',
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          _SectionCard(
            palette: palette,
            title: 'Profil utilisateur',
            child: Row(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundColor: palette.mutedSurface,
                  backgroundImage: avatarImage,
                  child: avatarImage == null
                      ? Text(
                          user.username.isNotEmpty ? user.username[0].toUpperCase() : 'U',
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: 24,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.username,
                        style: TextStyle(
                          color: palette.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        user.email,
                        style: TextStyle(color: palette.textSecondary),
                      ),
                      const SizedBox(height: 12),
                      FilledButton.icon(
                        onPressed: _pickAvatar,
                        icon: const Icon(Icons.photo_camera_outlined),
                        label: const Text('Modifier l\'avatar'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            palette: palette,
            title: 'Informations personnelles',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _InfoLine(label: 'Prénom', value: user.firstName.isEmpty ? 'Non renseigné' : user.firstName, palette: palette),
                const SizedBox(height: 12),
                _InfoLine(label: 'Nom', value: user.lastName.isEmpty ? 'Non renseigné' : user.lastName, palette: palette),
                const SizedBox(height: 12),
                _InfoLine(label: 'Adresse e-mail', value: user.email.isEmpty ? 'Non renseignée' : user.email, palette: palette),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            palette: palette,
            title: 'Personnalisation',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: 'Nom d\'utilisateur',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saveUsername,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Enregistrer'),
                  ),
                ),
                const Divider(height: 32),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Activer le mode clair'),
                  subtitle: const Text('Utilise une interface blanche plus lumineuse.'),
                  value: appPreferences.isLightMode,
                  onChanged: _toggleTheme,
                ),
                const Divider(height: 32),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Dossier de téléchargement des rapports'),
                  subtitle: downloadDirectory != null
                      ? Text(
                          downloadDirectory,
                          style: TextStyle(color: palette.textMuted),
                        )
                      : FutureBuilder<String?>(
                          future: _defaultDownloadDirectoryFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return Text(
                                'Recherche du dossier par défaut...',
                                style: TextStyle(color: palette.textMuted),
                              );
                            }
                            final resolved = snapshot.data;
                            if (resolved == null || resolved.isEmpty) {
                              return Text(
                                'Chemin par défaut indisponible',
                                style: TextStyle(color: palette.textMuted),
                              );
                            }
                            return Text(
                              resolved,
                              style: TextStyle(color: palette.textMuted),
                            );
                          },
                        ),
                  trailing: const Icon(Icons.folder_open_outlined),
                  onTap: _pickDownloadDirectory,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _SectionCard(
            palette: palette,
            title: 'Sécurité',
            child: Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(backgroundColor: palette.danger),
                onPressed: _logout,
                icon: const Icon(Icons.logout),
                label: const Text('Se déconnecter'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openMailsFromSettings(BuildContext context) {
    final navigator = Navigator.of(context);
    navigator.push(
      PageRouteBuilder(
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
        pageBuilder: (_, __, ___) => MailsPage(
          onOpenChat: () {
            navigator.pop();
            if (widget.onChatRequested != null) {
              widget.onChatRequested!();
            } else {
              navigator.maybePop();
            }
          },
          onOpenSettings: () {
            navigator.pop();
          },
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.palette,
    required this.title,
    required this.child,
  });

  final AppPalette palette;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(color: palette.shadow, blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({
    required this.label,
    required this.value,
    required this.palette,
  });

  final String label;
  final String value;
  final AppPalette palette;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.textMuted,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: palette.textPrimary,
            fontSize: 15,
          ),
        ),
      ],
    );
  }
}
