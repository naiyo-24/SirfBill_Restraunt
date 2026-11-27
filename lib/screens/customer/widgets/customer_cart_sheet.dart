import 'package:flutter/material.dart';

class CustomerCartSheet extends StatefulWidget {
  final Map<String, dynamic> tableInfo;
  final Map<String, int> cart;
  final List<Map<String, dynamic>> menuItems;
  final String? initialCustomerName;
  final String? initialCustomerPhone;
  final ValueChanged<Map<String, int>> onCartUpdated;
  final Future<void> Function({
    required String customerName,
    required String customerPhone,
    required String notes,
  }) onPlaceOrder;

  const CustomerCartSheet({
    super.key,
    required this.tableInfo,
    required this.cart,
    required this.menuItems,
    this.initialCustomerName,
    this.initialCustomerPhone,
    required this.onCartUpdated,
    required this.onPlaceOrder,
  });

  static void show(
    BuildContext context, {
    required Map<String, dynamic> tableInfo,
    required Map<String, int> cart,
    required List<Map<String, dynamic>> menuItems,
    String? initialCustomerName,
    String? initialCustomerPhone,
    required ValueChanged<Map<String, int>> onCartUpdated,
    required Future<void> Function({
      required String customerName,
      required String customerPhone,
      required String notes,
    }) onPlaceOrder,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CustomerCartSheet(
        tableInfo: tableInfo,
        cart: cart,
        menuItems: menuItems,
        initialCustomerName: initialCustomerName,
        initialCustomerPhone: initialCustomerPhone,
        onCartUpdated: onCartUpdated,
        onPlaceOrder: onPlaceOrder,
      ),
    );
  }

  @override
  State<CustomerCartSheet> createState() => _CustomerCartSheetState();
}

class _CustomerCartSheetState extends State<CustomerCartSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialCustomerName != null &&
        widget.initialCustomerName!.trim().isNotEmpty &&
        widget.initialCustomerName!.trim().toLowerCase() != 'dine-in guest') {
      _nameController.text = widget.initialCustomerName!.trim();
    }
    if (widget.initialCustomerPhone != null && widget.initialCustomerPhone!.trim().isNotEmpty) {
      _phoneController.text = widget.initialCustomerPhone!.trim();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Map<String, dynamic>? _findItem(String id) {
    try {
      return widget.menuItems.firstWhere((m) => m['id']?.toString() == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cartEntries = widget.cart.entries.where((e) => e.value > 0).toList();
    double subtotal = 0.0;
    for (final e in cartEntries) {
      final item = _findItem(e.key);
      if (item != null) {
        final p = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
        subtotal += p * e.value;
      }
    }
    final taxRate = double.tryParse((widget.tableInfo['tax_rate'] ?? 5.0).toString()) ?? 5.0;
    final taxAmt = (subtotal * taxRate) / 100.0;
    final grandTotal = (subtotal + taxAmt).roundToDouble();

    final tableCode = widget.tableInfo['table_code']?.toString() ?? 'T1';
    final section = widget.tableInfo['section']?.toString() ?? 'Dine-In';

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.shopping_bag_outlined, color: Color(0xFF10B981), size: 22),
                    SizedBox(width: 8),
                    Text(
                      'Your Table Order',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Table $tableCode • $section',
                    style: const TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold, fontSize: 11.5),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Cart Items List
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              children: [
                ...cartEntries.map((e) {
                  final item = _findItem(e.key);
                  if (item == null) return const SizedBox.shrink();
                  final name = item['name']?.toString() ?? 'Item';
                  final price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
                  final itemTotal = price * e.value;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                              Text('₹${price.toStringAsFixed(0)} each', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ),
                        Container(
                          height: 30,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 14),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  final newCart = Map<String, int>.from(widget.cart);
                                  if (e.value > 1) {
                                    newCart[e.key] = e.value - 1;
                                  } else {
                                    newCart.remove(e.key);
                                  }
                                  widget.onCartUpdated(newCart);
                                  if (newCart.isEmpty) Navigator.pop(context);
                                },
                              ),
                              Text('${e.value}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
                              IconButton(
                                icon: const Icon(Icons.add, size: 14),
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                constraints: const BoxConstraints(),
                                onPressed: () {
                                  final newCart = Map<String, int>.from(widget.cart);
                                  newCart[e.key] = e.value + 1;
                                  widget.onCartUpdated(newCart);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 14),
                        Text('₹${itemTotal.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
                      ],
                    ),
                  );
                }),

                const SizedBox(height: 12),
                const Divider(),
                const SizedBox(height: 8),

                // Special notes
                TextField(
                  controller: _notesController,
                  decoration: InputDecoration(
                    hintText: 'Special cooking requests (e.g. less spicy, no onions)...',
                    hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    prefixIcon: const Icon(Icons.notes_rounded, size: 18, color: Color(0xFF64748B)),
                    filled: true,
                    fillColor: const Color(0xFFF8FAFC),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(height: 10),

                // Customer info
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Your Name (Optional)',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.person_outline, size: 18, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          hintText: 'Mobile # (Optional)',
                          hintStyle: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF64748B)),
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Bill Breakdown
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Item Subtotal', style: TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                        Text('₹${subtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ]),
                      const SizedBox(height: 4),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Text('GST (${taxRate.toStringAsFixed(0)}%)', style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B))),
                        Text('₹${taxAmt.toStringAsFixed(1)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                      ]),
                      const Divider(height: 14),
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        const Text('Total Payable', style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                        Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                      ]),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Confirm Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isSubmitting
                    ? null
                    : () async {
                        setState(() => _isSubmitting = true);
                        try {
                          await widget.onPlaceOrder(
                            customerName: _nameController.text.trim(),
                            customerPhone: _phoneController.text.trim(),
                            notes: _notesController.text.trim(),
                          );
                          if (context.mounted) Navigator.pop(context);
                        } finally {
                          if (mounted) setState(() => _isSubmitting = false);
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isSubmitting
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Send Order to Kitchen (₹${grandTotal.toStringAsFixed(0)})',
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
