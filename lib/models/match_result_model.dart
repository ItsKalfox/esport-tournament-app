import 'package:cloud_firestore/cloud_firestore.dart';

enum MatchRound { qualifier, finals }

class MatchResultModel {
  final String id;
  final String tournamentId;
  final MatchRound round;
  final int matchNumber; // 1–4 for qualifier, 1 for finals
  final String teamId;
  final String teamName;
  final String teamLogoEmoji;
  final int placement; // 1 = first place
  final int kills;
  final int placementPoints;
  final int killPoints;
  final int totalPoints;
  final DateTime createdAt;

  const MatchResultModel({
    required this.id,
    required this.tournamentId,
    required this.round,
    required this.matchNumber,
    required this.teamId,
    required this.teamName,
    required this.teamLogoEmoji,
    required this.placement,
    required this.kills,
    required this.placementPoints,
    required this.killPoints,
    required this.totalPoints,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() => {
        'tournamentId': tournamentId,
        'round': round.name,
        'matchNumber': matchNumber,
        'teamId': teamId,
        'teamName': teamName,
        'teamLogoEmoji': teamLogoEmoji,
        'placement': placement,
        'kills': kills,
        'placementPoints': placementPoints,
        'killPoints': killPoints,
        'totalPoints': totalPoints,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory MatchResultModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return MatchResultModel(
      id: doc.id,
      tournamentId: m['tournamentId'] as String? ?? '',
      round: MatchRound.values.firstWhere(
        (r) => r.name == m['round'],
        orElse: () => MatchRound.qualifier,
      ),
      matchNumber: (m['matchNumber'] as num?)?.toInt() ?? 1,
      teamId: m['teamId'] as String? ?? '',
      teamName: m['teamName'] as String? ?? '',
      teamLogoEmoji: m['teamLogoEmoji'] as String? ?? '🎮',
      placement: (m['placement'] as num?)?.toInt() ?? 0,
      kills: (m['kills'] as num?)?.toInt() ?? 0,
      placementPoints: (m['placementPoints'] as num?)?.toInt() ?? 0,
      killPoints: (m['killPoints'] as num?)?.toInt() ?? 0,
      totalPoints: (m['totalPoints'] as num?)?.toInt() ?? 0,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

/// Aggregated leaderboard entry across all matches in a round
class LeaderboardEntry {
  final String teamId;
  final String teamName;
  final String teamLogoEmoji;
  int totalPlacementPoints;
  int totalKillPoints;
  int totalKills;
  int totalPoints;
  int matchesPlayed;
  bool advancedToFinals;

  LeaderboardEntry({
    required this.teamId,
    required this.teamName,
    required this.teamLogoEmoji,
    this.totalPlacementPoints = 0,
    this.totalKillPoints = 0,
    this.totalKills = 0,
    this.totalPoints = 0,
    this.matchesPlayed = 0,
    this.advancedToFinals = false,
  });

  void addResult(MatchResultModel r) {
    totalPlacementPoints += r.placementPoints;
    totalKillPoints += r.killPoints;
    totalKills += r.kills;
    totalPoints += r.totalPoints;
    matchesPlayed++;
  }
}
