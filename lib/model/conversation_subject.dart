
class ConversationSubject {
  final String id;
  final String titre;
  final DateTime lastUpdate;

  ConversationSubject({
    required this.id,
    required this.titre,
    required this.lastUpdate,
  });

  factory ConversationSubject.fromJson(Map<String, dynamic> json) {
    return ConversationSubject(
      id: json['id'].toString(),
      titre: json['title'],
      lastUpdate: DateTime.parse(json['last_update'])
    );
  }

  @override
  String toString() {
    return 'Conversation(id: $id, title: $titre, last_update: $lastUpdate)';
  }
}