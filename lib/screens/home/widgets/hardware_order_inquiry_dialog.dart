import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../models/hardware_product_model.dart';
import '../../../services/hardware/hardware_service.dart';

class HardwareOrderInquiryDialog extends StatefulWidget {
  final HardwareProduct item;
  final Future<void> Function(String message) onOpenWhatsApp;

  const HardwareOrderInquiryDialog({
    super.key,
    required this.item,
    required this.onOpenWhatsApp,
  });

  static Future<void> show(
    BuildContext context, {
    required HardwareProduct item,
    required Future<void> Function(String message) onOpenWhatsApp,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => HardwareOrderInquiryDialog(
        item: item,
        onOpenWhatsApp: onOpenWhatsApp,
      ),
    );
  }

  @override
  State<HardwareOrderInquiryDialog> createState() => _HardwareOrderInquiryDialogState();
}

class _HardwareOrderInquiryDialogState extends State<HardwareOrderInquiryDialog> {
  int _qty = 1;
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _pincodeCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSubmitting = false;

  final _inFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _pincodeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final item = widget.item;
    final isServicePlan = item.id.startsWith('PLAN-');
    final unitPrice = item.effectivePrice;
    final totalPrice = unitPrice * _qty;

    final rawPhone = _phoneCtrl.text.trim();
    final digits = rawPhone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = digits.length == 12 && digits.startsWith('91')
        ? digits.substring(2)
        : (digits.length == 11 && digits.startsWith('0') ? digits.substring(1) : digits);

    HardwareOrderModel? order;
    String? orderError;

    try {
      order = await HardwareService.createOrder(
        productId: item.id,
        productName: item.name,
        price: unitPrice,
        totalPrice: totalPrice,
        quantity: _qty,
        contactName: _nameCtrl.text.trim(),
        contactPhone: cleanPhone,
        shippingAddress: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
      );
    } catch (e) {
      debugPrint('Hardware order database store error: $e');
      orderError = e.toString();
    }

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (order != null) {
      final orderNo = order.orderNumber.isNotEmpty
          ? order.orderNumber
          : 'HWO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order #$orderNo successfully recorded!'),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 4),
        ),
      );

      final teamLabel = isServicePlan ? 'SirfBill Team' : 'SirfBill Hardware Team';
      final msg =
          'Hello $teamLabel! I have placed Order #$orderNo for:\n• ${item.name} (${item.sku})\n• Quantity: $_qty\n• Total: ${_inFormat.format(totalPrice)}\n• Contact: ${_nameCtrl.text}, ${_addressCtrl.text}, ${_cityCtrl.text} - ${_pincodeCtrl.text}\n• Phone: $cleanPhone';
      await widget.onOpenWhatsApp(msg);
    } else {
      Navigator.pop(context);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order noted! Directing to WhatsApp (Backend note: $orderError)'),
          backgroundColor: Colors.orange.shade800,
          duration: const Duration(seconds: 4),
        ),
      );

      final teamLabel = isServicePlan ? 'SirfBill Team' : 'SirfBill Hardware Team';
      final msg =
          'Hello $teamLabel! I want to order:\n• ${item.name} (${item.sku})\n• Quantity: $_qty\n• Total: ${_inFormat.format(totalPrice)}\n• Name: ${_nameCtrl.text}\n• Phone: $cleanPhone\n• Address: ${_addressCtrl.text}, ${_cityCtrl.text} - ${_pincodeCtrl.text}';
      await widget.onOpenWhatsApp(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final isServicePlan = item.id.startsWith('PLAN-');
    final unitPrice = item.effectivePrice;
    final totalPrice = unitPrice * _qty;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isServicePlan ? 'Service Plan Order / Inquiry' : 'Hardware Order / Inquiry',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    'SKU: ${item.sku} • Price: ${unitPrice == 0 ? 'FREE' : _inFormat.format(unitPrice)} each',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                            onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                          ),
                          Text('$_qty', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline, size: 20),
                            onPressed: () => setState(() => _qty++),
                          ),
                        ],
                      ),
                      Text(
                        'Total: ${totalPrice == 0 ? 'FREE' : _inFormat.format(totalPrice)}',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Contact / Restaurant Name *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s\-]')),
                      LengthLimitingTextInputFormatter(15),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone / WhatsApp *',
                      hintText: 'e.g. 9876543210',
                      prefixIcon: Icon(Icons.phone_android_rounded, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    validator: (v) {
                      final raw = (v ?? '').trim();
                      if (raw.isEmpty) {
                        return 'Phone number is required';
                      }
                      final digits = raw.replaceAll(RegExp(r'\D'), '');
                      String tenDigit = digits;
                      if (digits.length == 12 && digits.startsWith('91')) {
                        tenDigit = digits.substring(2);
                      } else if (digits.length == 11 && digits.startsWith('0')) {
                        tenDigit = digits.substring(1);
                      }
                      if (tenDigit.length != 10) {
                        return 'Enter a valid 10-digit mobile number';
                      }
                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(tenDigit)) {
                        return 'Must be a valid mobile starting with 6, 7, 8, or 9';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: InputDecoration(
                      labelText: isServicePlan ? 'Restaurant / Billing Address *' : 'Delivery Address *',
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cityCtrl,
                          decoration: const InputDecoration(
                            labelText: 'City *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextFormField(
                          controller: _pincodeCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: const InputDecoration(
                            labelText: 'Pincode *',
                            hintText: '6 digits',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Required';
                            if (v.trim().length != 6) return '6-digit pincode';
                            return null;
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check_circle_rounded, size: 18),
                      label: _isSubmitting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : const Text('Confirm Order & Open WhatsApp'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isSubmitting ? null : _submitOrder,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
