import 'package:flutter/material.dart';
import '../models/recipe_models.dart';
import '../services/recipe_api_service.dart';
import '../widgets/create_recipe_dialog.dart';
import '../widgets/inventory_header.dart';
import '../widgets/recipe_costing_dialog.dart';

class RecipeManagementSection extends StatefulWidget {
  const RecipeManagementSection({super.key});

  @override
  State<RecipeManagementSection> createState() => _RecipeManagementSectionState();
}

class _RecipeManagementSectionState extends State<RecipeManagementSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  RecipeCostStatus? _statusFilter;
  List<RecipeModel> _recipes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecipes() async {
    setState(() => _isLoading = true);
    try {
      final data = await RecipeApiService.getRecipes();
      if (mounted) {
        setState(() {
          _recipes = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteRecipe(RecipeModel r) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Recipe BOM'),
        content: Text('Are you sure you want to delete the Bill of Materials for "${r.itemName} (${r.variantName})"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await RecipeApiService.deleteRecipe(r.id);
      if (ok) {
        _loadRecipes();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Recipe deleted successfully.'),
            backgroundColor: Color(0xFF10B981),
          ));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _recipes.where((r) {
      final q = _searchQuery.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          r.itemName.toLowerCase().contains(q) ||
          r.itemCategory.toLowerCase().contains(q) ||
          r.variantName.toLowerCase().contains(q);
      final matchStatus = _statusFilter == null || r.costStatus == _statusFilter;
      return matchQuery && matchStatus;
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Recipe Management (Culinary BOM)',
          subtitle: 'Map POS menu items to raw ingredients, yield factors, food cost % and gross margin',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search recipe or dish name...',
          onRefresh: _loadRecipes,
          trailing: ElevatedButton.icon(
            onPressed: () => CreateRecipeDialog.show(context, onSaved: _loadRecipes),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('New Recipe BOM'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        _buildFilterBar(isDark),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (filtered.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildRecipeCard(context, filtered[index], isDark);
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const Text('Food Cost Filter: ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(width: 8),
          _buildFilterChip('All (${_recipes.length})', null),
          const SizedBox(width: 6),
          _buildFilterChip('Ideal ≤30%', RecipeCostStatus.ideal),
          const SizedBox(width: 6),
          _buildFilterChip('Warning 30-35%', RecipeCostStatus.warning),
          const SizedBox(width: 6),
          _buildFilterChip('Critical >35%', RecipeCostStatus.criticalSpike),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, RecipeCostStatus? status) {
    final isSelected = _statusFilter == status;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _statusFilter = status),
      selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No recipes configured yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'Create Bill of Materials (BOM) linking menu dishes to raw ingredients with automated Dual-UOM normalization.',
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => CreateRecipeDialog.show(context, onSaved: _loadRecipes),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create First Recipe BOM'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, RecipeModel recipe, bool isDark) {
    final statusColor = recipe.costStatus.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        tilePadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.restaurant, color: Color(0xFF10B981), size: 22),
        ),
        title: Row(
          children: [
            Text(
              recipe.itemName,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
              child: Text(recipe.variantName, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
              child: Text(recipe.costStatus.label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: statusColor)),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Wrap(
            spacing: 16,
            runSpacing: 8,
            children: [
              _buildCostPill('Portion Cost', '₹${recipe.plateCost.toStringAsFixed(1)}', isDark),
              _buildCostPill('Menu Price', '₹${recipe.sellingPrice.toStringAsFixed(0)}', isDark),
              _buildCostPill('Food Cost %', '${recipe.foodCostPercentage.toStringAsFixed(1)}%', isDark, valueColor: statusColor),
              _buildCostPill('Gross Margin', '${recipe.grossMarginPercentage.toStringAsFixed(1)}%', isDark, valueColor: const Color(0xFF10B981)),
              _buildCostPill('Yield', '${recipe.yieldServings.toStringAsFixed(1)} Servings', isDark),
            ],
          ),
        ),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('BILL OF MATERIALS (BOM) INGREDIENTS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    Row(
                      children: [
                        OutlinedButton.icon(
                          onPressed: () => RecipeCostingDialog.show(context, recipe: recipe),
                          icon: const Icon(Icons.analytics_outlined, size: 14),
                          label: const Text('Costing Analysis & Simulator', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                          style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF6366F1)),
                        ),
                        const SizedBox(width: 8),
                        OutlinedButton.icon(
                          onPressed: () => CreateRecipeDialog.show(context, existingRecipe: recipe, onSaved: _loadRecipes),
                          icon: const Icon(Icons.edit_outlined, size: 14),
                          label: const Text('Edit BOM', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Color(0xFFEF4444)),
                          onPressed: () => _deleteRecipe(recipe),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...recipe.lines.map((line) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '• ${line.ingredientName} (${line.quantityRequired.toStringAsFixed(1)} ${line.unit})',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        Text('Line Cost: ₹${line.lineCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
                if (recipe.instructions != null && recipe.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 4),
                  Text('Notes: ${recipe.instructions}', style: TextStyle(fontSize: 11.5, fontStyle: FontStyle.italic, color: Colors.grey.shade600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostPill(String label, String value, bool isDark, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: valueColor ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
    );
  }
}
