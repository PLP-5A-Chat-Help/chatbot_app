import 'dart:convert';
import 'dart:io';

import 'package:chatbot_app/views/discussion_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../utils/app_palette.dart';
import '../variables.dart';

/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  home_page.dart
---------------------------------- */

/// Page d'accueil de l'application
/// Cette page permet à l'utilisateur de se connecter à son compte.
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  String messageErreur = "";

  Future<HttpClient> createSecureHttpClient() async {
    final context = SecurityContext.defaultContext;
    final ByteData certData = await rootBundle.load('assets/certs/myCA.pem');
    context.setTrustedCertificatesBytes(certData.buffer.asUint8List());
    return HttpClient(context: context);
  }

  Future<void> connexion() async {
    setState(() {
      messageErreur = "";
    });

    final client = await createSecureHttpClient();
    final url = Uri.parse('$urlPrefix/login');
    final username = usernameController.text.trim();
    final body = {
      "email": username,
      "password": passwordController.text,
    };

    try {
      final request = await client.postUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);

        user.setAccessToken(data['access_token'] ?? '');
        user.setTokenType(data['token_type'] ?? '');
        user.setUsername(username.isEmpty ? 'Utilisateur' : username);

        if (data is Map<String, dynamic>) {
          final infos = data['utilisateur'] ?? data['user'];
          if (infos is Map<String, dynamic>) {
            user.setNames(
              first: (infos['prenom'] ?? infos['first_name'] ?? '') as String,
              last: (infos['nom'] ?? infos['last_name'] ?? '') as String,
            );
            final emailValue = (infos['email'] ?? username) as String;
            user.setEmail(emailValue);
            final avatar = infos['avatar'] as String?;
            if (avatar != null && avatar.isNotEmpty) {
              user.setAvatarPath(avatar);
            }
          } else {
            user.setEmail(username);
          }
        } else {
          user.setEmail(username);
        }

        usernameController.clear();
        passwordController.clear();

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DiscussionPage.empty()),
        );
      } else {
        setState(() {
          messageErreur = "Erreur lors de la connexion : ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        messageErreur = "Erreur pendant la connexion.";
      });
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: palette.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _AuthCard(
                palette: palette,
                messageErreur: messageErreur,
                onConnexion: connexion,
                usernameController: usernameController,
                passwordController: passwordController,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.palette,
    required this.messageErreur,
    required this.onConnexion,
    required this.usernameController,
    required this.passwordController,
  });

  final AppPalette palette;
  final String messageErreur;
  final VoidCallback onConnexion;
  final TextEditingController usernameController;
  final TextEditingController passwordController;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: palette.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: palette.border),
        boxShadow: [
          BoxShadow(color: palette.shadow, blurRadius: 30, offset: const Offset(0, 18)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Connexion",
            style: TextStyle(
              color: palette.textPrimary,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          if (messageErreur.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: palette.danger.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: palette.danger.withOpacity(0.35)),
              ),
              child: Text(
                messageErreur,
                style: TextStyle(
                  color: palette.danger,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _InputField(
            controller: usernameController,
            label: "Identifiant",
            hint: "Entrez votre identifiant",
            palette: palette,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: passwordController,
            label: "Mot de passe",
            hint: "Entrez votre mot de passe",
            palette: palette,
            obscureText: true,
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onConnexion,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                backgroundColor: palette.primary,
                foregroundColor: palette.accentTextOnPrimary,
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: const Text('Se connecter'),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.palette,
    this.obscureText = false,
    this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final AppPalette palette;
  final bool obscureText;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: palette.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: palette.mutedSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: palette.border),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            cursorColor: palette.primary,
            style: TextStyle(color: palette.textPrimary, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, color: palette.textMuted)
                  : null,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: palette.textMuted),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}
