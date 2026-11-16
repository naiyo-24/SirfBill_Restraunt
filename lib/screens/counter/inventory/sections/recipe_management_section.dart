import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../widgets/inventory_header.dart';

class RecipeManagementSection extends StatefulWidget {
  const RecipeManagementSection({super.key});

  @override
  State<RecipeManagementSection> createState() => _RecipeManagementSectionState();
}

class _RecipeManagementSectionState extends State<RecipeManagementSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<DishRecipe> _recipes = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _recipes.where((r) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          r.dishName.toLowerCase().contains(q) ||
          r.category.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Recipe Management (Culinary BOM)',
          subtitle: 'Map POS menu items to raw ingredients, yield factors, food cost % and gross margin',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search recipe or dish name...',
          trailing: ElevatedButton.icon(
            onPressed: () => _openAddRecipeDialog(context),
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
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(24),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final recipe = filtered[index];
                    return _buildRecipeCard(context, recipe, isDark);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.restaurant_menu_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No recipes configured yet', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Create Bill of Materials (BOM) linking menu dishes to raw ingredients',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildRecipeCard(BuildContext context, DishRecipe recipe, bool isDark) {
    final marginPercent = ((recipe.sellingPrice - recipe.totalCost) / recipe.sellingPrice) * 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
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
              recipe.dishName,
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
                recipe.category,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Row(
            children: [
              _buildCostPill('Portion Cost', '₹${recipe.totalCost.toStringAsFixed(1)}', isDark),
              const SizedBox(width: 16),
              _buildCostPill('Menu Price', '₹${recipe.sellingPrice.toStringAsFixed(0)}', isDark),
              const SizedBox(width: 16),
              _buildCostPill(
                'Food Cost %',
                '${recipe.foodCostPercentage.toStringAsFixed(1)}%',
                isDark,
              ),
              const SizedBox(width: 16),
              _buildCostPill(
                'Gross Margin',
                '${marginPercent.toStringAsFixed(1)}%',
                isDark,
              ),
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
                const Text(
                  'BILL OF MATERIALS (BOM) INGREDIENTS',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
                const SizedBox(height: 10),
                ...recipe.ingredients.map((ing) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${ing.ingredientName} (${ing.quantity.toStringAsFixed(0)} ${ing.recipeUom})',
                          style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87),
                        ),
                        Text(
                          '₹${ing.effectiveCost.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCostPill(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  void _openAddRecipeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Add Recipe Bill of Materials (BOM)'),
        content: const SizedBox(
          width: 450,
          child: Text('Map menu items from POS to raw ingredient quantities and calculate precise food cost.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
