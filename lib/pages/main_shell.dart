import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/store/store_home_screen.dart';
import '../pages/events/events_screen.dart';
import '../pages/chat/ai_chat_screen.dart';
import '../pages/techcommunity/tech_community.dart';
import '../pages/watch_live/watch_live_screen.dart';
import '../pages/meetups/meetups_screen.dart';
import '../../Gamer_passport_screen.dart' show ProfileScreen;
import '../services/auth_service.dart';

const kAccent = Color(0xFFFF8A00);
const kCardBg = Color(0xFF1A1A1A);
const kBorder = Color(0xFF2A2A2A);
const kTextPrimary = Color(0xFFE9E9E9);
const kTextSecondary = Color(0xFF9A9A9A);

final _tournamentData = [
  {
    'title': 'Rift Rivals Arena',
    'teams': '25 teams',
    'prize': 'LKR 70,000',
    'image': 'tournament1',
    'asset': 'assets/images/crewmotorfest.jpg',
  },
  {
    'title': 'Cyber Clash 2026',
    'teams': '32 teams',
    'prize': 'LKR 100,000',
    'image': 'tournament2',
    'asset': 'assets/images/cyberclash.jpg',
  },
  {
    'title': 'Esport Premier League',
    'teams': '16 teams',
    'prize': 'LKR 50,000',
    'image': 'tournament3',
    'asset': 'assets/images/league.jpg',
  },
  {
    'title': 'Valorant Showdown',
    'teams': '20 teams',
    'prize': 'LKR 85,000',
    'image': 'tournament4',
    'asset': 'assets/images/valorant.jpg',
  },
];

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const _PlaceholderPage(label: 'Home'),
    const EventsScreen(),
    const StoreScreen(),
    const _PlaceholderPage(label: 'Profile'),
    const _TempSettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      _HomeDashboardPage(onSelectTab: (i) => setState(() => _currentIndex = i)),
      const EventsScreen(),
      const TechCommunityScreen(),
      const StoreScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.black,
        border: Border(top: BorderSide(color: Color(0xFF1A1A1A), width: 1)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.grid_view_outlined,
                activeIcon: Icons.grid_view_rounded,
                isActive: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.emoji_events_outlined,
                activeIcon: Icons.emoji_events,
                isActive: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.groups_outlined,
                activeIcon: Icons.groups,
                isActive: currentIndex == 2,
                onTap: () => onTap(2),
              ),
              _NavItem(
                icon: Icons.shopping_bag_outlined,
                activeIcon: Icons.shopping_bag,
                isActive: currentIndex == 3,
                onTap: () => onTap(3),
              ),
              _NavItem(
                icon: Icons.person_outline,
                activeIcon: Icons.person,
                isActive: currentIndex == 4,
                onTap: () => onTap(4),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Nav Item ─────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 52,
        height: 44,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4B4B4B) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          isActive ? activeIcon : icon,
          color: const Color(0xFFD9D9D9),
          size: 24,
        ),
      ),
    );
  }
}

class _HomeDashboardPage extends StatefulWidget {
  final ValueChanged<int> onSelectTab;

  const _HomeDashboardPage({required this.onSelectTab});

  @override
  State<_HomeDashboardPage> createState() => _HomeDashboardPageState();
}

class _HomeDashboardPageState extends State<_HomeDashboardPage> {
  static const Color _bg = Color(0xFF101113);

  Future<String> _resolveUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return 'USER';

    if ((user.displayName ?? '').trim().isNotEmpty) {
      return user.displayName!.trim();
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = doc.data() ?? <String, dynamic>{};
    final displayName = (data['displayName'] as String?)?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;

    final firstName = (data['firstName'] as String?)?.trim();
    if (firstName != null && firstName.isNotEmpty) return firstName;

    final email = (user.email ?? '').trim();
    if (email.isNotEmpty) return email.split('@').first;
    return 'USER';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: FutureBuilder<String>(
          future: _resolveUserName(),
          builder: (context, snapshot) {
            final name = (snapshot.data ?? 'User').toUpperCase();
            final user = FirebaseAuth.instance.currentUser;

            return SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () {},
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
                              ),
                            ),
                            child: Center(
                              child: Text(
                                (() {
                                  final parts = name.split(' ');
                                  final initials = parts
                                      .take(2)
                                      .map((e) => e.isNotEmpty ? e[0] : '')
                                      .join()
                                      .toUpperCase();
                                  return initials.isNotEmpty ? initials : 'GX';
                                })(),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Home',
                          style: TextStyle(
                            color: Color(0xFFE9E9E9),
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'Poppins',
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Spacer(),
                        const SizedBox(width: 46),
                      ],
                    ),
                  ),
                  Container(
                    height: 1,
                    color: kBorder,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Welcome back, $name',
                      style: TextStyle(
                        color: kTextSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Poppins',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: _TournamentHighlightCard(
                      onSelectTab: widget.onSelectTab,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: GridView.count(
                      crossAxisCount: 3,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 2,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.74,
                      children: [
                        _FeatureTile(
                          icon: Icons.emoji_events,
                          label: 'Tournaments Arena',
                          onTap: () => widget.onSelectTab(1),
                        ),
                        _FeatureTile(
                          icon: Icons.storefront,
                          label: 'Store',
                          onTap: () => widget.onSelectTab(3),
                        ),
                        _FeatureTile(
                          icon: Icons.forum,
                          label: 'Chat',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const AIChatScreen(),
                            ),
                          ),
                        ),
                        _FeatureTile(
                          icon: Icons.memory,
                          label: 'Tech Community',
                          onTap: () => widget.onSelectTab(2),
                        ),
                        _FeatureTile(
                          icon: Icons.live_tv,
                          label: 'Watch Live',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const WatchLiveScreen(),
                            ),
                          ),
                        ),
                        _FeatureTile(
                          icon: Icons.groups,
                          label: 'Meetups',
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const MeetupsScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TournamentHighlightCard extends StatefulWidget {
  final ValueChanged<int> onSelectTab;

  const _TournamentHighlightCard({required this.onSelectTab});

  @override
  State<_TournamentHighlightCard> createState() =>
      _TournamentHighlightCardState();
}

class _TournamentHighlightCardState extends State<_TournamentHighlightCard> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 264,
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            itemCount: _tournamentData.length,
            itemBuilder: (context, index) {
              final data = _tournamentData[index];
              return Container(
                decoration: BoxDecoration(
                  color: kCardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: kBorder, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(12),
                      ),
                      child: _TournamentImage(
                        assetPath:
                            data['asset'] ?? 'assets/images/crewmotorfest.jpg',
                        fallbackUrl:
                            'https://picsum.photos/seed/${data['image']}/400/200',
                        height: 106,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: kAccent.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  index == 0 ? 'LIVE NOW' : 'UPCOMING',
                                  style: TextStyle(
                                    color: kAccent,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w600,
                                    fontSize: 10,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            data['title']!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kTextPrimary,
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${data['teams']} • ${data['prize']} prize',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: kTextSecondary,
                              fontFamily: 'Poppins',
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: SizedBox(
                                  height: 30,
                                  child: ElevatedButton(
                                    onPressed: () => widget.onSelectTab(1),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: kAccent,
                                      foregroundColor: Colors.black,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Register',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: SizedBox(
                                  height: 30,
                                  child: OutlinedButton(
                                    onPressed: () => widget.onSelectTab(1),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: kTextPrimary,
                                      side: BorderSide(
                                        color: kBorder,
                                        width: 1,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                    ),
                                    child: const Text(
                                      'Details',
                                      style: TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
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
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_tournamentData.length, (index) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _currentPage == index ? kAccent : kBorder,
                borderRadius: BorderRadius.circular(4),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _FeatureTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _FeatureTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              color: kAccent.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: kAccent.withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Icon(icon, color: kAccent, size: 32),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _TournamentImage extends StatelessWidget {
  final String assetPath;
  final String fallbackUrl;
  final double? height;
  final double? width;
  final BoxFit fit;

  const _TournamentImage({
    required this.assetPath,
    required this.fallbackUrl,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
  });

  Future<bool> _assetExists(String path) async {
    try {
      await rootBundle.load(path);
      return true;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _assetExists(assetPath),
      builder: (context, snapshot) {
        final exists = snapshot.data ?? false;
        if (exists) {
          return Image.asset(
            assetPath,
            width: width ?? double.infinity,
            height: height,
            fit: fit,
          );
        }

        return Image.network(
          fallbackUrl,
          width: width ?? double.infinity,
          height: height,
          fit: fit,
        );
      },
    );
  }
}

// ─── Temp Settings Page ───────────────────────────────────────────────────────
// Temporary — replace with real Settings screen when ready

class _TempSettingsPage extends StatelessWidget {
  const _TempSettingsPage();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, color: Color(0xFF333333), size: 48),
            const SizedBox(height: 12),
            const Text(
              'Settings — Coming Soon',
              style: TextStyle(color: Color(0xFF555555), fontSize: 14),
            ),
            if (user != null) ...[
              const SizedBox(height: 4),
              Text(
                user.email ?? '',
                style: const TextStyle(color: Color(0xFF444444), fontSize: 12),
              ),
            ],
            const SizedBox(height: 32),
            GestureDetector(
              onTap: () async => await AuthService.signOut(),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFff4444)),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout, color: Color(0xFFff4444), size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Sign Out',
                      style: TextStyle(
                        color: Color(0xFFff4444),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder Page ─────────────────────────────────────────────────────────
// Temporary placeholder — replace with real screens as they are built

class _PlaceholderPage extends StatelessWidget {
  final String label;
  const _PlaceholderPage({required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.construction, color: Color(0xFF333333), size: 48),
            const SizedBox(height: 12),
            Text(
              '$label — Coming Soon',
              style: const TextStyle(color: Color(0xFF555555), fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
