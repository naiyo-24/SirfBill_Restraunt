import 'package:flutter/material.dart';
import '../../../../models/restaurant_crm_models.dart';

class CrmKhataSettleDialog extends StatefulWidget {
  final RestaurantCustomer customer;
  final Future<bool> Function({
    required String customerId,
    required double amount,
    required String paymentMode,
    String? notes,
  }) onSettle;

  const CrmKhataSettleDialog({
    super.key,
    required this.customer,
    required this.onSettle,
  });

  static Future<bool?> show(
    BuildContext context, {
    required RestaurantCustomer customer,
    required Future<bool> Function({
      required String customerId,
      required double amount,
      required String paymentMode,
      String? notes,
    }) onSettle,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CrmKhataSettleDialog(customer: customer, onSettle: onSettle),
    );
  }

  @override
  State<CrmKhataSettleDialog> createState() => _CrmKhataSettleDialogState();
}

class _CrmKhataSettleDialogState extends State<CrmKhataSettleDialog> {
  late TextEditingController _amountController;
  final TextEditingController _notesController = TextEditingController();
  String _selectedPaymentMode = 'CASH';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.customer.creditBalance > 0
          ? widget.customer.creditBalance.toStringAsFixed(2)
          : '0.00',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final amt = double.tryParse(_amountController.text.trim()) ?? 0.0;
    if (amt <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid settlement amount greater than 0')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final success = await widget.onSettle(
        customerId: widget.customer.id,
        amount: amt,
        paymentMode: _selectedPaymentMode,
        notes: _notesController.text.trim().isNotEmpty ? _notesController.text.trim() : null,
      );

      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Settled ₹${amt.toStringAsFixed(2)} for ${widget.customer.name}!'),
              backgroundColor: const Color(0xFF10B981),
            ),
          );
        } else {
          setState(() => _isSubmitting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Settlement error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEF4444).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.payments_rounded, color: Color(0xFFEF4444), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Settle Khata Dues', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                Text(
                  widget.customer.name,
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 400,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Outstanding due banner
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Outstanding Dues:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                  Text(
                    '₹${widget.customer.creditBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Settlement Amount
            const Text('Settlement Amount (₹)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _amountController,
              keyboardType: const TextInputTextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                prefixText: '₹ ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
            const SizedBox(height: 14),

            // Payment Mode
            const Text('Payment Mode', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: ['CASH', 'UPI', 'CARD', 'BANK_TRANSFER'].map((mode) {
                final isSelected = _selectedPaymentMode == mode;
                return ChoiceChip(
                  label: Text(mode),
                  selected: isSelected,
                  selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                  labelStyle: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? const Color(0xFF10B981) : null,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedPaymentMode = mode);
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Reference Notes
            const Text('Remarks / Transaction Ref', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'e.g. UPI Ref / Cash handed over to cashier',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSubmit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Record Payment'),
        ),
      ],
    );
  }
}
