import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tournament_model.dart';
import '../../models/team_model.dart';
import '../../services/tournament_service.dart';
import 'join_tournament_screen.dart';
import 'enter_results_screen.dart';
import 'leaderboard_screen.dart';

class TournamentDetailScreen extends StatefulWidget {
  final String tournamentId;
  const TournamentDetailScreen({super.key, required this.tournamentId});

  @override
  State<TournamentDetailScreen> createState() =>
      _TournamentDetailScreenState();
}

class _TournamentDetailScreenState extends State<TournamentDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = TournamentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';

    return StreamBuilder<TournamentModel?>(
      stream: _service.getTournamentStream(widget.tournamentId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFF0D0D0D),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFFF0A500)),
            ),
          );
        }

        final tournament = snap.data;
        if (tournament == null) {
          return Scaffold(
            backgroundColor: const Color(0xFF0D0D0D),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline,
                      color: Color(0xFF555555), size: 48),
                  const SizedBox(height: 12),
                  const Text('Tournament not found',
                      style: TextStyle(color: Color(0xFF555555))),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Go back',
                        style: TextStyle(color: Color(0xFFF0A500))),
                  ),
                ],
              ),
            ),
          );
        }

        final isOrganizer = tournament.organizerUid == uid;

        return Scaffold(
          backgroundColor: const Color(0xFF0D0D0D),
          body: SafeArea(
            child: Column(
              children: [
                // Header
                _HeroHeader(
                    tournament: tournament,
                    onBack: () => Navigator.pop(context)),
                // Tabs
                Container(
                  color: const Color(0xFF111111),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFFF0A500),
                    indicatorWeight: 2,
                    labelColor: const Color(0xFFF0A500),
                    unselectedLabelColor: const Color(0xFF555555),
                    labelStyle: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w700),
                    tabs: const [
                      Tab(text: 'Overview'),
                      Tab(text: 'Teams'),
                      Tab(text: 'Leaderboard'),
                      Tab(text: 'Rules'),
                    ],
                  ),
                ),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _OverviewTab(tournament: tournament, isOrganizer: isOrganizer, service: _service),
                      _TeamsTab(tournament: tournament, service: _service),
                      _LeaderboardTab(tournament: tournament, service: _service),
                      _RulesTab(tournament: tournament),
                    ],
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _BottomActions(
            tournament: tournament,
            isOrganizer: isOrganizer,
            uid: uid,
            service: _service,
          ),
        );
      },
    );
  }
}

// ─── Hero Header ──────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback onBack;

  const _HeroHeader({required this.tournament, required this.onBack});

  Color get _statusColor {
    switch (tournament.status) {
      case TournamentStatus.upcoming:
        return const Color(0xFF4CAF50);
      case TournamentStatus.qualifier:
        return const Color(0xFFF0A500);
      case TournamentStatus.finals:
        return const Color(0xFFff6b35);
      case TournamentStatus.completed:
        return const Color(0xFF555555);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        '${tournament.date.day}/${tournament.date.month}/${tournament.date.year}';
    final totalPrize = tournament.prizeSlots
        .fold<double>(0, (s, p) => s + p.amount);
    final currency = tournament.prizeSlots.isNotEmpty
        ? tournament.prizeSlots.first.currency
        : '';

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1000), Color(0xFF111111)],
        ),
        border: Border(bottom: BorderSide(color: Color(0xFF2A2200))),
      ),
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onBack,
                icon: const Icon(Icons.arrow_back_ios,
                    color: Colors.white, size: 20),
              ),
              Expanded(
                child: Text(
                  tournament.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                  border:
                      Border.all(color: _statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  tournament.statusLabel,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _HeaderChip(
                    icon: Icons.calendar_today, label: dateStr),
                _HeaderChip(
                    icon: Icons.access_time, label: tournament.time),
                _HeaderChip(
                  icon: Icons.groups,
                  label:
                      '${tournament.registeredTeams}/${tournament.maxTeams} Teams',
                ),
                if (totalPrize > 0)
                  _HeaderChip(
                    icon: Icons.emoji_events,
                    label: '$currency ${totalPrize.toStringAsFixed(0)}',
                    color: const Color(0xFFF0A500),
                  ),
                _HeaderChip(
                    icon: Icons.person_outline,
                    label: 'by ${tournament.organizerName}'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _HeaderChip(
      {required this.icon,
      required this.label,
      this.color = const Color(0xFF777777)});

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(color: color, fontSize: 12)),
        ],
      );
}

// ─── Overview Tab ─────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final TournamentModel tournament;
  final bool isOrganizer;
  final TournamentService service;

  const _OverviewTab(
      {required this.tournament,
      required this.isOrganizer,
      required this.service});

  @override
  Widget build(BuildContext context) {
    final config = tournament.pointConfig;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (tournament.description.isNotEmpty) ...[
            const _SectionTitle('About'),
            const SizedBox(height: 6),
            Text(
              tournament.description,
              style: const TextStyle(
                  color: Color(0xFF999999), fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 20),
          ],

          const _SectionTitle('Format'),
          const SizedBox(height: 10),
          _FormatCard(tournament: tournament),
          const SizedBox(height: 20),

          const _SectionTitle('Points'),
          const SizedBox(height: 10),
          _PointsCard(config: config),
          const SizedBox(height: 20),

          if (tournament.prizeSlots.isNotEmpty) ...[
            const _SectionTitle('Prize Pool'),
            const SizedBox(height: 10),
            _PrizeCard(tournament: tournament),
            const SizedBox(height: 20),
          ],

          if (isOrganizer) ...[
            const _SectionTitle('Organizer Controls'),
            const SizedBox(height: 10),
            _OrganizerControls(
                tournament: tournament, service: service),
          ],
        ],
      ),
    );
  }
}

class _FormatCard extends StatelessWidget {
  final TournamentModel t;
  const _FormatCard({required TournamentModel tournament}) : t = tournament;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        children: [
          _FormatRow('Teams', '${t.maxTeams} teams'),
          _FormatRow(
              'Players per Team', '${t.playersPerTeam} players'),
          _FormatRow('Total Players', '${t.totalPlayers} players'),
          _FormatRow('Qualifier Matches', '4 matches'),
          _FormatRow('Finals', '1 match (top ${t.maxTeams} qualify)'),
        ],
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  final String label;
  final String value;
  const _FormatRow(this.label, this.value);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(
                    color: Color(0xFF777777), fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      );
}

class _PointsCard extends StatelessWidget {
  final PointConfig config;
  const _PointsCard({required this.config});

  @override
  Widget build(BuildContext context) {
    final sorted = config.placementPoints.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Column(
        children: [
          _FormatRow('Kill Points', '${config.killPoints} pts/kill'),
          const Divider(color: Color(0xFF222222), height: 16),
          ...sorted.map(
            (e) => _FormatRow(
              '#${e.key} Place',
              '${e.value} pts',
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeCard extends StatelessWidget {
  final TournamentModel tournament;
  const _PrizeCard({required this.tournament});

  @override
  Widget build(BuildContext context) {
    final currency = tournament.prizeSlots.isNotEmpty
        ? tournament.prizeSlots.first.currency
        : '';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1000), Color(0xFF141414)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2200)),
      ),
      child: Column(
        children: tournament.prizeSlots.map((slot) {
          final medal = slot.place == 1
              ? '🥇'
              : slot.place == 2
                  ? '🥈'
                  : slot.place == 3
                      ? '🥉'
                      : '#${slot.place}';
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Text(medal, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                    child: Text('#${slot.place} Place',
                        style: const TextStyle(
                            color: Color(0xFFCCCCCC), fontSize: 13))),
                Text(
                  '$currency ${slot.amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFF0A500),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _OrganizerControls extends StatelessWidget {
  final TournamentModel tournament;
  final TournamentService service;

  const _OrganizerControls(
      {required this.tournament, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (tournament.status == TournamentStatus.upcoming ||
            tournament.status == TournamentStatus.qualifier)
          _CtrlBtn(
            label: 'Enter Match Results',
            icon: Icons.edit_note,
            color: const Color(0xFFF0A500),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    EnterResultsScreen(tournament: tournament),
              ),
            ),
          ),
        if (tournament.status == TournamentStatus.qualifier)
          _CtrlBtn(
            label: 'Advance Top ${tournament.maxTeams} to Finals',
            icon: Icons.arrow_upward,
            color: const Color(0xFFff6b35),
            onTap: () async {
              final ok = await _confirm(context,
                  'Advance to Finals?',
                  'Top ${tournament.maxTeams} teams from qualifier leaderboard will advance. This cannot be undone.');
              if (ok == true) {
                await service.advanceToFinals(tournament.id, tournament.maxTeams);
              }
            },
          ),
        if (tournament.status == TournamentStatus.finals)
          _CtrlBtn(
            label: 'Complete Tournament',
            icon: Icons.flag,
            color: const Color(0xFF4CAF50),
            onTap: () async {
              final ok = await _confirm(context, 'Complete Tournament?',
                  'This will mark the tournament as completed.');
              if (ok == true) {
                await service.completeTournament(tournament.id);
              }
            },
          ),
      ],
    );
  }

  Future<bool?> _confirm(
      BuildContext context, String title, String message) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title:
            Text(title, style: const TextStyle(color: Colors.white)),
        content:
            Text(message, style: const TextStyle(color: Color(0xFF999999))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel',
                  style: TextStyle(color: Color(0xFF777777)))),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Confirm',
                  style: TextStyle(color: Color(0xFFF0A500)))),
        ],
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _CtrlBtn(
      {required this.label,
      required this.icon,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.4)),
            ),
            child: Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 10),
                Text(label,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ],
            ),
          ),
        ),
      );
}

// ─── Teams Tab ────────────────────────────────────────────────────────────────

class _TeamsTab extends StatelessWidget {
  final TournamentModel tournament;
  final TournamentService service;

  const _TeamsTab({required this.tournament, required this.service});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TeamModel>>(
      stream: service.getTeams(tournament.id),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
              child: CircularProgressIndicator(color: Color(0xFFF0A500)));
        }
        final teams = snap.data ?? [];
        if (teams.isEmpty) {
          return const Center(
            child: Text('No teams registered yet',
                style: TextStyle(color: Color(0xFF555555))),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (ctx, i) => _TeamTile(team: teams[i], rank: i + 1),
        );
      },
    );
  }
}

class _TeamTile extends StatelessWidget {
  final TeamModel team;
  final int rank;
  const _TeamTile({required this.team, required this.rank});

  @override
  Widget build(BuildContext context) {
    final hasImage = team.logoUrl.isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          Text('#$rank',
              style: const TextStyle(
                  color: Color(0xFF555555),
                  fontSize: 13,
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 10),
          // ── Team Logo ───────────────────────────────────────────────────
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1A1A1A),
              border: Border.all(
                color: hasImage
                    ? const Color(0xFF2A2200)
                    : const Color(0xFF222222),
              ),
              image: hasImage
                  ? DecorationImage(
                      image: NetworkImage(team.logoUrl),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasImage
                ? null
                : Center(
                    child: Text(team.logoEmoji,
                        style: const TextStyle(fontSize: 22))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(
                  'Captain: ${team.captainName}',
                  style: const TextStyle(
                      color: Color(0xFF555555), fontSize: 11),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${team.memberCount}/4',
              style: const TextStyle(
                  color: Color(0xFF777777),
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Leaderboard Tab ──────────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  final TournamentModel tournament;
  final TournamentService service;

  const _LeaderboardTab(
      {required this.tournament, required this.service});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => LeaderboardScreen(tournament: tournament),
          ),
        ),
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1A1000), Color(0xFF141414)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFF2A2200)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.leaderboard,
                  color: Color(0xFFF0A500), size: 48),
              const SizedBox(height: 12),
              const Text(
                'View Full Leaderboard',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                'See rankings for qualifiers and finals',
                style: TextStyle(color: Color(0xFF777777), fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Rules Tab ────────────────────────────────────────────────────────────────

class _RulesTab extends StatelessWidget {
  final TournamentModel tournament;
  const _RulesTab({required this.tournament});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Text(
          tournament.rules,
          style: const TextStyle(
            color: Color(0xFF999999),
            fontSize: 13,
            height: 1.7,
          ),
        ),
      );
}

// ─── Bottom Actions ───────────────────────────────────────────────────────────

class _BottomActions extends StatefulWidget {
  final TournamentModel tournament;
  final bool isOrganizer;
  final String uid;
  final TournamentService service;

  const _BottomActions({
    required this.tournament,
    required this.isOrganizer,
    required this.uid,
    required this.service,
  });

  @override
  State<_BottomActions> createState() => _BottomActionsState();
}

class _BottomActionsState extends State<_BottomActions> {
  bool _checkingTeam = true;
  TeamModel? _myTeam;

  @override
  void initState() {
    super.initState();
    _checkTeam();
  }

  Future<void> _checkTeam() async {
    final team = await widget.service.getUserTeam(
        widget.tournament.id, widget.uid);
    if (mounted) setState(() {
      _myTeam = team;
      _checkingTeam = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isOrganizer) return const SizedBox.shrink();
    if (_checkingTeam) return const SizedBox(height: 60);
    if (_myTeam != null) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(top: BorderSide(color: Color(0xFF222222))),
        ),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1A2A00),
            borderRadius: BorderRadius.circular(12),
            border:
                Border.all(color: const Color(0xFF4CAF50).withOpacity(0.4)),
          ),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle,
                    color: Color(0xFF4CAF50), size: 18),
                const SizedBox(width: 8),
                Text(
                  'Registered — ${_myTeam!.name} ${_myTeam!.logoEmoji}',
                  style: const TextStyle(
                    color: Color(0xFF4CAF50),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
    if (widget.tournament.isFull) {
      return Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
        decoration: const BoxDecoration(
          color: Color(0xFF111111),
          border: Border(top: BorderSide(color: Color(0xFF222222))),
        ),
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Center(
            child: Text('Tournament Full',
                style: TextStyle(color: Color(0xFF555555), fontSize: 13)),
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF222222))),
      ),
      child: GestureDetector(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => JoinTournamentScreen(
                tournament: widget.tournament,
              ),
            ),
          );
          _checkTeam();
        },
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
            ),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFF0A500).withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'Join Tournament',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: const TextStyle(
          color: Color(0xFFC8860A),
          fontSize: 13,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      );
}
