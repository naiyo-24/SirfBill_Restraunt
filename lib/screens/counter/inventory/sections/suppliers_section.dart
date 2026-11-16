// ignore_for_file: duplicate_ignore, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import '../widgets/inventory_header.dart';
import '../widgets/supplier_details_dialog.dart';

class SuppliersSection extends StatefulWidget {
  const SuppliersSection({super.key});

  @override
  State<SuppliersSection> createState() => _SuppliersSectionState();
}

class _SuppliersSectionState extends State<SuppliersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Supplier> _suppliers = [];

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final list = await InventoryApiService.getSuppliers(search: _searchQuery);
      if (mounted) {
        setState(() => _suppliers = list);
      }
    } catch (_) {
      if (mounted) setState(() => _suppliers = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _suppliers.where((s) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.contactPerson.toLowerCase().contains(q) ||
          s.gstin.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Suppliers & Vendors Directory',
          subtitle: 'Manage supplier contacts, credit terms, GSTIN compliance and active orders',
          searchController: _searchController,
          onSearchChanged: (v) {
            setState(() => _searchQuery = v);
            _loadSuppliers();
          },
          searchHint: 'Search supplier, contact, or GSTIN...',
          onRefresh: _loadSuppliers,
          isRefreshing: _isLoading,
          trailing: ElevatedButton.icon(
            onPressed: () => _openAddSupplierDialog(context),
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Add Supplier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : filtered.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final supplier = filtered[index];
                        return _buildSupplierTile(context, supplier, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No suppliers registered', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Click "Add Supplier" to register your first kitchen vendor',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSupplierTile(BuildContext context, Supplier s, bool isDark) {
    final initialChar = s.name.isNotEmpty ? s.name.substring(0, 1).toUpperCase() : 'V';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFF10B981).withValues(alpha: 0.05),
          onTap: () => _openSupplierDetails(context, s),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  child: Text(
                    initialChar,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            s.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${s.paymentTermsDays}d Credit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact: ${s.contactPerson.isNotEmpty ? s.contactPerson : s.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${s.phone.isNotEmpty ? s.phone : 'Not provided'} • GST: ${s.gstin.isNotEmpty ? s.gstin : 'Unregistered'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (s.email.isNotEmpty || s.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (s.email.isNotEmpty) s.email,
                            if (s.address.isNotEmpty) s.address,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${s.activeOrderCount} Invoices',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSupplierDetails(BuildContext context, Supplier s) {
    showDialog(
      context: context,
      builder: (_) => SupplierDetailsDialog(
        supplier: s,
        onUpdated: _loadSuppliers,
      ),
    );
  }

  void _openAddSupplierDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final contactCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final gstinCtrl = TextEditingController();
    final termsCtrl = TextEditingController(text: '15');
    final addressCtrl = TextEditingController();
    bool isSaving = false;
    String? gstinError;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Add Supplier / Vendor'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameCtrl,
                    decoration: const InputDecoration(labelText: 'Company / Business Name *'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: contactCtrl,
                          decoration: const InputDecoration(labelText: 'Contact Person Name'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: phoneCtrl,
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
                    controller: emailCtrl,
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
                          controller: gstinCtrl,
                          maxLength: 15,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(15),
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            _UpperCaseInputFormatter(),
                          ],
                          onChanged: (val) {
                            setDialogState(() {
                              if (val.trim().isNotEmpty && val.trim().length != 15) {
                                gstinError = 'Must be 15 chars (${val.trim().length}/15)';
                              } else {
                                gstinError = null;
                              }
                            });
                          },
                          decoration: InputDecoration(
                            labelText: 'GSTIN (15 Chars)',
                            hintText: 'e.g. 19AAAAA0000A1Z5',
                            errorText: gstinError,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: termsCtrl,
                          keyboardType: TextInputType.number,
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(labelText: 'Credit Terms (Days)'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: addressCtrl,
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
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      final name = nameCtrl.text.trim();
                      if (name.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please enter supplier name'), backgroundColor: Colors.orange),
                        );
                        return;
                      }

                      final gstin = gstinCtrl.text.trim().toUpperCase();
                      if (gstin.isNotEmpty && gstin.length != 15) {
                        setDialogState(() {
                          gstinError = 'GSTIN must be exactly 15 alphanumeric characters';
                        });
                        return;
                      }

                      setDialogState(() => isSaving = true);
                      try {
                        await InventoryApiService.createSupplier({
                          'name': name,
                          'contact_person': contactCtrl.text.trim(),
                          'phone': phoneCtrl.text.trim(),
                          'email': emailCtrl.text.trim(),
                          'address': addressCtrl.text.trim(),
                          'gstin': gstin,
                          'payment_terms_days': int.tryParse(termsCtrl.text) ?? 15,
                        });
                        if (mounted) {
                          Navigator.pop(ctx);
                          _loadSuppliers();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Supplier registered successfully!'),
                              backgroundColor: Color(0xFF10B981),
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
                          );
                        }
                      } finally {
                        setDialogState(() => isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: isSaving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Save Supplier'),
            ),
          ],
        ),
      ),
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
