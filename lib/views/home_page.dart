import 'dart:convert';
import 'dart:io';

import 'package:chatbot_app/views/discussion_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  // Controlleurs pour les champs de texte
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  // Message qui apparaît en cas d'erreur
  String messageErreur = "";

  /// Crée un client HTTP sécurisé avec le certificat CA
  Future<HttpClient> createSecureHttpClient() async {
    final context = SecurityContext.defaultContext;
    final ByteData certData = await rootBundle.load('assets/certs/myCA.pem');
    context.setTrustedCertificatesBytes(certData.buffer.asUint8List());
    return HttpClient(context: context);
  }


  /// Méthode pour se connecter
  void connexion() async {
    // Vide le message d'erreur
    setState(() {
      messageErreur = "";
    });

    // Crée un client HTTP sécurisé
    final client = await createSecureHttpClient();

    // Prépare l'URL et le corps de la requête
    final url = Uri.parse('$urlPrefix/login');
    final body = {
      "email": usernameController.text,
      "password": passwordController.text,
    };

    try {
      // Envoie la requête POST pour la connexion
      final request = await client.postUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode(body)));

      // Attend la réponse du serveur
      final response = await request.close();

      // Vérifie le code de statut de la réponse
      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = jsonDecode(responseBody);

        // Récupère le token d'accès
        user.setAccessToken(data['access_token']);
        user.setTokenType(data['token_type']);
        user.setUsername(usernameController.text);

        //print("Connexion réussie: ${user.getAccessToken()}");

        // Vide les champs de texte
        usernameController.clear();
        passwordController.clear();

        // Navigue vers la page de discussion
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DiscussionPage.empty()),
        );
      } else {
        // Affiche un message d'erreur si la connexion échoue (erreur envoyée par l'API)
        //print("Erreur lors de la connexion : ${response.statusCode}");
        setState(() {
          messageErreur = "Erreur lors de la connexion : ${response.statusCode}";
        });
      }
    } catch (e) {
      // Gère les exceptions et affiche un message d'erreur (erreur de connexion, problème de certificat, etc.)
      //print("Exception pendant la connexion : $e");
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

  Color get _backgroundColor => const Color(0xFF0B101A);
  Color get _panelColor => const Color(0xFF111827);
  Color get _inputColor => const Color(0xFF1F2937);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: _backgroundColor,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: _AuthCard(
                messageErreur: messageErreur,
                onConnexion: connexion,
                usernameController: usernameController,
                passwordController: passwordController,
                panelColor: _panelColor,
                inputColor: _inputColor,
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
    required this.messageErreur,
    required this.onConnexion,
    required this.usernameController,
    required this.passwordController,
    required this.panelColor,
    required this.inputColor,
  });

  final String messageErreur;
  final VoidCallback onConnexion;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Color panelColor;
  final Color inputColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 360,
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Connexion",
            style: TextStyle(
              color: Colors.white,
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
                color: Colors.red.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.withOpacity(0.4)),
              ),
              child: Text(
                messageErreur,
                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          _InputField(
            controller: usernameController,
            label: "Identifiant",
            hint: "Entrez votre identifiant",
            inputColor: inputColor,
            icon: Icons.person_outline,
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: passwordController,
            label: "Mot de passe",
            hint: "Entrez votre mot de passe",
            inputColor: inputColor,
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
                backgroundColor: const Color(0xFF2563EB),
                foregroundColor: Colors.white,
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
    required this.inputColor,
    this.obscureText = false,
    this.icon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Color inputColor;
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
            color: Colors.white.withOpacity(0.7),
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: inputColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.06)),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            cursorColor: Colors.white,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, color: Colors.white.withOpacity(0.6))
                  : null,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
            ),
          ),
        ),
      ],
    );
  }
}

