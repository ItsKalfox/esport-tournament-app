import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tournament_model.dart';
import '../../models/team_model.dart';
import '../../services/tournament_service.dart';
import 'create_team_screen.dart';

class JoinTournamentScreen extends StatefulWidget {
  final TournamentModel tournament;
  const JoinTournamentScreen({super.key, required this.tournament});

  @override
  State<JoinTournamentScreen> createState() => _JoinTournamentScreenState();
}

class _JoinTournamentScreenState extends State<JoinTournamentScreen> {
  final _service = TournamentService();
  String? _selectedTeamId;
  bool _joining = false;

  String get _uid => FirebaseAuth.instance.currentUser?.uid ?? '';
  int get _required => widget.tournament.playersPerTeam;

  Future<void> _join(TeamModel team) async {
    setState(() => _joining = true);
    try {
      await _service.registerTeamForTournament(
        globalTeam: team,
        tournamentId: widget.tournament.id,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Team registered! Good luck! 🏆'),
          backgroundColor: Color(0xFF2A8C00),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: const Color(0xFF8C0000),
          behavior: SnackBarBehavior.floating,
        ));
        setState(() => _joining = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(child: Column(children: [
        // ── Header ───────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
          child: Row(children: [
            IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
            ),
            const Expanded(child: Text('Join Tournament',
                style: TextStyle(color: Colors.white, fontSize: 20,
                    fontWeight: FontWeight.w800))),
          ]),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 20, bottom: 8),
          child: Text(widget.tournament.name,
              style: const TextStyle(color: Color(0xFFF0A500), fontSize: 12)),
        ),

        // ── Requirement Banner ────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1000),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2A2200)),
            ),
            child: Row(children: [
              const Icon(Icons.groups, color: Color(0xFFF0A500), size: 18),
              const SizedBox(width: 10),
              Expanded(child: RichText(text: TextSpan(
                style: const TextStyle(fontSize: 13),
                children: [
                  const TextSpan(text: 'This tournament requires ',
                      style: TextStyle(color: Color(0xFF999999))),
                  TextSpan(text: '$_required-player teams',
                      style: const TextStyle(color: Color(0xFFF0A500),
                          fontWeight: FontWeight.w700)),
                ],
              ))),
            ]),
          ),
        ),
        const SizedBox(height: 16),

        // ── Team List ─────────────────────────────────────────────────────
        Expanded(
          child: StreamBuilder<List<TeamModel>>(
            stream: _service.getAllUserTeams(_uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFF0A500)));
              }
              final teams = snap.data ?? [];

              if (teams.isEmpty) {
                return _NoTeamsState(required: _required);
              }

              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(children: [
                    const Text('Select a Team',
                        style: TextStyle(color: Color(0xFFC8860A), fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(
                          builder: (_) => const CreateTeamScreen())),
                      child: Row(children: const [
                        Icon(Icons.add, color: Color(0xFF007FFF), size: 14),
                        SizedBox(width: 4),
                        Text('New Team', style: TextStyle(
                            color: Color(0xFF007FFF), fontSize: 12,
                            fontWeight: FontWeight.w700)),
                      ]),
                    ),
                  ]),
                ),
                const SizedBox(height: 10),
                Expanded(child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                  itemCount: teams.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) {
                    final team = teams[i];
                    // Compatible = correct size AND fully filled
                    final sizeMatch = team.maxMembers == _required;
                    final isFull = team.members.length == _required;
                    final compatible = sizeMatch && isFull;
                    final selected = _selectedTeamId == team.id;
                    return _TeamSelectTile(
                      team: team,
                      required: _required,
                      compatible: compatible,
                      sizeMatch: sizeMatch,
                      selected: selected,
                      onTap: compatible
                          ? () => setState(() =>
                              _selectedTeamId = selected ? null : team.id)
                          : null,
                    );
                  },
                )),
              ]);
            },
          ),
        ),

        // ── Join Button ───────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: StreamBuilder<List<TeamModel>>(
            stream: _service.getAllUserTeams(_uid),
            builder: (context, snap) {
              final teams = snap.data ?? [];
              final selectedTeam = teams.cast<TeamModel?>()
                  .firstWhere((t) => t?.id == _selectedTeamId, orElse: () => null);

              if (_joining) {
                return const Center(child: CircularProgressIndicator(
                    color: Color(0xFFF0A500)));
              }

              return GestureDetector(
                onTap: selectedTeam != null ? () => _join(selectedTeam) : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: selectedTeam != null
                        ? const LinearGradient(
                            colors: [Color(0xFFC8860A), Color(0xFFF0A500)])
                        : null,
                    color: selectedTeam == null ? const Color(0xFF1A1A1A) : null,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: selectedTeam != null
                          ? Colors.transparent
                          : const Color(0xFF2A2A2A),
                    ),
                    boxShadow: selectedTeam != null ? [BoxShadow(
                      color: const Color(0xFFF0A500).withOpacity(0.3),
                      blurRadius: 16, offset: const Offset(0, 4),
                    )] : null,
                  ),
                  child: Center(child: Text(
                    selectedTeam != null
                        ? 'Join with "${selectedTeam.name}" 🏆'
                        : 'Select a compatible team above',
                    style: TextStyle(
                      color: selectedTeam != null ? Colors.black : const Color(0xFF555555),
                      fontWeight: FontWeight.w800, fontSize: 14,
                    ),
                  )),
                ),
              );
            },
          ),
        ),
      ])),
    );
  }
}

// ─── No Teams State ───────────────────────────────────────────────────────────

class _NoTeamsState extends StatelessWidget {
  final int required;
  const _NoTeamsState({required this.required});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.group_off, color: Color(0xFF333333), size: 56),
        const SizedBox(height: 16),
        const Text("You don't have any teams yet",
            style: TextStyle(color: Color(0xFF777777), fontSize: 14)),
        const SizedBox(height: 8),
        Text('Create a $required-player team to join this tournament',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFF555555), fontSize: 12)),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => const CreateTeamScreen())),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                  colors: [Color(0xFF0055AA), Color(0xFF007FFF)]),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('Create a Team',
                style: TextStyle(color: Colors.white,
                    fontWeight: FontWeight.w800, fontSize: 14)),
          ),
        ),
      ]),
    ),
  );
}

// ─── Team Select Tile ─────────────────────────────────────────────────────────

class _TeamSelectTile extends StatelessWidget {
  final TeamModel team;
  final int required;
  final bool compatible;
  final bool sizeMatch;
  final bool selected;
  final VoidCallback? onTap;

  const _TeamSelectTile({
    required this.team,
    required this.required,
    required this.compatible,
    required this.sizeMatch,
    required this.selected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = team.logoUrl.isNotEmpty;
    final isFull = team.members.length == team.maxMembers;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF1A1000)
              : compatible
                  ? const Color(0xFF141414)
                  : const Color(0xFF0E0E0E),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: selected
                ? const Color(0xFFF0A500)
                : compatible
                    ? const Color(0xFF222222)
                    : const Color(0xFF1A1A1A),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(children: [
          // Logo
          Opacity(
            opacity: compatible ? 1.0 : 0.35,
            child: Container(
              width: 46, height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A1A1A),
                border: Border.all(color: compatible
                    ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A)),
                image: hasImage
                    ? DecorationImage(
                        image: NetworkImage(team.logoUrl), fit: BoxFit.cover)
                    : null,
              ),
              child: hasImage ? null
                  : Center(child: Text(team.logoEmoji,
                      style: const TextStyle(fontSize: 22))),
            ),
          ),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Opacity(
            opacity: compatible ? 1.0 : 0.4,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(team.name, style: const TextStyle(
                  color: Colors.white, fontSize: 14, fontWeight: FontWeight.w700)),
              const SizedBox(height: 3),
              Row(children: [
                Text('${team.members.length}/${team.maxMembers} members',
                    style: TextStyle(
                      color: compatible
                          ? const Color(0xFF4CAF50)  // green when eligible
                          : const Color(0xFF777777),
                      fontSize: 11,
                      fontWeight: compatible ? FontWeight.w600 : FontWeight.normal,
                    )),
                if (!compatible) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A0A0A),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: const Color(0xFF3A1A1A)),
                    ),
                    child: Text(
                      !sizeMatch
                          ? 'Needs $required players'
                          : !isFull
                              ? 'Not full (${team.members.length}/$required)'
                              : '',
                      style: const TextStyle(
                          color: Color(0xFF884444), fontSize: 9,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ]),
            ]),
          )),

          // Status indicator
          if (selected)
            Container(
              width: 28, height: 28,
              decoration: const BoxDecoration(
                shape: BoxShape.circle, color: Color(0xFFF0A500)),
              child: const Icon(Icons.check, color: Colors.black, size: 16),
            )
          else if (!compatible)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: const Text('Incompatible',
                  style: TextStyle(color: Color(0xFF555555), fontSize: 10)),
            )
          else
            Container(
              width: 24, height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
            ),
        ]),
      ),
    );
  }
}
