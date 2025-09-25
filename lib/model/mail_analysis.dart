import 'dart:math';

class MailAnalysis {
  MailAnalysis({
    required this.subject,
    required this.analyzedAt,
    required this.maliciousnessScore,
    required this.sender,
    required this.summary,
  }) : _randomSeed = subject.hashCode ^ analyzedAt.millisecondsSinceEpoch;

  final String subject;
  final DateTime analyzedAt;
  final int maliciousnessScore;
  final String sender;
  final String summary;

  final int _randomSeed;

  List<String> buildSampleIndicators() {
    final random = Random(_randomSeed);
    return List.generate(4, (index) {
      final id = random.nextInt(9000) + 1000;
      final score = (random.nextDouble() * 100).toStringAsFixed(1);
      return 'Indicateur #$id — Score de risque : $score%';
    });
  }
}
