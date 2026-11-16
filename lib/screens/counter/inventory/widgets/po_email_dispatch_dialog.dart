import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/inventory_ops_models.dart';
import '../services/procurement_api_service.dart';
import '../utils/purchase_order_pdf_helper.dart';

class PoEmailDispatchDialog extends StatefulWidget {
  final PurchaseOrder po;
  final String? restaurantName;

  const PoEmailDispatchDialog({
    super.key,
    required this.po,
    this.restaurantName,
  });

  @override
  State<PoEmailDispatchDialog> createState() => _PoEmailDispatchDialogState();
}

class _PoEmailDispatchDialogState extends State<PoEmailDispatchDialog> {
  final _formKey = GlobalKey<FormState>();
  late PurchaseOrder _activePo;
  late TextEditingController _emailController;
  late TextEditingController _subjectController;
  late TextEditingController _messageController;
  bool _isSending = false;
  String _effectiveRestaurantName = '';

  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _activePo = widget.po;
    _effectiveRestaurantName = (widget.restaurantName != null && widget.restaurantName!.isNotEmpty)
        ? widget.restaurantName!
        : _activePo.outletName.trim();
    _emailController = TextEditingController(text: _activePo.supplierEmail);
    _subjectController = TextEditingController(
      text: 'Purchase Order ${_activePo.poNumber}${_effectiveRestaurantName.isNotEmpty ? " - $_effectiveRestaurantName" : ""}',
    );

    _messageController = TextEditingController(text: _buildMessageBody(_effectiveRestaurantName));
    _resolveProfileAndItems();
  }

  Future<void> _resolveProfileAndItems() async {
    PurchaseOrder poToUse = _activePo;
    if (poToUse.items.isEmpty && poToUse.id.isNotEmpty) {
      final full = await ProcurementApiService.getPurchaseOrderById(poToUse.id);
      if (full != null) {
        poToUse = full;
      }
    }

    String name = _effectiveRestaurantName;
    if (name.isEmpty) {
      if (poToUse.outletName.isNotEmpty) {
        name = poToUse.outletName;
      } else {
        final profile = await PurchaseOrderPdfHelper.loadActiveProfile();
        name = profile['name'] ?? '';
      }
    }

    if (mounted) {
      setState(() {
        _activePo = poToUse;
        _effectiveRestaurantName = name;
        _subjectController.text = 'Purchase Order ${_activePo.poNumber}${name.isNotEmpty ? " - $name" : ""}';
        _messageController.text = _buildMessageBody(name);
      });
    }
  }

  String _buildMessageBody(String restName) {
    final buffer = StringBuffer();
    buffer.writeln('Dear ${_activePo.supplierName},');
    buffer.writeln();
    buffer.writeln('Please find our Purchase Order ${_activePo.poNumber} for kitchen inventory replenishment.');
    buffer.writeln();
    buffer.writeln('--- ORDER DETAILS ---');
    buffer.writeln('Order Date: ${_dateFormat.format(_activePo.orderDate)}');
    buffer.writeln('Expected Delivery: ${_dateFormat.format(_activePo.expectedDeliveryDate)}');
    buffer.writeln('Total Line Items: ${_activePo.items.length}');
    buffer.writeln('Estimated Base Amount: Rs. ${_activePo.totalAmount.toStringAsFixed(2)}');
    buffer.writeln('(Physical invoice GST and delivery weights confirmed upon GRN dock receipt)');
    buffer.writeln();
    buffer.writeln('--- COMMODITY REQUISITION ---');
    for (int i = 0; i < _activePo.items.length; i++) {
      final it = _activePo.items[i];
      buffer.writeln('${i + 1}. ${it.ingredientName}: ${it.orderedQty.toStringAsFixed(1)} ${it.uom} @ Rs.${it.unitPrice.toStringAsFixed(2)} = Rs.${(it.orderedQty * it.unitPrice).toStringAsFixed(2)}');
    }
    if (_activePo.notes.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Delivery Instructions / Gate Pass: ${_activePo.notes}');
    }
    buffer.writeln();
    buffer.writeln('Kindly confirm receipt and expected delivery dispatch time.');
    if (restName.isNotEmpty) {
      buffer.writeln('Thank you,');
      buffer.writeln(restName);
    }
    return buffer.toString();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendViaMailClient() async {
    final toEmail = _emailController.text.trim();
    if (toEmail.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter supplier email address'), backgroundColor: Colors.red),
      );
      return;
    }

    final uri = Uri(
      scheme: 'mailto',
      path: toEmail,
      queryParameters: {
        'subject': _subjectController.text.trim(),
        'body': _messageController.text,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        if (widget.po.status == POStatus.draft) {
          try {
            await ProcurementApiService.issuePurchaseOrder(widget.po.id);
          } catch (_) {}
        }
        if (mounted) {
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Opened email client for PO dispatch'), backgroundColor: Color(0xFF10B981)),
          );
        }
      } else {
        throw 'Could not launch email app';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open email client: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _sendViaSystem() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSending = true);

    try {
      final res = await ProcurementApiService.emailPurchaseOrder(
        widget.po.id,
        recipientEmail: _emailController.text.trim(),
        customMessage: _messageController.text,
      );

      if (mounted) {
        Navigator.of(context).pop(true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(res['message']?.toString() ?? 'PO emailed successfully to vendor!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send email: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        constraints: BoxConstraints(maxWidth: 600, maxHeight: MediaQuery.of(context).size.height * 0.9),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mark_email_read_rounded, color: Color(0xFF3B82F6), size: 20),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Email Purchase Order',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          widget.po.poNumber,
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded, size: 20),
                  ),
                ],
              ),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Supplier Email Address *',
                          hintText: 'e.g. orders@supplier.com',
                          prefixIcon: const Icon(Icons.email_outlined, size: 18),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter email address' : null,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _subjectController,
                        style: const TextStyle(fontSize: 13),
                        decoration: InputDecoration(
                          labelText: 'Subject',
                          prefixIcon: const Icon(Icons.subject_rounded, size: 18),
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _messageController,
                        maxLines: 9,
                        style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
                        decoration: InputDecoration(
                          labelText: 'Order Summary Message Body',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          contentPadding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  OutlinedButton.icon(
                    onPressed: _isSending ? null : _sendViaMailClient,
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Open in Mail Client'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton.icon(
                        onPressed: _isSending ? null : _sendViaSystem,
                        icon: _isSending
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.send_rounded, size: 16),
                        label: const Text('Send PO Email'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
