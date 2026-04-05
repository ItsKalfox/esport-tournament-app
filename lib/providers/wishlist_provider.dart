import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product.dart';

class WishlistProvider extends ChangeNotifier {
  final List<ProductModel> _items = [];
  bool _loading = false;

  List<ProductModel> get items => List.unmodifiable(_items);
  bool get isEmpty => _items.isEmpty;
  bool get isLoading => _loading;
  int get count => _items.length;

  // Check if product is wishlisted
  bool isWishlisted(String productId) => _items.any((p) => p.id == productId);

  // Load wishlist from Firestore
  Future<void> loadWishlist() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _loading = true;
    notifyListeners();

    try {
      final snap = await FirebaseFirestore.instance
          .collection('wishlists')
          .doc(user.uid)
          .collection('items')
          .get();

      _items.clear();
      for (final doc in snap.docs) {
        final data = doc.data();
        // Re-fetch product from Firestore to get latest price/stock
        final productSnap = await FirebaseFirestore.instance
            .collection('products')
            .doc(doc.id)
            .get();
        if (productSnap.exists) {
          _items.add(
            ProductModel.fromFirestore(productSnap.data()!, productSnap.id),
          );
        }
      }
    } catch (e) {
      debugPrint('Error loading wishlist: $e');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  // Toggle wishlist (add/remove)
  Future<void> toggle(ProductModel product) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final ref = FirebaseFirestore.instance
        .collection('wishlists')
        .doc(user.uid)
        .collection('items')
        .doc(product.id);

    if (isWishlisted(product.id)) {
      _items.removeWhere((p) => p.id == product.id);
      notifyListeners();
      await ref.delete();
    } else {
      _items.add(product);
      notifyListeners();
      await ref.set({
        'productId': product.id,
        'name': product.name,
        'addedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }
}
