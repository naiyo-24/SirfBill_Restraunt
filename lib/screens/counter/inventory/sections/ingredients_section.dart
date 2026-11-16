import 'package:flutter/material.dart';
import 'package:sirfbill_restaurant/config/api_constants.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import '../widgets/add_ingredient_dialog.dart';
import '../widgets/ingredient_details_dialog.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_status_badge.dart';

class IngredientsSection extends StatefulWidget {
  const IngredientsSection({super.key});

  @override
  State<IngredientsSection> createState() => _IngredientsSectionState();
}

class _IngredientsSectionState extends State<IngredientsSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategoryId;
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

    final filteredItems = _ingredients.where((item) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          item.name.toLowerCase().contains(q) ||
          item.code.toLowerCase().contains(q);
      final matchesCategory =
          _selectedCategoryId == null || item.categoryId == _selectedCategoryId;
      return matchesSearch && matchesCategory;
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
        _buildCategoryFilters(isDark),
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

  Widget _buildCategoryFilters(bool isDark) {
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
            isSelected: _selectedCategoryId == null,
            onSelected: () {
              setState(() => _selectedCategoryId = null);
              _loadData();
            },
            isDark: isDark,
          ),
          ..._categories.map((cat) {
            return _buildFilterChip(
              label: cat.name,
              isSelected: _selectedCategoryId == cat.id,
              onSelected: () {
                setState(() => _selectedCategoryId = cat.id);
                _loadData();
              },
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
    final healthPercent = (item.stockHealthPercent / 100.0).clamp(0.0, 1.0);

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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openIngredientDetails(context, item),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildIngredientThumbnail(item, isDark),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
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
                              item.code,
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
                        '${item.categoryName.isNotEmpty ? item.categoryName : 'General'} • ${item.storageLocation}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Supplier: ${item.primarySupplierName.isNotEmpty ? item.primarySupplierName : 'Direct Kitchen'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Stock: ${(item.currentStock / (item.recipeUom == 'G' || item.recipeUom == 'ML' ? 1000 : 1)).toStringAsFixed(1)} ${item.purchaseUom}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          InventoryStatusBadge.stockLevel(
                            currentStock: item.currentStock,
                            minPar: item.minParLevel,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: healthPercent,
                          minHeight: 6,
                          backgroundColor:
                              isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            item.isOutOfStock
                                ? const Color(0xFFEF4444)
                                : (item.isLowStock
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFF10B981)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Par: ${(item.minParLevel / 1000).toStringAsFixed(1)} kg min / ${(item.idealParLevel / 1000).toStringAsFixed(1)} kg max',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '₹${item.costPerPurchaseUnit.toStringAsFixed(0)} / ${item.purchaseUom}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      '≈ ₹${(item.costPerRecipeUnit * 100).toStringAsFixed(2)} / 100${item.recipeUom.toLowerCase()}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Ingredient',
                          onPressed: () => _openAddIngredientDialog(context, item: item),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                          tooltip: 'Delete Ingredient',
                          onPressed: () => _confirmDeleteIngredient(item),
                        ),
                      ],
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

  Widget _buildIngredientThumbnail(Ingredient item, bool isDark) {
    final imgUrl = item.imageUrl?.trim() ?? '';
    if (imgUrl.isNotEmpty) {
      final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
      final String fullUrl;
      if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
        fullUrl = imgUrl.startsWith(base)
            ? imgUrl
            : '$base/api/restaurant/inventory/proxy-image?url=${Uri.encodeComponent(imgUrl)}';
      } else {
        fullUrl = '$base${imgUrl.startsWith('/') ? '' : '/'}$imgUrl';
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          fullUrl,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          loadingBuilder: (ctx, child, progress) =>
              progress == null ? child : _buildFallbackIcon(isDark),
          errorBuilder: (_, __, ___) => _buildFallbackIcon(isDark),
        ),
      );
    }
    return _buildFallbackIcon(isDark);
  }

  Widget _buildFallbackIcon(bool isDark) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.grain, color: Color(0xFF10B981), size: 24),
    );
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
