import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store_banner.dart';
import '../models/product.dart';
import '../models/category_model.dart';

class StoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ─── Categories ───────────────────────────────────────────────────────────
  Stream<List<CategoryModel>> getCategories() {
    return _db
        .collection('categories')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => CategoryModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  // ─── Banners ──────────────────────────────────────────────────────────────
  Stream<List<BannerModel>> getBanners() {
    return _db
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order')
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => BannerModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  // ─── Products ─────────────────────────────────────────────────────────────
  Stream<List<ProductModel>> getSpecialOffers() {
    return _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('isOnSale', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<ProductModel>> getFeaturedProducts() {
    return _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('isFeatured', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<ProductModel>> getHighlightedProducts() {
    return _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('isHighlighted', isEqualTo: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  // ← uses 'categoryId' to match what admin panel saves
  Stream<List<ProductModel>> getProductsByCategory(String categoryId) {
    return _db
        .collection('products')
        .where('isActive', isEqualTo: true)
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => ProductModel.fromFirestore(d.data(), d.id))
              .toList(),
        );
  }

  Stream<List<ProductModel>> getAllProducts({String? categoryId}) {
    Query query = _db.collection('products').where('isActive', isEqualTo: true);
    if (categoryId != null && categoryId != 'all') {
      query = query.where('categoryId', isEqualTo: categoryId);
    }
    return query.snapshots().map(
      (snap) => snap.docs
          .map(
            (d) => ProductModel.fromFirestore(
              d.data() as Map<String, dynamic>,
              d.id,
            ),
          )
          .toList(),
    );
  }

  // ─── Stock ────────────────────────────────────────────────────────────────
  Future<void> decrementStock(String productId, int quantity) async {
    await _db.collection('products').doc(productId).update({
      'stock': FieldValue.increment(-quantity),
    });
  }

  Stream<int> watchStock(String productId) {
    return _db
        .collection('products')
        .doc(productId)
        .snapshots()
        .map((snap) => (snap.data()?['stock'] ?? 0) as int);
  }
}
