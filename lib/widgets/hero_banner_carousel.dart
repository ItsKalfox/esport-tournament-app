import 'package:flutter/material.dart';
import '../models/store_banner.dart';

class HeroBannerCarousel extends StatefulWidget {
  final List<BannerModel> banners;

  const HeroBannerCarousel({super.key, required this.banners});

  @override
  State<HeroBannerCarousel> createState() => _HeroBannerCarouselState();
}

class _HeroBannerCarouselState extends State<HeroBannerCarousel> {
  final PageController _controller = PageController();
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    // Auto-scroll every 4 seconds
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  void _autoScroll() {
    if (!mounted) return;
    final next = (_currentIndex + 1) % widget.banners.length;
    _controller.animateToPage(
      next,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
    );
    Future.delayed(const Duration(seconds: 4), _autoScroll);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.banners.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        SizedBox(
          height: 160,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: widget.banners.length,
            itemBuilder: (context, index) {
              return _BannerCard(banner: widget.banners[index]);
            },
          ),
        ),
        const SizedBox(height: 10),
        // Dot indicators
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.banners.length, (i) {
            final isActive = i == _currentIndex;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
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
      ],
    );
  }
}

class _BannerCard extends StatelessWidget {
  final BannerModel banner;

  const _BannerCard({required this.banner});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1200), Color(0xFF0D1A2E), Color(0xFF0A0A0A)],
        ),
        border: Border.all(color: const Color(0xFF2A2200), width: 1),
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC8860A),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Text(
                    banner.badgeText.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.black,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Title
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Color(0xFFF0A500),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    height: 1.2,
                  ),
                ),
                Text(
                  banner.subtitle,
                  style: const TextStyle(
                    color: Color(0xFFAAAAAA),
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 10),
                // Button
                GestureDetector(
                  onTap: () {
                    // Navigate to banner link
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8860A),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      banner.buttonText.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Right-side image (uses network image if URL set, else placeholder)
          Positioned(
            right: 0,
            top: 0,
            bottom: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(14),
                bottomRight: Radius.circular(14),
              ),
              child: SizedBox(
                width: 140,
                child: banner.imageUrl.isNotEmpty
                    ? Image.network(
                        banner.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderImage(),
                      )
                    : _PlaceholderImage(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlaceholderImage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A5F), Color(0xFF0D2040)],
        ),
      ),
      child: const Icon(Icons.computer, size: 56, color: Color(0xFF4A8AFF)),
    );
  }
}
