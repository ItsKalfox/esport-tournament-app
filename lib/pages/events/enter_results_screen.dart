import 'package:flutter/material.dart';
import '../../models/tournament_model.dart';
import '../../models/team_model.dart';
import '../../models/match_result_model.dart';
import '../../services/tournament_service.dart';

class EnterResultsScreen extends StatefulWidget {
  final TournamentModel tournament;
  const EnterResultsScreen({super.key, required this.tournament});

  @override
  State<EnterResultsScreen> createState() => _EnterResultsScreenState();
}

class _EnterResultsScreenState extends State<EnterResultsScreen> {
  final _service = TournamentService();
  MatchRound _round = MatchRound.qualifier;
  int _matchNumber = 1;
  bool _saving = false;

  // teamId → {placementCtrl, killsCtrl}
  final Map<String, Map<String, TextEditingController>> _ctrls = {};
  List<TeamModel> _teams = [];
  bool _teamsLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeams();
  }

  Future<void> _loadTeams() async {
    _service.getTeams(widget.tournament.id).listen((teams) {
      if (!mounted) return;
      final filtered = _round == MatchRound.finals
          ? teams.where((t) => t.advancedToFinals).toList()
          : teams;
      _teams = filtered.toList();
      // Init controllers for new teams
      for (final t in _teams) {
        if (!_ctrls.containsKey(t.id)) {
          _ctrls[t.id] = {
            'placement': TextEditingController(),
            'kills': TextEditingController(),
          };
        }
      }
      setState(() => _teamsLoading = false);
    });
  }

  void _applyRoundChange(MatchRound r) {
    setState(() {
      _round = r;
      _matchNumber = 1;
      _teamsLoading = true;
    });
    _loadTeams();
  }

  Future<void> _saveResults() async {
    // Validate all placements are filled
    final missing = _teams
        .where((t) =>
            _ctrls[t.id]!['placement']!.text.trim().isEmpty)
        .map((t) => t.name)
        .toList();
    if (missing.isNotEmpty) {
      _showSnack(
          'Missing placement for: ${missing.join(', ')}');
      return;
    }

    // Check for duplicate placements
    final placements = _teams
        .map((t) =>
            int.tryParse(_ctrls[t.id]!['placement']!.text.trim()) ?? 0)
        .toList();
    final uniquePlacements = placements.toSet();
    if (uniquePlacements.length != placements.length) {
      _showSnack('Duplicate placements detected. Each team must have a unique rank.');
      return;
    }

    setState(() => _saving = true);
    try {
      final config = widget.tournament.pointConfig;
      final results = _teams.map((t) {
        final placement =
            int.tryParse(_ctrls[t.id]!['placement']!.text.trim()) ?? 1;
        final kills =
            int.tryParse(_ctrls[t.id]!['kills']!.text.trim()) ?? 0;
        final placePts = config.pointsFor(placement);
        final killPts = kills * config.killPoints;
        return MatchResultModel(
          id: '',
          tournamentId: widget.tournament.id,
          round: _round,
          matchNumber: _matchNumber,
          teamId: t.id,
          teamName: t.name,
          teamLogoEmoji: t.logoEmoji,
          placement: placement,
          kills: kills,
          placementPoints: placePts,
          killPoints: killPts,
          totalPoints: placePts + killPts,
          createdAt: DateTime.now(),
        );
      }).toList();

      await _service.saveMatchResults(
          widget.tournament.id, _round, _matchNumber, results);

      // Update tournament status if needed
      if (widget.tournament.status == TournamentStatus.upcoming) {
        await _service.updateTournamentStatus(
            widget.tournament.id, TournamentStatus.qualifier);
      } else if (_round == MatchRound.finals &&
          widget.tournament.status == TournamentStatus.finals) {
        // Keep as finals
      }

      if (mounted) {
        _showSnack(
            'Results saved for Match $_matchNumber! ✅', success: true);
        // Clear fields after save
        for (final c in _ctrls.values) {
          c['placement']!.clear();
          c['kills']!.clear();
        }
      }
    } catch (e) {
      _showSnack('Error saving: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool success = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            success ? const Color(0xFF2A8C00) : const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    for (final m in _ctrls.values) {
      m['placement']!.dispose();
      m['kills']!.dispose();
    }
    super.dispose();
  }

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
                      'Enter Match Results',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Round selector
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _RoundBtn(
                      label: 'Qualifiers',
                      active: _round == MatchRound.qualifier,
                      onTap: () =>
                          _applyRoundChange(MatchRound.qualifier),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _RoundBtn(
                      label: 'Finals',
                      active: _round == MatchRound.finals,
                      onTap: () =>
                          _applyRoundChange(MatchRound.finals),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Match number selector (only for qualifier)
            if (_round == MatchRound.qualifier)
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'MATCH NUMBER',
                      style: TextStyle(
                        color: Color(0xFF777777),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(4, (i) {
                        final n = i + 1;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _matchNumber = n),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 48,
                              height: 36,
                              decoration: BoxDecoration(
                                color: _matchNumber == n
                                    ? const Color(0xFF2A1800)
                                    : const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _matchNumber == n
                                      ? const Color(0xFFF0A500)
                                      : const Color(0xFF2A2A2A),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  'M$n',
                                  style: TextStyle(
                                    color: _matchNumber == n
                                        ? const Color(0xFFF0A500)
                                        : const Color(0xFF777777),
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Column headers
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: const [
                  SizedBox(width: 44),
                  Expanded(
                    flex: 3,
                    child: Text('Team',
                        style: TextStyle(
                            color: Color(0xFF777777),
                            fontSize: 11,
                            fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(
                    width: 70,
                    child: Text('Placement',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF777777), fontSize: 11)),
                  ),
                  SizedBox(width: 8),
                  SizedBox(
                    width: 60,
                    child: Text('Kills',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: Color(0xFF777777), fontSize: 11)),
                  ),
                ],
              ),
            ),
            const Divider(color: Color(0xFF222222), height: 1),
            // Teams list
            Expanded(
              child: _teamsLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFF0A500)))
                  : _teams.isEmpty
                      ? const Center(
                          child: Text(
                          'No teams found',
                          style: TextStyle(color: Color(0xFF555555)),
                        ))
                      : ListView.separated(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          itemCount: _teams.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 6),
                          itemBuilder: (ctx, i) {
                            final team = _teams[i];
                            final placementCtrl =
                                _ctrls[team.id]!['placement']!;
                            final killsCtrl =
                                _ctrls[team.id]!['kills']!;
                            return _ResultRow(
                              team: team,
                              placementCtrl: placementCtrl,
                              killsCtrl: killsCtrl,
                            );
                          },
                        ),
            ),
            // Save button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _saving
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFF0A500)))
                  : GestureDetector(
                      onTap: _saveResults,
                      child: Container(
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Text(
                            'Save Results',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Result Row ───────────────────────────────────────────────────────────────

class _ResultRow extends StatelessWidget {
  final TeamModel team;
  final TextEditingController placementCtrl;
  final TextEditingController killsCtrl;

  const _ResultRow({
    required this.team,
    required this.placementCtrl,
    required this.killsCtrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF222222)),
      ),
      child: Row(
        children: [
          // Emoji
          SizedBox(
            width: 34,
            child:
                Text(team.logoEmoji, style: const TextStyle(fontSize: 22)),
          ),
          const SizedBox(width: 10),
          // Team name
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  team.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${team.memberCount} players',
                  style: const TextStyle(
                      color: Color(0xFF555555), fontSize: 10),
                ),
              ],
            ),
          ),
          // Placement input
          SizedBox(
            width: 70,
            child: _NumberInput(
                controller: placementCtrl, hint: '#'),
          ),
          const SizedBox(width: 8),
          // Kills input
          SizedBox(
            width: 60,
            child: _NumberInput(controller: killsCtrl, hint: '0'),
          ),
        ],
      ),
    );
  }
}

class _NumberInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _NumberInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) => Container(
        height: 36,
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: TextField(
          controller: controller,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.number,
          style: const TextStyle(
              color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFF444444), fontSize: 13),
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
        ),
      );
}

// ─── Round Button ─────────────────────────────────────────────────────────────

class _RoundBtn extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _RoundBtn(
      {required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          decoration: BoxDecoration(
            gradient: active
                ? const LinearGradient(
                    colors: [Color(0xFF2A1800), Color(0xFF1A1000)])
                : null,
            color: active ? null : const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? const Color(0xFFF0A500)
                  : const Color(0xFF2A2A2A),
            ),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: active
                    ? const Color(0xFFF0A500)
                    : const Color(0xFF777777),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
      );
}
