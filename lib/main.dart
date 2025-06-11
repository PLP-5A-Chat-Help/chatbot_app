import 'dart:io';

import 'package:chatbot_app/views/home_page.dart';
import 'package:flutter/material.dart';
import 'package:window_size/window_size.dart';

/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  main.dart
---------------------------------- */


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Taille minium de la fenêtre sur Windows
  if (Platform.isWindows) {
    setWindowMinSize(const Size(512, 640));
  }
  // Lancement de l'application
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child :  MaterialApp(
        title: 'Chatbot App',
        theme: ThemeData(
          textSelectionTheme: TextSelectionThemeData(
            selectionColor: Colors.cyan.withValues(alpha: 0.4),// Couleur de fond lors de la sélection
          ),
        ),

        // Page d'acceuil
        home: const HomePage(),
      ),
    );

  }
}

