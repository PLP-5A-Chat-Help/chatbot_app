
import 'dart:core';

/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  user.dart
---------------------------------- */

/// Classe représentant un utilisateur
/// Elle contient le token d'authentification, le type de token et le nom d'utilisateur
class User {

  String accessToken;
  String tokenType;
  String username;

  User({
    required this.accessToken,
    required this.tokenType,
    required this.username,
  });

  void setAccessToken(String token) {
    accessToken = token;
  }

  void setTokenType(String type) {
    tokenType = type;
  }

  void setUsername(String name) {
    username = name;
  }

  void clear() {
    accessToken = '';
    tokenType = '';
    username = 'Utilisateur';
  }

  String getAccessToken() {
    return accessToken;
  }

}