import 'package:flutter/material.dart';
import '../models/product.dart';

class FeaturedProductCard extends StatelessWidget {
  final ProductModel product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  const FeaturedProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2200), width: 1),
        ),
        child: Row(
          children: [
            // Product image
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                bottomLeft: Radius.circular(12),
              ),
              child: SizedBox(
                width: 110,
                height: 110,
                child: product.imageUrl.isNotEmpty
                    ? Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _placeholder(product.categoryId),
                      )
                    : _placeholder(product.categoryId),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 12,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'LKR ${_formatPrice(product.price)}',
                      style: const TextStyle(
                        color: Color(0xFFF0A500),
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      product.inStock
                          ? (product.isLowStock
                                ? 'Only ${product.stock} left'
                                : 'In stock · ${product.stock} units')
                          : 'Out of stock',
                      style: TextStyle(
                        color: product.isLowStock
                            ? const Color(0xFFCC4400)
                            : const Color(0xFF666666),
                        fontSize: 10,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: product.inStock ? onAddToCart : null,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: product.inStock
                                ? const Color(0xFFC8860A)
                                : const Color(0xFF444444),
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(
                          product.inStock ? '+ Add to Cart' : 'Unavailable',
                          style: TextStyle(
                            color: product.inStock
                                ? const Color(0xFFC8860A)
                                : const Color(0xFF666666),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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

  Widget _placeholder(String category) {
    final icons = {
      'monitors': Icons.monitor,
      'gpus': Icons.memory,
      'peripherals': Icons.keyboard,
      'pcs': Icons.computer,
      'headsets': Icons.headset,
      'merch': Icons.checkroom,
    };

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A1200), Color(0xFF2A1800)],
        ),
      ),
      child: Icon(
        icons[category] ?? Icons.devices_other,
        size: 48,
        color: const Color(0xFFC8860A),
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
