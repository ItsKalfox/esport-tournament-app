// Replace the existing _TopBar widget in your store_screen.dart with this one
// This adds the menu (≡) icon between search and cart

import 'package:flutter/material.dart';
import '../../widgets/store_drawer.dart';

class StoreTopBar extends StatelessWidget {
  const StoreTopBar({super.key});

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
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 10, 18, 8),
      child: Row(
        children: [
          // Logo placeholder — replace with your brand asset
          Container(
            width: 36,
            height: 36,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Color(0xFFC8860A), Color(0xFFF0A500)],
              ),
            ),
            child: const Center(
              child: Text(
                'GX',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const Spacer(),
          const Text(
            'Store',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          const Spacer(),
          // Search icon
          IconButton(
            onPressed: () {
              // Open search
            },
            icon: const Icon(Icons.search, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Menu icon (≡) — opens side drawer
          IconButton(
            onPressed: () => _openDrawer(context),
            icon: const Icon(Icons.menu, color: Colors.white, size: 22),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          // Cart icon
          IconButton(
            onPressed: () {
              // Open cart
            },
            icon: const Icon(
              Icons.shopping_cart_outlined,
              color: Colors.white,
              size: 22,
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
      ),
    );
  }
}
