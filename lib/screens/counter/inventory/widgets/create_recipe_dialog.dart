import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../services/restaurant/restaurant_menu_service.dart';
import '../models/inventory_models.dart';
import '../models/recipe_models.dart';
import '../services/inventory_api_service.dart';
import '../services/recipe_api_service.dart';

class CreateRecipeDialog extends StatefulWidget {
  final RecipeModel? existingRecipe;
  final VoidCallback? onSaved;

  const CreateRecipeDialog({super.key, this.existingRecipe, this.onSaved});

  static Future<void> show(BuildContext context, {RecipeModel? existingRecipe, VoidCallback? onSaved}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateRecipeDialog(existingRecipe: existingRecipe, onSaved: onSaved),
    );
  }

  @override
  State<CreateRecipeDialog> createState() => _CreateRecipeDialogState();
}

class _RecipeLineDraft {
  Ingredient? ingredient;
  final TextEditingController qtyController = TextEditingController(text: '100');
  String unit = 'G';
  _RecipeLineDraft({this.ingredient, double initialQty = 100.0, String? initialUnit}) {
    qtyController.text = initialQty.toStringAsFixed(initialQty.truncateToDouble() == initialQty ? 0 : 2);
    if (initialUnit != null) unit = initialUnit;
  }
}

class _CreateRecipeDialogState extends State<CreateRecipeDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _yieldController = TextEditingController(text: '1.0');
  final TextEditingController _instructionsController = TextEditingController();
  final TextEditingController _variantController = TextEditingController(text: 'Standard');

  List<PosMenuItem> _menuItems = [];
  List<Ingredient> _ingredients = [];
  PosMenuItem? _selectedMenuItem;
  final List<_RecipeLineDraft> _lines = [];

  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadDependencies();
  }

  @override
  void dispose() {
    _yieldController.dispose();
    _instructionsController.dispose();
    _variantController.dispose();
    for (final l in _lines) {
      l.qtyController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadDependencies() async {
    try {
      final items = await RestaurantMenuService.fetchMenuItems();
      final ings = await InventoryApiService.getIngredients();

      if (mounted) {
        setState(() {
          _menuItems = items;
          _ingredients = ings;
          _isLoading = false;

          if (widget.existingRecipe != null) {
            final er = widget.existingRecipe!;
            _variantController.text = er.variantName;
            _yieldController.text = er.yieldServings.toStringAsFixed(1);
            _instructionsController.text = er.instructions ?? '';
            _selectedMenuItem = items.where((m) => m.id == er.itemId).firstOrNull;

            for (final line in er.lines) {
              final matchedIng = ings.where((i) => i.id == line.ingredientId).firstOrNull;
              _lines.add(_RecipeLineDraft(
                ingredient: matchedIng,
                initialQty: line.quantityRequired,
                initialUnit: line.unit,
              ));
            }
          }

          if (_lines.isEmpty) {
            _lines.add(_RecipeLineDraft(
              ingredient: ings.isNotEmpty ? ings.first : null,
              initialUnit: ings.isNotEmpty ? (ings.first.recipeUom.isNotEmpty ? ings.first.recipeUom : 'G') : 'G',
            ));
          }
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _estimatedTotalBatchCost {
    double total = 0.0;
    for (final line in _lines) {
      final ing = line.ingredient;
      if (ing != null) {
        final qty = double.tryParse(line.qtyController.text) ?? 0.0;
        final fromUnit = line.unit.trim().toUpperCase();
        final targetUom = (ing.recipeUom.isNotEmpty ? ing.recipeUom : 'G').trim().toUpperCase();
        double normQty = qty;
        if (fromUnit != targetUom) {
          if ((fromUnit == 'KG' && targetUom == 'G') || (fromUnit == 'LTR' && targetUom == 'ML')) {
            normQty = qty * 1000.0;
          } else if ((fromUnit == 'G' && targetUom == 'KG') || (fromUnit == 'ML' && targetUom == 'LTR')) {
            normQty = qty / 1000.0;
          } else if (fromUnit == 'DOZEN' && targetUom == 'PCS') {
            normQty = qty * 12.0;
          } else if (fromUnit == 'PCS' && targetUom == 'DOZEN') {
            normQty = qty / 12.0;
          }
        }
        total += normQty * ing.costPerRecipeUnit;
      }
    }
    return total;
  }

  Future<void> _saveRecipe() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedMenuItem == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a menu dish from the POS catalog.')));
      return;
    }
    if (_lines.isEmpty || _lines.any((l) => l.ingredient == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add valid ingredients to all recipe lines.')));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final yieldVal = double.tryParse(_yieldController.text) ?? 1.0;
      final outletId = await RecipeApiService.getResolvedOutletId();
      final payload = {
        if (widget.existingRecipe != null) 'id': widget.existingRecipe!.id,
        if (outletId.isNotEmpty) 'outlet_id': outletId,
        'item_id': _selectedMenuItem!.id,
        'variant_name': _variantController.text.trim().isEmpty ? 'Standard' : _variantController.text.trim(),
        'yield_servings': yieldVal,
        'instructions': _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
        'lines': _lines.map((l) {
          final qty = double.tryParse(l.qtyController.text) ?? 1.0;
          return {
            'ingredient_id': l.ingredient!.id,
            'quantity_required': qty,
            'unit': l.unit,
          };
        }).toList(),
      };

      await RecipeApiService.createOrUpdateRecipe(payload);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Recipe Bill of Materials (BOM) saved successfully!'),
          backgroundColor: Color(0xFF10B981),
        ));
        Navigator.pop(context);
        widget.onSaved?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save recipe: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Container(
        width: 820,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(context, isDark),
                    const SizedBox(height: 16),
                    _buildDishAndYieldSelectors(isDark),
                    const SizedBox(height: 16),
                    _buildLinesHeader(),
                    const SizedBox(height: 8),
                    Expanded(child: _buildLinesList(isDark)),
                    const SizedBox(height: 12),
                    _buildEstimatedCostSummary(isDark),
                    const SizedBox(height: 16),
                    _buildActions(context),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final isEdit = widget.existingRecipe != null;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.menu_book_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? 'Edit Recipe Bill of Materials (BOM)' : 'Create Recipe Bill of Materials (BOM)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                const SizedBox(height: 2),
                Text(
                  'Map menu dishes to raw commodities with automatic Dual-UOM normalization (KG/G/ML/LTR)',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20)),
      ],
    );
  }

  Widget _buildDishAndYieldSelectors(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<PosMenuItem>(
                  initialValue: _selectedMenuItem,
                  decoration: const InputDecoration(labelText: 'Menu Item / Dish *', border: OutlineInputBorder(), isDense: true),
                  items: _menuItems.map((m) => DropdownMenuItem(value: m, child: Text('${m.name} (₹${m.price.toStringAsFixed(0)})'))).toList(),
                  onChanged: (val) => setState(() => _selectedMenuItem = val),
                  validator: (v) => v == null ? 'Select dish' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _variantController,
                  decoration: const InputDecoration(labelText: 'Variant', hintText: 'Standard / Half / Full', border: OutlineInputBorder(), isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _yieldController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Yield (Servings) *', border: OutlineInputBorder(), isDense: true),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter > 0' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TextFormField(
            controller: _instructionsController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Culinary Preparation & Plating Notes (Optional)', border: OutlineInputBorder(), isDense: true),
          ),
        ],
      ),
    );
  }

  Widget _buildLinesHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('RAW INGREDIENT REQUIREMENTS (DUAL-UOM NORMALIZED)', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ElevatedButton.icon(
          onPressed: () {
            setState(() {
              _lines.add(_RecipeLineDraft(
                ingredient: _ingredients.isNotEmpty ? _ingredients.first : null,
                initialUnit: _ingredients.isNotEmpty ? (_ingredients.first.recipeUom.isNotEmpty ? _ingredients.first.recipeUom : 'G') : 'G',
              ));
            });
          },
          icon: const Icon(Icons.add, size: 14),
          label: const Text('Add Ingredient Line', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
        ),
      ],
    );
  }

  Widget _buildLinesList(bool isDark) {
    final units = ['G', 'KG', 'ML', 'LTR', 'PCS', 'DOZEN', 'PORTION', 'TSP', 'TBSP'];
    return ListView.builder(
      itemCount: _lines.length,
      itemBuilder: (context, index) {
        final line = _lines[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: DropdownButtonFormField<Ingredient>(
                  initialValue: line.ingredient,
                  decoration: const InputDecoration(labelText: 'Ingredient', isDense: true, border: OutlineInputBorder()),
                  items: _ingredients.map((i) => DropdownMenuItem(value: i, child: Text('${i.name} (₹${i.costPerPurchaseUnit.toStringAsFixed(1)}/${i.purchaseUom})'))).toList(),
                  onChanged: (val) {
                    setState(() {
                      line.ingredient = val;
                      if (val != null && val.recipeUom.isNotEmpty) line.unit = val.recipeUom;
                    });
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: line.qtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Quantity', isDense: true, border: OutlineInputBorder()),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: units.contains(line.unit) ? line.unit : 'G',
                  decoration: const InputDecoration(labelText: 'UOM Unit', isDense: true, border: OutlineInputBorder()),
                  items: units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) => setState(() => line.unit = val ?? 'G'),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFEF4444), size: 20),
                onPressed: _lines.length <= 1 ? null : () => setState(() => _lines.removeAt(index)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEstimatedCostSummary(bool isDark) {
    final batchCost = _estimatedTotalBatchCost;
    final yieldVal = double.tryParse(_yieldController.text) ?? 1.0;
    final portionCost = yieldVal > 0 ? (batchCost / yieldVal) : batchCost;
    final sellingPrice = _selectedMenuItem?.price ?? 0.0;
    final foodCostPct = sellingPrice > 0 ? ((portionCost / sellingPrice) * 100) : 0.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Est. Batch Cost: ₹${batchCost.toStringAsFixed(2)}  •  Portion Cost: ₹${portionCost.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: Color(0xFF047857))),
          Text('Projected Food Cost: ${foodCostPct.toStringAsFixed(1)}% (Selling Price: ₹${sellingPrice.toStringAsFixed(0)})',
              style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold, color: foodCostPct > 35 ? const Color(0xFFEF4444) : (foodCostPct > 30 ? const Color(0xFFF59E0B) : const Color(0xFF047857)))),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: _isSaving ? null : _saveRecipe,
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
          child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save Recipe BOM', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
