import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 16, 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  const Text(
                    'My Orders',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Orders list ───────────────────────────────────────────
            Expanded(
              child: user == null
                  ? _buildNotLoggedIn(context)
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('orders')
                          .where('userId', isEqualTo: user.uid)
                          .orderBy('createdAt', descending: true)
                          .snapshots(),
                      builder: (context, snap) {
                        if (snap.connectionState == ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFFF0A500),
                              strokeWidth: 2,
                            ),
                          );
                        }

                        if (snap.hasError) {
                          return _buildEmpty(
                            icon: Icons.error_outline,
                            message: 'Failed to load orders',
                            sub: 'Please try again later',
                          );
                        }

                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) {
                          return _buildEmpty(
                            icon: Icons.receipt_long_outlined,
                            message: 'No orders yet',
                            sub: 'Your orders will appear here',
                          );
                        }

                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (context, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final orderId = docs[i].id;
                            return _OrderCard(
                              orderId: orderId,
                              data: data,
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => _OrderDetailScreen(
                                    orderId: orderId,
                                    data: data,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotLoggedIn(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, color: Color(0xFF333333), size: 56),
          const SizedBox(height: 16),
          const Text(
            'Sign in to view orders',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your order history will appear here',
            style: TextStyle(color: Color(0xFF444444), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty({
    required IconData icon,
    required String message,
    required String sub,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF222222), size: 64),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF555555),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            sub,
            style: const TextStyle(color: Color(0xFF444444), fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Order Card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;
  final VoidCallback onTap;

  const _OrderCard({
    required this.orderId,
    required this.data,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final items = data['items'] as List? ?? [];
    final total = (data['total'] ?? 0).toDouble();
    final createdAt = data['createdAt'] as Timestamp?;
    final statusInfo = _statusInfo(status);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF2A2A2A)),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order #${orderId.substring(0, 8).toUpperCase()}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          createdAt != null
                              ? _formatDate(createdAt.toDate())
                              : '—',
                          style: const TextStyle(
                            color: Color(0xFF555555),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusInfo['bg'] as Color,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusInfo['border'] as Color),
                    ),
                    child: Text(
                      statusInfo['label'] as String,
                      style: TextStyle(
                        color: statusInfo['color'] as Color,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Mini timeline
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: _MiniTimeline(status: status),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: Color(0xFF111111),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(top: BorderSide(color: Color(0xFF1E1E1E))),
              ),
              child: Row(
                children: [
                  Text(
                    '${items.length} item${items.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 12,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'LKR ${total.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}',
                    style: const TextStyle(
                      color: Color(0xFFF0A500),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right,
                    color: Color(0xFF444444),
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.day} ${_months[d.month - 1]} ${d.year}  ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  Map<String, dynamic> _statusInfo(String status) {
    switch (status) {
      case 'processing':
        return {
          'label': 'Processing',
          'color': const Color(0xFF4A8AFF),
          'bg': const Color(0xFF001A2E),
          'border': const Color(0xFF002A4E),
        };
      case 'shipped':
        return {
          'label': 'Shipped',
          'color': const Color(0xFF00CCCC),
          'bg': const Color(0xFF001A1A),
          'border': const Color(0xFF002A2A),
        };
      case 'delivered':
        return {
          'label': 'Delivered',
          'color': const Color(0xFF4caf50),
          'bg': const Color(0xFF0a2a0a),
          'border': const Color(0xFF1a4a1a),
        };
      case 'cancelled':
        return {
          'label': 'Cancelled',
          'color': const Color(0xFFff4444),
          'bg': const Color(0xFF2a0a0a),
          'border': const Color(0xFF4a1a1a),
        };
      case 'refunded':
        return {
          'label': 'Refunded',
          'color': const Color(0xFFAA66FF),
          'bg': const Color(0xFF1A0A2E),
          'border': const Color(0xFF2A1A4E),
        };
      default:
        return {
          'label': 'Pending',
          'color': const Color(0xFFF0A500),
          'bg': const Color(0xFF1A1200),
          'border': const Color(0xFF2A2000),
        };
    }
  }
}

// ── Mini Timeline ─────────────────────────────────────────────────────────────
class _MiniTimeline extends StatelessWidget {
  final String status;
  const _MiniTimeline({required this.status});

  static const _steps = ['pending', 'processing', 'shipped', 'delivered'];

  int get _currentStep {
    final idx = _steps.indexOf(status);
    return idx == -1 ? 0 : idx;
  }

  bool get _isCancelled => status == 'cancelled' || status == 'refunded';

  @override
  Widget build(BuildContext context) {
    if (_isCancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFF2a0a0a),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFff4444)),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFff4444),
                size: 14,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              status == 'refunded' ? 'Order Refunded' : 'Order Cancelled',
              style: const TextStyle(
                color: Color(0xFFff4444),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: List.generate(_steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          // Connector line
          final stepIndex = i ~/ 2;
          final isDone = stepIndex < _currentStep;
          return Expanded(
            child: Container(
              height: 2,
              color: isDone ? const Color(0xFFF0A500) : const Color(0xFF2A2A2A),
            ),
          );
        }

        // Step circle
        final stepIndex = i ~/ 2;
        final isDone = stepIndex <= _currentStep;
        final isCurrent = stepIndex == _currentStep;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: isCurrent ? 28 : 22,
              height: isCurrent ? 28 : 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDone
                    ? const Color(0xFFF0A500)
                    : const Color(0xFF1A1A1A),
                border: Border.all(
                  color: isDone
                      ? const Color(0xFFF0A500)
                      : const Color(0xFF2A2A2A),
                  width: isCurrent ? 2 : 1,
                ),
              ),
              child: Icon(
                isDone ? Icons.check : _stepIcon(stepIndex),
                color: isDone ? Colors.black : const Color(0xFF444444),
                size: isCurrent ? 14 : 11,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _stepLabel(stepIndex),
              style: TextStyle(
                color: isDone
                    ? const Color(0xFFF0A500)
                    : const Color(0xFF444444),
                fontSize: 9,
                fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
              ),
            ),
          ],
        );
      }),
    );
  }

  IconData _stepIcon(int index) {
    switch (index) {
      case 0:
        return Icons.receipt_outlined;
      case 1:
        return Icons.settings_outlined;
      case 2:
        return Icons.local_shipping_outlined;
      case 3:
        return Icons.home_outlined;
      default:
        return Icons.circle_outlined;
    }
  }

  String _stepLabel(int index) {
    switch (index) {
      case 0:
        return 'Placed';
      case 1:
        return 'Processing';
      case 2:
        return 'Shipped';
      case 3:
        return 'Delivered';
      default:
        return '';
    }
  }
}

// ── Order Detail Screen ───────────────────────────────────────────────────────
class _OrderDetailScreen extends StatelessWidget {
  final String orderId;
  final Map<String, dynamic> data;

  const _OrderDetailScreen({required this.orderId, required this.data});

  String _fmt(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final status = data['status'] ?? 'pending';
    final items = data['items'] as List? ?? [];
    final address = data['address'] as Map<String, dynamic>? ?? {};
    final createdAt = data['createdAt'] as Timestamp?;

    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Column(
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 10, 16, 10),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Column(
                    children: [
                      const Text(
                        'Order Details',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '#${orderId.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          color: Color(0xFF555555),
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Full timeline ──────────────────────────────────
                    _Section(
                      title: 'Order Status',
                      child: _FullTimeline(status: status),
                    ),

                    // ── Order date ─────────────────────────────────────
                    if (createdAt != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              color: Color(0xFF555555),
                              size: 14,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Ordered on ${_formatDate(createdAt.toDate())}',
                              style: const TextStyle(
                                color: Color(0xFF555555),
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),

                    // ── Items ──────────────────────────────────────────
                    _Section(
                      title: 'Items (${items.length})',
                      child: Column(
                        children: items.map((item) {
                          final i = item as Map<String, dynamic>;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Container(
                                    width: 52,
                                    height: 52,
                                    color: const Color(0xFF1A1200),
                                    child:
                                        i['imageUrl'] != null &&
                                            i['imageUrl'].toString().isNotEmpty
                                        ? Image.network(
                                            i['imageUrl'],
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(
                                                  Icons.devices_other_outlined,
                                                  color: Color(0xFF333333),
                                                  size: 24,
                                                ),
                                          )
                                        : const Icon(
                                            Icons.devices_other_outlined,
                                            color: Color(0xFF333333),
                                            size: 24,
                                          ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        i['name'] ?? '',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      Text(
                                        'x${i['quantity']}',
                                        style: const TextStyle(
                                          color: Color(0xFF555555),
                                          fontSize: 11,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  _fmt(
                                    (i['price'] as num).toDouble() *
                                        (i['quantity'] as num).toInt(),
                                  ),
                                  style: const TextStyle(
                                    color: Color(0xFFF0A500),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                    // ── Delivery address ───────────────────────────────
                    if (address.isNotEmpty)
                      _Section(
                        title: 'Delivery Address',
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A1A1A),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFF2A2A2A)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                color: Color(0xFFF0A500),
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  [
                                        address['line1'],
                                        address['city'],
                                        address['district'],
                                      ]
                                      .where(
                                        (e) =>
                                            e != null &&
                                            e.toString().isNotEmpty,
                                      )
                                      .join(', '),
                                  style: const TextStyle(
                                    color: Color(0xFFCCCCCC),
                                    fontSize: 13,
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // ── Payment summary ────────────────────────────────
                    _Section(
                      title: 'Payment Summary',
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        child: Column(
                          children: [
                            _SummaryRow(
                              'Subtotal',
                              _fmt((data['subtotal'] ?? 0).toDouble()),
                            ),
                            const SizedBox(height: 6),
                            _SummaryRow(
                              'Delivery',
                              (data['deliveryFee'] ?? 0) == 0
                                  ? 'Free'
                                  : _fmt((data['deliveryFee']).toDouble()),
                              valueColor: (data['deliveryFee'] ?? 0) == 0
                                  ? const Color(0xFF4caf50)
                                  : null,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Divider(color: Color(0xFF1E1E1E)),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _fmt((data['total'] ?? 0).toDouble()),
                                  style: const TextStyle(
                                    color: Color(0xFFF0A500),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(
                                  Icons.payment_outlined,
                                  color: Color(0xFF555555),
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  data['paymentMethod'] == 'cod'
                                      ? 'Cash on Delivery'
                                      : 'Online Payment',
                                  style: const TextStyle(
                                    color: Color(0xFF666666),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
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

  String _formatDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

// ── Full Timeline ─────────────────────────────────────────────────────────────
class _FullTimeline extends StatelessWidget {
  final String status;
  const _FullTimeline({required this.status});

  static const _steps = [
    {
      'key': 'pending',
      'label': 'Order Placed',
      'sub': 'We received your order',
      'icon': Icons.receipt_outlined,
    },
    {
      'key': 'processing',
      'label': 'Processing',
      'sub': 'Your order is being prepared',
      'icon': Icons.settings_outlined,
    },
    {
      'key': 'shipped',
      'label': 'Shipped',
      'sub': 'Your order is on the way',
      'icon': Icons.local_shipping_outlined,
    },
    {
      'key': 'delivered',
      'label': 'Delivered',
      'sub': 'Order delivered successfully',
      'icon': Icons.home_outlined,
    },
  ];

  int get _currentStep {
    final idx = _steps.indexWhere((s) => s['key'] == status);
    return idx == -1 ? 0 : idx;
  }

  bool get _isCancelled => status == 'cancelled' || status == 'refunded';

  @override
  Widget build(BuildContext context) {
    if (_isCancelled) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF2a0a0a),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF4a1a1a)),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: const Color(0xFF3a0a0a),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFff4444)),
              ),
              child: const Icon(
                Icons.close,
                color: Color(0xFFff4444),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  status == 'refunded' ? 'Order Refunded' : 'Order Cancelled',
                  style: const TextStyle(
                    color: Color(0xFFff4444),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  status == 'refunded'
                      ? 'Your refund is being processed'
                      : 'This order has been cancelled',
                  style: const TextStyle(
                    color: Color(0xFF884444),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return Column(
      children: List.generate(_steps.length, (i) {
        final step = _steps[i];
        final isDone = i <= _currentStep;
        final isCurrent = i == _currentStep;
        final isLast = i == _steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left side — icon + line
            Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? const Color(0xFFF0A500)
                        : const Color(0xFF1A1A1A),
                    border: Border.all(
                      color: isDone
                          ? const Color(0xFFF0A500)
                          : const Color(0xFF2A2A2A),
                      width: isCurrent ? 2 : 1,
                    ),
                  ),
                  child: Icon(
                    isDone
                        ? (isCurrent ? step['icon'] as IconData : Icons.check)
                        : step['icon'] as IconData,
                    color: isDone ? Colors.black : const Color(0xFF444444),
                    size: 16,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 36,
                    color: i < _currentStep
                        ? const Color(0xFFF0A500)
                        : const Color(0xFF2A2A2A),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            // Right side — text
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 20, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      step['label'] as String,
                      style: TextStyle(
                        color: isDone ? Colors.white : const Color(0xFF444444),
                        fontSize: 13,
                        fontWeight: isCurrent
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      step['sub'] as String,
                      style: TextStyle(
                        color: isDone
                            ? const Color(0xFF888888)
                            : const Color(0xFF333333),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final String title;
  final Widget child;
  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  const _SummaryRow(this.label, this.value, {this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF777777), fontSize: 12),
        ),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
