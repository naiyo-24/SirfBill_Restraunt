import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
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
    final totalPrice = item.price * _qty;

    try {
      final order = await HardwareService.createOrder(
        productId: item.id,
        quantity: _qty,
        contactName: _nameCtrl.text.trim(),
        contactPhone: _phoneCtrl.text.trim(),
        shippingAddress: _addressCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        pincode: _pincodeCtrl.text.trim(),
      );

      final orderNo = order?.orderNumber ??
          'HWO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
      final msg =
          'Hello SirfBill Hardware Team! I have placed Order #$orderNo for:\n• ${item.name} (${item.sku})\n• Quantity: $_qty\n• Total: ${_inFormat.format(totalPrice)}\n• Delivery to: ${_nameCtrl.text}, ${_addressCtrl.text}, ${_cityCtrl.text} - ${_pincodeCtrl.text}\n• Phone: ${_phoneCtrl.text}';

      if (mounted) Navigator.pop(context);
      await widget.onOpenWhatsApp(msg);
    } catch (_) {
      final msg =
          'Hello SirfBill Hardware Team! I want to purchase:\n• ${item.name} (${item.sku})\n• Quantity: $_qty\n• Name: ${_nameCtrl.text}\n• Phone: ${_phoneCtrl.text}\n• Address: ${_addressCtrl.text}, ${_cityCtrl.text} - ${_pincodeCtrl.text}';
      if (mounted) Navigator.pop(context);
      await widget.onOpenWhatsApp(msg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final totalPrice = item.price * _qty;

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
                      const Text(
                        'Hardware Order / Inquiry',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                    'SKU: ${item.sku} • Price: ${_inFormat.format(item.price)} each',
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
                        'Total: ${_inFormat.format(totalPrice)}',
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
                    decoration: const InputDecoration(
                      labelText: 'Contact Phone / WhatsApp *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    validator: (v) => v == null || v.length < 10 ? 'Enter valid 10-digit number' : null,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address *',
                      contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
                          decoration: const InputDecoration(
                            labelText: 'Pincode *',
                            contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                          ),
                          validator: (v) => v == null || v.length < 6 ? '6-digit pincode' : null,
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
