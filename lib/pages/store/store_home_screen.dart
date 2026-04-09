import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/store_banner.dart';
import '../../models/product.dart';
import '../../services/store_service.dart';
import '../../widgets/hero_banner_carousel.dart';
import '../../widgets/product_card.dart';
import '../../widgets/featured_product_card.dart';
import '../../widgets/store_drawer.dart';
import 'product_detail_screen.dart';
import 'cart_screen.dart';
import 'store_search_screen.dart';
import 'package:provider/provider.dart';
import '../../providers/cart_provider.dart';

class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final service = StoreService();

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _TopBar()),

            // ── Hero Banner Carousel ─────────────────────────────────────────
            SliverToBoxAdapter(
              child: StreamBuilder<List<BannerModel>>(
                stream: service.getBanners(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _BannerSkeleton();
                  }
                  final banners = snap.data ?? [];
                  if (banners.isEmpty) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 14),
                    child: HeroBannerCarousel(banners: banners),
                  );
                },
              ),
            ),

            // ── Special Offers ────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Special Offers',
                accent: ' %',
                onSeeAll: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<List<ProductModel>>(
                stream: service.getSpecialOffers(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _HorizontalSkeleton();
                  }
                  final products = snap.data ?? [];
                  if (products.isEmpty) {
                    return const _EmptySection(
                      message: 'No special offers right now',
                    );
                  }
                  return SizedBox(
                    height: 208,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      itemCount: products.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => ProductCard(
                        product: products[i],
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ProductDetailScreen(product: products[i]),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Featured Gear ─────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: _SectionHeader(
                title: 'Featured',
                accent: ' Gear',
                accentColor: Colors.white,
                onSeeAll: () {},
              ),
            ),
            SliverToBoxAdapter(
              child: StreamBuilder<List<ProductModel>>(
                stream: service.getFeaturedProducts(),
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const _FeaturedSkeleton();
                  }
                  final products = snap.data ?? [];
                  if (products.isEmpty) {
                    return const _EmptySection(message: 'No featured products');
                  }
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: products
                          .map(
                            (p) => Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: FeaturedProductCard(
                                product: p,
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: p),
                                  ),
                                ),
                                onAddToCart: () => _addToCart(context, p),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  );
                },
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 20)),

            // ── Info Cards ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  children: [
                    _InfoCard(
                      icon: Icons.verified_user_outlined,
                      title: 'Warranty Assured',
                      description:
                          'In case of faulty products, we have an unending warranty and claim procedures to make sure your requirements are met in minimum time loss.',
                    ),
                    const SizedBox(height: 10),
                    _InfoCard(
                      icon: Icons.layers_outlined,
                      title: 'Custom Orders',
                      description:
                          'In case your requirements supersede what the local market has to offer, we assist with assistance to meet those requirements.',
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  void _addToCart(BuildContext context, ProductModel product) {
    context.read<CartProvider>().addItem(product);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${product.name} added to cart!'),
        backgroundColor: const Color(0xFFC8860A),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

// ─── Top Bar ──────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  void _openDrawer(BuildContext context) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: false,
        pageBuilder: (_, __, ___) => const StoreDrawer(),
        transitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName ?? '';
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
      child: SizedBox(
        height: 46,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered title
            const Text(
              'Store',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),

            // Left — user avatar / initials
            Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 10),
                child: GestureDetector(
                  onTap: () => _openDrawer(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        initials.isNotEmpty ? initials : 'GX',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Right — search + menu + cart
            Align(
              alignment: Alignment.centerRight,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Search
                  IconButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const StoreSearchScreen(),
                      ),
                    ),
                    icon: const Icon(
                      Icons.search,
                      color: Colors.white,
                      size: 22,
                    ),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  // Menu
                  IconButton(
                    onPressed: () => _openDrawer(context),
                    icon: const Icon(Icons.menu, color: Colors.white, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                  // Cart with badge
                  Consumer<CartProvider>(
                    builder: (context, cart, _) {
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          IconButton(
                            onPressed: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const CartScreen(),
                              ),
                            ),
                            icon: const Icon(
                              Icons.shopping_cart_outlined,
                              color: Colors.white,
                              size: 22,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 36,
                              minHeight: 36,
                            ),
                          ),
                          if (cart.itemCount > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                width: 16,
                                height: 16,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFF0A500),
                                  shape: BoxShape.circle,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  cart.itemCount > 9
                                      ? '9+'
                                      : '${cart.itemCount}',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(width: 4),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final String accent;
  final Color accentColor;
  final VoidCallback? onSeeAll;

  const _SectionHeader({
    required this.title,
    required this.accent,
    this.accentColor = const Color(0xFFF0A500),
    this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: title,
                  style: const TextStyle(
                    color: Color(0xFFF0A500),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                TextSpan(
                  text: accent,
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: onSeeAll,
            child: const Text(
              'See all →',
              style: TextStyle(color: Color(0xFFC8860A), fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Info Card ────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2200), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF1E1600),
              border: Border.all(color: const Color(0xFFC8860A), width: 1),
            ),
            child: Icon(icon, color: const Color(0xFFC8860A), size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFFF0A500),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Skeleton Loaders ─────────────────────────────────────────────────────────

class _BannerSkeleton extends StatelessWidget {
  const _BannerSkeleton();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 160,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}

class _HorizontalSkeleton extends StatelessWidget {
  const _HorizontalSkeleton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 208,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, __) => Container(
          width: 152,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

class _FeaturedSkeleton extends StatelessWidget {
  const _FeaturedSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        children: List.generate(
          2,
          (_) => Container(
            height: 110,
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF1A1A1A),
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;
  const _EmptySection({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF555555), fontSize: 13),
      ),
    );
  }
}
