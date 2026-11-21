import 'package:flutter/material.dart';
import '../../../models/hardware_product_model.dart';
import '../../../services/hardware/hardware_service.dart';

class AddEditHardwareProductDialog extends StatefulWidget {
  final HardwareProduct? existingProduct;
  final VoidCallback onSaved;

  const AddEditHardwareProductDialog({
    super.key,
    this.existingProduct,
    required this.onSaved,
  });

  @override
  State<AddEditHardwareProductDialog> createState() => _AddEditHardwareProductDialogState();
}

class _AddEditHardwareProductDialogState extends State<AddEditHardwareProductDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _skuCtrl;
  late TextEditingController _nameCtrl;
  late TextEditingController _brandCtrl;
  late TextEditingController _modelCtrl;
  late TextEditingController _shortDescCtrl;
  late TextEditingController _descCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _mrpCtrl;
  late TextEditingController _taxRateCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _warrantyCtrl;
  late TextEditingController _imageCtrl;
  late TextEditingController _featuresCtrl;

  String _category = 'PRINTER';
  bool _isPopular = false;
  bool _isFeatured = false;
  bool _isActive = true;
  bool _isSaving = false;

  final List<Map<String, String>> _categories = [
    {'key': 'PRINTER', 'label': 'Thermal Printers'},
    {'key': 'POS_TERMINAL', 'label': 'POS Terminals'},
    {'key': 'HANDHELD_PDA', 'label': 'Handheld Captains'},
    {'key': 'KDS_DISPLAY', 'label': 'Kitchen KDS'},
    {'key': 'CASH_DRAWER', 'label': 'Cash Drawers'},
    {'key': 'SCANNER', 'label': 'Barcode & QR Scanners'},
    {'key': 'PAPER_ROLLS', 'label': 'Thermal Paper Rolls'},
    {'key': 'ACCESSORY', 'label': 'Cables & Accessories'},
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.existingProduct;
    _skuCtrl = TextEditingController(text: p?.sku ?? '');
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _brandCtrl = TextEditingController(text: p?.brand ?? 'SirfBill');
    _modelCtrl = TextEditingController(text: p?.modelNumber ?? '');
    _shortDescCtrl = TextEditingController(text: p?.shortDescription ?? '');
    _descCtrl = TextEditingController(text: p?.description ?? '');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _mrpCtrl = TextEditingController(text: p != null ? p.mrp.toStringAsFixed(0) : '');
    _taxRateCtrl = TextEditingController(text: p != null ? p.taxRate.toStringAsFixed(0) : '18');
    _stockCtrl = TextEditingController(text: p != null ? p.stockQuantity.toString() : '20');
    _warrantyCtrl = TextEditingController(text: p != null ? p.warrantyMonths.toString() : '12');
    _imageCtrl = TextEditingController(text: p?.primaryImageUrl ?? '');
    _featuresCtrl = TextEditingController(text: p?.features.join('\n') ?? '');

    if (p != null) {
      _category = p.category.toUpperCase();
      _isPopular = p.isPopular;
      _isFeatured = p.isFeatured;
      _isActive = p.isActive;
    }
  }

  @override
  void dispose() {
    _skuCtrl.dispose();
    _nameCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    _shortDescCtrl.dispose();
    _descCtrl.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _taxRateCtrl.dispose();
    _stockCtrl.dispose();
    _warrantyCtrl.dispose();
    _imageCtrl.dispose();
    _featuresCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final featuresList = _featuresCtrl.text
        .split('\n')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final payload = {
      'sku': _skuCtrl.text.trim(),
      'name': _nameCtrl.text.trim(),
      'category': _category,
      'brand': _brandCtrl.text.trim(),
      'model_number': _modelCtrl.text.trim(),
      'short_description': _shortDescCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'price': double.tryParse(_priceCtrl.text) ?? 0.0,
      'mrp': double.tryParse(_mrpCtrl.text) ?? (double.tryParse(_priceCtrl.text) ?? 0.0),
      'tax_rate': double.tryParse(_taxRateCtrl.text) ?? 18.0,
      'stock_quantity': int.tryParse(_stockCtrl.text) ?? 0,
      'warranty_months': int.tryParse(_warrantyCtrl.text) ?? 12,
      'primary_image_url': _imageCtrl.text.trim(),
      'features': featuresList,
      'is_popular': _isPopular,
      'is_featured': _isFeatured,
      'is_active': _isActive,
      'in_stock': (int.tryParse(_stockCtrl.text) ?? 0) > 0,
    };

    try {
      if (widget.existingProduct != null) {
        await HardwareService.updateProduct(widget.existingProduct!.id, payload);
      } else {
        await HardwareService.createProduct(payload);
      }
      widget.onSaved();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving product: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.existingProduct != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 800),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isEdit ? 'Edit Hardware Product' : 'List New Hardware Product',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                Expanded(
                  child: ListView(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _skuCtrl,
                              decoration: const InputDecoration(labelText: 'SKU Identifier *', hintText: 'e.g. SB-PRN-80MM-PRO'),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _categories.any((c) => c['key'] == _category) ? _category : 'PRINTER',
                              decoration: const InputDecoration(labelText: 'Category *'),
                              items: _categories.map((c) => DropdownMenuItem(value: c['key'], child: Text(c['label']!))).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _category = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: const InputDecoration(labelText: 'Product Name *', hintText: 'e.g. SirfBill 80mm High-Speed Thermal Printer'),
                        validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _brandCtrl,
                              decoration: const InputDecoration(labelText: 'Brand', hintText: 'SirfBill'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _modelCtrl,
                              decoration: const InputDecoration(labelText: 'Model Number', hintText: 'SB-80T Pro'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _priceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Selling Price (₹) *', prefixText: '₹ '),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _mrpCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'MRP (₹) *', prefixText: '₹ '),
                              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _taxRateCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'GST Rate %', suffixText: '%'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Stock Units', hintText: '25'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _warrantyCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Warranty (Months)', hintText: '12'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _shortDescCtrl,
                        maxLines: 2,
                        decoration: const InputDecoration(labelText: 'Short Description', hintText: 'One line technical summary for card listing'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _descCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Full Description', hintText: 'Detailed product description, ports, compatibility'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _featuresCtrl,
                        maxLines: 3,
                        decoration: const InputDecoration(labelText: 'Bullet Features (One per line)', hintText: 'Triple Interface: USB + LAN + Bluetooth\nAuto-Cutter (1.5M cuts)'),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _imageCtrl,
                        decoration: const InputDecoration(labelText: 'Primary Image URL (Optional)', hintText: 'https://...'),
                      ),
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          FilterChip(
                            label: const Text('Popular / Bestseller'),
                            selected: _isPopular,
                            onSelected: (v) => setState(() => _isPopular = v),
                            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                          ),
                          FilterChip(
                            label: const Text('Featured on Home'),
                            selected: _isFeatured,
                            onSelected: (v) => setState(() => _isFeatured = v),
                            selectedColor: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                          ),
                          FilterChip(
                            label: const Text('Active for Sale'),
                            selected: _isActive,
                            onSelected: (v) => setState(() => _isActive = v),
                            selectedColor: const Color(0xFF6366F1).withValues(alpha: 0.2),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: _isSaving ? null : _handleSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      ),
                      child: _isSaving
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text(isEdit ? 'Update Product' : 'List Product'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
