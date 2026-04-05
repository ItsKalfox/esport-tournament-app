import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMember {
  final String uid;
  final String displayName;
  final String email;

  const TeamMember({
    required this.uid,
    required this.displayName,
    required this.email,
  });

  Map<String, dynamic> toMap() =>
      {'uid': uid, 'displayName': displayName, 'email': email};

  factory TeamMember.fromMap(Map<String, dynamic> m) => TeamMember(
        uid: m['uid'] as String? ?? '',
        displayName: m['displayName'] as String? ?? 'Unknown',
        email: m['email'] as String? ?? '',
      );
}

class TeamModel {
  final String id;
  final String tournamentId;
  final String name;
  final String logoEmoji;
  final String logoUrl; // Firebase Storage URL, takes priority over emoji if set
  final String captainUid;
  final String captainName;
  final List<TeamMember> members;
  final List<String> pendingEmails;
  final bool advancedToFinals;
  final DateTime createdAt;

  const TeamModel({
    required this.id,
    required this.tournamentId,
    required this.name,
    required this.logoEmoji,
    this.logoUrl = '',
    required this.captainUid,
    required this.captainName,
    required this.members,
    required this.pendingEmails,
    required this.advancedToFinals,
    required this.createdAt,
  });

  int get memberCount => members.length;
  bool get isFull => members.length >= 4;

  Map<String, dynamic> toMap() => {
        'tournamentId': tournamentId,
        'name': name,
        'logoEmoji': logoEmoji,
        'logoUrl': logoUrl,
        'captainUid': captainUid,
        'captainName': captainName,
        'members': members.map((m) => m.toMap()).toList(),
        'pendingEmails': pendingEmails,
        'advancedToFinals': advancedToFinals,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory TeamModel.fromDoc(DocumentSnapshot doc) {
    final m = doc.data() as Map<String, dynamic>;
    return TeamModel(
      id: doc.id,
      tournamentId: m['tournamentId'] as String? ?? '',
      name: m['name'] as String? ?? '',
      logoEmoji: m['logoEmoji'] as String? ?? '🎮',
      logoUrl: m['logoUrl'] as String? ?? '',
      captainUid: m['captainUid'] as String? ?? '',
      captainName: m['captainName'] as String? ?? '',
      members: (m['members'] as List<dynamic>? ?? [])
          .map((e) => TeamMember.fromMap(e as Map<String, dynamic>))
          .toList(),
      pendingEmails:
          (m['pendingEmails'] as List<dynamic>? ?? []).cast<String>(),
      advancedToFinals: m['advancedToFinals'] as bool? ?? false,
      createdAt: (m['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
