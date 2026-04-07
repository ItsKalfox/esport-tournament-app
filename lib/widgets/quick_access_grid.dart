import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class QuickAccessGrid extends StatelessWidget {
  final Function(String route) onNavigate;

  const QuickAccessGrid({super.key, required this.onNavigate});

  static const List<Map<String, dynamic>> _items = [
    {'label': 'Tournaments',    'icon': Icons.emoji_events,   'route': '/tournaments'},
    {'label': 'Store',          'icon': Icons.storefront,     'route': '/store'},
    {'label': 'Chat',           'icon': Icons.chat_bubble,    'route': '/chat'},
    {'label': 'Tech Community', 'icon': Icons.groups,         'route': '/community'},
    {'label': 'Watch Live',     'icon': Icons.play_circle,    'route': '/watch'},
    {'label': 'Calendar',       'icon': Icons.calendar_month, 'route': '/calendar'},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Row(children: [
            _buildItem(context, _items[0]),
            const SizedBox(width: 12),
            _buildItem(context, _items[1]),
            const SizedBox(width: 12),
            _buildItem(context, _items[2]),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            _buildItem(context, _items[3]),
            const SizedBox(width: 12),
            _buildItem(context, _items[4]),
            const SizedBox(width: 12),
            _buildItem(context, _items[5]),
          ]),
        ],
      ),
    );
  }

  Widget _buildItem(BuildContext context, Map<String, dynamic> item) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onNavigate(item['route']),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE07B2A), Color(0xFFB85E1A)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primaryOrange.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(item['icon'] as IconData,
                    color: AppColors.white, size: 32),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              item['label'],
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}