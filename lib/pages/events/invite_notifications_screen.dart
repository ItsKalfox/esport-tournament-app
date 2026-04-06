import 'package:flutter/material.dart';
import '../../services/tournament_service.dart';

class InviteNotificationsScreen extends StatelessWidget {
  const InviteNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = TournamentService();
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
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
                      'Team Invitations',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const Icon(Icons.notifications_active,
                      color: Color(0xFFF0A500), size: 22),
                  const SizedBox(width: 8),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: service.getPendingInvites(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFFF0A500)),
                    );
                  }
                  final invites = snap.data ?? [];
                  if (invites.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.mark_email_read_outlined,
                              color: Color(0xFF333333), size: 56),
                          const SizedBox(height: 14),
                          const Text(
                            'No pending invitations',
                            style: TextStyle(
                                color: Color(0xFF555555), fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'When someone invites you to a team,\nit will appear here.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Color(0xFF444444), fontSize: 12),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: invites.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) =>
                        _InviteCard(invite: invites[i], service: service),
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

class _InviteCard extends StatefulWidget {
  final Map<String, dynamic> invite;
  final TournamentService service;

  const _InviteCard({required this.invite, required this.service});

  @override
  State<_InviteCard> createState() => _InviteCardState();
}

class _InviteCardState extends State<_InviteCard> {
  bool _loading = false;

  Future<void> _accept() async {
    setState(() => _loading = true);
    try {
      await widget.service.acceptInvite(
        widget.invite['id'] as String,
        widget.invite['tournamentId'] as String,
        widget.invite['teamId'] as String,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('You joined ${widget.invite['teamName']}! 🎮'),
            backgroundColor: const Color(0xFF2A8C00),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: const Color(0xFF333333),
            behavior: SnackBarBehavior.floating,
          ),
        );
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _decline() async {
    setState(() => _loading = true);
    try {
      await widget.service.declineInvite(widget.invite['id'] as String);
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final teamName = widget.invite['teamName'] as String? ?? 'Unknown Team';
    final logo = widget.invite['teamLogoEmoji'] as String? ?? '🎮';
    final inviterName = widget.invite['inviterName'] as String? ?? 'Someone';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF141414),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF2A2200)),
                ),
                child: Center(
                  child: Text(logo,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      teamName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$inviterName invited you to join their team',
                      style: const TextStyle(
                          color: Color(0xFF777777), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            const Center(
              child: SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      color: Color(0xFFF0A500), strokeWidth: 2)),
            )
          else
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _decline,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        border:
                            Border.all(color: const Color(0xFF333333)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Text(
                          'Decline',
                          style: TextStyle(
                              color: Color(0xFF777777),
                              fontWeight: FontWeight.w600,
                              fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: _accept,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF1A4A00),
                            Color(0xFF2A8C00)
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: const Color(0xFF4CAF50)
                                .withOpacity(0.5)),
                      ),
                      child: const Center(
                        child: Text(
                          'Accept ✓',
                          style: TextStyle(
                              color: Color(0xFF4CAF50),
                              fontWeight: FontWeight.w700,
                              fontSize: 13),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}
