import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/inventory_api_service.dart';

class AddSupplierDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const AddSupplierDialog({super.key, required this.onCreated});

  @override
  State<AddSupplierDialog> createState() => _AddSupplierDialogState();
}

class _AddSupplierDialogState extends State<AddSupplierDialog> {
  final _nameCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _gstinCtrl = TextEditingController();
  final _termsCtrl = TextEditingController(text: '15');
  final _addressCtrl = TextEditingController();

  bool _isSaving = false;
  String? _gstinError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstinCtrl.dispose();
    _termsCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter supplier name'), backgroundColor: Colors.orange),
      );
      return;
    }

    final gstin = _gstinCtrl.text.trim().toUpperCase();
    if (gstin.isNotEmpty && gstin.length != 15) {
      setState(() => _gstinError = 'GSTIN must be exactly 15 alphanumeric characters');
      return;
    }

    setState(() => _isSaving = true);
    try {
      await InventoryApiService.createSupplier({
        'name': name,
        'contact_person': _contactCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'gstin': gstin,
        'payment_terms_days': int.tryParse(_termsCtrl.text) ?? 15,
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier registered successfully!'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: const Text('Add Supplier / Vendor', style: TextStyle(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameCtrl,
                decoration: const InputDecoration(labelText: 'Company / Business Name *'),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _contactCtrl,
                      decoration: const InputDecoration(labelText: 'Contact Person Name'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(10),
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        hintText: '10-digit mobile number',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'e.g. billing@vendor.com',
                ),
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _gstinCtrl,
                      maxLength: 15,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(15),
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                        _UpperCaseInputFormatter(),
                      ],
                      onChanged: (val) {
                        setState(() {
                          if (val.trim().isNotEmpty && val.trim().length != 15) {
                            _gstinError = 'Must be 15 chars (${val.trim().length}/15)';
                          } else {
                            _gstinError = null;
                          }
                        });
                      },
                      decoration: InputDecoration(
                        labelText: 'GSTIN (15 Chars)',
                        hintText: 'e.g. 19AAAAA0000A1Z5',
                        errorText: _gstinError,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _termsCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Credit Terms (Days)'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Business Address',
                  hintText: 'Shop / Warehouse address',
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Supplier'),
        ),
      ],
    );
  }
}

class _UpperCaseInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}
