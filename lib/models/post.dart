class Post {
  final String id;
  final String? userId;
  final String? userName;
  final String? userInitials;
  final String? userAvatar;
  final String? caption;
  final List<String> imageUrls;
  final String? feeling;
  final List<String> taggedUsers;
  final String? repostedFrom;
  final DateTime? createdAt;
  int likes;
  bool liked;
  int likeCount;
  List<String> likers;

  Post({
    this.id = '',
    this.userId,
    this.userName,
    this.userInitials,
    this.userAvatar,
    this.caption,
    this.imageUrls = const [],
    this.feeling,
    this.taggedUsers = const [],
    this.repostedFrom,
    this.createdAt,
    this.likes = 0,
    this.liked = false,
    this.likeCount = 0,
    this.likers = const [],
  });

  factory Post.fromFirestore(Map<String, dynamic> data, String docId) {
    return Post(
      id: docId,
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      userInitials: data['userInitials'] as String? ?? 'GX',
      userAvatar: data['userAvatar'] as String?,
      caption: data['caption'] as String?,
      imageUrls: (data['imageUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      feeling: data['feeling'] as String?,
      taggedUsers: (data['taggedUsers'] as List<dynamic>?)?.cast<String>() ?? [],
      repostedFrom: data['repostedFrom'] as String?,
      createdAt: data['createdAt'] != null 
        ? DateTime.tryParse(data['createdAt'].toString())
        : null,
      likeCount: data['likeCount'] as int? ?? 0,
      likers: (data['likers'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'userInitials': userInitials,
      'userAvatar': userAvatar,
      'caption': caption,
      'imageUrls': imageUrls,
      'feeling': feeling,
      'taggedUsers': taggedUsers,
      'repostedFrom': repostedFrom,
      'createdAt': createdAt?.toIso8601String(),
      'likeCount': likeCount,
      'likers': likers,
    };
  }
}

class Comment {
  final String? userId;
  final String? userName;
  final String? userInitials;
  final String? text;
  final DateTime? createdAt;

  Comment({
    this.userId,
    this.userName,
    this.userInitials,
    this.text,
    this.createdAt,
  });

  factory Comment.fromFirestore(Map<String, dynamic> data) {
    return Comment(
      userId: data['userId'] as String?,
      userName: data['userName'] as String?,
      userInitials: data['userInitials'] as String? ?? 'GX',
      text: data['text'] as String?,
      createdAt: data['createdAt'] != null 
        ? DateTime.tryParse(data['createdAt'].toString())
        : null,
    );
  }
}