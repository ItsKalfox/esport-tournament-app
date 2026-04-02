import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/cart_provider.dart';
import '../../services/stripe_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _districtCtrl = TextEditingController();

  String _paymentMethod = 'online'; // 'online' | 'cod'
  bool _processing = false;

  final _stripe = StripeService();

  @override
  void initState() {
    super.initState();
    // Pre-fill email if user is logged in
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _emailCtrl.text = user.email ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    super.dispose();
  }

  String _fmt(double price) {
    return 'LKR ${price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  Future<String> _createOrder(CartProvider cart) async {
    final user = FirebaseAuth.instance.currentUser;
    final orderRef = FirebaseFirestore.instance.collection('orders').doc();

    await orderRef.set({
      'userId': user?.uid ?? 'guest',
      'customerName': _nameCtrl.text.trim(),
      'customerEmail': _emailCtrl.text.trim(),
      'customerPhone': _phoneCtrl.text.trim(),
      'address': {
        'line1': _addressCtrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
      },
      'items': cart.items
          .map(
            (item) => {
              'productId': item.product.id,
              'name': item.product.name,
              'imageUrl': item.product.primaryImage,
              'price': item.product.price,
              'quantity': item.quantity,
              'variants': item.selectedVariants,
            },
          )
          .toList(),
      'subtotal': cart.subtotal,
      'deliveryFee': cart.deliveryFee,
      'total': cart.total,
      'paymentMethod': _paymentMethod,
      'paymentStatus': _paymentMethod == 'cod' ? 'pending' : 'awaiting',
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    return orderRef.id;
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _processing = true);

    final cart = context.read<CartProvider>();

    try {
      // 1. Create order in Firestore
      final orderId = await _createOrder(cart);

      if (_paymentMethod == 'online') {
        // 2. Process Stripe payment
        final result = await _stripe.presentPaymentSheet(
          amount: cart.total,
          orderId: orderId,
          customerEmail: _emailCtrl.text.trim(),
        );

        if (result.isSuccess) {
          // Update order status to processing
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .update({
                'paymentStatus': 'paid',
                'status': 'processing',
                'paidAt': FieldValue.serverTimestamp(),
              });

          cart.clear();
          if (mounted) _showSuccess(orderId);
        } else if (result.isCancelled) {
          // Delete the pending order if user cancelled
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Payment cancelled'),
                backgroundColor: Color(0xFF1A1A1A),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } else {
          // Payment failed — delete pending order
          await FirebaseFirestore.instance
              .collection('orders')
              .doc(orderId)
              .delete();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(result.errorMessage ?? 'Payment failed'),
                backgroundColor: const Color(0xFFCC2200),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // COD — order placed directly
        cart.clear();
        if (mounted) _showSuccess(orderId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: const Color(0xFFCC2200),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  void _showSuccess(String orderId) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => _OrderSuccessScreen(orderId: orderId)),
      (route) => route.isFirst,
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();

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
                  const Text(
                    'Checkout',
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

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Delivery details ──────────────────────────────
                      _SectionTitle('Delivery Details'),
                      const SizedBox(height: 12),
                      _Field(
                        controller: _nameCtrl,
                        label: 'Full name',
                        hint: 'e.g. Kavindu Perera',
                        icon: Icons.person_outline,
                        validator: (v) =>
                            v!.isEmpty ? 'Name is required' : null,
                      ),
                      _Field(
                        controller: _emailCtrl,
                        label: 'Email address',
                        hint: 'e.g. kavindu@gmail.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            v!.isEmpty ? 'Email is required' : null,
                      ),
                      _Field(
                        controller: _phoneCtrl,
                        label: 'Phone number',
                        hint: 'e.g. 0771234567',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        validator: (v) =>
                            v!.isEmpty ? 'Phone is required' : null,
                      ),
                      _Field(
                        controller: _addressCtrl,
                        label: 'Address',
                        hint: 'Street address',
                        icon: Icons.location_on_outlined,
                        validator: (v) =>
                            v!.isEmpty ? 'Address is required' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _Field(
                              controller: _cityCtrl,
                              label: 'City',
                              hint: 'e.g. Colombo',
                              icon: Icons.location_city_outlined,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _Field(
                              controller: _districtCtrl,
                              label: 'District',
                              hint: 'e.g. Colombo',
                              icon: Icons.map_outlined,
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // ── Payment method ────────────────────────────────
                      _SectionTitle('Payment Method'),
                      const SizedBox(height: 12),
                      _PaymentMethodSelector(
                        selected: _paymentMethod,
                        onSelect: (m) => setState(() => _paymentMethod = m),
                      ),

                      const SizedBox(height: 20),

                      // ── Order summary ─────────────────────────────────
                      _SectionTitle('Order Summary'),
                      const SizedBox(height: 12),
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF2A2A2A)),
                        ),
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            ...cart.items.map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${item.product.name} x${item.quantity}',
                                        style: const TextStyle(
                                          color: Color(0xFF999999),
                                          fontSize: 12,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Text(
                                      _fmt(item.subtotal),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const Divider(color: Color(0xFF1E1E1E), height: 16),
                            _SummaryRow('Subtotal', _fmt(cart.subtotal)),
                            const SizedBox(height: 4),
                            _SummaryRow(
                              'Delivery',
                              cart.deliveryFee == 0
                                  ? 'Free'
                                  : _fmt(cart.deliveryFee),
                              valueColor: cart.deliveryFee == 0
                                  ? const Color(0xFF4caf50)
                                  : null,
                            ),
                            const Divider(color: Color(0xFF1E1E1E), height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                Text(
                                  _fmt(cart.total),
                                  style: const TextStyle(
                                    color: Color(0xFFF0A500),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      // Sticky place order button
      bottomNavigationBar: Container(
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
        child: GestureDetector(
          onTap: _processing ? null : _placeOrder,
          child: Container(
            height: 52,
            decoration: BoxDecoration(
              color: _processing
                  ? const Color(0xFF333333)
                  : const Color(0xFFF0A500),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _processing
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Processing...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _paymentMethod == 'online'
                            ? Icons.credit_card
                            : Icons.local_shipping_outlined,
                        color: Colors.black,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _paymentMethod == 'online'
                            ? 'Pay · ${_fmt(cart.total)}'
                            : 'Place Order · ${_fmt(cart.total)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// ── Payment Method Selector ───────────────────────────────────────────────────
class _PaymentMethodSelector extends StatelessWidget {
  final String selected;
  final ValueChanged<String> onSelect;

  const _PaymentMethodSelector({
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _PaymentOption(
          value: 'online',
          selected: selected,
          onSelect: onSelect,
          icon: Icons.credit_card,
          title: 'Credit / Debit Card',
          subtitle: 'Secure payment via Stripe',
          badge: 'Recommended',
        ),
        const SizedBox(height: 10),
        _PaymentOption(
          value: 'cod',
          selected: selected,
          onSelect: onSelect,
          icon: Icons.local_shipping_outlined,
          title: 'Cash on Delivery',
          subtitle: 'Pay when your order arrives',
        ),
      ],
    );
  }
}

class _PaymentOption extends StatelessWidget {
  final String value;
  final String selected;
  final ValueChanged<String> onSelect;
  final IconData icon;
  final String title;
  final String subtitle;
  final String? badge;

  const _PaymentOption({
    required this.value,
    required this.selected,
    required this.onSelect,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onSelect(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1A1200) : const Color(0xFF161616),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFF0A500)
                : const Color(0xFF2A2A2A),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFF0A500).withOpacity(0.15)
                    : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: isSelected
                    ? const Color(0xFFF0A500)
                    : const Color(0xFF666666),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFFCCCCCC),
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0A2A0A),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: const Color(0xFF1A4A1A)),
                          ),
                          child: Text(
                            badge!,
                            style: const TextStyle(
                              color: Color(0xFF4caf50),
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF666666),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFFF0A500)
                      : const Color(0xFF444444),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Container(
                      margin: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFF0A500),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Order Success Screen ──────────────────────────────────────────────────────
class _OrderSuccessScreen extends StatelessWidget {
  final String orderId;
  const _OrderSuccessScreen({required this.orderId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D0D),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0A2A0A),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF4caf50),
                      width: 2,
                    ),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Color(0xFF4caf50),
                    size: 40,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Order Placed!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Thank you for your order.\nWe\'ll get it to you soon!',
                  style: TextStyle(
                    color: Color(0xFF777777),
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF161616),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF2A2A2A)),
                  ),
                  child: Text(
                    'Order #${orderId.substring(0, 8).toUpperCase()}',
                    style: const TextStyle(
                      color: Color(0xFFF0A500),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: () =>
                      Navigator.popUntil(context, (route) => route.isFirst),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0A500),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'Continue Shopping',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
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

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 13),
          prefixIcon: Icon(icon, color: const Color(0xFF555555), size: 18),
          filled: true,
          fillColor: const Color(0xFF1A1A1A),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFF2A2A2A)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFF0A500)),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCC2200)),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFCC2200)),
          ),
        ),
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
