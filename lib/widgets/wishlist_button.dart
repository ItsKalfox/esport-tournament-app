import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/wishlist_provider.dart';
import '../models/product.dart';

class WishlistButton extends StatelessWidget {
  final ProductModel product;
  final double size;
  final bool showBackground;

  const WishlistButton({
    super.key,
    required this.product,
    this.size = 18,
    this.showBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<WishlistProvider>(
      builder: (context, wishlist, _) {
        final isWishlisted = wishlist.isWishlisted(product.id);
        return GestureDetector(
          onTap: () => wishlist.toggle(product),
          child: showBackground
              ? Container(
                  width: size + 16,
                  height: size + 16,
                  decoration: BoxDecoration(
                    color: isWishlisted
                        ? const Color(0xFF2A0A0A)
                        : Colors.black54,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isWishlisted
                          ? const Color(0xFFff4444)
                          : const Color(0xFF333333),
                    ),
                  ),
                  child: Icon(
                    isWishlisted ? Icons.favorite : Icons.favorite_border,
                    color: isWishlisted
                        ? const Color(0xFFff4444)
                        : Colors.white,
                    size: size,
                  ),
                )
              : Icon(
                  isWishlisted ? Icons.favorite : Icons.favorite_border,
                  color: isWishlisted
                      ? const Color(0xFFff4444)
                      : const Color(0xFF666666),
                  size: size,
                ),
        );
      },
    );
  }
}
