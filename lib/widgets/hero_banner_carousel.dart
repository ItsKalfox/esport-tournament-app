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
          height: 180,
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
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF2A2200), width: 1),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // ── Full background image ──────────────────────────────────
          if (banner.imageUrl.isNotEmpty)
            Image.network(
              banner.imageUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _gradientBackground(),
            )
          else
            _gradientBackground(),

          // ── Dark gradient overlay (left side for text readability) ─
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xEE0D0D0D),
                  Color(0xAA0D0D0D),
                  Color(0x440D0D0D),
                  Colors.transparent,
                ],
                stops: [0.0, 0.4, 0.65, 1.0],
              ),
            ),
          ),

          // ── Text content ───────────────────────────────────────────
          Positioned(
            left: 16,
            top: 16,
            bottom: 16,
            right: 100, // leave right side for image visibility
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Badge
                if (banner.badgeText.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
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

                // Title
                Text(
                  banner.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.3,
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),

                // Subtitle
                if (banner.subtitle.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    banner.subtitle,
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 11,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],

                const SizedBox(height: 12),

                // Button
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFC8860A),
                      borderRadius: BorderRadius.circular(6),
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
        ],
      ),
    );
  }

  Widget _gradientBackground() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1200), Color(0xFF0D1A2E), Color(0xFF0A0A0A)],
        ),
      ),
      child: const Center(
        child: Icon(Icons.computer, size: 64, color: Color(0xFF4A8AFF)),
      ),
    );
  }
}
