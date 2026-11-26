import 'package:flutter/material.dart';
import '../../../../services/restaurant/customer_dining_service.dart';

class PendingQrOrdersDialog extends StatefulWidget {
  final String outletId;
  final VoidCallback onOrderConfirmed;

  const PendingQrOrdersDialog({
    super.key,
    required this.outletId,
    required this.onOrderConfirmed,
  });

  static void show(
    BuildContext context, {
    required String outletId,
    required VoidCallback onConfirmed,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PendingQrOrdersDialog(
        outletId: outletId,
        onOrderConfirmed: onConfirmed,
      ),
    );
  }

  @override
  State<PendingQrOrdersDialog> createState() => _PendingQrOrdersDialogState();
}

class _PendingQrOrdersDialogState extends State<PendingQrOrdersDialog> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _orders = [];
  String? _processingOrderId;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    final list = await CustomerDiningService.fetchPendingQrOrders(outletId: widget.outletId);
    if (mounted) {
      setState(() {
        _orders = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleConfirm(String orderId) async {
    setState(() => _processingOrderId = orderId);
    try {
      final ok = await CustomerDiningService.confirmQrOrder(orderId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                SizedBox(width: 8),
                Text('Order Confirmed & Automatically Sent to Kitchen KDS!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onOrderConfirmed();
        await _loadOrders();
        if (_orders.isEmpty && mounted) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _processingOrderId = null);
    }
  }

  Future<void> _handleReject(String orderId) async {
    setState(() => _processingOrderId = orderId);
    try {
      final ok = await CustomerDiningService.rejectQrOrder(orderId);
      if (ok && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Order has been declined.'),
            backgroundColor: Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
          ),
        );
        widget.onOrderConfirmed();
        await _loadOrders();
        if (_orders.isEmpty && mounted) {
          Navigator.pop(context);
        }
      }
    } finally {
      if (mounted) setState(() => _processingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 580,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.82,
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.notifications_active_rounded, color: Color(0xFFF59E0B), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Incoming Table QR Orders',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                        ),
                        Text(
                          '${_orders.length} order(s) awaiting cashier confirmation',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                        ),
                      ],
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Divider(height: 1),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : _orders.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 48, color: Color(0xFF10B981)),
                              SizedBox(height: 12),
                              Text('No pending QR orders at the moment.', style: TextStyle(color: Color(0xFF64748B), fontWeight: FontWeight.bold)),
                            ],
                          ),
                        )
                      : ListView.separated(
                          itemCount: _orders.length,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (context, idx) {
                            final ord = _orders[idx];
                            final oId = ord['id']?.toString() ?? '';
                            final oNum = ord['order_number']?.toString() ?? '';
                            final custName = ord['customer_name']?.toString() ?? 'Dine-in Guest';
                            final custPhone = ord['customer_phone']?.toString();
                            final notes = ord['notes']?.toString();
                            final grandTot = double.tryParse((ord['grand_total'] ?? 0).toString()) ?? 0.0;
                            final lines = (ord['lines'] is List) ? (ord['lines'] as List) : [];
                            final isBusy = _processingOrderId == oId;

                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.table_restaurant_rounded, size: 14, color: Color(0xFF6366F1)),
                                            const SizedBox(width: 4),
                                            Text(oNum, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF6366F1))),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '₹${grandTot.toStringAsFixed(0)}',
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Customer: $custName${custPhone != null && custPhone.isNotEmpty ? " ($custPhone)" : ""}',
                                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF334155)),
                                  ),
                                  if (notes != null && notes.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Note: "$notes"',
                                      style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFFF59E0B)),
                                    ),
                                  ],
                                  const SizedBox(height: 10),
                                  const Divider(height: 1),
                                  const SizedBox(height: 8),

                                  // Line items
                                  ...lines.map((ln) {
                                    final iname = ln['item_name']?.toString() ?? 'Item';
                                    final iqty = ln['quantity']?.toString() ?? '1';
                                    final itot = double.tryParse((ln['line_total'] ?? 0).toString()) ?? 0.0;
                                    return Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 2.5),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('$iqty x $iname', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
                                          Text('₹${itot.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                                        ],
                                      ),
                                    );
                                  }),

                                  const SizedBox(height: 14),
                                  // Action Buttons
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: isBusy ? null : () => _handleReject(oId),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: const Color(0xFFEF4444),
                                            side: const BorderSide(color: Color(0xFFEF4444)),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                          child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          onPressed: isBusy ? null : () => _handleConfirm(oId),
                                          icon: isBusy
                                              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                              : const Icon(Icons.soup_kitchen_rounded, size: 18),
                                          label: const Text('Confirm & Send to Kitchen', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF10B981),
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
