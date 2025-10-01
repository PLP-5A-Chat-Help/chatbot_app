
import 'dart:core';


/* ----------------------------------
  Projet 4A : Chatbot App
  Date : 11/06/2025
  Conversation.dart
---------------------------------- */

/// Classe représentant une conversation composée d'un id, d'un titre et d'une liste de messages.
/// Chaque message est une liste contenant le nom de l'expéditeur, le message et une émotion associée.
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
