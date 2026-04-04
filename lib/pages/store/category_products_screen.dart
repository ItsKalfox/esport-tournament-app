import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../models/product.dart';
import '../../services/store_service.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/wishlist_button.dart';
import 'package:provider/provider.dart';
import 'product_detail_screen.dart';

class CategoryProductsScreen extends StatefulWidget {
  final CategoryModel category;
  const CategoryProductsScreen({super.key, required this.category});

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _search = '';
  String _sortBy = 'name';

  Color get _catColor {
    try {
      final h = (widget.category.color ?? '#F0A500').replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFFF0A500);
    }
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductModel> _filter(List<ProductModel> products) {
    var list = products.where((p) {
      return _search.isEmpty ||
          p.name.toLowerCase().contains(_search.toLowerCase());
    }).toList();
    switch (_sortBy) {
      case 'price_asc':
        list.sort((a, b) => a.price.compareTo(b.price));
        break;
      case 'price_desc':
        list.sort((a, b) => b.price.compareTo(a.price));
        break;
      default:
        list.sort((a, b) => a.name.compareTo(b.name));
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final color = _catColor;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(color),
            _buildSearchBar(color),
            Expanded(
              child: StreamBuilder<List<ProductModel>>(
                stream: StoreService().getProductsByCategory(
                  widget.category.id,
                ),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: color,
                        strokeWidth: 2,
                      ),
                    );
                  }
                  final all = snap.data ?? [];
                  final products = _filter(all);
                  if (products.isEmpty) return _buildEmpty(color);
                  return GridView.builder(
                    padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, i) =>
                        _ProductCard(product: products[i], catColor: color),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(Color color) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0D0D0D),
        border: Border(
          bottom: BorderSide(color: color.withOpacity(0.3), width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: Colors.white,
              size: 18,
            ),
          ),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: color.withOpacity(0.4), width: 1),
            ),
            child: Icon(
              _mapIcon(widget.category.iconId),
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (widget.category.description != null &&
                    widget.category.description!.isNotEmpty)
                  Text(
                    widget.category.description!,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2A2A)),
              ),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => setState(() => _search = v),
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  hintText: 'Search in ${widget.category.name}...',
                  hintStyle: const TextStyle(
                    color: Color(0xFF444444),
                    fontSize: 13,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    color: Color(0xFF555555),
                    size: 18,
                  ),
                  suffixIcon: _search.isNotEmpty
                      ? GestureDetector(
                          onTap: () {
                            _searchCtrl.clear();
                            setState(() => _search = '');
                          },
                          child: const Icon(
                            Icons.close,
                            color: Color(0xFF555555),
                            size: 16,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _sortBy = v),
            color: const Color(0xFF1A1A1A),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
              side: const BorderSide(color: Color(0xFF2A2A2A)),
            ),
            itemBuilder: (_) => [
              _sortItem('name', 'Name A-Z', _sortBy),
              _sortItem('price_asc', 'Price: Low to High', _sortBy),
              _sortItem('price_desc', 'Price: High to Low', _sortBy),
            ],
            child: Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: _sortBy != 'name'
                      ? color.withOpacity(0.5)
                      : const Color(0xFF2A2A2A),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.sort,
                    color: _sortBy != 'name' ? color : const Color(0xFF555555),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _sortLabel(_sortBy),
                    style: TextStyle(
                      color: _sortBy != 'name'
                          ? color
                          : const Color(0xFF777777),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
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

  PopupMenuItem<String> _sortItem(String value, String label, String current) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(
            current == value
                ? Icons.radio_button_checked
                : Icons.radio_button_unchecked,
            color: current == value
                ? const Color(0xFFF0A500)
                : const Color(0xFF555555),
            size: 16,
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: current == value ? const Color(0xFFF0A500) : Colors.white,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  String _sortLabel(String val) {
    switch (val) {
      case 'price_asc':
        return 'Price ↑';
      case 'price_desc':
        return 'Price ↓';
      default:
        return 'Name';
    }
  }

  Widget _buildEmpty(Color color) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            color: color.withOpacity(0.2),
            size: 64,
          ),
          const SizedBox(height: 16),
          Text(
            _search.isNotEmpty
                ? 'No results for "$_search"'
                : 'No products yet in\n${widget.category.name}',
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (_search.isNotEmpty) ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() => _search = '');
              },
              child: Text(
                'Clear search',
                style: TextStyle(
                  color: color,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _mapIcon(String? id) {
    const map = {
      'cpu': Icons.memory,
      'gpu': Icons.developer_board,
      'ram': Icons.storage,
      'motherboard': Icons.dashboard_outlined,
      'storage': Icons.save_outlined,
      'ssd': Icons.sd_card_outlined,
      'psu': Icons.bolt,
      'cooling': Icons.ac_unit,
      'case': Icons.computer,
      'monitor': Icons.monitor,
      'keyboard': Icons.keyboard,
      'mouse': Icons.mouse,
      'headset': Icons.headset,
      'controller': Icons.sports_esports,
      'webcam': Icons.videocam_outlined,
      'microphone': Icons.mic_outlined,
      'gamepad': Icons.sports_esports_outlined,
      'chair': Icons.chair_outlined,
      'desk': Icons.desk,
      'tshirt': Icons.checkroom,
      'cap': Icons.face_outlined,
      'bag': Icons.shopping_bag_outlined,
      'router': Icons.router_outlined,
      'lightning': Icons.flash_on,
    };
    return map[id] ?? Icons.category_outlined;
  }
}

// ── Product Card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final ProductModel product;
  final Color catColor;

  const _ProductCard({required this.product, required this.catColor});

  String _formatPrice(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ProductDetailScreen(product: product),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2200), width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                  child: Container(
                    height: 130,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          catColor.withOpacity(0.1),
                          const Color(0xFF1A1200),
                        ],
                      ),
                    ),
                    child: product.primaryImage.isNotEmpty
                        ? Image.network(
                            product.primaryImage,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                if (product.saleTag != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: product.saleTag == 'New'
                            ? const Color(0xFF4A8AFF)
                            : const Color(0xFFC8860A),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        product.saleTag!,
                        style: TextStyle(
                          color: product.saleTag == 'New'
                              ? Colors.white
                              : Colors.black,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                if (product.isLowStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFCC2200),
                        borderRadius: BorderRadius.circular(4),
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
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF444444)),
                          ),
                          child: const Text(
                            'OUT OF STOCK',
                            style: TextStyle(
                              color: Color(0xFF888888),
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
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
                    const Spacer(),
                    Text(
                      _formatPrice(product.price),
                      style: const TextStyle(
                        color: Color(0xFFF0A500),
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (product.originalPrice != null) ...[
                      const SizedBox(height: 1),
                      Text(
                        _formatPrice(product.originalPrice!),
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 10,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    // Add to cart
                    GestureDetector(
                      onTap: product.inStock
                          ? () {
                              context.read<CartProvider>().addItem(product);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    '${product.name} added to cart!',
                                  ),
                                  backgroundColor: const Color(0xFFC8860A),
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          : null,
                      child: Container(
                        width: double.infinity,
                        height: 30,
                        decoration: BoxDecoration(
                          color: product.inStock
                              ? catColor.withOpacity(0.12)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: product.inStock
                                ? catColor.withOpacity(0.4)
                                : const Color(0xFF2A2A2A),
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          product.inStock ? '+ Add to Cart' : 'Unavailable',
                          style: TextStyle(
                            color: product.inStock
                                ? catColor
                                : const Color(0xFF444444),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
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

  Widget _placeholder() {
    return Container(
      alignment: Alignment.center,
      child: Icon(
        Icons.devices_other_outlined,
        color: catColor.withOpacity(0.25),
        size: 40,
      ),
    );
  }
}
