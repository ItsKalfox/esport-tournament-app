import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'create_post_screen.dart';

class Post {
  final String id;
  final String title;
  final String imageSeed;
  int likes;
  bool liked;
  final String? asset;

  Post({
    required this.id,
    required this.title,
    required this.imageSeed,
    this.likes = 0,
    this.liked = false,
    this.asset,
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
      asset: 'assets/images/gpu.jpg',
    ),
    Post(
      id: '4',
      title: 'Top 10 Developer Tools in 2026',
      imageSeed: 'tech4',
      likes: 88,
      asset: 'assets/images/devtools.jpg',
    ),
  ];

  Map<String, bool> _likedPosts = {};
  Map<String, int> _likeCounts = {};
  Map<String, List<Map<String, dynamic>>> _comments = {};
  final Set<String> _repostedPosts = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<Post> _filteredLocalPosts() {
    if (_searchQuery.trim().isEmpty) return posts;
    final q = _searchQuery.toLowerCase();
    return posts.where((p) => p.title.toLowerCase().contains(q)).toList();
  }

  List<DocumentSnapshot> _filteredFirestorePosts(List<DocumentSnapshot> docs) {
    if (_searchQuery.trim().isEmpty) return docs;
    final q = _searchQuery.toLowerCase();
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final caption = (data['caption'] as String?) ?? '';
      final userName = (data['userName'] as String?) ?? '';
      final feeling = (data['feeling'] as String?) ?? '';
      final repostedFrom = (data['repostedFrom'] as String?) ?? '';
      final composite = '$caption $userName $feeling $repostedFrom'
          .toLowerCase();
      return composite.contains(q);
    }).toList();
  }

  void _openSearch() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1A1A1A),
          content: TextField(
            controller: _searchController,
            autofocus: true,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search posts, users, captions...',
              hintStyle: TextStyle(color: Colors.grey[500]),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear, color: Colors.white),
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
              ),
            ),
            onChanged: (v) {
              setState(() {
                _searchQuery = v;
              });
            },
            onSubmitted: (_) => Navigator.of(context).pop(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleLike(String postId, int? index) async {
    if (index != null && index < posts.length) {
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
    } else {
      final docRef = FirebaseFirestore.instance.collection('posts').doc(postId);
      final doc = await docRef.get();
      if (doc.exists) {
        final currentLikes = (doc.data()?['likeCount'] as int?) ?? 0;
        final currentLikers = (doc.data()?['likers'] as List<dynamic>?) ?? [];
        final userId = FirebaseAuth.instance.currentUser?.uid ?? '';

        final isLiked = currentLikers.contains(userId);

        await docRef.update({
          'likeCount': isLiked ? currentLikes - 1 : currentLikes + 1,
          'likers': isLiked
              ? FieldValue.arrayRemove([userId])
              : FieldValue.arrayUnion([userId]),
        });

        setState(() {
          _likedPosts[postId] = !isLiked;
          _likeCounts[postId] = isLiked ? currentLikes - 1 : currentLikes + 1;
        });
      }
    }
  }

  void _showComments(String postId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A1A),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => _CommentsSheet(
        postId: postId,
        comments: _comments[postId] ?? [],
        onCommentAdded: (comment) {
          setState(() {
            _comments[postId] = [...(_comments[postId] ?? []), comment];
          });
        },
      ),
    );
  }

  Future<void> _repost(String postId, Map<String, dynamic> postData) async {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Anonymous';
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    try {
      await FirebaseFirestore.instance.collection('posts').add({
        'userId': user?.uid,
        'userName': name,
        'userInitials': initials.isNotEmpty ? initials : 'GX',
        'userAvatar': user?.photoURL ?? '',
        'caption': postData['caption'] ?? '',
        'imageUrls': postData['imageUrls'] ?? [],
        'feeling': postData['feeling'] ?? '',
        'taggedUsers': postData['taggedUsers'] ?? [],
        'repostedFrom': postData['userName'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'likes': 0,
        'likeCount': 0,
        'likers': [],
      });

      setState(() {
        _repostedPosts.add(postId);
      });

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Post reposted!')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error reposting: $e')));
      }
    }
  }

  void _toggleLikeStatic(int index) {
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
            SliverToBoxAdapter(child: _TopBar(onSearch: _openSearch)),
            SliverToBoxAdapter(
              child: Divider(
                color: accent.withValues(alpha: 0.9),
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
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const CreatePostScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.edit, color: Colors.white),
                  label: const Text(
                    'CREATE POST',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
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
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(20),
                        child: CircularProgressIndicator(color: accent),
                      ),
                    ),
                  );
                }

                final firestorePosts = snapshot.data?.docs ?? [];

                final localFiltered = _filteredLocalPosts();
                final remoteFiltered = _filteredFirestorePosts(firestorePosts);

                return SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    if (index < localFiltered.length) {
                      final localIndex = posts.indexOf(localFiltered[index]);
                      return _buildPostCard(context, localIndex);
                    } else {
                      final postIndex = index - localFiltered.length;
                      if (postIndex < remoteFiltered.length) {
                        final postDoc = remoteFiltered[postIndex];
                        return _buildFirestorePostCard(context, postDoc);
                      }
                      return null;
                    }
                  }, childCount: localFiltered.length + remoteFiltered.length),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildFirestorePostCard(
    BuildContext context,
    DocumentSnapshot postDoc,
  ) {
    final data = postDoc.data() as Map<String, dynamic>;
    final postId = postDoc.id;
    final imageUrls = data['imageUrls'] as List<dynamic>? ?? [];
    final userInitials = data['userInitials'] as String? ?? 'GX';
    final userName = data['userName'] as String? ?? 'Anonymous';
    final caption = data['caption'] as String? ?? '';
    final feeling = data['feeling'] as String? ?? '';
    final taggedUsers = data['taggedUsers'] as List<dynamic>? ?? [];
    final repostedFrom = data['repostedFrom'] as String? ?? '';
    final likeCount = data['likeCount'] as int? ?? 0;
    final likers = data['likers'] as List<dynamic>? ?? [];

    final userId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isLiked = likers.contains(userId);
    final isReposted = _repostedPosts.contains(postId);

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
              if (repostedFrom.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                  child: Row(
                    children: [
                      const Icon(Icons.repeat, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Reposted from $repostedFrom',
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: accent, width: 2),
                      ),
                      child: Center(
                        child: Text(
                          userInitials,
                          style: const TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              if (imageUrls.isNotEmpty)
                SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: Image.network(
                    imageUrls.first as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      color: const Color(0xFF2A2A2A),
                      child: const Icon(
                        Icons.image,
                        color: Colors.grey,
                        size: 50,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (caption.isNotEmpty)
                      Text(
                        caption,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    if (feeling.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: accent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Feeling $feeling',
                          style: TextStyle(
                            color: accent,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (taggedUsers.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 4,
                        children: taggedUsers
                            .map(
                              (user) => Text(
                                '@$user',
                                style: TextStyle(
                                  color: Colors.blue[300],
                                  fontSize: 12,
                                ),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleLike(postId, null),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: isLiked
                                  ? Colors.red[700]
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.6),
                              ),
                            ),
                            child: Icon(
                              isLiked ? Icons.favorite : Icons.favorite_border,
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$likeCount',
                          style: const TextStyle(color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        GestureDetector(
                          onTap: () => _showComments(postId),
                          child: _iconBox(Icons.chat_bubble_outline),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: isReposted
                              ? null
                              : () => _repost(postId, data),
                          child: Icon(
                            Icons.repeat,
                            color: isReposted ? Colors.grey : Colors.white,
                            size: 20,
                          ),
                        ),
                        const Spacer(),
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
                child: post.asset != null
                    ? Image.asset(
                        post.asset!,
                        fit: BoxFit.cover,
                        errorBuilder: (c, e, st) => Image.network(
                          'https://picsum.photos/seed/${post.imageSeed}/800/400',
                          fit: BoxFit.cover,
                        ),
                      )
                    : index == 0
                    ? Image.asset(
                        'assets/images/cyberclash.jpg',
                        fit: BoxFit.cover,
                      )
                    : index == 1
                    ? Image.asset(
                        'assets/images/aisecret.jpg',
                        fit: BoxFit.cover,
                      )
                    : Image.network(
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
                          onTap: () => _toggleLikeStatic(index),
                          child: Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: post.liked
                                  ? Colors.red[700]
                                  : const Color(0xFF2A2A2A),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(
                                color: accent.withValues(alpha: 0.6),
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
        border: Border.all(color: accent.withValues(alpha: 0.6)),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    );
  }
}

class _TopBar extends StatelessWidget {
  final VoidCallback? onSearch;

  const _TopBar({this.onSearch});

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
                    onPressed: onSearch,
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

class _CommentsSheet extends StatefulWidget {
  final String postId;
  final List<Map<String, dynamic>> comments;
  final Function(Map<String, dynamic>) onCommentAdded;

  const _CommentsSheet({
    required this.postId,
    required this.comments,
    required this.onCommentAdded,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();

  Future<void> _addComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? 'Anonymous';
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    final comment = {
      'userId': user?.uid,
      'userName': name,
      'userInitials': initials.isNotEmpty ? initials : 'GX',
      'text': _commentController.text.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    };

    await FirebaseFirestore.instance
        .collection('posts')
        .doc(widget.postId)
        .collection('comments')
        .add(comment);

    widget.onCommentAdded(comment);
    _commentController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A1A),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  'Comments',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('posts')
                      .doc(widget.postId)
                      .collection('comments')
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    final comments = snapshot.data?.docs ?? [];

                    if (comments.isEmpty) {
                      return Center(
                        child: Text(
                          'No comments yet',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      itemCount: comments.length,
                      itemBuilder: (context, index) {
                        final comment =
                            comments[index].data() as Map<String, dynamic>;
                        return _buildCommentItem(comment);
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                  top: 8,
                ),
                decoration: const BoxDecoration(color: Color(0xFF2A2A2A)),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        style: const TextStyle(color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _addComment,
                      icon: const Icon(Icons.send, color: Color(0xFFFF8A00)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final initials = comment['userInitials'] as String? ?? 'GX';
    final userName = comment['userName'] as String? ?? 'Anonymous';
    final text = comment['text'] as String? ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  text,
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
