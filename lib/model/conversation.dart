
import 'dart:core';

class Conversation {

  int id;
  List<List<String>> messages;

  Conversation({
    required this.id,
    required this.messages,
  });

  void addMessage(String sender, String message) {
    messages.add([sender, message]);
  }

}
