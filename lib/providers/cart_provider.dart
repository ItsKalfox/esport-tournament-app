import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/product.dart';

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => List.unmodifiable(_items);

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  bool get isEmpty => _items.isEmpty;

  double get subtotal => _items.fold(0, (sum, item) => sum + item.subtotal);

  double get deliveryFee => subtotal > 10000 ? 0 : 350;

  double get total => subtotal + deliveryFee;

  // Add product to cart
  void addItem(
    ProductModel product, {
    int quantity = 1,
    Map<String, String> variants = const {},
  }) {
    final tempItem = CartItem(
      product: product,
      quantity: quantity,
      selectedVariants: variants,
    );

    final existing = _items.indexWhere((i) => i.key == tempItem.key);
    if (existing != -1) {
      // Already in cart — increase quantity capped at stock
      final newQty = (_items[existing].quantity + quantity).clamp(
        1,
        product.stock,
      );
      _items[existing].quantity = newQty;
    } else {
      _items.add(tempItem);
    }
    notifyListeners();
  }

  void removeItem(String key) {
    _items.removeWhere((i) => i.key == key);
    notifyListeners();
  }

  void updateQuantity(String key, int quantity) {
    final index = _items.indexWhere((i) => i.key == key);
    if (index == -1) return;
    if (quantity <= 0) {
      _items.removeAt(index);
    } else {
      _items[index].quantity = quantity.clamp(1, _items[index].product.stock);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  bool containsProduct(String productId) =>
      _items.any((i) => i.product.id == productId);
}
