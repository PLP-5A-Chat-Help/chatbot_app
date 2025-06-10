import 'dart:convert';
import 'dart:io';

import 'package:chatbot_app/views/discussion_page.dart';
import 'package:flutter/material.dart';

import '../variables.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  TextEditingController usernameController = TextEditingController();
  TextEditingController passwordController = TextEditingController();


  Future<HttpClient> createSecureHttpClient() async {
    final context = SecurityContext.defaultContext;
    context.setTrustedCertificates('assets/certs/myCA.pem');
    return HttpClient(context: context);
  }

  void connexion() async {
    final client = await createSecureHttpClient();
    //final client = HttpClient()..badCertificateCallback = (cert, host, port) => true;

    final url = Uri.parse('$urlPrefix/login');
    final body = {
      "email": usernameController.text,
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

        user.setAccessToken(data['access_token']);
        user.setTokenType(data['token_type']);

        print("Connexion réussie: ${user.getAccessToken()}"); //todo

        usernameController.clear();
        passwordController.clear();

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DiscussionPage.empty()),
        );
      } else {
        print("Erreur lors de la connexion : ${response.statusCode}");
      }
    } catch (e) {
      print("Exception pendant la connexion : $e");
    }
  }

  void inscription() async {
     final client = await createSecureHttpClient();
    //final client = HttpClient()..badCertificateCallback = (cert, host, port) => true;


    final url = Uri.parse('$urlPrefix/register');
    final body = {
      "email": usernameController.text,
      "password": passwordController.text,
    };

    try {
      final request = await client.postUrl(url);
      request.headers.set(HttpHeaders.contentTypeHeader, "application/json");
      request.add(utf8.encode(jsonEncode(body)));

      final response = await request.close();

      if (response.statusCode == 200) {
        print("Inscription réussie"); // todo
        connexion(); // Appelle la version corrigée de connexion avec le context
      } else {
        print("Erreur lors de l'inscription : ${response.statusCode}");
      }
    } catch (e) {
      print("Exception pendant l'inscription : $e");
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
            Expanded(child: Image.asset("assets/logo.png", width: 320, height: 320)),
            const SizedBox(height: 20),

            Container(
              width: 300,
              height: 50,
              decoration: BoxDecoration(color: const Color.fromRGBO(85, 85, 85, 1), borderRadius: BorderRadius.circular(25)),
              child: Center(
                child: TextField(
                  controller: usernameController,
                  decoration: InputDecoration(
                    hintText: "Identifiant",
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
