class ProductModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final double? originalPrice;
  final String categoryId;
  final int stock;
  final bool isActive;
  final bool isFeatured;
  final bool isHighlighted;
  final bool isOnSale;
  final String? saleTag;
  final double? discountPercent;
  final DateTime? offerEndsAt;
  final List<String> images;
  final List<Map<String, String>> specifications;
  final List<Map<String, dynamic>> variants;

  ProductModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    this.originalPrice,
    required this.categoryId,
    required this.stock,
    required this.isActive,
    required this.isFeatured,
    required this.isHighlighted,
    required this.isOnSale,
    this.saleTag,
    this.discountPercent,
    this.offerEndsAt,
    this.images = const [],
    this.specifications = const [],
    this.variants = const [],
  });

  bool get inStock => stock > 0;
  bool get isLowStock => stock > 0 && stock <= 5;

  String get primaryImage => images.isNotEmpty ? images[0] : imageUrl;

  factory ProductModel.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> imagesList = [];
    if (data['images'] is List) {
      imagesList = List<String>.from(
        (data['images'] as List).whereType<String>(),
      );
    }

    List<Map<String, String>> specs = [];
    if (data['specifications'] is List) {
      specs = (data['specifications'] as List)
          .whereType<Map>()
          .map(
            (s) => {
              'key': s['key']?.toString() ?? '',
              'value': s['value']?.toString() ?? '',
            },
          )
          .toList();
    }

    List<Map<String, dynamic>> variantsList = [];
    if (data['variants'] is List) {
      variantsList = (data['variants'] as List)
          .whereType<Map>()
          .map((v) => Map<String, dynamic>.from(v))
          .toList();
    }

    return ProductModel(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      price: (data['price'] ?? 0).toDouble(),
      originalPrice: data['originalPrice'] != null
          ? (data['originalPrice']).toDouble()
          : null,
      categoryId: data['categoryId'] ?? data['category'] ?? '',
      stock: data['stock'] ?? 0,
      isActive: data['isActive'] ?? true,
      isFeatured: data['isFeatured'] ?? false,
      isHighlighted: data['isHighlighted'] ?? false,
      isOnSale: data['isOnSale'] ?? false,
      saleTag: data['saleTag'],
      discountPercent: data['discountPercent'] != null
          ? (data['discountPercent']).toDouble()
          : null,
      offerEndsAt: data['offerEndsAt'] != null
          ? (data['offerEndsAt'] as dynamic).toDate()
          : null,
      images: imagesList,
      specifications: specs,
      variants: variantsList,
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'description': description,
    'imageUrl': imageUrl,
    'price': price,
    'originalPrice': originalPrice,
    'categoryId': categoryId,
    'stock': stock,
    'isActive': isActive,
    'isFeatured': isFeatured,
    'isHighlighted': isHighlighted,
    'isOnSale': isOnSale,
    'saleTag': saleTag,
    'discountPercent': discountPercent,
    'offerEndsAt': offerEndsAt,
    'images': images,
    'specifications': specifications,
    'variants': variants,
  };
}
