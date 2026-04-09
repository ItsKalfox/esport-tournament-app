import 'package:flutter/foundation.dart';
import '../models/post.dart';
import '../services/post_service.dart';

class TechCommunityProvider extends ChangeNotifier {
  final PostService _postService = PostService();
  
  List<Post> _posts = [];
  bool _isLoading = false;
  String? _error;
  final Set<String> _repostedPosts = {};

  List<Post> get posts => _posts;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Set<String> get repostedPosts => _repostedPosts;

  Future<void> loadPosts() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _posts = await _postService.getPosts();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> likePost(String postId) async {
    try {
      await _postService.likePost(postId);
      await loadPosts();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> addComment(String postId, String text) async {
    try {
      await _postService.addComment(postId, text);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> repost(Post post) async {
    try {
      await _postService.repost(post);
      _repostedPosts.add(post.id);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  bool isPostLiked(String postId) {
    final post = _posts.firstWhere(
      (p) => p.id == postId,
      orElse: () => Post(),
    );
    final userId = post.userId;
    return post.likers.contains(userId);
  }

  bool isPostReposted(String postId) {
    return _repostedPosts.contains(postId);
  }
}