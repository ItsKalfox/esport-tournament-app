import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SavedAddressesScreen extends StatelessWidget {
  const SavedAddressesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

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
                    'Saved Addresses',
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
                  Align(
                    alignment: Alignment.centerRight,
                    child: GestureDetector(
                      onTap: () => _showAddressForm(context, user),
                      child: const Text(
                        '+ Add',
                        style: TextStyle(
                          color: Color(0xFFF0A500),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: user == null
                  ? _buildNotLoggedIn()
                  : StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user.uid)
                          .collection('addresses')
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
                        final docs = snap.data?.docs ?? [];
                        if (docs.isEmpty) return _buildEmpty(context, user);
                        return ListView.separated(
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 24),
                          itemCount: docs.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, i) {
                            final data = docs[i].data() as Map<String, dynamic>;
                            final docId = docs[i].id;
                            return _AddressCard(
                              data: data,
                              onEdit: () => _showAddressForm(
                                context,
                                user,
                                docId: docId,
                                existing: data,
                              ),
                              onDelete: () =>
                                  _deleteAddress(context, user, docId),
                              onSetDefault: () =>
                                  _setDefault(user, docId, docs),
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

  void _showAddressForm(
    BuildContext context,
    User? user, {
    String? docId,
    Map<String, dynamic>? existing,
  }) {
    if (user == null) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF161616),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) =>
          _AddressForm(user: user, docId: docId, existing: existing),
    );
  }

  void _deleteAddress(BuildContext context, User user, String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF161616),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text(
          'Delete Address',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: const Text(
          'Remove this address?',
          style: TextStyle(color: Color(0xFF999999), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF666666)),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFff4444)),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('addresses')
          .doc(docId)
          .delete();
    }
  }

  Future<void> _setDefault(
    User user,
    String docId,
    List<QueryDocumentSnapshot> docs,
  ) async {
    final batch = FirebaseFirestore.instance.batch();
    for (final doc in docs) {
      batch.update(doc.reference, {'isDefault': doc.id == docId});
    }
    await batch.commit();
  }

  Widget _buildNotLoggedIn() {
    return const Center(
      child: Text(
        'Sign in to view saved addresses',
        style: TextStyle(color: Color(0xFF555555), fontSize: 14),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, User user) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.location_on_outlined,
            color: Color(0xFF222222),
            size: 64,
          ),
          const SizedBox(height: 16),
          const Text(
            'No saved addresses',
            style: TextStyle(
              color: Color(0xFF555555),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Add an address for faster checkout',
            style: TextStyle(color: Color(0xFF444444), fontSize: 13),
          ),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: () => _showAddressForm(context, user),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0A500),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Add Address',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Address Card ──────────────────────────────────────────────────────────────
class _AddressCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onSetDefault;

  const _AddressCard({
    required this.data,
    required this.onEdit,
    required this.onDelete,
    required this.onSetDefault,
  });

  @override
  Widget build(BuildContext context) {
    final isDefault = data['isDefault'] == true;
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF161616),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDefault ? const Color(0xFFF0A500) : const Color(0xFF2A2A2A),
          width: isDefault ? 1.5 : 1,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['label'] ?? 'Address',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (isDefault)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1200),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFF0A500)),
                  ),
                  child: const Text(
                    'Default',
                    style: TextStyle(
                      color: Color(0xFFF0A500),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            [
              data['line1'],
              data['city'],
              data['district'],
            ].where((e) => e != null && e.toString().isNotEmpty).join(', '),
            style: const TextStyle(
              color: Color(0xFF999999),
              fontSize: 12,
              height: 1.5,
            ),
          ),
          if (data['phone'] != null && data['phone'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                data['phone'],
                style: const TextStyle(color: Color(0xFF666666), fontSize: 11),
              ),
            ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (!isDefault)
                GestureDetector(
                  onTap: onSetDefault,
                  child: const Text(
                    'Set as default',
                    style: TextStyle(
                      color: Color(0xFFF0A500),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: onEdit,
                child: const Text(
                  'Edit',
                  style: TextStyle(color: Color(0xFF777777), fontSize: 12),
                ),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: onDelete,
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Color(0xFFff4444), fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Address Form ──────────────────────────────────────────────────────────────
class _AddressForm extends StatefulWidget {
  final User user;
  final String? docId;
  final Map<String, dynamic>? existing;

  const _AddressForm({required this.user, this.docId, this.existing});

  @override
  State<_AddressForm> createState() => _AddressFormState();
}

class _AddressFormState extends State<_AddressForm> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _labelCtrl;
  late final TextEditingController _line1Ctrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _districtCtrl;
  late final TextEditingController _phoneCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _labelCtrl = TextEditingController(text: e?['label'] ?? '');
    _line1Ctrl = TextEditingController(text: e?['line1'] ?? '');
    _cityCtrl = TextEditingController(text: e?['city'] ?? '');
    _districtCtrl = TextEditingController(text: e?['district'] ?? '');
    _phoneCtrl = TextEditingController(text: e?['phone'] ?? '');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _line1Ctrl.dispose();
    _cityCtrl.dispose();
    _districtCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final data = {
        'label': _labelCtrl.text.trim(),
        'line1': _line1Ctrl.text.trim(),
        'city': _cityCtrl.text.trim(),
        'district': _districtCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'isDefault': widget.existing?['isDefault'] ?? false,
        'createdAt': widget.docId == null
            ? FieldValue.serverTimestamp()
            : widget.existing?['createdAt'],
      };
      final col = FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.uid)
          .collection('addresses');
      if (widget.docId != null) {
        await col.doc(widget.docId).update(data);
      } else {
        await col.add(data);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Failed to save address')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.docId == null ? 'Add Address' : 'Edit Address',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 16),
            _FormField(
              ctrl: _labelCtrl,
              label: 'Label',
              hint: 'e.g. Home, Office',
            ),
            _FormField(
              ctrl: _line1Ctrl,
              label: 'Street Address',
              hint: 'e.g. 123 Main St',
              required: true,
            ),
            Row(
              children: [
                Expanded(
                  child: _FormField(
                    ctrl: _cityCtrl,
                    label: 'City',
                    hint: 'e.g. Colombo',
                    required: true,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _FormField(
                    ctrl: _districtCtrl,
                    label: 'District',
                    hint: 'e.g. Colombo',
                    required: true,
                  ),
                ),
              ],
            ),
            _FormField(
              ctrl: _phoneCtrl,
              label: 'Phone',
              hint: 'e.g. 0771234567',
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF0A500),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: _saving
                    ? const CircularProgressIndicator(
                        color: Colors.black,
                        strokeWidth: 2,
                      )
                    : Text(
                        widget.docId == null
                            ? 'Save Address'
                            : 'Update Address',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FormField extends StatelessWidget {
  final TextEditingController ctrl;
  final String label;
  final String hint;
  final bool required;
  final TextInputType? keyboard;

  const _FormField({
    required this.ctrl,
    required this.label,
    required this.hint,
    this.required = false,
    this.keyboard,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: required
            ? (v) => v!.isEmpty ? '$label is required' : null
            : null,
        style: const TextStyle(color: Colors.white, fontSize: 13),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF888888), fontSize: 12),
          hintStyle: const TextStyle(color: Color(0xFF444444), fontSize: 13),
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
        ),
      ),
    );
  }
}
