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
/// Cette page permet à l'utilisateur de se connecter ou de s'inscrire.
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

  /// Méthode pour s'inscrire
  void inscription() async {
    // Vide le message d'erreur
    setState(() {
      messageErreur = "";
    });
    // Crée un client HTTP sécurisé
    final client = await createSecureHttpClient();

    // Prépare l'URL et le corps de la requête
    final url = Uri.parse('$urlPrefix/register');
    final body = {
      "email": usernameController.text,
      "password": passwordController.text,
    };

    try {
      // Envoie la requête POST pour l'inscription
      final request = await client.postUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode(body)));

      // Attend la réponse du serveur
      final response = await request.close();

      if (response.statusCode == 200) {
        // print("Inscription réussie");

        // Popup pour informer l'utilisateur qu'il doit aller valider son inscription dans ses mails
        showDialog(context: context, builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF111827),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text(
              "Inscription réussie",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: const Text(
              "Veuillez valider votre comptre via votre email avant de vous connecter.",
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
            actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  "OK",
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          );
        },);

      } else {
        // Affiche un message d'erreur si l'inscription échoue (erreur envoyée par l'API)
        //print("Erreur lors de l'inscription : ${response.statusCode}");
        setState(() {
          messageErreur = "Erreur lors de l'inscription : ${response.statusCode}";
        });

      }
    } catch (e) {
      // Gère les exceptions et affiche un message d'erreur (erreur de connexion, problème de certificat, etc.)
      //print("Exception pendant l'inscription : $e");
      setState(() {
        messageErreur = "Erreur pendant l'inscription.";
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 960;
              final EdgeInsets horizontalPadding =
                  EdgeInsets.symmetric(horizontal: isWide ? 64 : 24);

              final content = ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: isWide ? 48 : 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isWide)
                        _HeaderSection(
                          backgroundColor: _panelColor,
                          gradient: _primaryGradient,
                        ),
                      Expanded(
                        child: isWide
                            ? Row(
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 40),
                                      child: _HeroSection(gradient: _primaryGradient),
                                    ),
                                  ),
                                  Expanded(
                                    child: Align(
                                      alignment: Alignment.center,
                                      child: _AuthCard(
                                        messageErreur: messageErreur,
                                        onConnexion: connexion,
                                        onInscription: inscription,
                                        usernameController: usernameController,
                                        passwordController: passwordController,
                                        panelColor: _panelColor,
                                        inputColor: _inputColor,
                                        gradient: _primaryGradient,
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : SingleChildScrollView(
                                child: Column(
                                  children: [
                                    const SizedBox(height: 32),
                                    _AuthCard(
                                      messageErreur: messageErreur,
                                      onConnexion: connexion,
                                      onInscription: inscription,
                                      usernameController: usernameController,
                                      passwordController: passwordController,
                                      panelColor: _panelColor,
                                      inputColor: _inputColor,
                                      gradient: _primaryGradient,
                                    ),
                                    const SizedBox(height: 32),
                                    _HeroSection(gradient: _primaryGradient),
                                  ],
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              );

              return Center(
                child: Padding(
                  padding: horizontalPadding,
                  child: content,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  LinearGradient get _primaryGradient => const LinearGradient(
        colors: [Color(0xFF2563EB), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}

class _HeaderSection extends StatelessWidget {
  const _HeaderSection({
    required this.backgroundColor,
    required this.gradient,
  });

  final Color backgroundColor;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: gradient,
            ),
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Image.asset('assets/logo.png'),
            ),
          ),
          const SizedBox(width: 16),
          const Expanded(
            child: Text(
              "Bienvenue sur NovaMind",
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.gradient});

  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.04),
            Colors.white.withOpacity(0.01),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return gradient.createShader(bounds);
            },
            child: const Text(
              "NovaMind",
              style: TextStyle(
                color: Colors.white,
                fontSize: 42,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            "L'assistant conversationnel conçu pour libérer votre créativité.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.75),
              fontSize: 18,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: const [
              _FeatureChip(icon: Icons.flash_on_rounded, label: "Réponses instantanées"),
              _FeatureChip(icon: Icons.auto_awesome_rounded, label: "Idées sur mesure"),
              _FeatureChip(icon: Icons.lock_rounded, label: "Sécurité renforcée"),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.4),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: gradient,
                  ),
                  child: const Icon(Icons.lock_open_rounded, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Text(
                    "Connexion sécurisée via certificat CA pour protéger vos données.",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 16,
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

class _AuthCard extends StatelessWidget {
  const _AuthCard({
    required this.messageErreur,
    required this.onConnexion,
    required this.onInscription,
    required this.usernameController,
    required this.passwordController,
    required this.panelColor,
    required this.inputColor,
    required this.gradient,
  });

  final String messageErreur;
  final VoidCallback onConnexion;
  final VoidCallback onInscription;
  final TextEditingController usernameController;
  final TextEditingController passwordController;
  final Color panelColor;
  final Color inputColor;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 460,
      padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 30),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: gradient,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Image.asset('assets/logo.png'),
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Ravi de vous revoir",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    "Connectez-vous à votre espace",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 32),
          if (messageErreur.isNotEmpty)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 24),
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
            label: "Adresse mail",
            hint: "prenom.nom@email.com",
            inputColor: inputColor,
            icon: Icons.alternate_email_rounded,
          ),
          const SizedBox(height: 20),
          _InputField(
            controller: passwordController,
            label: "Mot de passe",
            hint: "••••••••",
            obscureText: true,
            inputColor: inputColor,
            icon: Icons.lock_outline_rounded,
          ),
          const SizedBox(height: 28),
          _GradientButton(
            onPressed: onConnexion,
            label: "Se connecter",
            gradient: gradient,
          ),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: onInscription,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              foregroundColor: Colors.white,
              side: BorderSide(color: Colors.white.withOpacity(0.2)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            child: const Text("Créer un compte"),
          ),
          const SizedBox(height: 24),
          Text(
            "En vous connectant, vous acceptez nos conditions d'utilisation et notre politique de confidentialité.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: 12,
              height: 1.4,
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

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.onPressed,
    required this.label,
    required this.gradient,
  });

  final VoidCallback onPressed;
  final String label;
  final Gradient gradient;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2563EB).withOpacity(0.45),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        child: Text(label),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white.withOpacity(0.75), size: 20),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
