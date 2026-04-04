import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/category_model.dart';
import '../services/store_service.dart';
import '../pages/store/category_products_screen.dart';
import '../pages/store/order_tracking_screen.dart';
import '../pages/store/wishlist_screen.dart';
import '../pages/store/saved_addresses_screen.dart';
import '../pages/store/payment_details_screen.dart';

class StoreDrawer extends StatefulWidget {
  const StoreDrawer({super.key});

  @override
  State<StoreDrawer> createState() => _StoreDrawerState();
}

class _StoreDrawerState extends State<StoreDrawer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _fadeAnim = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    await _controller.reverse();
    if (mounted) Navigator.of(context).pop();
  }

  void _closeAndNavigate(BuildContext context, Widget screen) {
    Navigator.of(context).pop();
    Navigator.of(context).push(MaterialPageRoute(builder: (_) => screen));
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: GestureDetector(
          onTap: _close,
          child: Container(
            color: Colors.black54,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () {},
                child: SlideTransition(
                  position: _slideAnim,
                  child: _DrawerContent(
                    onClose: _close,
                    onNavigate: (screen) => _closeAndNavigate(context, screen),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DrawerContent extends StatelessWidget {
  final VoidCallback onClose;
  final void Function(Widget screen) onNavigate;

  const _DrawerContent({required this.onClose, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: MediaQuery.of(context).size.width * 0.82,
      height: double.infinity,
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(left: BorderSide(color: Color(0xFF2A2A2A))),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _DrawerHeader(onClose: onClose),
            const Divider(color: Color(0xFF1E1E1E), height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionLabel(label: 'Browse by Category'),
                    _CategoriesSection(onNavigate: onNavigate),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFF1E1E1E), height: 1),
                    const SizedBox(height: 8),
                    _SectionLabel(label: 'My Account'),
                    _DrawerItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Order Tracking',
                      onTap: () => onNavigate(const OrderTrackingScreen()),
                    ),
                    _DrawerItem(
                      icon: Icons.favorite_outline,
                      label: 'Wishlist',
                      onTap: () => onNavigate(const WishlistScreen()),
                    ),
                    _DrawerItem(
                      icon: Icons.payment_outlined,
                      label: 'Payment Details',
                      onTap: () => onNavigate(const PaymentDetailsScreen()),
                    ),
                    _DrawerItem(
                      icon: Icons.location_on_outlined,
                      label: 'Saved Addresses',
                      onTap: () => onNavigate(const SavedAddressesScreen()),
                    ),
                    const SizedBox(height: 8),
                    const Divider(color: Color(0xFF1E1E1E), height: 1),
                    const SizedBox(height: 8),
                    _SectionLabel(label: 'Support'),
                    _DrawerItem(
                      icon: Icons.verified_user_outlined,
                      label: 'Warranty Claims',
                      onTap: onClose,
                    ),
                    _DrawerItem(
                      icon: Icons.layers_outlined,
                      label: 'Custom Orders',
                      onTap: onClose,
                    ),
                    _DrawerItem(
                      icon: Icons.headset_mic_outlined,
                      label: 'Contact Support',
                      onTap: onClose,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Drawer Header ─────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final VoidCallback onClose;
  const _DrawerHeader({required this.onClose});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName?.isNotEmpty == true
        ? user!.displayName!
        : 'Guest';
    final email = user?.email ?? '';
    final initials = name
        .split(' ')
        .take(2)
        .map((e) => e.isNotEmpty ? e[0].toUpperCase() : '')
        .join();

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 16, 12, 16),
      child: Row(
        children: [
          // Avatar with initials
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
              ),
            ),
            child: Center(
              child: Text(
                initials.isNotEmpty ? initials : 'G',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (email.isNotEmpty)
                  Text(
                    email,
                    style: const TextStyle(
                      color: Color(0xFF555555),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, color: Color(0xFF555555), size: 20),
          ),
        ],
      ),
    );
  }
}

// ── Categories Section ────────────────────────────────────────────────────────
class _CategoriesSection extends StatelessWidget {
  final void Function(Widget screen) onNavigate;
  const _CategoriesSection({required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<CategoryModel>>(
      stream: StoreService().getCategories(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Color(0xFFF0A500),
                ),
              ),
            ),
          );
        }
        final categories = snap.data ?? [];
        if (categories.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            child: Text(
              'No categories available',
              style: TextStyle(color: Color(0xFF555555), fontSize: 13),
            ),
          );
        }
        return Column(
          children: categories
              .map(
                (cat) => _CategoryItem(
                  category: cat,
                  onTap: () =>
                      onNavigate(CategoryProductsScreen(category: cat)),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

// ── Category Item ─────────────────────────────────────────────────────────────
class _CategoryItem extends StatelessWidget {
  final CategoryModel category;
  final VoidCallback onTap;
  const _CategoryItem({required this.category, required this.onTap});

  Color get _color {
    try {
      final h = (category.color ?? '#F0A500').replaceAll('#', '');
      return Color(int.parse('FF$h', radix: 16));
    } catch (_) {
      return const Color(0xFFF0A500);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3), width: 1),
              ),
              child: Icon(_mapIcon(category.iconId), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category.name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (category.description != null &&
                      category.description!.isNotEmpty)
                    Text(
                      category.description!,
                      style: const TextStyle(
                        color: Color(0xFF555555),
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.6), size: 18),
          ],
        ),
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

// ── Drawer Item ───────────────────────────────────────────────────────────────
class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF666666), size: 20),
            const SizedBox(width: 14),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right, color: Color(0xFF333333), size: 16),
          ],
        ),
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFF444444),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}
