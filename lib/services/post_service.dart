import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/post.dart';

class PostService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<List<Post>> getPosts() async {
    final snapshot = await _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .get();
    
    return snapshot.docs
        .map((doc) => Post.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Stream<QuerySnapshot> getPostsStream() {
    return _firestore
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createPost({
    required List<String> imageUrls,
    String? caption,
    String? feeling,
    List<String>? taggedUsers,
  }) async {
    final user = _auth.currentUser;
    final name = user?.displayName ?? 'Anonymous';
    final initials = name.split(' ').take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    final docRef = await _firestore.collection('posts').add({
      'userId': user?.uid,
      'userName': name,
      'userInitials': initials.isNotEmpty ? initials : 'GX',
      'userAvatar': user?.photoURL ?? '',
      'caption': caption ?? '',
      'imageUrls': imageUrls,
      'feeling': feeling ?? '',
      'taggedUsers': taggedUsers ?? [],
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'likers': <String>[],
    });

    return docRef.id;
  }

  Future<void> likePost(String postId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final docRef = _firestore.collection('posts').doc(postId);
    final doc = await docRef.get();
    if (!doc.exists) return;

    final currentLikers = (doc.data()?['likers'] as List<dynamic>?)?.cast<String>() ?? [];
    final userId = user.uid;
    final isLiked = currentLikers.contains(userId);

    await docRef.update({
      'likeCount': isLiked ? FieldValue.increment(-1) : FieldValue.increment(1),
      'likers': isLiked 
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
    });
  }

  Future<void> addComment(String postId, String text) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = user.displayName ?? 'Anonymous';
    final initials = name.split(' ').take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    await _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .add({
      'userId': user.uid,
      'userName': name,
      'userInitials': initials.isNotEmpty ? initials : 'GX',
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getCommentsStream(String postId) {
    return _firestore
        .collection('posts')
        .doc(postId)
        .collection('comments')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> repost(Post originalPost) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = user.displayName ?? 'Anonymous';
    final initials = name.split(' ').take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    await _firestore.collection('posts').add({
      'userId': user.uid,
      'userName': name,
      'userInitials': initials.isNotEmpty ? initials : 'GX',
      'userAvatar': user.photoURL ?? '',
      'caption': originalPost.caption ?? '',
      'imageUrls': originalPost.imageUrls,
      'feeling': originalPost.feeling ?? '',
      'taggedUsers': originalPost.taggedUsers,
      'repostedFrom': originalPost.userName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'likeCount': 0,
      'likers': <String>[],
    });
  }
}