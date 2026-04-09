import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/store_service.dart';
import 'product_detail_screen.dart';

class StoreSearchScreen extends StatefulWidget {
  const StoreSearchScreen({super.key});

  @override
  State<StoreSearchScreen> createState() => _StoreSearchScreenState();
}

class _StoreSearchScreenState extends State<StoreSearchScreen> {
  final TextEditingController _ctrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  List<ProductModel> _allProducts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    StoreService().getAllProducts().first.then((products) {
      if (mounted)
        setState(() {
          _allProducts = products;
          _loading = false;
        });
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(_focusNode);
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  List<ProductModel> get _results {
    if (_query.isEmpty) return [];
    final q = _query.toLowerCase();
    return _allProducts
        .where(
          (p) =>
              p.name.toLowerCase().contains(q) ||
              p.description.toLowerCase().contains(q),
        )
        .toList();
  }

  String _formatPrice(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const SizedBox(
                      width: 38,
                      height: 46,
                      child: Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A1A1A),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _query.isNotEmpty
                              ? const Color(0xFFF0A500).withOpacity(0.4)
                              : const Color(0xFF2A2A2A),
                        ),
                      ),
                      child: TextField(
                        controller: _ctrl,
                        focusNode: _focusNode,
                        onChanged: (v) => setState(() => _query = v),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search products, brands...',
                          hintStyle: const TextStyle(
                            color: Color(0xFF444444),
                            fontSize: 14,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Color(0xFF555555),
                            size: 20,
                          ),
                          suffixIcon: _query.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _ctrl.clear();
                                    setState(() => _query = '');
                                  },
                                  child: const Icon(
                                    Icons.close,
                                    color: Color(0xFF555555),
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 14,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Result count
            if (_query.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 8),
                child: Row(
                  children: [
                    Text(
                      _loading
                          ? 'Searching...'
                          : '${results.length} result${results.length != 1 ? 's' : ''} for "$_query"',
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),

            // Content
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFF0A500),
                        strokeWidth: 2,
                      ),
                    )
                  : _query.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search,
                            color: Color(0xFF222222),
                            size: 64,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Search the store',
                            style: TextStyle(
                              color: Color(0xFF555555),
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '${_allProducts.length} products available',
                            style: const TextStyle(
                              color: Color(0xFF333333),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : results.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.search_off,
                            color: Color(0xFF222222),
                            size: 56,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No results for "$_query"',
                            style: const TextStyle(
                              color: Color(0xFF555555),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Try a different search term',
                            style: TextStyle(
                              color: Color(0xFF444444),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                      itemCount: results.length,
                      separatorBuilder: (_, __) =>
                          const Divider(color: Color(0xFF1A1A1A), height: 1),
                      itemBuilder: (context, i) => _SearchResultItem(
                        product: results[i],
                        query: _query,
                        formatPrice: _formatPrice,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SearchResultItem extends StatelessWidget {
  final ProductModel product;
  final String query;
  final String Function(double) formatPrice;

  const _SearchResultItem({
    required this.product,
    required this.query,
    required this.formatPrice,
  });

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
        padding: const EdgeInsets.symmetric(vertical: 12),
        color: Colors.transparent,
        child: Row(
          children: [
            // Thumbnail — uses imageUrl (single string)
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF2A2200)),
              ),
              child: product.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(
                          Icons.devices_other_outlined,
                          color: Color(0xFF333333),
                          size: 28,
                        ),
                      ),
                    )
                  : const Icon(
                      Icons.devices_other_outlined,
                      color: Color(0xFF333333),
                      size: 28,
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HighlightText(text: product.name, query: query),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(
                          color: Color(0xFFF0A500),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (product.originalPrice != null) ...[
                        const SizedBox(width: 6),
                        Text(
                          formatPrice(product.originalPrice!),
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (product.saleTag != null) ...[
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFC8860A),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            product.saleTag!,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                      ],
                      Text(
                        product.inStock
                            ? product.isLowStock
                                  ? 'Only ${product.stock} left'
                                  : 'In stock'
                            : 'Out of stock',
                        style: TextStyle(
                          color: product.inStock
                              ? product.isLowStock
                                    ? const Color(0xFFFF6600)
                                    : const Color(0xFF4caf50)
                              : const Color(0xFFff4444),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF333333), size: 18),
          ],
        ),
      ),
    );
  }
}

class _HighlightText extends StatelessWidget {
  final String text;
  final String query;
  const _HighlightText({required this.text, required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    final lower = text.toLowerCase();
    final qLower = query.toLowerCase();
    final index = lower.indexOf(qLower);
    if (index == -1) {
      return Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    return RichText(
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      text: TextSpan(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
        children: [
          TextSpan(text: text.substring(0, index)),
          TextSpan(
            text: text.substring(index, index + query.length),
            style: const TextStyle(
              color: Color(0xFFF0A500),
              fontWeight: FontWeight.w800,
            ),
          ),
          TextSpan(text: text.substring(index + query.length)),
        ],
      ),
    );
  }
}
