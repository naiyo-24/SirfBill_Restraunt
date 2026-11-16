import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import 'ingredient_image_picker.dart';

class AddIngredientDialog extends StatefulWidget {
  final Ingredient? initialIngredient;

  const AddIngredientDialog({super.key, this.initialIngredient});

  @override
  State<AddIngredientDialog> createState() => _AddIngredientDialogState();
}

class _AddIngredientDialogState extends State<AddIngredientDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _codeController;
  late final TextEditingController _conversionController;
  late final TextEditingController _currentStockController;
  late final TextEditingController _minParController;
  late final TextEditingController _idealParController;
  late final TextEditingController _costController;
  late final TextEditingController _storageController;

  List<IngredientCategory> _categories = [];
  List<Supplier> _suppliers = [];
  String _selectedCategory = '';
  String _purchaseUom = 'KG';
  String _recipeUom = 'G';
  String _selectedSupplier = '';
  String? _imageUrl;
  bool _isPerishable = false;
  bool _userEditedSku = false;
  bool _isSaving = false;

  String _generateSku(String name, [String? categoryId]) {
    final clean = name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '').toUpperCase();
    if (clean.isEmpty) return '';

    String prefix = 'ING';
    if (categoryId != null && categoryId.isNotEmpty) {
      final match = _categories.where((c) => c.id == categoryId).toList();
      if (match.isNotEmpty && match.first.code.trim().isNotEmpty) {
        prefix = match.first.code.trim().toUpperCase();
      }
    }

    final words = clean.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    String itemPart = '';
    if (words.length == 1) {
      itemPart = words[0].length <= 6 ? words[0] : words[0].substring(0, 6);
    } else if (words.length == 2) {
      final w1 = words[0].length <= 4 ? words[0] : words[0].substring(0, 4);
      final w2 = words[1].length <= 4 ? words[1] : words[1].substring(0, 4);
      itemPart = '$w1-$w2';
    } else {
      itemPart = words.take(3).map((w) => w.length <= 3 ? w : w.substring(0, 3)).join('-');
    }

    return '$prefix-$itemPart';
  }

  void _onNameChanged() {
    if (!_userEditedSku && widget.initialIngredient == null) {
      final name = _nameController.text;
      final autoSku = _generateSku(name, _selectedCategory);
      if (_codeController.text != autoSku) {
        _codeController.text = autoSku;
      }
    }
  }

  @override
  void initState() {
    super.initState();
    final init = widget.initialIngredient;
    String fmt(double? v, String def) =>
        v == null ? def : (v == v.roundToDouble() ? v.toInt().toString() : v.toString());

    _nameController = TextEditingController(text: init?.name ?? '');
    _codeController = TextEditingController(text: init?.code ?? '');
    _userEditedSku = init != null && init.code.isNotEmpty;
    _conversionController = TextEditingController(text: fmt(init?.uomConversionFactor, '1000'));
    _currentStockController = TextEditingController(text: fmt(init?.currentStock, '0'));
    _minParController = TextEditingController(text: fmt(init?.minParLevel, '5000'));
    _idealParController = TextEditingController(text: fmt(init?.idealParLevel, '20000'));
    _costController = TextEditingController(text: fmt(init?.costPerPurchaseUnit, '100'));
    _storageController = TextEditingController(text: init?.storageLocation ?? 'Ambient Store');

    if (init != null) {
      _selectedCategory = init.categoryId;
      _purchaseUom = init.purchaseUom;
      _recipeUom = init.recipeUom;
      _selectedSupplier = init.primarySupplierId;
      _isPerishable = init.isPerishable;
      _imageUrl = init.imageUrl;
    } else {
      _nameController.addListener(_onNameChanged);
    }

    _loadCategoriesAndSuppliers();
  }

  Future<void> _loadCategoriesAndSuppliers() async {
    try {
      final results = await Future.wait([
        InventoryApiService.getCategories(),
        InventoryApiService.getSuppliers(),
      ]);
      if (mounted) {
        setState(() {
          _categories = results[0] as List<IngredientCategory>;
          _suppliers = results[1] as List<Supplier>;
          if (_categories.isNotEmpty && (widget.initialIngredient == null || !_categories.any((c) => c.id == _selectedCategory))) {
            _selectedCategory = _categories.first.id;
          }
          if (_suppliers.isNotEmpty && (widget.initialIngredient == null || !_suppliers.any((s) => s.id == _selectedSupplier))) {
            _selectedSupplier = _suppliers.first.id;
          }
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _nameController.removeListener(_onNameChanged);
    for (final c in [_nameController, _codeController, _conversionController, _currentStockController, _minParController, _idealParController, _costController, _storageController]) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialIngredient != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 650,
        constraints: BoxConstraints(maxWidth: 650, maxHeight: MediaQuery.of(context).size.height * 0.85),
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
                  Text(
                    isEditing ? 'Edit Ingredient' : 'Add New Ingredient',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20)),
                ],
              ),
              const Divider(height: 20),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTextField(
                              controller: _nameController,
                              label: 'Ingredient Name',
                              hint: 'e.g. Basmati Rice, Chicken',
                              validator: (v) => v!.isEmpty ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildTextField(
                              controller: _codeController,
                              label: 'SKU / Code',
                              hint: 'Auto-generated',
                              onChanged: (_) => setState(() => _userEditedSku = true),
                              suffixIcon: Container(
                                margin: const EdgeInsets.all(8),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _userEditedSku ? 'CUSTOM' : 'AUTO',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _userEditedSku ? Colors.orange : const Color(0xFF10B981),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      IngredientImagePicker(
                        initialImageUrl: _imageUrl,
                        onImageChanged: (url) => setState(() => _imageUrl = url),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildCategoryDropdown()),
                          const SizedBox(width: 12),
                          Expanded(child: _buildSupplierDropdown()),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildUomDropdown(label: 'Purchase Unit (Supplier)', value: _purchaseUom, onChanged: (v) => setState(() => _purchaseUom = v!))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildUomDropdown(label: 'Recipe Unit (Kitchen BOM)', value: _recipeUom, onChanged: (v) => setState(() => _recipeUom = v!))),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _conversionController, label: 'Conversion (1 Purchase = X Recipe)', hint: '1000', keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _buildTextField(controller: _currentStockController, label: 'Current Stock ($_recipeUom)', hint: '0', keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _minParController, label: 'Min Par Level (Alert)', hint: '5000', keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _idealParController, label: 'Ideal Par Level', hint: '20000', keyboardType: TextInputType.number)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildTextField(controller: _costController, label: 'Cost / Purchase Unit (₹)', hint: '280', keyboardType: TextInputType.number)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _storageController,
                              label: 'Storage Location',
                              hint: 'Shelf A / Deep Freezer',
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Material(
                              color: Colors.transparent,
                              child: SwitchListTile(
                                title: const Text('Perishable item', style: TextStyle(fontSize: 13)),
                                subtitle: const Text('Track shelf life & expiry', style: TextStyle(fontSize: 11)),
                                value: _isPerishable,
                                activeThumbColor: const Color(0xFF10B981),
                                contentPadding: EdgeInsets.zero,
                                onChanged: (v) => setState(() => _isPerishable = v),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _saveIngredient,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(widget.initialIngredient == null ? 'Save Ingredient' : 'Update Ingredient'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    Widget? suffixIcon,
    ValueChanged<String>? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 12, color: Colors.grey),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryDropdown() {
    final validCategory = _categories.any((c) => c.id == _selectedCategory)
        ? _selectedCategory
        : (_categories.isNotEmpty ? _categories.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Category', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: validCategory,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: _categories.isEmpty ? 'No Categories Configured' : 'Select Category',
          ),
          items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) {
            if (v != null) {
              setState(() {
                _selectedCategory = v;
                if (!_userEditedSku && _nameController.text.trim().isNotEmpty) {
                  _codeController.text = _generateSku(_nameController.text, v);
                }
              });
            }
          },
        ),
      ],
    );
  }

  Widget _buildSupplierDropdown() {
    final validSupplier = _suppliers.any((s) => s.id == _selectedSupplier)
        ? _selectedSupplier
        : (_suppliers.isNotEmpty ? _suppliers.first.id : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Primary Supplier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: validSupplier,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            hintText: _suppliers.isEmpty ? 'No Suppliers Added' : 'Select Supplier',
          ),
          items: _suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: (v) {
            if (v != null) setState(() => _selectedSupplier = v);
          },
        ),
      ],
    );
  }

  Widget _buildUomDropdown({
    required String label,
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    final units = ['KG', 'G', 'L', 'ML', 'PCS', 'DOZ', 'BAG', 'BOX'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
          items: units.map((u) => DropdownMenuItem(value: u, child: Text(u, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Future<void> _saveIngredient() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final sku = _codeController.text.trim().isNotEmpty && _codeController.text.trim() != 'ING-'
          ? _codeController.text.trim()
          : _generateSku(_nameController.text, _selectedCategory);

      String? finalImageUrl = (_imageUrl != null && _imageUrl!.trim().isNotEmpty) ? _imageUrl!.trim() : null;
      if (finalImageUrl != null && (finalImageUrl.startsWith('http://') || finalImageUrl.startsWith('https://'))) {
        try {
          final uploaded = await InventoryApiService.uploadIngredientFromUrl(finalImageUrl);
          if (uploaded != null && uploaded.isNotEmpty) {
            finalImageUrl = uploaded;
            _imageUrl = uploaded;
          }
        } catch (_) {}
      }

      final payload = {
        'name': _nameController.text.trim(),
        'sku': sku.isNotEmpty ? sku : 'ING-ITEM',
        'code': sku.isNotEmpty ? sku : 'ING-ITEM',
        'unit': _recipeUom,
        'recipe_uom': _recipeUom,
        'purchase_uom': _purchaseUom,
        'category_id': _selectedCategory.isNotEmpty ? _selectedCategory : null,
        'uom_conversion_factor': double.tryParse(_conversionController.text) ?? 1000.0,
        'current_stock': double.tryParse(_currentStockController.text) ?? 0.0,
        'reorder_level': double.tryParse(_minParController.text) ?? 0.0,
        'min_par_level': double.tryParse(_minParController.text) ?? 0.0,
        'ideal_par_level': double.tryParse(_idealParController.text) ?? 0.0,
        'cost_per_purchase_unit': double.tryParse(_costController.text) ?? 0.0,
        'primary_supplier_id': _selectedSupplier.isNotEmpty ? _selectedSupplier : null,
        'storage_location': _storageController.text.trim(),
        'storage_zone': _storageController.text.trim(),
        'is_perishable': _isPerishable,
        'image_url': finalImageUrl,
        'is_active': true,
      };

      Ingredient? saved = widget.initialIngredient != null
          ? await InventoryApiService.updateIngredient(widget.initialIngredient!.id, payload)
          : await InventoryApiService.createIngredient(payload);

      if (mounted) {
        Navigator.of(context).pop(saved);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.initialIngredient != null ? 'Ingredient updated!' : 'Ingredient created!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}
