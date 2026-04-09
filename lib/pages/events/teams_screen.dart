import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/team_model.dart';
import '../../services/tournament_service.dart';
import 'create_team_screen.dart';
import 'team_detail_screen.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final service = TournamentService();

    return StreamBuilder<List<TeamModel>>(
      stream: service.getAllUserTeams(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF0A500)));
        }
        final teams = snap.data ?? [];
        if (teams.isEmpty) {
          return _EmptyState();
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
          itemCount: teams.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (ctx, i) => _TeamCard(
            team: teams[i],
            uid: uid,
            onTap: () => Navigator.push(ctx, MaterialPageRoute(
              builder: (_) => TeamDetailScreen(teamId: teams[i].id),
            )),
          ),
        );
      },
    );
  }
}

// ─── Empty State ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          shape: BoxShape.circle,
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: const Icon(Icons.group_add_outlined, color: Color(0xFF333333), size: 36),
      ),
      const SizedBox(height: 16),
      const Text("You're not in any teams yet",
          style: TextStyle(color: Color(0xFF777777), fontSize: 14)),
      const SizedBox(height: 8),
      const Text("Create a team to compete in tournaments",
          style: TextStyle(color: Color(0xFF444444), fontSize: 12)),
      const SizedBox(height: 24),
      GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => const CreateTeamScreen(),
        )),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFC8860A), Color(0xFFF0A500)]),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Create Your First Team',
              style: TextStyle(color: Colors.black,
                  fontWeight: FontWeight.w800, fontSize: 14)),
        ),
      ),
    ]),
  );
}

// ─── Team Card ────────────────────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  final TeamModel team;
  final String uid;
  final VoidCallback onTap;
  const _TeamCard({required this.team, required this.uid, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isCaptain = team.captainUid == uid;
    final hasImage = team.logoUrl.isNotEmpty;
    final memberCount = team.members.length;
    final maxCount = team.maxMembers;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        child: Row(children: [
          // Logo
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: isCaptain ? const Color(0xFF2A2200) : const Color(0xFF222222),
              ),
              image: hasImage
                  ? DecorationImage(image: NetworkImage(team.logoUrl), fit: BoxFit.cover)
                  : null,
            ),
            child: hasImage ? null
                : Center(child: Text(team.logoEmoji,
                    style: const TextStyle(fontSize: 26))),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(team.name, style: const TextStyle(
                    color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                if (isCaptain) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A1800),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text('CAPTAIN', style: TextStyle(
                        color: Color(0xFFF0A500), fontSize: 9, fontWeight: FontWeight.w800)),
                  ),
                ],
              ]),
              const SizedBox(height: 4),
              Row(children: [
                // Member fill bar
                Expanded(child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: memberCount / maxCount,
                    backgroundColor: const Color(0xFF222222),
                    valueColor: AlwaysStoppedAnimation(
                      memberCount == maxCount
                          ? const Color(0xFF4CAF50)
                          : const Color(0xFFF0A500),
                    ),
                    minHeight: 4,
                  ),
                )),
                const SizedBox(width: 8),
                Text('$memberCount/$maxCount',
                    style: const TextStyle(color: Color(0xFF777777), fontSize: 11)),
              ]),
            ],
          )),
          const SizedBox(width: 10),
          // Team size badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFF2A2A2A)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text('$maxCount',
                  style: const TextStyle(color: Colors.white,
                      fontSize: 16, fontWeight: FontWeight.w800)),
              const Text('players', style: TextStyle(
                  color: Color(0xFF555555), fontSize: 9)),
            ]),
          ),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right, color: Color(0xFF333333), size: 20),
        ]),
      ),
    );
  }
}
