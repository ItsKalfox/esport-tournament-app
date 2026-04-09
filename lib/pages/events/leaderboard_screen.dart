import 'package:flutter/material.dart';
import '../../models/tournament_model.dart';
import '../../models/match_result_model.dart';
import '../../services/tournament_service.dart';

class LeaderboardScreen extends StatefulWidget {
  final TournamentModel tournament;
  const LeaderboardScreen({super.key, required this.tournament});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  MatchRound _round = MatchRound.qualifier;
  final _service = TournamentService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 12, 16, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back_ios,
                        color: Colors.white, size: 20),
                  ),
                  const Expanded(
                    child: Text(
                      'Leaderboard',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.emoji_events,
                      color: Color(0xFFF0A500), size: 24),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 8),
              child: Text(
                widget.tournament.name,
                style:
                    const TextStyle(color: Color(0xFFF0A500), fontSize: 12),
              ),
            ),
            // Round toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    _RoundToggle(
                      label: 'Qualifiers',
                      active: _round == MatchRound.qualifier,
                      onTap: () =>
                          setState(() => _round = MatchRound.qualifier),
                    ),
                    _RoundToggle(
                      label: 'Finals',
                      active: _round == MatchRound.finals,
                      onTap: () =>
                          setState(() => _round = MatchRound.finals),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Column headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF141414),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    SizedBox(
                        width: 32,
                        child: Text('Rank',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 10,
                                fontWeight: FontWeight.w700))),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text('Team',
                          style: TextStyle(
                              color: Color(0xFF777777),
                              fontSize: 10,
                              fontWeight: FontWeight.w700)),
                    ),
                    SizedBox(
                        width: 48,
                        child: Text('Place',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF777777), fontSize: 10))),
                    SizedBox(
                        width: 48,
                        child: Text('Kills',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF777777), fontSize: 10))),
                    SizedBox(
                        width: 52,
                        child: Text('Total',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF777777),
                                fontSize: 10,
                                fontWeight: FontWeight.w700))),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            // Leaderboard list
            Expanded(
              child: StreamBuilder<List<LeaderboardEntry>>(
                stream: _service.getLeaderboard(
                    widget.tournament.id, _round),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFF0A500)),
                    );
                  }
                  final entries = snap.data ?? [];
                  if (entries.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.bar_chart,
                              color: Color(0xFF333333), size: 56),
                          const SizedBox(height: 14),
                          Text(
                            _round == MatchRound.qualifier
                                ? 'No qualifier results yet'
                                : 'No finals results yet',
                            style: const TextStyle(
                                color: Color(0xFF555555), fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Results will appear here after\nthe organizer enters match data.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF444444), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: entries.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 6),
                    itemBuilder: (ctx, i) => _LeaderboardRow(
                      entry: entries[i],
                      rank: i + 1,
                      winnerCount: widget.tournament.winnerCount,
                      animationDelay: Duration(milliseconds: i * 40),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Leaderboard Row ──────────────────────────────────────────────────────────

class _LeaderboardRow extends StatefulWidget {
  final LeaderboardEntry entry;
  final int rank;
  final int winnerCount;
  final Duration animationDelay;

  const _LeaderboardRow({
    required this.entry,
    required this.rank,
    required this.winnerCount,
    required this.animationDelay,
  });

  @override
  State<_LeaderboardRow> createState() => _LeaderboardRowState();
}

class _LeaderboardRowState extends State<_LeaderboardRow>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _opacity =
        CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0.05, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    Future.delayed(widget.animationDelay, () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _rankEmoji {
    if (widget.rank == 1) return '🥇';
    if (widget.rank == 2) return '🥈';
    if (widget.rank == 3) return '🥉';
    return '#${widget.rank}';
  }

  Color get _rowColor {
    if (widget.rank == 1) return const Color(0xFF1A1400);
    if (widget.rank == 2) return const Color(0xFF141414);
    if (widget.rank == 3) return const Color(0xFF141414);
    if (widget.rank <= widget.winnerCount) return const Color(0xFF0D1A0D);
    return const Color(0xFF111111);
  }

  Color get _borderColor {
    if (widget.rank == 1) return const Color(0xFFFFD700).withOpacity(0.4);
    if (widget.rank == 2) return const Color(0xFFC0C0C0).withOpacity(0.3);
    if (widget.rank == 3) return const Color(0xFFCD7F32).withOpacity(0.3);
    if (widget.rank <= widget.winnerCount)
      return const Color(0xFF4CAF50).withOpacity(0.2);
    return const Color(0xFF222222);
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _slide,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: _rowColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _borderColor),
          ),
          child: Row(
            children: [
              // Rank
              SizedBox(
                width: 32,
                child: Text(
                  _rankEmoji,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 15),
                ),
              ),
              const SizedBox(width: 8),
              // Team
              Text(widget.entry.teamLogoEmoji,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.entry.teamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      '${widget.entry.matchesPlayed} match${widget.entry.matchesPlayed == 1 ? '' : 'es'}',
                      style: const TextStyle(
                          color: Color(0xFF555555), fontSize: 10),
                    ),
                  ],
                ),
              ),
              // Placement pts
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Text(
                      '${widget.entry.totalPlacementPoints}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const Text('place',
                        style: TextStyle(
                            color: Color(0xFF555555), fontSize: 9)),
                  ],
                ),
              ),
              // Kill pts
              SizedBox(
                width: 48,
                child: Column(
                  children: [
                    Text(
                      '${widget.entry.totalKills}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600),
                    ),
                    const Text('kills',
                        style: TextStyle(
                            color: Color(0xFF555555), fontSize: 9)),
                  ],
                ),
              ),
              // Total pts
              SizedBox(
                width: 52,
                child: Text(
                  '${widget.entry.totalPoints}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFFF0A500),
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Round Toggle ─────────────────────────────────────────────────────────────

class _RoundToggle extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RoundToggle(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
        child: GestureDetector(
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(
                      colors: [Color(0xFFC8860A), Color(0xFFF0A500)])
                  : null,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? Colors.black : const Color(0xFF777777),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      );
}
