import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';

class SupplierDetailsDialog extends StatefulWidget {
  final Supplier supplier;
  final VoidCallback onUpdated;

  const SupplierDetailsDialog({
    super.key,
    required this.supplier,
    required this.onUpdated,
  });

  @override
  State<SupplierDetailsDialog> createState() => _SupplierDetailsDialogState();
}

class _SupplierDetailsDialogState extends State<SupplierDetailsDialog> {
  late Supplier _supplier;
  bool _isEditing = false;
  bool _isSaving = false;

  late TextEditingController _nameCtrl;
  late TextEditingController _contactCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstinCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _termsCtrl;
  String? _gstinError;

  @override
  void initState() {
    super.initState();
    _supplier = widget.supplier;
    _initControllers();
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: _supplier.name);
    _contactCtrl = TextEditingController(text: _supplier.contactPerson);
    _phoneCtrl = TextEditingController(text: _supplier.phone);
    _emailCtrl = TextEditingController(text: _supplier.email);
    _gstinCtrl = TextEditingController(text: _supplier.gstin);
    _addressCtrl = TextEditingController(text: _supplier.address);
    _termsCtrl = TextEditingController(text: _supplier.paymentTermsDays.toString());
    _gstinError = null;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _addressCtrl.dispose();
    _termsCtrl.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier name is required'), backgroundColor: Colors.orange),
      );
      return;
    }

    final gstin = _gstinCtrl.text.trim().toUpperCase();
    if (gstin.isNotEmpty && gstin.length != 15) {
      setState(() => _gstinError = 'Must be exactly 15 alphanumeric characters');
      return;
    }

    setState(() => _isSaving = true);
    try {
      final updated = await InventoryApiService.updateSupplier(_supplier.id, {
        'name': name,
        'contact_person': _contactCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'gstin': gstin,
        'address': _addressCtrl.text.trim(),
        'payment_terms_days': int.tryParse(_termsCtrl.text) ?? _supplier.paymentTermsDays,
      });

      if (mounted) {
        if (updated != null) {
          setState(() {
            _supplier = updated;
            _isEditing = false;
          });
        } else {
          setState(() => _isEditing = false);
        }
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier details updated!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Update failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteSupplier() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Supplier'),
        content: Text('Are you sure you want to delete "${_supplier.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await InventoryApiService.deleteSupplier(_supplier.id);
      if (ok && mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier deleted successfully'), backgroundColor: Color(0xFF10B981)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      child: Container(
        width: 560,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: _isEditing ? _buildEditForm(isDark) : _buildDetailsView(isDark),
              ),
            ),
            const SizedBox(height: 16),
            _buildFooterActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final initial = _supplier.name.isNotEmpty ? _supplier.name[0].toUpperCase() : 'V';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
          child: Text(
            initial,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _supplier.name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Verified Vendor',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              ),
            ],
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }

  Widget _buildDetailsView(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildMetricCard('Credit Terms', '${_supplier.paymentTermsDays} Days', Icons.calendar_month_outlined, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildMetricCard('Active Invoices', '${_supplier.activeOrderCount}', Icons.receipt_long_outlined, isDark)),
          ],
        ),
        const SizedBox(height: 20),
        const Text('Contact & Compliance', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildInfoTile('Contact Person', _supplier.contactPerson.isNotEmpty ? _supplier.contactPerson : 'Not provided', Icons.person_outline, isDark),
        _buildInfoTile('Phone Number', _supplier.phone.isNotEmpty ? _supplier.phone : 'Not provided', Icons.phone_outlined, isDark, canCopy: _supplier.phone.isNotEmpty),
        _buildInfoTile('Email Address', _supplier.email.isNotEmpty ? _supplier.email : 'Not provided', Icons.email_outlined, isDark, canCopy: _supplier.email.isNotEmpty),
        _buildInfoTile('GSTIN Number', _supplier.gstin.isNotEmpty ? _supplier.gstin : 'Unregistered', Icons.verified_outlined, isDark, canCopy: _supplier.gstin.isNotEmpty),
        _buildInfoTile('Business Address', _supplier.address.isNotEmpty ? _supplier.address : 'Not provided', Icons.location_on_outlined, isDark),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: const Color(0xFF10B981)),
              const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ],
          ),
          const SizedBox(height: 6),
          Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value, IconData icon, bool isDark, {bool canCopy = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Text('$label: ', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey)),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          if (canCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 14),
              tooltip: 'Copy',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$label copied to clipboard!'), duration: const Duration(seconds: 1)),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEditForm(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Company / Business Name *')),
        const SizedBox(height: 10),
        TextField(controller: _contactCtrl, decoration: const InputDecoration(labelText: 'Contact Person Name')),
        const SizedBox(height: 10),
        TextField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          inputFormatters: [LengthLimitingTextInputFormatter(10), FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(labelText: 'Phone Number (10 Digits)'),
        ),
        const SizedBox(height: 10),
        TextField(controller: _emailCtrl, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(labelText: 'Email Address')),
        const SizedBox(height: 10),
        TextField(
          controller: _gstinCtrl,
          maxLength: 15,
          textCapitalization: TextCapitalization.characters,
          inputFormatters: [
            LengthLimitingTextInputFormatter(15),
            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
          ],
          decoration: InputDecoration(
            labelText: 'GSTIN Number (15 Characters)',
            errorText: _gstinError,
          ),
        ),
        const SizedBox(height: 10),
        TextField(controller: _termsCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Credit Terms (Days)')),
        const SizedBox(height: 10),
        TextField(controller: _addressCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Business Address')),
      ],
    );
  }

  Widget _buildFooterActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (!_isEditing)
          TextButton.icon(
            onPressed: _deleteSupplier,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
            label: const Text('Delete Vendor', style: TextStyle(color: Colors.redAccent)),
          )
        else
          const SizedBox(),
        Row(
          children: [
            if (_isEditing)
              TextButton(
                onPressed: () {
                  setState(() {
                    _isEditing = false;
                    _initControllers();
                  });
                },
                child: const Text('Cancel'),
              ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _isSaving
                  ? null
                  : () {
                      if (_isEditing) {
                        _saveChanges();
                      } else {
                        setState(() => _isEditing = true);
                      }
                    },
              icon: Icon(_isEditing ? Icons.save : Icons.edit_outlined, size: 16),
              label: Text(_isEditing ? 'Save Changes' : 'Edit Vendor'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
