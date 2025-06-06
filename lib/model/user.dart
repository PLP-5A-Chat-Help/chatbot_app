
import 'dart:core';

class User {

  String accessToken;
  String tokenType;

  User({
    required this.accessToken,
    required this.tokenType,
  });

  void setAccessToken(String token) {
    accessToken = token;
  }

  void setTokenType(String type) {
    tokenType = type;
  }

  void clear() {
    accessToken = '';
    tokenType = '';
  }

  String getAccessToken() {
    return accessToken;
  }

}