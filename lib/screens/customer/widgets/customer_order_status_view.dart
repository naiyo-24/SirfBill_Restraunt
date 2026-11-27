import 'dart:async';
import 'package:flutter/material.dart';
import 'package:printing/printing.dart';
import '../../../../services/restaurant/customer_dining_service.dart';
import '../../../../utils/pdf_thermal_generator.dart';

class CustomerOrderStatusView extends StatefulWidget {
  final Map<String, dynamic> initialOrder;
  final Map<String, dynamic> tableInfo;
  final VoidCallback onOrderMore;
  final VoidCallback? onStartNewOrder;

  const CustomerOrderStatusView({
    super.key,
    required this.initialOrder,
    required this.tableInfo,
    required this.onOrderMore,
    this.onStartNewOrder,
  });

  @override
  State<CustomerOrderStatusView> createState() => _CustomerOrderStatusViewState();
}

class _CustomerOrderStatusViewState extends State<CustomerOrderStatusView> {
  late Map<String, dynamic> _order;
  Timer? _statusTimer;
  bool _isDownloadingBill = false;

  @override
  void initState() {
    super.initState();
    _order = widget.initialOrder;
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    final orderId = _order['id']?.toString() ?? _order['order_number']?.toString();
    if (orderId == null || orderId.isEmpty) return;

    _statusTimer = Timer.periodic(const Duration(seconds: 4), (_) async {
      final updated = await CustomerDiningService.fetchOrderStatus(orderId);
      if (updated != null && mounted) {
        setState(() => _order = updated);
      }
    });
  }

  Future<void> _downloadBillPdf() async {
    if (_isDownloadingBill) return;
    setState(() => _isDownloadingBill = true);
    try {
      final orderNumber = _order['order_number']?.toString() ?? 'BILL';
      final rawLines = (_order['lines'] is List) ? (_order['lines'] as List) : [];
      final items = rawLines.map((ln) {
        final qty = (ln['quantity'] is num) ? (ln['quantity'] as num).toInt() : 1;
        final unitPrice = double.tryParse((ln['unit_price'] ?? 0).toString()) ?? 0.0;
        final lineTotal = double.tryParse((ln['line_total'] ?? (unitPrice * qty)).toString()) ?? (unitPrice * qty);
        return <String, dynamic>{
          'name': ln['item_name']?.toString() ?? 'Item',
          'qty': qty,
          'quantity': qty,
          'price': unitPrice,
          'total': lineTotal,
        };
      }).toList();

      final subtotal = double.tryParse((_order['subtotal'] ?? 0).toString()) ?? 0.0;
      final discount = double.tryParse((_order['discount_amount'] ?? 0).toString()) ?? 0.0;
      final tax = double.tryParse((_order['tax_amount'] ?? 0).toString()) ?? 0.0;
      final grandTotal = double.tryParse((_order['grand_total'] ?? 0).toString()) ?? 0.0;
      final tableCode = widget.tableInfo['table_code']?.toString() ?? 'T1';
      final custName = _order['customer_name']?.toString() ?? 'Dine-in Guest';

      final pdfBytes = await PdfThermalGenerator.generateThermalBill(
        items: items,
        subtotal: subtotal,
        discount: discount,
        tax: tax,
        grandTotal: grandTotal,
        roundedTotal: grandTotal.roundToDouble(),
        invoiceNumber: orderNumber,
        customerName: '$custName • Table $tableCode',
        customerPhone: _order['customer_phone']?.toString(),
        shopName: widget.tableInfo['outlet_name']?.toString() ?? 'SirfBill Restaurant',
        address: widget.tableInfo['outlet_address']?.toString() ?? '',
        phone: widget.tableInfo['outlet_phone']?.toString() ?? '',
        shopGstNo: '',
      );

      await Printing.sharePdf(bytes: pdfBytes, filename: 'Receipt_$orderNumber.pdf');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not download bill: $e'), backgroundColor: const Color(0xFFEF4444)),
        );
      }
    } finally {
      if (mounted) setState(() => _isDownloadingBill = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (_order['status'] ?? 'PENDING_CONFIRMATION').toString().toUpperCase();
    final paymentStatus = (_order['payment_status'] ?? '').toString().toUpperCase();
    final orderNumber = _order['order_number']?.toString() ?? 'ORD';
    final grandTotal = double.tryParse((_order['grand_total'] ?? 0).toString()) ?? 0.0;
    final lines = (_order['lines'] is List) ? (_order['lines'] as List) : [];

    final isSettled = status == 'COMPLETED' || status == 'PAID' || paymentStatus == 'PAID';
    final isServed = status == 'SERVED';
    final isCancelled = status.contains('CANCEL') || status.contains('REJECT');
    final isConfirmed = !isSettled && !isCancelled && status != 'PENDING_CONFIRMATION';

    final tableCode = widget.tableInfo['table_code']?.toString() ?? 'T1';
    final section = widget.tableInfo['section']?.toString() ?? '1st Floor';

    Color themeColor;
    IconData icon;
    String statusTitle;
    String statusSubtitle;

    if (isSettled) {
      themeColor = const Color(0xFF059669);
      icon = Icons.celebration_rounded;
      statusTitle = 'Thank You for Dining With Us!';
      statusSubtitle = 'Your bill has been settled. We hope you enjoyed your meal and look forward to serving you again!';
    } else if (isCancelled) {
      themeColor = const Color(0xFFEF4444);
      icon = Icons.cancel_outlined;
      statusTitle = 'Order Declined';
      statusSubtitle = 'The counter could not accept this order. Please call a waiter for assistance.';
    } else if (isServed) {
      themeColor = const Color(0xFF059669);
      icon = Icons.restaurant_rounded;
      statusTitle = 'Served at Your Table!';
      statusSubtitle = 'Enjoy your meal! You can add more food items anytime.';
    } else if (isConfirmed) {
      themeColor = const Color(0xFF10B981);
      icon = Icons.soup_kitchen_rounded;
      statusTitle = 'Cooking in Kitchen!';
      statusSubtitle = 'Order confirmed by cashier & tickets sent to kitchen chefs.';
    } else {
      themeColor = const Color(0xFFF59E0B);
      icon = Icons.hourglass_top_rounded;
      statusTitle = 'Awaiting Counter Confirmation...';
      statusSubtitle = 'Your order is on the POS screen. Cashier will confirm and dispatch to kitchen momentarily.';
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: isSettled
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF0F172A)),
                onPressed: widget.onOrderMore,
                tooltip: 'Back to Menu',
              ),
        automaticallyImplyLeading: false,
        title: Text(
          isSettled ? 'Bill Settled' : 'Order $orderNumber',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
        ),
        actions: [
          if (!isSettled)
            TextButton.icon(
              onPressed: widget.onOrderMore,
              icon: const Icon(Icons.restaurant_menu_rounded, size: 16, color: Color(0xFF059669)),
              label: const Text('Menu', style: TextStyle(color: Color(0xFF059669), fontWeight: FontWeight.w700)),
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 10),
            // Header card
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: themeColor.withValues(alpha: 0.12),
                    ),
                    child: Icon(icon, size: 34, color: themeColor),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    statusTitle,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: themeColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    statusSubtitle,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFF64748B), height: 1.3),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Table $tableCode • $section', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(orderNumber, style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6366F1))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Order items list
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Items Ordered', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  ...lines.map((ln) {
                    final name = ln['item_name']?.toString() ?? 'Item';
                    final qty = ln['quantity']?.toString() ?? '1';
                    final tot = double.tryParse((ln['line_total'] ?? 0).toString()) ?? 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$qty x $name',
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
                            ),
                          ),
                          Text('₹${tot.toStringAsFixed(0)}', style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Amount', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900)),
                      Text('₹${grandTotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Download Bill + Add more items / Back to menu buttons
            if (isSettled) ...[
              SizedBox(
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: _isDownloadingBill ? null : _downloadBillPdf,
                  icon: _isDownloadingBill
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.download_rounded, size: 19),
                  label: Text(_isDownloadingBill ? 'Generating PDF...' : 'Download Bill (PDF)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            SizedBox(
              height: 48,
              child: isSettled
                  ? OutlinedButton.icon(
                      onPressed: widget.onStartNewOrder ?? widget.onOrderMore,
                      icon: const Icon(Icons.restaurant_menu_rounded, size: 18),
                      label: const Text('Back to Menu', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    )
                  : OutlinedButton.icon(
                      onPressed: widget.onOrderMore,
                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 18),
                      label: const Text('Add More Food Items', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF059669),
                        side: const BorderSide(color: Color(0xFF059669), width: 1.2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
