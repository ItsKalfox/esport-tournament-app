import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class Post {
  final String id;
  final String title;
  final String imageSeed;
  int likes;
  bool liked;

  Post({
    required this.id,
    required this.title,
    required this.imageSeed,
    this.likes = 0,
    this.liked = false,
  });
}

class TechCommunityScreen extends StatefulWidget {
  const TechCommunityScreen({super.key});

  @override
  State<TechCommunityScreen> createState() => _TechCommunityScreenState();
}

class _TechCommunityScreenState extends State<TechCommunityScreen> {
  static const Color bg = Color(0xFF121212);
  static const Color accent = Color(0xFFFF8A00);

  final List<Post> posts = [
    Post(
      id: '1',
      title: 'CLASH OF CHAMPIONS:\nGrand Finale',
      imageSeed: 'tech1',
      likes: 120,
    ),
    Post(
      id: '2',
      title: 'The AI Secret That Could Boost Your Productivity',
      imageSeed: 'tech2',
      likes: 45,
    ),
    Post(
      id: '3',
      title: 'New GPU Benchmarks Revealed',
      imageSeed: 'tech3',
      likes: 30,
    ),
    Post(
      id: '4',
      title: 'Top 10 Developer Tools in 2026',
      imageSeed: 'tech4',
      likes: 88,
    ),
  ];

  void _toggleLike(int index) {
    setState(() {
      final p = posts[index];
      if (p.liked) {
        p.liked = false;
        p.likes = (p.likes - 1).clamp(0, 999999);
      } else {
        p.liked = true;
        p.likes = p.likes + 1;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar()),
            SliverToBoxAdapter(
              child: Divider(
                color: accent.withOpacity(0.9),
                thickness: 3,
                indent: 12,
                endIndent: 12,
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 18,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Create post tapped')),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'CREATE POST',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Tech Feed',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            SliverToBoxAdapter(child: const SizedBox(height: 12)),
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) => _buildPostCard(context, index),
                childCount: posts.length,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostCard(BuildContext context, int index) {
    final post = posts[index];
    final largeImage = index == 0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: accent, width: 2),
          color: const Color(0xFF1A1A1A),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                height: largeImage ? 180 : 150,
                width: double.infinity,
                child: Image.network(
                  'https://picsum.photos/seed/${post.imageSeed}/800/400',
                  fit: BoxFit.cover,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleLike(index),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: post.liked
                                  ? Colors.red[700]
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accent.withOpacity(0.6),
                              ),
                            ),
                            child: Icon(
                              post.liked
                                  ? Icons.favorite
                                  : Icons.favorite_border,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${post.likes}',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        _iconBox(Icons.crop_square),
                        const SizedBox(width: 8),
                        _iconBox(Icons.repeat),
                        const Spacer(),
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.brown[700],
                            shape: BoxShape.circle,
                            border: Border.all(color: accent, width: 2),
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
      ),
    );
  }

  Widget _iconBox(IconData icon) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A2A),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: accent.withOpacity(0.6)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _TopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? '';
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Text(
              'Tech Community',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
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
                      initials.isNotEmpty ? initials : 'GX',
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.w900,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
