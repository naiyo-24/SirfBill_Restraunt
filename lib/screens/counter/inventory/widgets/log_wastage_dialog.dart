import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../services/restaurant/restaurant_menu_service.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import '../services/recipe_api_service.dart';
import '../services/wastage_api_service.dart';

class LogWastageDialog extends StatefulWidget {
  final VoidCallback? onLogged;

  const LogWastageDialog({super.key, this.onLogged});

  static Future<void> show(BuildContext context, {VoidCallback? onLogged}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => LogWastageDialog(onLogged: onLogged),
    );
  }

  @override
  State<LogWastageDialog> createState() => _LogWastageDialogState();
}

class _LogWastageDialogState extends State<LogWastageDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Track A1: Raw Material
  final _rawFormKey = GlobalKey<FormState>();
  Ingredient? _selectedIngredient;
  final TextEditingController _rawQtyController = TextEditingController(text: '1.0');
  String _rawUnit = 'KG';
  String _rawReason = 'SPOILAGE';
  final TextEditingController _rawNotesController = TextEditingController();

  // Track A2: Cooked Dish
  final _dishFormKey = GlobalKey<FormState>();
  PosMenuItem? _selectedDish;
  final TextEditingController _dishVariantController = TextEditingController(text: 'Standard');
  final TextEditingController _dishPortionsController = TextEditingController(text: '1.0');
  String _dishReason = 'BURNT_RUINED';
  final TextEditingController _dishNotesController = TextEditingController();

  List<Ingredient> _ingredients = [];
  List<PosMenuItem> _dishes = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadCatalog();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _rawQtyController.dispose();
    _rawNotesController.dispose();
    _dishVariantController.dispose();
    _dishPortionsController.dispose();
    _dishNotesController.dispose();
    super.dispose();
  }

  Future<void> _loadCatalog() async {
    try {
      final ings = await InventoryApiService.getIngredients();
      final menu = await RestaurantMenuService.fetchMenuItems();
      if (mounted) {
        setState(() {
          _ingredients = ings;
          _dishes = menu;
          if (ings.isNotEmpty) {
            _selectedIngredient = ings.first;
            _rawUnit = ings.first.purchaseUom.isNotEmpty ? ings.first.purchaseUom : 'KG';
          }
          if (menu.isNotEmpty) _selectedDish = menu.first;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  double get _estimatedRawLoss {
    if (_selectedIngredient == null) return 0.0;
    final qty = double.tryParse(_rawQtyController.text) ?? 0.0;
    final ing = _selectedIngredient!;
    final factor = (_rawUnit.toUpperCase() == 'KG' || _rawUnit.toUpperCase() == 'LTR') ? 1000.0 : 1.0;
    final recipeQty = (_rawUnit.toUpperCase() == ing.recipeUom.toUpperCase()) ? qty : (qty * factor);
    return recipeQty * ing.costPerRecipeUnit;
  }

  Future<void> _submitRawWaste() async {
    if (!_rawFormKey.currentState!.validate() || _selectedIngredient == null) return;
    setState(() => _isSaving = true);
    try {
      final qty = double.tryParse(_rawQtyController.text) ?? 1.0;
      final payload = {
        'ingredient_id': _selectedIngredient!.id,
        'quantity': qty,
        'input_uom': _rawUnit,
        'waste_reason': _rawReason,
        'notes': _rawNotesController.text.trim().isEmpty ? null : _rawNotesController.text.trim(),
      };

      await WastageApiService.logRawMaterialWaste(payload);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Raw material wastage logged & deducted from inventory.'),
          backgroundColor: Color(0xFFEF4444),
        ));
        Navigator.pop(context);
        widget.onLogged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log waste: $e'), backgroundColor: const Color(0xFFEF4444)));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _submitDishWaste() async {
    if (!_dishFormKey.currentState!.validate() || _selectedDish == null) return;
    setState(() => _isSaving = true);
    try {
      final portions = double.tryParse(_dishPortionsController.text) ?? 1.0;
      final outletId = await RecipeApiService.getResolvedOutletId();
      final payload = {
        'item_id': _selectedDish!.id,
        'variant_name': _dishVariantController.text.trim().isEmpty ? 'Standard' : _dishVariantController.text.trim(),
        'portions': portions,
        if (outletId.isNotEmpty) 'outlet_id': outletId,
        'waste_reason': _dishReason,
        'notes': _dishNotesController.text.trim().isEmpty ? null : _dishNotesController.text.trim(),
      };

      final res = await WastageApiService.logCookedDishWaste(payload);
      if (mounted) {
        final loss = res?['total_financial_loss_inr'] ?? 0.0;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Cooked dish loss logged (BOM exploded, ₹$loss lost).'),
          backgroundColor: const Color(0xFFEA580C),
        ));
        Navigator.pop(context);
        widget.onLogged?.call();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to log dish waste: $e'), backgroundColor: const Color(0xFFEF4444)));
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
        width: 720,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.all(24),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context, isDark),
                  const SizedBox(height: 16),
                  _buildTabBar(isDark),
                  const SizedBox(height: 16),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildRawMaterialTab(isDark),
                        _buildCookedDishTab(isDark),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 24),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Record Kitchen Food Loss',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                'Unbilled kitchen loss with automatic WAC valuation and ledger auditing',
                style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, size: 20)),
      ],
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
        labelColor: Colors.white,
        unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(icon: Icon(Icons.inventory_2_outlined, size: 16), text: 'Raw Materials'),
          Tab(icon: Icon(Icons.restaurant_outlined, size: 16), text: 'Cooked Dishes'),
        ],
      ),
    );
  }

  Widget _buildRawMaterialTab(bool isDark) {
    final rawUnits = ['KG', 'G', 'LTR', 'ML', 'PCS', 'DOZEN', 'BOX'];
    final reasons = [
      {'code': 'SPOILAGE', 'label': 'Spoilage / Souring (Chiller failure, sour curd)'},
      {'code': 'EXPIRY', 'label': 'Expired Shelf-Life (Pantry package expired)'},
      {'code': 'DROPPED_SPILL', 'label': 'Dropped / Container Spillage'},
      {'code': 'PREP_TRIM', 'label': 'Butchery & Cutting Trim Loss'},
    ];

    return Form(
      key: _rawFormKey,
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.info_outline, size: 16, color: Color(0xFFDC2626)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Direct Raw Material: Deducts normalized quantity from warehouse stock and logs financial leakage at live WAC cost.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFDC2626)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<Ingredient>(
            initialValue: _selectedIngredient,
            decoration: const InputDecoration(labelText: 'Raw Material / Commodity *', border: OutlineInputBorder(), isDense: true),
            items: _ingredients.map((i) => DropdownMenuItem(value: i, child: Text('${i.name} (${i.currentStock.toStringAsFixed(1)} ${i.recipeUom} on hand)'))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedIngredient = val;
                if (val != null && val.purchaseUom.isNotEmpty) _rawUnit = val.purchaseUom;
              });
            },
            validator: (v) => v == null ? 'Select ingredient' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _rawQtyController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Wasted Quantity *', border: OutlineInputBorder(), isDense: true),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter > 0' : null,
                  onChanged: (_) => setState(() {}),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: rawUnits.contains(_rawUnit) ? _rawUnit : 'KG',
                  decoration: const InputDecoration(labelText: 'Unit *', border: OutlineInputBorder(), isDense: true),
                  items: rawUnits.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                  onChanged: (val) => setState(() => _rawUnit = val ?? 'KG'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _rawReason,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Root-Cause Reason *', border: OutlineInputBorder(), isDense: true),
            items: reasons.map((r) => DropdownMenuItem(value: r['code']!, child: Text(r['label']!, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => setState(() => _rawReason = val ?? 'SPOILAGE'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _rawNotesController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Incident Notes & Observations (e.g., freezer temp, batch #)', border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Estimated Financial Loss:', style: TextStyle(fontSize: 13, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                Text('₹${_estimatedRawLoss.toStringAsFixed(2)}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFFEF4444))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitRawWaste,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Log Raw Waste', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCookedDishTab(bool isDark) {
    final reasons = [
      {'code': 'BURNT_RUINED', 'label': 'Burnt / Overcooked / Ruined Pot during Cooking'},
      {'code': 'DROPPED_SPILL', 'label': 'Dropped Cooked Plate or Spill on Prep Line'},
      {'code': 'EXPIRED_BUFFET', 'label': 'Expired Buffet / Display Holding Tray'},
      {'code': 'STAFF_TASTING', 'label': 'Staff Quality Check & Tasting Sample'},
    ];

    return Form(
      key: _dishFormKey,
      child: ListView(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: const Color(0xFFEA580C).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: const Row(
              children: [
                Icon(Icons.auto_fix_high_rounded, size: 16, color: Color(0xFFEA580C)),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Recipe BOM Explosion: Discarding an unbilled cooked dish automatically explodes its recipe and subtracts constituent raw materials from stock.',
                    style: TextStyle(fontSize: 12, color: Color(0xFFEA580C)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<PosMenuItem>(
            initialValue: _selectedDish,
            decoration: const InputDecoration(labelText: 'Menu Dish / Prepared Recipe *', border: OutlineInputBorder(), isDense: true),
            items: _dishes.map((d) => DropdownMenuItem(value: d, child: Text('${d.name} (₹${d.price.toStringAsFixed(0)})'))).toList(),
            onChanged: (val) => setState(() => _selectedDish = val),
            validator: (v) => v == null ? 'Select menu dish' : null,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextFormField(
                  controller: _dishVariantController,
                  decoration: const InputDecoration(labelText: 'Variant', hintText: 'Standard / Full / Half', border: OutlineInputBorder(), isDense: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _dishPortionsController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Portions Discarded *', border: OutlineInputBorder(), isDense: true),
                  validator: (v) => (double.tryParse(v ?? '') ?? 0) <= 0 ? 'Enter > 0' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            initialValue: _dishReason,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Waste Root Cause *', border: OutlineInputBorder(), isDense: true),
            items: reasons.map((r) => DropdownMenuItem(value: r['code']!, child: Text(r['label']!, overflow: TextOverflow.ellipsis))).toList(),
            onChanged: (val) => setState(() => _dishReason = val ?? 'BURNT_RUINED'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _dishNotesController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Culinary Waste Notes (e.g. pot bottom scorched, spilled tray)', border: OutlineInputBorder(), isDense: true),
          ),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submitDishWaste,
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEA580C), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12)),
              child: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Explode BOM & Log Waste', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
