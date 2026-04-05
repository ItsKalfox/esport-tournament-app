import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/tournament_model.dart';
import '../../services/tournament_service.dart';
import 'create_tournament_screen.dart';
import 'tournament_detail_screen.dart';
import 'invite_notifications_screen.dart';

class EventsScreen extends StatefulWidget {
  const EventsScreen({super.key});

  @override
  State<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends State<EventsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  final _service = TournamentService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _TopBar(service: _service),
            const SizedBox(height: 12),
            // Search bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: _SearchBar(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              ),
            ),
            const SizedBox(height: 14),
            // Tabs
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 38,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                labelColor: Colors.black,
                unselectedLabelColor: const Color(0xFF777777),
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: const [
                  Tab(text: 'Browse'),
                  Tab(text: 'My Tournaments'),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Tab content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _TournamentList(
                    stream: _service.getTournaments(),
                    searchQuery: _searchQuery,
                    emptyMessage: 'No tournaments yet',
                  ),
                  _TournamentList(
                    stream: _service.getMyTournaments(
                      FirebaseAuth.instance.currentUser?.uid ?? '',
                    ),
                    searchQuery: _searchQuery,
                    emptyMessage: 'You haven\'t organized any tournaments',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _OrganizeButton(),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final TournamentService service;
  const _TopBar({required this.service});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 0),
      child: Row(
        children: [
          const Expanded(
            child: Text(
              'Events',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ),
          // Bell icon with badge
          StreamBuilder<int>(
            stream: service.getPendingInviteCount(),
            builder: (context, snap) {
              final count = snap.data ?? 0;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InviteNotificationsScreen(),
                      ),
                    ),
                    icon: Icon(
                      count > 0
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: count > 0
                          ? const Color(0xFFF0A500)
                          : const Color(0xFF777777),
                      size: 24,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: Color(0xFFff4444),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          count > 9 ? '9+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

// ─── Search Bar ───────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  const _SearchBar({required this.controller, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        decoration: const InputDecoration(
          hintText: 'Search tournaments…',
          hintStyle: TextStyle(color: Color(0xFF555555), fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Color(0xFF555555), size: 20),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ─── Tournament List ──────────────────────────────────────────────────────────

class _TournamentList extends StatelessWidget {
  final Stream<List<TournamentModel>> stream;
  final String searchQuery;
  final String emptyMessage;

  const _TournamentList({
    required this.stream,
    required this.searchQuery,
    required this.emptyMessage,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TournamentModel>>(
      stream: stream,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFF0A500)),
          );
        }
        var tournaments = snap.data ?? [];
        if (searchQuery.isNotEmpty) {
          tournaments = tournaments
              .where((t) =>
                  t.name.toLowerCase().contains(searchQuery) ||
                  t.organizerName.toLowerCase().contains(searchQuery))
              .toList();
        }
        if (tournaments.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.emoji_events_outlined,
                    color: Color(0xFF333333), size: 56),
                const SizedBox(height: 14),
                Text(
                  emptyMessage,
                  style: const TextStyle(
                      color: Color(0xFF555555), fontSize: 14),
                ),
              ],
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          itemCount: tournaments.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) => _TournamentCard(
            tournament: tournaments[i],
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    TournamentDetailScreen(tournamentId: tournaments[i].id),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── Tournament Card ──────────────────────────────────────────────────────────

class _TournamentCard extends StatelessWidget {
  final TournamentModel tournament;
  final VoidCallback onTap;

  const _TournamentCard({required this.tournament, required this.onTap});

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
        .fold<double>(0, (sum, p) => sum + p.amount);
    final currency =
        tournament.prizeSlots.isNotEmpty ? tournament.prizeSlots.first.currency : 'USD';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF141414),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF222222)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Poster Banner ──────────────────────────────────────────────
            if (tournament.posterUrl.isNotEmpty)
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: Image.network(
                      tournament.posterUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (ctx, child, progress) =>
                          progress == null
                              ? child
                              : Container(
                                  color: const Color(0xFF1A1A1A),
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Color(0xFFF0A500),
                                      strokeWidth: 2,
                                    ),
                                  ),
                                ),
                      errorBuilder: (_, __, ___) => Container(
                        color: const Color(0xFF1A1A1A),
                        child: const Center(
                          child: Icon(Icons.broken_image,
                              color: Color(0xFF333333), size: 32),
                        ),
                      ),
                    ),
                  ),
                  // Status badge overlay on poster
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(6),
                        border:
                            Border.all(color: _statusColor.withOpacity(0.6)),
                      ),
                      child: Text(
                        tournament.statusLabel,
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            // ── Card Body ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      // Trophy icon (shown only when no poster)
                      if (tournament.posterUrl.isEmpty) ...[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A1800), Color(0xFF1A1000)],
                            ),
                            border: Border.all(
                                color: const Color(0xFFC8860A), width: 1),
                          ),
                          child: const Icon(
                            Icons.emoji_events,
                            color: Color(0xFFF0A500),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                      ],
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tournament.name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'by ${tournament.organizerName}',
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Status badge (shown inline only when no poster)
                      if (tournament.posterUrl.isEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                                color: _statusColor.withOpacity(0.4)),
                          ),
                          child: Text(
                            tournament.statusLabel,
                            style: TextStyle(
                              color: _statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Divider(color: Color(0xFF222222), height: 1),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _InfoChip(
                        icon: Icons.calendar_today,
                        label: dateStr,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.access_time,
                        label: tournament.time,
                      ),
                      const SizedBox(width: 12),
                      _InfoChip(
                        icon: Icons.groups,
                        label:
                            '${tournament.registeredTeams}/${tournament.maxTeams}',
                      ),
                      const Spacer(),
                      if (totalPrize > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF2A1800), Color(0xFF1A1000)],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            '🏆 $currency ${totalPrize.toStringAsFixed(0)}',
                            style: const TextStyle(
                              color: Color(0xFFF0A500),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: const Color(0xFF777777)),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(color: Color(0xFF777777), fontSize: 11)),
      ],
    );
  }
}

// ─── FAB ──────────────────────────────────────────────────────────────────────

class _OrganizeButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CreateTournamentScreen()),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF0A500).withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.black, size: 20),
            SizedBox(width: 6),
            Text(
              'Organize',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
