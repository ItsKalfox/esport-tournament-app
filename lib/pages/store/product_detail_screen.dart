import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../services/store_service.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;
  const ProductDetailScreen({super.key, required this.product});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final PageController _imageCtrl = PageController();
  int _currentImage = 0;
  int _quantity = 1;
  final Map<String, String> _selectedVariants = {};

  @override
  void initState() {
    super.initState();
    // Pre-select first option of each variant
    for (final v in widget.product.variants) {
      final name = v['name']?.toString() ?? '';
      final options = v['options'];
      if (name.isNotEmpty && options is List && options.isNotEmpty) {
        _selectedVariants[name] = options[0].toString();
      }
    }
  }

  @override
  void dispose() {
    _imageCtrl.dispose();
    super.dispose();
  }

  List<String> get _images {
    final list = widget.product.images.isNotEmpty
        ? widget.product.images
        : widget.product.imageUrl.isNotEmpty
        ? [widget.product.imageUrl]
        : [];
    return List<String>.from(list);
  }

  void _addToCart() {
    context.read<CartProvider>().addItem(
      widget.product,
      quantity: _quantity,
      variants: _selectedVariants,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${widget.product.name} added to cart!'),
        backgroundColor: const Color(0xFFC8860A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final images = _images;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: Stack(
        children: [
          // ── Scrollable content ────────────────────────────────────────
          CustomScrollView(
            slivers: [
              // ── Image gallery ───────────────────────────────────────
              SliverToBoxAdapter(
                child: _ImageGallery(
                  images: images,
                  controller: _imageCtrl,
                  currentIndex: _currentImage,
                  onPageChanged: (i) => setState(() => _currentImage = i),
                  onBack: () => Navigator.pop(context),
                  product: product,
                ),
              ),

              // ── Product info ────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Sale tag
                      if (product.saleTag != null)
                        Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
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
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),

                      // Name
                      Text(
                        product.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Price row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.baseline,
                        textBaseline: TextBaseline.alphabetic,
                        children: [
                          Text(
                            _formatPrice(product.price),
                            style: const TextStyle(
                              color: Color(0xFFF0A500),
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          if (product.originalPrice != null) ...[
                            const SizedBox(width: 10),
                            Text(
                              _formatPrice(product.originalPrice!),
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 15,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            if (product.discountPercent != null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0A2A0A),
                                  borderRadius: BorderRadius.circular(4),
                                  border: Border.all(
                                    color: const Color(0xFF1A4A1A),
                                  ),
                                ),
                                child: Text(
                                  '${product.discountPercent!.toStringAsFixed(0)}% OFF',
                                  style: const TextStyle(
                                    color: Color(0xFF4caf50),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Stock indicator
                      _StockIndicator(product: product),
                      const SizedBox(height: 16),

                      // Description
                      if (product.description.isNotEmpty) ...[
                        const _SectionTitle('Description'),
                        const SizedBox(height: 8),
                        Text(
                          product.description,
                          style: const TextStyle(
                            color: Color(0xFF999999),
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Variants selector
                      if (product.variants.isNotEmpty) ...[
                        const _SectionTitle('Options'),
                        const SizedBox(height: 12),
                        ...product.variants.map((v) {
                          final name = v['name']?.toString() ?? '';
                          final options = v['options'];
                          if (name.isEmpty || options is! List) {
                            return const SizedBox.shrink();
                          }
                          return _VariantSelector(
                            name: name,
                            options: List<String>.from(options),
                            selected: _selectedVariants[name] ?? '',
                            onSelect: (opt) =>
                                setState(() => _selectedVariants[name] = opt),
                          );
                        }),
                        const SizedBox(height: 20),
                      ],

                      // Quantity selector
                      if (product.inStock) ...[
                        const _SectionTitle('Quantity'),
                        const SizedBox(height: 12),
                        _QuantitySelector(
                          quantity: _quantity,
                          maxQuantity: product.stock,
                          onChanged: (q) => setState(() => _quantity = q),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Specifications
                      if (product.specifications.isNotEmpty) ...[
                        const _SectionTitle('Specifications'),
                        const SizedBox(height: 12),
                        _SpecsTable(specs: product.specifications),
                        const SizedBox(height: 20),
                      ],

                      // Related products
                      _RelatedProducts(
                        categoryId: product.categoryId,
                        excludeId: product.id,
                      ),

                      // Bottom padding for the sticky button
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Sticky Add to Cart button ────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _AddToCartBar(
              product: product,
              quantity: _quantity,
              onAddToCart: _addToCart,
            ),
          ),
        ],
      ),
    );
  }

  String _formatPrice(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}

// ── Image Gallery ─────────────────────────────────────────────────────────────
class _ImageGallery extends StatelessWidget {
  final List<String> images;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onPageChanged;
  final VoidCallback onBack;
  final ProductModel product;

  const _ImageGallery({
    required this.images,
    required this.controller,
    required this.currentIndex,
    required this.onPageChanged,
    required this.onBack,
    required this.product,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 320,
      child: Stack(
        children: [
          // Image pages
          images.isEmpty
              ? Container(
                  color: const Color(0xFF1A1200),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.devices_other_outlined,
                    color: Color(0xFF333333),
                    size: 80,
                  ),
                )
              : PageView.builder(
                  controller: controller,
                  onPageChanged: onPageChanged,
                  itemCount: images.length,
                  itemBuilder: (_, i) => Image.network(
                    images[i],
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFF1A1200),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.devices_other_outlined,
                        color: Color(0xFF333333),
                        size: 80,
                      ),
                    ),
                  ),
                ),

          // Dark gradient at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 80,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xFF0D0D0D)],
                ),
              ),
            ),
          ),

          // Back button
          Positioned(
            top: 48,
            left: 8,
            child: GestureDetector(
              onTap: onBack,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: const Icon(
                  Icons.arrow_back_ios,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ),
          ),

          // Dot indicators
          if (images.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(images.length, (i) {
                  final isActive = i == currentIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 16 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFFF0A500)
                          : const Color(0xFF333333),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),

          // Image count badge
          if (images.length > 1)
            Positioned(
              top: 48,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFF333333)),
                ),
                child: Text(
                  '${currentIndex + 1}/${images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Stock Indicator ───────────────────────────────────────────────────────────
class _StockIndicator extends StatelessWidget {
  final ProductModel product;
  const _StockIndicator({required this.product});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData icon;

    if (!product.inStock) {
      color = const Color(0xFFff4444);
      label = 'Out of Stock';
      icon = Icons.remove_circle_outline;
    } else if (product.isLowStock) {
      color = const Color(0xFFFF6600);
      label = 'Only ${product.stock} left — order soon!';
      icon = Icons.warning_amber_outlined;
    } else {
      color = const Color(0xFF4caf50);
      label = 'In Stock (${product.stock} available)';
      icon = Icons.check_circle_outline;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Variant Selector ──────────────────────────────────────────────────────────
class _VariantSelector extends StatelessWidget {
  final String name;
  final List<String> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _VariantSelector({
    required this.name,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF999999),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                selected,
                style: const TextStyle(
                  color: Color(0xFFF0A500),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: options.map((opt) {
              final isSelected = opt == selected;
              return GestureDetector(
                onTap: () => onSelect(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF1A1200)
                        : const Color(0xFF1A1A1A),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFFF0A500)
                          : const Color(0xFF2A2A2A),
                      width: isSelected ? 1.5 : 1,
                    ),
                  ),
                  child: Text(
                    opt,
                    style: TextStyle(
                      color: isSelected
                          ? const Color(0xFFF0A500)
                          : const Color(0xFF888888),
                      fontSize: 12,
                      fontWeight: isSelected
                          ? FontWeight.w700
                          : FontWeight.w400,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ── Quantity Selector ─────────────────────────────────────────────────────────
class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({
    required this.quantity,
    required this.maxQuantity,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _QtyBtn(
          icon: Icons.remove,
          enabled: quantity > 1,
          onTap: () => onChanged(quantity - 1),
        ),
        Container(
          width: 52,
          height: 40,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            border: Border.symmetric(
              horizontal: BorderSide(color: Color(0xFF2A2A2A)),
            ),
          ),
          child: Text(
            '$quantity',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        _QtyBtn(
          icon: Icons.add,
          enabled: quantity < maxQuantity,
          onTap: () => onChanged(quantity + 1),
        ),
        const SizedBox(width: 14),
        Text(
          'Max $maxQuantity',
          style: const TextStyle(color: Color(0xFF555555), fontSize: 11),
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
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: enabled ? const Color(0xFF1A1A1A) : const Color(0xFF111111),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: enabled ? const Color(0xFF2A2A2A) : const Color(0xFF1A1A1A),
          ),
        ),
        child: Icon(
          icon,
          color: enabled ? const Color(0xFFF0A500) : const Color(0xFF333333),
          size: 18,
        ),
      ),
    );
  }
}

// ── Specifications Table ──────────────────────────────────────────────────────
class _SpecsTable extends StatefulWidget {
  final List<Map<String, String>> specs;
  const _SpecsTable({required this.specs});

  @override
  State<_SpecsTable> createState() => _SpecsTableState();
}

class _SpecsTableState extends State<_SpecsTable> {
  bool _expanded = false;
  static const int _previewCount = 5;

  @override
  Widget build(BuildContext context) {
    final showSpecs = _expanded
        ? widget.specs
        : widget.specs.take(_previewCount).toList();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A2A)),
      ),
      child: Column(
        children: [
          ...showSpecs.asMap().entries.map((entry) {
            final i = entry.key;
            final spec = entry.value;
            final isLast =
                i == showSpecs.length - 1 &&
                (_expanded || widget.specs.length <= _previewCount);
            return Container(
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : const Border(
                        bottom: BorderSide(color: Color(0xFF1E1E1E)),
                      ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      spec['key'] ?? '',
                      style: const TextStyle(
                        color: Color(0xFF666666),
                        fontSize: 12,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      spec['value'] ?? '',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          if (widget.specs.length > _previewCount)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Show less'
                          : 'Show all ${widget.specs.length} specs',
                      style: const TextStyle(
                        color: Color(0xFFF0A500),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: const Color(0xFFF0A500),
                      size: 16,
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

// ── Related Products ──────────────────────────────────────────────────────────
class _RelatedProducts extends StatelessWidget {
  final String categoryId;
  final String excludeId;

  const _RelatedProducts({required this.categoryId, required this.excludeId});

  String _formatPrice(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: StoreService().getProductsByCategory(categoryId),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final related = (snap.data ?? [])
            .where((p) => p.id != excludeId)
            .take(6)
            .toList();
        if (related.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _SectionTitle('Related Products'),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: related.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final p = related[i];
                  return GestureDetector(
                    onTap: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProductDetailScreen(product: p),
                      ),
                    ),
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFF161616),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF2A2200)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(10),
                              topRight: Radius.circular(10),
                            ),
                            child: SizedBox(
                              height: 110,
                              width: double.infinity,
                              child: p.primaryImage.isNotEmpty
                                  ? Image.network(
                                      p.primaryImage,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: const Color(0xFF1A1200),
                                        child: const Icon(
                                          Icons.devices_other_outlined,
                                          color: Color(0xFF333333),
                                          size: 36,
                                        ),
                                      ),
                                    )
                                  : Container(
                                      color: const Color(0xFF1A1200),
                                      child: const Icon(
                                        Icons.devices_other_outlined,
                                        color: Color(0xFF333333),
                                        size: 36,
                                      ),
                                    ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    color: Color(0xFFCCCCCC),
                                    fontSize: 11,
                                    height: 1.3,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _formatPrice(p.price),
                                  style: const TextStyle(
                                    color: Color(0xFFF0A500),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
          ],
        );
      },
    );
  }
}

// ── Sticky Add to Cart Bar ────────────────────────────────────────────────────
class _AddToCartBar extends StatelessWidget {
  final ProductModel product;
  final int quantity;
  final VoidCallback onAddToCart;

  const _AddToCartBar({
    required this.product,
    required this.quantity,
    required this.onAddToCart,
  });

  String _formatPrice(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        16,
        12,
        16,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
      ),
      child: Row(
        children: [
          // Total price
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Total',
                style: TextStyle(color: Color(0xFF555555), fontSize: 11),
              ),
              Text(
                _formatPrice(product.price * quantity),
                style: const TextStyle(
                  color: Color(0xFFF0A500),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Add to cart button
          Expanded(
            child: GestureDetector(
              onTap: product.inStock ? onAddToCart : null,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: product.inStock
                      ? const Color(0xFFF0A500)
                      : const Color(0xFF1A1A1A),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      product.inStock
                          ? Icons.shopping_cart_outlined
                          : Icons.remove_shopping_cart_outlined,
                      color: product.inStock
                          ? Colors.black
                          : const Color(0xFF444444),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      product.inStock ? 'Add to Cart' : 'Out of Stock',
                      style: TextStyle(
                        color: product.inStock
                            ? Colors.black
                            : const Color(0xFF444444),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
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
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
