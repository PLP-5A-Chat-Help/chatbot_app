
import 'dart:core';

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
  }

  String getAccessToken() {
    return accessToken;
  }

}