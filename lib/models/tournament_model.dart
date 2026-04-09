import 'package:cloud_firestore/cloud_firestore.dart';

enum TournamentStatus { upcoming, qualifier, finals, completed }

class PointConfig {
  final Map<int, int> placementPoints; // placement rank → points
  final int killPoints;

  const PointConfig({
    required this.placementPoints,
    required this.killPoints,
  });

  factory PointConfig.defaults() => PointConfig(
        placementPoints: {
          1: 250,
          2: 200,
          3: 175,
          4: 150,
          5: 125,
          6: 100,
          7: 75,
          8: 50,
          9: 25,
          10: 10,
        },
        killPoints: 15,
      );

  Map<String, dynamic> toMap() => {
        'placementPoints':
            placementPoints.map((k, v) => MapEntry(k.toString(), v)),
        'killPoints': killPoints,
      };

  factory PointConfig.fromMap(Map<String, dynamic> m) => PointConfig(
        placementPoints: (m['placementPoints'] as Map<String, dynamic>? ?? {})
            .map((k, v) => MapEntry(int.parse(k), (v as num).toInt())),
        killPoints: (m['killPoints'] as num?)?.toInt() ?? 15,
      );

  int pointsFor(int placement) => placementPoints[placement] ?? 0;
}

class PrizeSlot {
  final int place;
  final double amount;
  final String currency;

  const PrizeSlot({
    required this.place,
    required this.amount,
    required this.currency,
  });

  Map<String, dynamic> toMap() =>
      {'place': place, 'amount': amount, 'currency': currency};

  factory PrizeSlot.fromMap(Map<String, dynamic> m) => PrizeSlot(
        place: (m['place'] as num).toInt(),
        amount: (m['amount'] as num).toDouble(),
        currency: m['currency'] as String? ?? 'USD',
      );
}

class TournamentModel {
  final String id;
  final String name;
  final String description;
  final String rules;
  final DateTime date;
  final String time; // "HH:mm" format
  final TournamentStatus status;
  final String organizerUid;
  final String organizerName;
  final int maxTeams;
  final int playersPerTeam;
  final int totalPlayers;
  final int registeredTeams;
  final PointConfig pointConfig;
  final List<PrizeSlot> prizeSlots;
  final int winnerCount;
  final String posterUrl; // Firebase Storage download URL, empty if not uploaded
  final DateTime createdAt;

  const TournamentModel({
    required this.id,
    required this.name,
    required this.description,
    required this.rules,
    required this.date,
    required this.time,
    required this.status,
    required this.organizerUid,
    required this.organizerName,
    required this.maxTeams,
    required this.playersPerTeam,
    required this.totalPlayers,
    required this.registeredTeams,
    required this.pointConfig,
    required this.prizeSlots,
    required this.winnerCount,
    this.posterUrl = '',
    required this.createdAt,
  });

  bool get isFull => registeredTeams >= maxTeams;

  String get statusLabel {
    switch (status) {
      case TournamentStatus.upcoming:
        return 'Upcoming';
      case TournamentStatus.qualifier:
        return 'Qualifiers';
      case TournamentStatus.finals:
        return 'Finals';
      case TournamentStatus.completed:
        return 'Completed';
    }
  }

  static const String _defaultRules = '''
BATTLE ROYALE TOURNAMENT RULES

1. GENERAL
• All participants must be registered before the tournament begins.
• Players must be present at the designated start time. A 5-minute grace period will be given.
• Teams must consist of exactly 4 players each.

2. FORMAT
• Qualifier Round: 4 matches played across 25 teams (100 players total).
• Finals Round: Top 25 teams from qualifiers compete in 1 final match.
• Points are accumulated from placement and kills.

3. SCORING
• Points are awarded per match based on final placement and total kills.
• Kill points: fixed per elimination.
• Placement points: decreasing scale from 1st to last place.

4. CONDUCT
• No cheating, exploiting glitches, or using unauthorized software.
• Verbal abuse, harassment, and unsportsmanlike behavior will result in disqualification.
• Any disputes must be raised with the organizer within 15 minutes after a match ends.

5. CONNECTIVITY
• Players are responsible for their own internet connection.
• Disconnection during a match does not warrant a rematch unless agreed by the organizer.

6. PRIZES
• Prize distribution will occur within 48 hours of the tournament's conclusion.
• The organizer reserves the right to modify rules before the tournament starts with prior notice.

Good luck and may the best team win!''';

  static String get defaultRules => _defaultRules;

  Map<String, dynamic> toMap() => {
        'name': name,
        'description': description,
        'rules': rules,
        'date': Timestamp.fromDate(date),
        'time': time,
        'status': status.name,
        'organizerUid': organizerUid,
        'organizerName': organizerName,
        'maxTeams': maxTeams,
        'playersPerTeam': playersPerTeam,
        'totalPlayers': totalPlayers,
        'registeredTeams': registeredTeams,
        'pointConfig': pointConfig.toMap(),
        'prizeSlots': prizeSlots.map((p) => p.toMap()).toList(),
        'winnerCount': winnerCount,
        'posterUrl': posterUrl,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory TournamentModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return TournamentModel(
      id: doc.id,
      name: m['name'] as String? ?? '',
      description: m['description'] as String? ?? '',
      rules: m['rules'] as String? ?? _defaultRules,
      date: (m['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      time: m['time'] as String? ?? '00:00',
      status: TournamentStatus.values.firstWhere(
        (s) => s.name == m['status'],
        orElse: () => TournamentStatus.upcoming,
      ),
      organizerUid: m['organizerUid'] as String? ?? '',
      organizerName: m['organizerName'] as String? ?? 'Unknown',
      maxTeams: (m['maxTeams'] as num?)?.toInt() ?? 25,
      playersPerTeam: (m['playersPerTeam'] as num?)?.toInt() ?? 4,
      totalPlayers: (m['totalPlayers'] as num?)?.toInt() ?? 100,
      registeredTeams: (m['registeredTeams'] as num?)?.toInt() ?? 0,
      pointConfig: PointConfig.fromMap(
          m['pointConfig'] as Map<String, dynamic>? ?? {}),
      prizeSlots: (m['prizeSlots'] as List<dynamic>? ?? [])
          .map((e) => PrizeSlot.fromMap(e as Map<String, dynamic>))
          .toList(),
      winnerCount: (m['winnerCount'] as num?)?.toInt() ?? 3,
      posterUrl: m['posterUrl'] as String? ?? '',
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
