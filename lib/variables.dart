import 'model/app_preferences.dart';
import 'model/user.dart';

/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  variables.dart
---------------------------------- */

/// Variables globales de l'application

String urlPrefix = "https://192.168.100.1:8000"; // en HTTPS

final AppPreferences appPreferences = AppPreferences();

User user = User(
  username: 'Utilisateur',
  accessToken: '',
  tokenType: '',
  firstName: '',
  lastName: '',
  email: '',
  avatarPath: null,
);

