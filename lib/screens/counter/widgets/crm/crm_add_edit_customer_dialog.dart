import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../models/restaurant_crm_models.dart';

class CrmAddEditCustomerDialog extends StatefulWidget {
  final RestaurantCustomer? customer;
  final Future<bool> Function(Map<String, dynamic> data, {String? customerId}) onSave;

  const CrmAddEditCustomerDialog({
    super.key,
    this.customer,
    required this.onSave,
  });

  static Future<bool?> show(
    BuildContext context, {
    RestaurantCustomer? customer,
    required Future<bool> Function(Map<String, dynamic> data, {String? customerId}) onSave,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => CrmAddEditCustomerDialog(customer: customer, onSave: onSave),
    );
  }

  @override
  State<CrmAddEditCustomerDialog> createState() => _CrmAddEditCustomerDialogState();
}

class _CrmAddEditCustomerDialogState extends State<CrmAddEditCustomerDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _gstCtrl;
  late TextEditingController _creditLimitCtrl;
  late TextEditingController _notesCtrl;
  DateTime? _dob;
  DateTime? _anniversary;
  final List<String> _selectedDietaryTags = [];
  bool _isSubmitting = false;

  final List<String> _availableDietaryTags = [
    'Veg',
    'Non-Veg',
    'Jain',
    'Vegan',
    'Halal',
    'Gluten-Free',
    'Nut Allergy',
    'Less Spicy',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _gstCtrl = TextEditingController(text: c?.gstNumber ?? '');
    _creditLimitCtrl = TextEditingController(text: c != null ? c.creditLimit.toStringAsFixed(0) : '0');
    _notesCtrl = TextEditingController(text: c?.notes ?? '');
    _dob = c?.dob;
    _anniversary = c?.anniversary;
    if (c != null && c.tags.isNotEmpty) {
      _selectedDietaryTags.addAll(c.tags);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _gstCtrl.dispose();
    _creditLimitCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isDob}) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isDob ? _dob : _anniversary) ?? now,
      firstDate: DateTime(1920),
      lastDate: now,
    );
    if (picked != null) {
      setState(() {
        if (isDob) {
          _dob = picked;
        } else {
          _anniversary = picked;
        }
      });
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final df = DateFormat('yyyy-MM-dd');
    final payload = <String, dynamic>{
      'name': _nameCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
      if (_emailCtrl.text.trim().isNotEmpty) 'email': _emailCtrl.text.trim(),
      if (_gstCtrl.text.trim().isNotEmpty) 'gst_number': _gstCtrl.text.trim().toUpperCase(),
      'credit_limit': double.tryParse(_creditLimitCtrl.text.trim()) ?? 0.0,
      if (_dob != null) 'dob': df.format(_dob!),
      if (_anniversary != null) 'anniversary': df.format(_anniversary!),
      'tags': _selectedDietaryTags,
      if (_notesCtrl.text.trim().isNotEmpty) 'notes': _notesCtrl.text.trim(),
      'is_active': true,
    };

    try {
      final success = await widget.onSave(payload, customerId: widget.customer?.id);
      if (mounted) {
        if (success) {
          Navigator.pop(context, true);
        } else {
          setState(() => _isSubmitting = false);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving customer: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final df = DateFormat('dd MMM yyyy');

    return AlertDialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Icon(
            widget.customer == null ? Icons.person_add_rounded : Icons.edit_rounded,
            color: const Color(0xFF10B981),
            size: 22,
          ),
          const SizedBox(width: 10),
          Text(
            widget.customer == null ? 'New Guest Profile' : 'Edit Guest Profile',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name & Phone
                Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Guest Full Name *',
                          prefixIcon: Icon(Icons.person_outline, size: 18),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Mobile Phone *',
                          prefixIcon: Icon(Icons.phone_outlined, size: 18),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Phone is required';
                          final clean = v.replaceAll(RegExp(r'\D'), '');
                          if (clean.length < 8) return 'Enter valid phone';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Email & GSTIN
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(
                          labelText: 'Email Address (Optional)',
                          prefixIcon: Icon(Icons.mail_outline, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _gstCtrl,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: 'Corporate GSTIN',
                          prefixIcon: Icon(Icons.badge_outlined, size: 18),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Credit Limit
                TextFormField(
                  controller: _creditLimitCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Store Credit (Khata) Limit (₹)',
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined, size: 18),
                    helperText: 'Maximum dining credit tab allowed before settlement is required',
                  ),
                ),
                const SizedBox(height: 14),

                // Birthday & Anniversary
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cake_outlined, size: 16),
                        label: Text(_dob != null ? df.format(_dob!) : 'Date of Birth'),
                        onPressed: () => _pickDate(isDob: true),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.favorite_border_rounded, size: 16),
                        label: Text(_anniversary != null ? df.format(_anniversary!) : 'Anniversary'),
                        onPressed: () => _pickDate(isDob: false),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Dietary Preferences
                const Text('Dietary Tags & Allergies', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _availableDietaryTags.map((tag) {
                    final isSelected = _selectedDietaryTags.contains(tag);
                    return FilterChip(
                      label: Text(tag, style: const TextStyle(fontSize: 11)),
                      selected: isSelected,
                      selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                      checkmarkColor: const Color(0xFF10B981),
                      onSelected: (val) {
                        setState(() {
                          if (val) {
                            _selectedDietaryTags.add(tag);
                          } else {
                            _selectedDietaryTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Special Notes
                TextFormField(
                  controller: _notesCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Seating / VIP Service Notes',
                    hintText: 'e.g. Prefers window table, regular guest of Chef',
                    alignLabelWithHint: true,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: _isSubmitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(widget.customer == null ? 'Create Profile' : 'Save Changes'),
        ),
      ],
    );
  }
}
