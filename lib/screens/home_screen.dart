import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../constants/app_colors.dart';
import '../widgets/featured_tournament_card.dart';
import '../widgets/community_feed_card.dart';
import '../widgets/quick_access_grid.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedNavIndex = 0;

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Logged-in user display name ─────────────────────────────────────────
  String get _displayName {
    final user = _auth.currentUser;
    if (user == null) return 'USER';
    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!.toUpperCase();
    }
    return user.email?.split('@').first.toUpperCase() ?? 'USER';
  }

  // ── Format Firestore Timestamp → readable string ────────────────────────
  String _formatDate(dynamic value) {
    if (value == null) return '';
    try {
      final dt = (value as Timestamp).toDate();
      const months = [
        'Jan','Feb','Mar','Apr','May','Jun',
        'Jul','Aug','Sep','Oct','Nov','Dec'
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (_) {
      return value.toString();
    }
  }

  // ── Navigation ──────────────────────────────────────────────────────────
  void _handleNavTap(int index) {
    setState(() => _selectedNavIndex = index);
    const routes = [
      '/home', '/tournaments', '/community', '/store', '/profile'
    ];
    if (index != 0) {
      Navigator.pushNamed(context, routes[index]).then((_) {
        setState(() => _selectedNavIndex = 0);
      });
    }
  }

  void _handleQuickNav(String route) {
    Navigator.pushNamed(context, route);
  }

  // ════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── App Bar ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _buildUserAvatar(),
      ),
      title: const Text(
        'HOME',
        style: TextStyle(
          color: AppColors.white,
          fontWeight: FontWeight.bold,
          fontSize: 18,
          letterSpacing: 2,
        ),
      ),
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(2),
        child: Container(height: 2, color: AppColors.primaryOrange),
      ),
    );
  }

  // Shows the logged-in user's Google photo if available
  Widget _buildUserAvatar() {
    final user = _auth.currentUser;
    final photoUrl = user?.photoURL ?? '';
    return CircleAvatar(
      backgroundColor: AppColors.primaryOrange,
      backgroundImage:
          photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
      child: photoUrl.isEmpty
          ? const Icon(Icons.person, color: AppColors.white, size: 20)
          : null,
    );
  }

  // ── Body ─────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),

          // Welcome text
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'WELCOME BACK, $_displayName!',
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
                fontSize: 16,
                letterSpacing: 1,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // ── BANNERS (from banners collection) ──────────────────────────
          // Fields used: imageUrl, title, buttonText, isActive, order
          _buildBannerSection(),

          const SizedBox(height: 20),

          // ── UPCOMING TOURNAMENTS ───────────────────────────────────────
          // Fields used: name, maxTeams, playersPerTeam, organizerName, date
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'UPCOMING TOURNAMENTS',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildTournamentsSection(),

          const SizedBox(height: 20),

          // ── COMMUNITY FEED (from posts collection) ─────────────────────
          // Fields used: caption, imageUrls[], userName, userAvatar,
          //              userInitials, likeCount
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'YOUR COMMUNITY FEED',
              style: TextStyle(
                color: AppColors.grey,
                fontSize: 12,
                letterSpacing: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _buildCommunityFeedSection(),

          const SizedBox(height: 24),

          // ── QUICK ACCESS GRID ──────────────────────────────────────────
          QuickAccessGrid(onNavigate: _handleQuickNav),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Banner carousel ───────────────────────────────────────────────────────
  // banners fields: imageUrl, title, buttonText, isActive, order
  Widget _buildBannerSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('banners')
          .where('isActive', isEqualTo: true)
          .orderBy('order')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 160,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // hide if no banners
        }

        final banners = snapshot.data!.docs;

        return SizedBox(
          height: 160,
          child: PageView.builder(
            padEnds: false,
            controller: PageController(viewportFraction: 0.9),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final d = banners[index].data() as Map<String, dynamic>;
              final imageUrl = (d['imageUrl'] ?? '').toString();
              final title    = (d['title']    ?? '').toString();
              final btnText  = (d['buttonText'] ?? 'Learn More').toString();

              return Container(
                margin: const EdgeInsets.only(right: 12, left: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.cardBackground,
                  border: Border.all(
                      color: AppColors.primaryOrange.withOpacity(0.3)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Background image
                    if (imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              const SizedBox.shrink(),
                        ),
                      ),
                    // Dark overlay
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ),
                    // Title + button
                    Positioned(
                      bottom: 12,
                      left: 12,
                      right: 12,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () =>
                                _handleQuickNav('/store'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryOrange,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(6)),
                            ),
                            child: Text(btnText,
                                style: const TextStyle(fontSize: 11)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Tournaments section ───────────────────────────────────────────────────
  // tournaments fields: name, maxTeams, playersPerTeam, organizerName,
  //                     date (Timestamp), createdAt (Timestamp)
  Widget _buildTournamentsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('tournaments')
          .orderBy('createdAt', descending: true)
          .limit(5)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 130,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text('Could not load tournaments: ${snapshot.error}',
                style: const TextStyle(color: AppColors.grey)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No upcoming tournaments yet.',
                style: TextStyle(color: AppColors.grey)),
          );
        }

        final docs = snapshot.data!.docs;

        return SizedBox(
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d  = docs[index].data() as Map<String, dynamic>;
              final id = docs[index].id;

              // ── Map real Firestore field names ──────────────────────
              final name      = (d['name']          ?? 'Tournament').toString();
              final maxTeams  = d['maxTeams']        ?? 0;
              final perTeam   = d['playersPerTeam']  ?? 4;
              final organizer = (d['organizerName']  ?? '').toString();
              final dateStr   = _formatDate(d['date']);
              // tournaments has no imageUrl — show icon placeholder
              const imageUrl  = '';

              final slots = '$maxTeams teams · $perTeam per team';

              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.80,
                  child: FeaturedTournamentCard(
                    tournamentName: name,
                    teamSlots:      slots,
                    organizerName:  organizer,
                    tournamentDate: dateStr,
                    imagePath:      imageUrl,
                    onRegister: () => Navigator.pushNamed(
                      context, '/tournaments',
                      arguments: {'tournamentId': id},
                    ),
                    onViewDetails: () => Navigator.pushNamed(
                      context, '/tournaments',
                      arguments: {'tournamentId': id},
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── Community feed section ────────────────────────────────────────────────
  // posts fields: caption, imageUrls (array), userName, userAvatar,
  //               userInitials, likeCount, createdAt
  Widget _buildCommunityFeedSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db
          .collection('posts')
          .orderBy('createdAt', descending: true)
          .limit(6)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.primaryOrange),
            ),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text('No community posts yet.',
                style: TextStyle(color: AppColors.grey)),
          );
        }

        final docs = snapshot.data!.docs;

        return SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.only(left: 16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final d = docs[index].data() as Map<String, dynamic>;

              // ── Map real Firestore field names ──────────────────────
              final caption      = (d['caption']      ?? '').toString();
              final userName     = (d['userName']     ?? 'User').toString();
              final userAvatar   = (d['userAvatar']   ?? '').toString();
              final userInitials = (d['userInitials'] ?? '').toString();
              final likeCount    = (d['likeCount']    as int?) ?? 0;

              // imageUrls is an array — take the first element
              String imagePath = '';
              final imageUrls = d['imageUrls'];
              if (imageUrls is List && imageUrls.isNotEmpty) {
                imagePath = imageUrls[0].toString();
              }

              return CommunityFeedCard(
                caption:      caption,
                userName:     userName,
                userAvatar:   userAvatar,
                userInitials: userInitials,
                imagePath:    imagePath,
                likeCount:    likeCount,
                onTap: () => _handleQuickNav('/community'),
              );
            },
          ),
        );
      },
    );
  }

  // ── Bottom Navigation Bar ─────────────────────────────────────────────────
  Widget _buildBottomNav() {
    const navItems = [
      {'icon': Icons.grid_view_rounded,     'label': 'Home'},
      {'icon': Icons.emoji_events_outlined, 'label': 'Tournaments'},
      {'icon': Icons.groups_outlined,       'label': 'Community'},
      {'icon': Icons.storefront_outlined,   'label': 'Store'},
      {'icon': Icons.person_outline,        'label': 'Profile'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: AppColors.navBarBackground,
        border: Border(
          top: BorderSide(
              color: AppColors.primaryOrange.withOpacity(0.3)),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(navItems.length, (index) {
              final isSelected = _selectedNavIndex == index;
              return GestureDetector(
                onTap: () => _handleNavTap(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryOrange.withOpacity(0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    navItems[index]['icon'] as IconData,
                    color: isSelected
                        ? AppColors.primaryOrange
                        : AppColors.grey,
                    size: 26,
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}