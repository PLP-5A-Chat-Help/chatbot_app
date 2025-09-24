
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
  String firstName;
  String lastName;
  String email;
  String? avatarPath;

  User({
    required this.accessToken,
    required this.tokenType,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.avatarPath,
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

  void setNames({String? first, String? last}) {
    if (first != null) firstName = first;
    if (last != null) lastName = last;
  }

  void setEmail(String value) {
    email = value;
  }

  void setAvatarPath(String? path) {
    avatarPath = path;
  }

  void clear() {
    accessToken = '';
    tokenType = '';
    username = 'Utilisateur';
    firstName = '';
    lastName = '';
    email = '';
    avatarPath = null;
  }

  String getAccessToken() {
    return accessToken;
  }

}
