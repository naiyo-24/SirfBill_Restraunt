import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';

class CategoryFormDialog extends StatefulWidget {
  final IngredientCategory? initialCategory;

  const CategoryFormDialog({super.key, this.initialCategory});

  @override
  State<CategoryFormDialog> createState() => _CategoryFormDialogState();
}

class _CategoryFormDialogState extends State<CategoryFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _zoneController;

  bool _isSaving = false;
  String _selectedColorHex = '#10B981';

  static const List<Map<String, String>> _storagePresets = [
    {'label': 'Ambient (Dry)', 'zone': 'Ambient Store (Shelf A-C)'},
    {'label': 'Chiller (2°C - 4°C)', 'zone': 'Walk-in Chiller (2°C - 4°C)'},
    {'label': 'Deep Freezer (-18°C)', 'zone': 'Deep Freezer (-18°C)'},
    {'label': 'Bar Store', 'zone': 'Bar & Beverage Racks'},
  ];

  static const List<String> _colorPalette = [
    '#10B981', // Emerald
    '#3B82F6', // Blue
    '#F59E0B', // Amber
    '#EF4444', // Red
    '#8B5CF6', // Purple
    '#06B6D4', // Cyan
  ];

  @override
  void initState() {
    super.initState();
    final cat = widget.initialCategory;
    _nameController = TextEditingController(text: cat?.name ?? '');
    _zoneController = TextEditingController(
      text: cat?.storageZone ?? 'Ambient Store (Shelf A-C)',
    );

    if (cat != null) {
      _selectedColorHex = '#${cat.accentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      if (widget.initialCategory == null) {
        final result = await InventoryApiService.createCategory(
          name: _nameController.text.trim(),
          storageZoneTemp: _zoneController.text.trim(),
          colorCode: _selectedColorHex,
        );
        if (mounted) Navigator.pop(context, result);
      } else {
        final result = await InventoryApiService.updateCategory(
          widget.initialCategory!.id,
          name: _nameController.text.trim(),
          code: widget.initialCategory!.code,
          storageZoneTemp: _zoneController.text.trim(),
          colorCode: _selectedColorHex,
        );
        if (mounted) Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = widget.initialCategory != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 520,
        constraints: BoxConstraints(
          maxWidth: 520,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
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
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEditing ? 'Edit Storage Category' : 'New Storage Category',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, size: 20),
                  ),
                ],
              ),
              const Divider(height: 20),

              // Scrollable Body
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Category Name
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Category Name *',
                          hintText: 'e.g. Dry & Grain Pantry, Meat & Poultry',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 14),

                      // Storage Zone & Temperature Presets
                      const Text(
                        'Storage Zone & Temperature Spec',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: _storagePresets.map((preset) {
                          final isSelected = _zoneController.text == preset['zone'];
                          return ActionChip(
                            label: Text(preset['label']!, style: const TextStyle(fontSize: 11)),
                            backgroundColor: isSelected
                                ? const Color(0xFF10B981).withValues(alpha: 0.15)
                                : null,
                            side: BorderSide(
                              color: isSelected
                                  ? const Color(0xFF10B981)
                                  : Colors.grey.shade300,
                            ),
                            onPressed: () {
                              setState(() => _zoneController.text = preset['zone']!);
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _zoneController,
                        decoration: const InputDecoration(
                          labelText: 'Custom Zone / Shelf Label',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Accent Color Picker
                      const Text(
                        'Card Color Tag',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: _colorPalette.map((hex) {
                          final isSelected = _selectedColorHex == hex;
                          final color = Color(int.parse('FF${hex.replaceAll('#', '')}', radix: 16));
                          return GestureDetector(
                            onTap: () => setState(() => _selectedColorHex = hex),
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: isSelected
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: color.withValues(alpha: 0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        ),
                                      ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),
              // Footer Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isSaving ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditing ? 'Update Category' : 'Create Category'),
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
