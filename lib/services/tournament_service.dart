import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/tournament_model.dart';
import '../models/team_model.dart';
import '../models/match_result_model.dart';

class TournamentService {
  static final _db = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  // ── Collections ──────────────────────────────────────────────────────────────
  CollectionReference get _tournaments => _db.collection('tournaments');
  CollectionReference get _matchResults => _db.collection('matchResults');
  CollectionReference get _teamInvites => _db.collection('teamInvites');

  CollectionReference _teams(String tournamentId) =>
      _tournaments.doc(tournamentId).collection('teams');

  // ── Create Tournament ─────────────────────────────────────────────────────
  Future<String> createTournament(TournamentModel tournament) async {
    final ref = await _tournaments.add(tournament.toMap());
    return ref.id;
  }

  // ── Stream All Tournaments ────────────────────────────────────────────────
  Stream<List<TournamentModel>> getTournaments() {
    return _tournaments
        .orderBy('date', descending: false)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TournamentModel.fromDoc(d)).toList());
  }

  // ── Stream My Tournaments (organized or participating) ────────────────────
  Stream<List<TournamentModel>> getMyTournaments(String uid) {
    return _tournaments
        .where('organizerUid', isEqualTo: uid)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => TournamentModel.fromDoc(d)).toList());
  }

  // ── Stream Single Tournament ──────────────────────────────────────────────
  Stream<TournamentModel?> getTournamentStream(String id) {
    return _tournaments.doc(id).snapshots().map(
        (doc) => doc.exists ? TournamentModel.fromDoc(doc) : null);
  }

  // ── Update Tournament Status ──────────────────────────────────────────────
  Future<void> updateTournamentStatus(
      String id, TournamentStatus status) async {
    await _tournaments.doc(id).update({'status': status.name});
  }

  // ── Create / Join Team ────────────────────────────────────────────────────
  Future<String> createTeam(TeamModel team) async {
    final user = _auth.currentUser!;
    final teamData = team.toMap();
    final ref = await _teams(team.tournamentId).add(teamData);

    // Increment registered teams count
    await _tournaments.doc(team.tournamentId).update({
      'registeredTeams': FieldValue.increment(1),
    });

    // Send in-app invites for pending emails
    for (final email in team.pendingEmails) {
      await _sendInvite(
        tournamentId: team.tournamentId,
        teamId: ref.id,
        teamName: team.name,
        teamLogoEmoji: team.logoEmoji,
        inviterName: user.displayName ?? 'Captain',
        inviteeEmail: email,
      );
    }

    return ref.id;
  }

  // ── Check if user already has a team in tournament ────────────────────────
  Future<TeamModel?> getUserTeam(String tournamentId, String uid) async {
    final snap = await _teams(tournamentId)
        .where('captainUid', isEqualTo: uid)
        .limit(1)
        .get();
    if (snap.docs.isNotEmpty) {
      return TeamModel.fromDoc(snap.docs.first);
    }
    // Check as member
    final memberSnap = await _teams(tournamentId).get();
    for (final doc in memberSnap.docs) {
      final team = TeamModel.fromDoc(doc);
      if (team.members.any((m) => m.uid == uid)) return team;
    }
    return null;
  }

  // ── Stream Teams in Tournament ────────────────────────────────────────────
  Stream<List<TeamModel>> getTeams(String tournamentId) {
    return _teams(tournamentId)
        .orderBy('createdAt')
        .snapshots()
        .map((snap) => snap.docs.map((d) => TeamModel.fromDoc(d)).toList());
  }

  // ── Invite Teammate ───────────────────────────────────────────────────────
  Future<void> _sendInvite({
    required String tournamentId,
    required String teamId,
    required String teamName,
    required String teamLogoEmoji,
    required String inviterName,
    required String inviteeEmail,
  }) async {
    final uid = _auth.currentUser?.uid ?? '';
    await _teamInvites.add({
      'tournamentId': tournamentId,
      'teamId': teamId,
      'teamName': teamName,
      'teamLogoEmoji': teamLogoEmoji,
      'inviterUid': uid,
      'inviterName': inviterName,
      'inviteeEmail': inviteeEmail.toLowerCase().trim(),
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendInvite({
    required String tournamentId,
    required String teamId,
    required String teamName,
    required String teamLogoEmoji,
    required String inviteeEmail,
  }) async {
    final user = _auth.currentUser!;
    await _sendInvite(
      tournamentId: tournamentId,
      teamId: teamId,
      teamName: teamName,
      teamLogoEmoji: teamLogoEmoji,
      inviterName: user.displayName ?? 'Captain',
      inviteeEmail: inviteeEmail,
    );
    // Add email to pendingEmails list on team doc
    await _teams(tournamentId).doc(teamId).update({
      'pendingEmails': FieldValue.arrayUnion([inviteeEmail.toLowerCase().trim()]),
    });
  }

  // ── Pending Invites for current user ──────────────────────────────────────
  Stream<List<Map<String, dynamic>>> getPendingInvites() {
    final email =
        _auth.currentUser?.email?.toLowerCase().trim() ?? '';
    return _teamInvites
        .where('inviteeEmail', isEqualTo: email)
        .where('status', isEqualTo: 'pending')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => {'id': d.id, ...d.data() as Map<String, dynamic>})
            .toList());
  }

  // Count of pending invites (for badge)
  Stream<int> getPendingInviteCount() {
    return getPendingInvites().map((list) => list.length);
  }

  // ── Accept Invite ─────────────────────────────────────────────────────────
  Future<void> acceptInvite(String inviteId, String tournamentId,
      String teamId) async {
    final user = _auth.currentUser!;
    final member = TeamMember(
      uid: user.uid,
      displayName: user.displayName ?? 'Player',
      email: user.email ?? '',
    );

    await _db.runTransaction((tx) async {
      final inviteRef = _teamInvites.doc(inviteId);
      final teamRef = _teams(tournamentId).doc(teamId);

      tx.update(inviteRef, {'status': 'accepted'});
      tx.update(teamRef, {
        'members': FieldValue.arrayUnion([member.toMap()]),
        'pendingEmails': FieldValue.arrayRemove(
            [user.email?.toLowerCase().trim() ?? '']),
      });
    });
  }

  // ── Decline Invite ────────────────────────────────────────────────────────
  Future<void> declineInvite(String inviteId) async {
    await _teamInvites.doc(inviteId).update({'status': 'declined'});
  }

  // ── Enter Match Results ───────────────────────────────────────────────────
  Future<void> saveMatchResults(
      String tournamentId,
      MatchRound round,
      int matchNumber,
      List<MatchResultModel> results) async {
    final batch = _db.batch();

    // Delete existing results for this exact match (idempotent)
    final existing = await _matchResults
        .where('tournamentId', isEqualTo: tournamentId)
        .where('round', isEqualTo: round.name)
        .where('matchNumber', isEqualTo: matchNumber)
        .get();
    for (final doc in existing.docs) {
      batch.delete(doc.reference);
    }

    for (final result in results) {
      final ref = _matchResults.doc();
      batch.set(ref, result.toMap());
    }

    await batch.commit();
  }

  // ── Stream Match Results for leaderboard ──────────────────────────────────
  Stream<List<MatchResultModel>> getMatchResults(
      String tournamentId, MatchRound round) {
    return _matchResults
        .where('tournamentId', isEqualTo: tournamentId)
        .where('round', isEqualTo: round.name)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => MatchResultModel.fromDoc(d)).toList());
  }

  // ── Aggregate Leaderboard ─────────────────────────────────────────────────
  Stream<List<LeaderboardEntry>> getLeaderboard(
      String tournamentId, MatchRound round) {
    return getMatchResults(tournamentId, round).map((results) {
      final map = <String, LeaderboardEntry>{};
      for (final r in results) {
        map.putIfAbsent(
          r.teamId,
          () => LeaderboardEntry(
            teamId: r.teamId,
            teamName: r.teamName,
            teamLogoEmoji: r.teamLogoEmoji,
          ),
        );
        map[r.teamId]!.addResult(r);
      }
      final entries = map.values.toList()
        ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      return entries;
    });
  }

  // ── Advance top-N teams to Finals ─────────────────────────────────────────
  Future<void> advanceToFinals(String tournamentId, int topN) async {
    // Get qualifier leaderboard snapshot
    final snap = await _matchResults
        .where('tournamentId', isEqualTo: tournamentId)
        .where('round', isEqualTo: MatchRound.qualifier.name)
        .get();

    final map = <String, LeaderboardEntry>{};
    for (final doc in snap.docs) {
      final r = MatchResultModel.fromDoc(doc);
      map.putIfAbsent(
        r.teamId,
        () => LeaderboardEntry(
          teamId: r.teamId,
          teamName: r.teamName,
          teamLogoEmoji: r.teamLogoEmoji,
        ),
      );
      map[r.teamId]!.addResult(r);
    }

    final sorted = map.values.toList()
      ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    final topTeamIds =
        sorted.take(topN).map((e) => e.teamId).toSet();

    final batch = _db.batch();
    final teamsSnap = await _teams(tournamentId).get();
    for (final doc in teamsSnap.docs) {
      batch.update(doc.reference,
          {'advancedToFinals': topTeamIds.contains(doc.id)});
    }
    batch.update(_tournaments.doc(tournamentId),
        {'status': TournamentStatus.finals.name});
    await batch.commit();
  }

  // ── Complete Tournament ───────────────────────────────────────────────────
  Future<void> completeTournament(String tournamentId) async {
    await _tournaments
        .doc(tournamentId)
        .update({'status': TournamentStatus.completed.name});
  }

  // ── Get finalists ─────────────────────────────────────────────────────────
  Stream<List<TeamModel>> getFinalists(String tournamentId) {
    return _teams(tournamentId)
        .where('advancedToFinals', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => TeamModel.fromDoc(d)).toList());
  }
}
