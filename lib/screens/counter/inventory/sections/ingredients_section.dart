import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../widgets/ingredient_catalog_card.dart';
import '../widgets/ingredient_details_dialog.dart';
import '../widgets/inventory_header.dart';

class IngredientsSection extends StatefulWidget {
  final ValueChanged<List<Ingredient>>? onIngredientsLoaded;

  const IngredientsSection({super.key, this.onIngredientsLoaded});

  @override
  State<IngredientsSection> createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<IngredientsSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
  bool _showLowStockOnly = false;
  bool _isLoading = true;
  List<IngredientCategory> _categories = [];
  List<Ingredient> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final cats = await InventoryApiService.getCategories();
      final items = await InventoryApiService.getIngredients(
        categoryId: _selectedCategoryId,
        search: _searchQuery,
      );

      if (mounted) {
        setState(() {
          _categories = cats;
          _ingredients = items;
        });
        widget.onIngredientsLoaded?.call(items);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _categories = [];
          _ingredients = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final lowStockCount = _ingredients.where((i) => i.isLowStock || i.isOutOfStock).length;
    final filteredItems = _ingredients.where((item) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.code.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategoryId == null || item.categoryId == _selectedCategoryId;
      final matchesStock = !_showLowStockOnly || (item.isLowStock || item.isOutOfStock);
      return matchesSearch && matchesCategory && matchesStock;
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Ingredients Catalog',
          subtitle: 'Raw commodities, dual UOM conversions, costs and par-level thresholds',
          searchController: _searchController,
          onSearchChanged: (v) {
            setState(() => _searchQuery = v);
          },
          searchHint: 'Search ingredients or SKU...',
          onRefresh: _loadData,
          isRefreshing: _isLoading,
          trailing: ElevatedButton.icon(
            onPressed: () => _openAddIngredientDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Add Ingredient'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        _buildCategoryFilters(isDark, lowStockCount),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : filteredItems.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filteredItems.length,
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        return _buildIngredientCard(context, item, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildCategoryFilters(bool isDark, int lowStockCount) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildFilterChip(
            label: 'All Categories',
            isSelected: _selectedCategoryId == null && !_showLowStockOnly,
            onSelected: () => setState(() {
              _selectedCategoryId = null;
              _showLowStockOnly = false;
            }),
            isDark: isDark,
          ),
          if (lowStockCount > 0)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                selected: _showLowStockOnly,
                avatar: Icon(Icons.warning_amber_rounded, size: 14, color: _showLowStockOnly ? Colors.white : const Color(0xFFEF4444)),
                label: Text('Low Stock Alerts ($lowStockCount)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _showLowStockOnly ? Colors.white : const Color(0xFFEF4444))),
                backgroundColor: isDark ? const Color(0xFFEF4444).withValues(alpha: 0.15) : const Color(0xFFFEF2F2),
                selectedColor: const Color(0xFFEF4444),
                onSelected: (val) => setState(() => _showLowStockOnly = val),
                side: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
              ),
            ),
          ..._categories.map((cat) {
            return _buildFilterChip(
              label: cat.name,
              isSelected: _selectedCategoryId == cat.id && !_showLowStockOnly,
              onSelected: () => setState(() {
                _selectedCategoryId = cat.id;
                _showLowStockOnly = false;
              }),
              isDark: isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected
              ? Colors.white
              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        backgroundColor: Colors.transparent,
        selectedColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFF10B981)
                : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }

  Widget _buildIngredientCard(BuildContext context, Ingredient item, bool isDark) {
    return IngredientCatalogCard(
      item: item,
      isDark: isDark,
      onTap: () => _openIngredientDetails(context, item),
      onEdit: () => _openAddIngredientDialog(context, item: item),
      onDelete: () => _confirmDeleteIngredient(item),
    );
  }

  void _openIngredientDetails(BuildContext context, Ingredient item) {
    showDialog(
      context: context,
      builder: (ctx) => IngredientDetailsDialog(
        item: item,
        onEdit: () => _openAddIngredientDialog(context, item: item),
      ),
    );
  }

  Future<void> _confirmDeleteIngredient(Ingredient item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Ingredient'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final ok = await InventoryApiService.deleteIngredient(item.id);
      if (ok) {
        _loadData();
      }
    }
  }



  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No ingredients found', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Try adjusting your search query or category filter',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _openAddIngredientDialog(BuildContext context, {Ingredient? item}) async {
    final result = await showDialog(
      context: context,
      builder: (_) => AddIngredientDialog(initialIngredient: item),
    );
    if (result != null) {
      _loadData();
    }
  }
}
