import 'dart:convert';
import 'dart:io';

import 'package:auto_size_text/auto_size_text.dart';
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
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
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
            title: const Text("Inscription réussie",
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            content: const Text("Veuillez valider votre comptre via votre email avant de vous connecter.",
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            backgroundColor: const Color.fromRGBO(117, 117, 117, 1.0),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text("OK",
                  style: TextStyle(color: Colors.white, fontSize: 16),
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(59, 59, 63, 1),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 10),
            // Logo de l'application
            Expanded(child: Image.asset("assets/logo.png", width: 320, height: 320)),

            // Message d'erreur s'il y en a un
            messageErreur.isNotEmpty ?
              SizedBox(
                height: 30,
                child: Padding(
                  padding: const EdgeInsets.all(2.0),
                  child: AutoSizeText(
                    messageErreur,
                    maxLines: 1,
                    maxFontSize: 16,
                    minFontSize: 8,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              )
            : const SizedBox(height: 30),

            // Champ de texte pour l'adresse mail
            Container(
              width: 300,
              height: 50,
              decoration: BoxDecoration(color: const Color.fromRGBO(85, 85, 85, 1), borderRadius: BorderRadius.circular(25)),
              child: Center(
                child: TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: "Adresse Mail",
                    hintStyle: const TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: Colors.white,
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.02),

            // Champ de texte pour le mot de passe
            Container(
              width: 300,
              height: 50,
              decoration: BoxDecoration(color: const Color.fromRGBO(85, 85, 85, 1), borderRadius: BorderRadius.circular(25)),
              child: Center(
                child: TextField(
                  controller: passwordController,
                  decoration: InputDecoration(
                    hintText: "Mot de passe",
                    hintStyle: const TextStyle(color: Colors.white30),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  cursorColor: Colors.white,
                ),
              ),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.05),

            // Bouton de connexion
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(85, 85, 85, 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                minimumSize: const Size(150, 40),
              ),
              onPressed: connexion,
              child: const Text("Se connecter", style: TextStyle(color: Colors.white30, fontSize: 16)),
            ),

            SizedBox(height: MediaQuery.of(context).size.height * 0.01),

            // Bouton d'inscription
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color.fromRGBO(85, 85, 85, 1),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                minimumSize: const Size(150, 40),
              ),
              onPressed: inscription,
              child: const Text("S'inscrire", style: TextStyle(color: Colors.white30, fontSize: 16)),
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }
}
