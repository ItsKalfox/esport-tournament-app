import '../models/product.dart';

class CartItem {
  final ProductModel product;
  final Map<String, String> selectedVariants;
  int quantity;

  CartItem({
    required this.product,
    required this.quantity,
    this.selectedVariants = const {},
  });

  double get subtotal => product.price * quantity;

  // Unique key based on product id + variant combo
  String get key {
    if (selectedVariants.isEmpty) return product.id;
    final variantKey = selectedVariants.entries
        .map((e) => '${e.key}:${e.value}')
        .join('|');
    return '${product.id}_$variantKey';
  }
}
