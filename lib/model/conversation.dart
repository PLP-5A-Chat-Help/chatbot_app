
import 'dart:core';

class Conversation {

  String id;
  String title;
  List<List<String>> messages;

  Conversation({
    required this.id,
    required this.title,
    required this.messages,
  });

  void addMessage(String sender, String message, String image) {
    messages.add([sender, message, image]);
  }

}
