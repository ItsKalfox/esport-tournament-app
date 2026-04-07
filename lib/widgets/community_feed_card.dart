import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class CommunityFeedCard extends StatelessWidget {
  final String caption;
  final String userName;
  final String userAvatar;
  final String userInitials;
  final String imagePath;
  final int likeCount;
  final VoidCallback onTap;

  const CommunityFeedCard({
    super.key,
    required this.caption,
    required this.userName,
    required this.userAvatar,
    required this.userInitials,
    required this.imagePath,
    required this.likeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkGrey),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: imagePath.isNotEmpty
                  ? Image.network(
                      imagePath,
                      height: 90,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imgPlaceholder(),
                    )
                  : _imgPlaceholder(),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    caption,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    CircleAvatar(
                      radius: 10,
                      backgroundColor: AppColors.primaryOrange,
                      backgroundImage: userAvatar.isNotEmpty
                          ? NetworkImage(userAvatar)
                          : null,
                      child: userAvatar.isEmpty
                          ? Text(
                              userInitials.isNotEmpty ? userInitials[0] : '?',
                              style: const TextStyle(fontSize: 8, color: AppColors.white),
                            )
                          : null,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        userName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.grey, fontSize: 9),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.thumb_up_outlined,
                        color: AppColors.primaryOrange, size: 13),
                    const SizedBox(width: 3),
                    Text('$likeCount',
                        style: const TextStyle(color: AppColors.grey, fontSize: 10)),
                    const SizedBox(width: 8),
                    const Icon(Icons.comment_outlined, color: AppColors.grey, size: 13),
                    const SizedBox(width: 8),
                    const Icon(Icons.share_outlined, color: AppColors.grey, size: 13),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imgPlaceholder() {
    return Container(
      height: 90,
      color: AppColors.darkGrey,
      child: const Icon(Icons.image, color: AppColors.primaryOrange, size: 36),
    );
  }
}
