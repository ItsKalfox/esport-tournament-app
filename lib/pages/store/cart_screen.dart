import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';
import '../../models/cart_item.dart';
import 'checkout_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  String _fmt(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Consumer<CartProvider>(
          builder: (context, cart, _) {
            return Column(
              children: [
                // ── Top bar ─────────────────────────────────────────────
                _TopBar(itemCount: cart.itemCount),

                // ── Content ─────────────────────────────────────────────
                Expanded(
                  child: cart.isEmpty
                      ? _EmptyCart()
                      : Column(
                          children: [
                            // Cart items list
                            Expanded(
                              child: ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  14,
                                  8,
                                  14,
                                  16,
                                ),
                                itemCount: cart.items.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) => _CartItemCard(
                                  item: cart.items[i],
                                  onRemove: () =>
                                      cart.removeItem(cart.items[i].key),
                                  onQtyChange: (q) =>
                                      cart.updateQuantity(cart.items[i].key, q),
                                ),
                              ),
                            ),

                            // Order summary
                            _OrderSummary(cart: cart),
                          ],
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Top Bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  final int itemCount;
  const _TopBar({required this.itemCount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 16, 10),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Centered title
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'My Cart',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (itemCount > 0) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0A500),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$itemCount',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
          // Back button left
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
                size: 18,
              ),
            ),
          ),
          // Clear all right
          if (itemCount > 0)
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _confirmClear(context),
                child: const Text(
                  'Clear',
                  style: TextStyle(color: Color(0xFFff4444), fontSize: 13),
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Clear Cart',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'Remove all items from your cart?',
          style: TextStyle(color: Color(0xFF999999), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () {
              context.read<CartProvider>().clear();
              Navigator.pop(context);
            },
            child: const Text(
              'Clear',
              style: TextStyle(color: Color(0xFFff4444)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Cart Item Card ────────────────────────────────────────────────────────────
class _CartItemCard extends StatelessWidget {
  final CartItem item;
  final VoidCallback onRemove;
  final ValueChanged<int> onQtyChange;

  const _CartItemCard({
    required this.item,
    required this.onRemove,
    required this.onQtyChange,
  });

  String _fmt(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final product = item.product;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2200)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                width: 80,
                height: 80,
                color: const Color(0xFF1A1200),
                child: product.primaryImage.isNotEmpty
                    ? Image.network(
                        product.primaryImage,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.devices_other_outlined,
                          color: Color(0xFF333333),
                          size: 32,
                        ),
                      )
                    : const Icon(
                        Icons.devices_other_outlined,
                        color: Color(0xFF333333),
                        size: 32,
                      ),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name + remove button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          product.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            height: 1.3,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2A0A0A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF4A1A1A)),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFFff4444),
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // Variants
                  if (item.selectedVariants.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      children: item.selectedVariants.entries
                          .map(
                            (e) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A1A1A),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(
                                  color: const Color(0xFF2A2A2A),
                                ),
                              ),
                              child: Text(
                                '${e.key}: ${e.value}',
                                style: const TextStyle(
                                  color: Color(0xFF888888),
                                  fontSize: 10,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Price + quantity row
                  Row(
                    children: [
                      // Price
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _fmt(item.subtotal),
                              style: const TextStyle(
                                color: Color(0xFFF0A500),
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            if (item.quantity > 1)
                              Text(
                                '${_fmt(product.price)} each',
                                style: const TextStyle(
                                  color: Color(0xFF555555),
                                  fontSize: 10,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Quantity controls
                      Row(
                        children: [
                          _QtyBtn(
                            icon: Icons.remove,
                            enabled: item.quantity > 1,
                            onTap: () => onQtyChange(item.quantity - 1),
                          ),
                          Container(
                            width: 36,
                            height: 32,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              border: Border.symmetric(
                                vertical: BorderSide(color: Color(0xFF2A2A2A)),
                              ),
                            ),
                            child: Text(
                              '${item.quantity}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _QtyBtn(
                            icon: Icons.add,
                            enabled: item.quantity < product.stock,
                            onTap: () => onQtyChange(item.quantity + 1),
                          ),
                        ],
                      ),
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
}

// ── Order Summary ─────────────────────────────────────────────────────────────
class _OrderSummary extends StatelessWidget {
  final CartProvider cart;
  const _OrderSummary({required this.cart});

  String _fmt(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).padding.bottom + 16,
      ),
      child: Column(
        children: [
          // Summary rows
          _SummaryRow(
            label: 'Subtotal (${cart.itemCount} items)',
            value: _fmt(cart.subtotal),
          ),
          const SizedBox(height: 6),
          _SummaryRow(
            label: 'Delivery',
            value: cart.deliveryFee == 0 ? 'Free' : _fmt(cart.deliveryFee),
            valueColor: cart.deliveryFee == 0 ? const Color(0xFF4caf50) : null,
          ),
          if (cart.deliveryFee == 0) ...[
            const SizedBox(height: 4),
            const Row(
              children: [
                Icon(Icons.check_circle, color: Color(0xFF4caf50), size: 12),
                SizedBox(width: 4),
                Text(
                  'Free delivery on orders over LKR 10,000',
                  style: TextStyle(color: Color(0xFF4caf50), fontSize: 10),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(
                  Icons.info_outline,
                  color: Color(0xFF555555),
                  size: 12,
                ),
                const SizedBox(width: 4),
                Text(
                  'Add LKR ${_fmt(10000 - cart.subtotal)} more for free delivery',
                  style: const TextStyle(
                    color: Color(0xFF555555),
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(color: Color(0xFF1E1E1E)),
          ),
          // Total
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                _fmt(cart.total),
                style: const TextStyle(
                  color: Color(0xFFF0A500),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Checkout button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CheckoutScreen()),
              );
            },
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFF0A500),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.shopping_bag_outlined,
                    color: Colors.black,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Checkout · ${_fmt(cart.total)}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Empty Cart ────────────────────────────────────────────────────────────────
class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.shopping_cart_outlined,
            color: Color(0xFF222222),
            size: 72,
          ),
          const SizedBox(height: 16),
          const Text(
            'Your cart is empty',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add products to get started',
            style: TextStyle(color: Color(0xFF444444), fontSize: 13),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFF0A500)),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Browse Store',
                style: TextStyle(
                  color: Color(0xFFF0A500),
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _SummaryRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF777777), fontSize: 13),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _QtyBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: enabled ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFFF0A500) : const Color(0xFF333333),
          size: 16,
        ),
      ),
    );
  }
}
