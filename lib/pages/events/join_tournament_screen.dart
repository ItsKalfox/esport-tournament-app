import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tournament_model.dart';
import '../../models/team_model.dart';
import '../../services/tournament_service.dart';

const List<String> _kEmojis = [
  '🎮', '⚔️', '🔥', '🏆', '👾', '💀', '🐉', '🦅', '⚡', '🌪️',
  '🎯', '🛡️', '🚀', '🐺', '🦁', '💎', '🔱', '☠️', '🦊', '🐯',
];

class JoinTournamentScreen extends StatefulWidget {
  final TournamentModel tournament;
  const JoinTournamentScreen({super.key, required this.tournament});

  @override
  State<JoinTournamentScreen> createState() => _JoinTournamentScreenState();
}

class _JoinTournamentScreenState extends State<JoinTournamentScreen> {
  final _service = TournamentService();
  final _teamNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _selectedEmoji = '🎮';
  final List<String> _pendingEmails = [];
  bool _loading = false;

  @override
  void dispose() {
    _teamNameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _addEmail() {
    final email = _emailCtrl.text.trim().toLowerCase();
    if (email.isEmpty) return;
    if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
      _showSnack('Please enter a valid email address');
      return;
    }
    if (_pendingEmails.contains(email)) {
      _showSnack('Email already added');
      return;
    }
    if (_pendingEmails.length >= 3) {
      _showSnack('Max 3 teammates (4 players per team)');
      return;
    }
    final currentEmail =
        FirebaseAuth.instance.currentUser?.email?.toLowerCase();
    if (email == currentEmail) {
      _showSnack('You can\'t invite yourself');
      return;
    }
    setState(() {
      _pendingEmails.add(email);
      _emailCtrl.clear();
    });
  }

  Future<void> _joinTournament() async {
    if (_teamNameCtrl.text.trim().isEmpty) {
      _showSnack('Please enter a team name');
      return;
    }
    setState(() => _loading = true);
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final captain = TeamMember(
        uid: user.uid,
        displayName: user.displayName ?? 'Captain',
        email: user.email ?? '',
      );
      final team = TeamModel(
        id: '',
        tournamentId: widget.tournament.id,
        name: _teamNameCtrl.text.trim(),
        logoEmoji: _selectedEmoji,
        captainUid: user.uid,
        captainName: user.displayName ?? 'Captain',
        members: [captain],
        pendingEmails: _pendingEmails,
        advancedToFinals: false,
        createdAt: DateTime.now(),
      );
      await _service.createTeam(team);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Team created! Invites sent to teammates 🎮'),
            backgroundColor: Color(0xFF2A8C00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      _showSnack('Error: $e');
      setState(() => _loading = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF333333),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      'Create Your Team',
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
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 20, bottom: 4),
              child: Text(
                widget.tournament.name,
                style: const TextStyle(
                    color: Color(0xFFF0A500), fontSize: 12),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Team Name
                    const _Label('Team Name *'),
                    _DarkInput(
                      controller: _teamNameCtrl,
                      hint: 'Enter your team name',
                    ),
                    const SizedBox(height: 20),

                    // Logo Picker
                    const _Label('Team Logo (Emoji)'),
                    const SizedBox(height: 10),
                    _EmojiPicker(
                      selected: _selectedEmoji,
                      onSelect: (e) => setState(() => _selectedEmoji = e),
                    ),
                    const SizedBox(height: 20),

                    // Preview
                    _TeamPreview(
                      name: _teamNameCtrl.text.trim().isEmpty
                          ? 'Your Team'
                          : _teamNameCtrl.text.trim(),
                      emoji: _selectedEmoji,
                    ),
                    const SizedBox(height: 24),

                    // Invite Teammates
                    const _Label('Invite Teammates (up to 3)'),
                    const SizedBox(height: 4),
                    const Text(
                      'Enter teammate email addresses. They\'ll receive an in-app invite.',
                      style: TextStyle(color: Color(0xFF555555), fontSize: 11),
                    ),
                    const SizedBox(height: 10),

                    // Email input row
                    Row(
                      children: [
                        Expanded(
                          child: _DarkInput(
                            controller: _emailCtrl,
                            hint: 'teammate@email.com',
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                        const SizedBox(width: 10),
                        GestureDetector(
                          onTap: _addEmail,
                          child: Container(
                            height: 46,
                            width: 46,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFC8860A),
                                  Color(0xFFF0A500)
                                ],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.add,
                                color: Colors.black, size: 22),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Added emails
                    if (_pendingEmails.isNotEmpty)
                      ..._pendingEmails.asMap().entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF141414),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                      color: const Color(0xFF2A2200)),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.email_outlined,
                                        color: Color(0xFFF0A500), size: 16),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        e.value,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 13),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: () => setState(
                                          () => _pendingEmails.removeAt(e.key)),
                                      child: const Icon(Icons.close,
                                          color: Color(0xFF555555),
                                          size: 16),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                    const SizedBox(height: 8),
                    Text(
                      '${1 + _pendingEmails.length}/4 players in your team',
                      style: const TextStyle(
                          color: Color(0xFF777777), fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Join button
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFF0A500)))
                  : GestureDetector(
                      onTap: _joinTournament,
                      child: Container(
                        height: 52,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
                          ),
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF0A500).withOpacity(0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Text(
                            'Join Tournament 🎮',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
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

// ─── Emoji Picker ─────────────────────────────────────────────────────────────

class _EmojiPicker extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _EmojiPicker({required this.selected, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _kEmojis.map((emoji) {
        final isSelected = emoji == selected;
        return GestureDetector(
          onTap: () => onSelect(emoji),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF2A1800)
                  : const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected
                    ? const Color(0xFFF0A500)
                    : const Color(0xFF2A2A2A),
                width: isSelected ? 2 : 1,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFF0A500).withOpacity(0.3),
                        blurRadius: 8,
                      )
                    ]
                  : null,
            ),
            child:
                Center(child: Text(emoji, style: const TextStyle(fontSize: 22))),
          ),
        );
      }).toList(),
    );
  }
}

// ─── Team Preview ─────────────────────────────────────────────────────────────

class _TeamPreview extends StatelessWidget {
  final String name;
  final String emoji;

  const _TeamPreview({required this.name, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1000), Color(0xFF141414)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2200)),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF2A2200)),
            ),
            child: Center(
                child: Text(emoji, style: const TextStyle(fontSize: 28))),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Preview',
                  style:
                      TextStyle(color: Color(0xFF555555), fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Shared ───────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFFC8860A),
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      );
}

class _DarkInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType keyboardType;

  const _DarkInput({
    required this.controller,
    required this.hint,
    this.keyboardType = TextInputType.text,
  });

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: Color(0xFF444444), fontSize: 14),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
          ),
        ),
      );
}
