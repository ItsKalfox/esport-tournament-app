import 'package:flutter/material.dart';
import '../models/product.dart';
import '../widgets/wishlist_button.dart';

class ProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;

  const ProductCard({super.key, required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 152,
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2200), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image area
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: SizedBox(
                    height: 104,
                    width: double.infinity,
                    child: product.primaryImage.isNotEmpty
                        ? Image.network(
                            product.primaryImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _ProductPlaceholder(
                              category: product.categoryId,
                            ),
                          )
                        : _ProductPlaceholder(category: product.categoryId),
                  ),
                ),
                // Sale tag
                if (product.saleTag != null)
                  Positioned(
                    top: 7,
                    left: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: product.saleTag == 'New'
                            ? const Color(0xFF4A8AFF)
                            : const Color(0xFFC8860A),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        product.saleTag!,
                        style: TextStyle(
                          color: product.saleTag == 'New'
                              ? Colors.white
                              : Colors.black,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                // Low stock badge
                if (product.isLowStock)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC2200),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        'Only ${product.stock} left',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                // Wishlist button
                Positioned(
                  bottom: 7,
                  right: 7,
                  child: WishlistButton(product: product, size: 14),
                ),
                // Out of stock overlay
                if (!product.inStock)
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: const Text(
                          'OUT OF STOCK',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 11,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'LKR ${_formatPrice(product.price)}',
                        style: const TextStyle(
                          color: Color(0xFFF0A500),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: 4),
                        Text(
                          'LKR ${_formatPrice(product.originalPrice!)}',
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 10,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
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

  String _formatPrice(double price) {
    return price
        .toStringAsFixed(0)
        .replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},',
        );
  }
}

class _ProductPlaceholder extends StatelessWidget {
  final String category;
  const _ProductPlaceholder({required this.category});

  IconData get _icon {
    switch (category) {
      case 'monitors':
        return Icons.monitor;
      case 'gpus':
        return Icons.memory;
      case 'peripherals':
        return Icons.keyboard;
      case 'pcs':
        return Icons.computer;
      case 'headsets':
        return Icons.headset;
      case 'merch':
        return Icons.checkroom;
      default:
        return Icons.devices_other;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1200), Color(0xFF2A1800)],
        ),
      ),
      child: Icon(_icon, size: 48, color: const Color(0xFFC8860A)),
    );
  }
}
