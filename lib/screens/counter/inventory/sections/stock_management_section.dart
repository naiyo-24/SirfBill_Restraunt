import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_status_badge.dart';
import '../widgets/adjust_stock_dialog.dart';

class StockManagementSection extends StatefulWidget {
  const StockManagementSection({super.key});

  @override
  State<StockManagementSection> createState() => _StockManagementSectionState();
}

class _StockManagementSectionState extends State<StockManagementSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Ingredient> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      final list = await InventoryApiService.getIngredients(search: _searchQuery);
      if (mounted) setState(() => _ingredients = list);
    } catch (_) {
      if (mounted) setState(() => _ingredients = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _ingredients.where((i) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          i.name.toLowerCase().contains(q) ||
          i.code.toLowerCase().contains(q) ||
          i.storageLocation.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Stock Balances & Adjustments',
          subtitle: 'Live commodity on-hand quantities, safety par buffer, and manual inventory adjustments',
          searchController: _searchController,
          onSearchChanged: (v) {
            setState(() => _searchQuery = v);
            _loadIngredients();
          },
          searchHint: 'Search stock by name, code or storage...',
          onRefresh: _loadIngredients,
          isRefreshing: _isLoading,
          trailing: ElevatedButton.icon(
            onPressed: () => _openAdjustStockDialog(context),
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Adjust Stock Balance'),
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
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildStockRow(context, item, isDark);
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
          Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No ingredients found to adjust', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Please add ingredients in the Ingredients Catalog to track live balances',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildStockRow(BuildContext context, Ingredient item, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.code} • ${item.storageLocation}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
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
                Text(
                  item.formattedStock,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Par Min: ${(item.minParLevel / 1000).toStringAsFixed(1)} ${item.purchaseUom}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          InventoryStatusBadge.stockLevel(
            currentStock: item.currentStock,
            minPar: item.minParLevel,
          ),
          const SizedBox(width: 16),
          OutlinedButton(
            onPressed: () => _openAdjustStockDialog(context, item: item),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              side: const BorderSide(color: Color(0xFF10B981)),
            ),
            child: const Text('Adjust', style: TextStyle(color: Color(0xFF10B981))),
          ),
        ],
      ),
    );
  }

  void _openAdjustStockDialog(BuildContext context, {Ingredient? item}) {
    if (item == null && _ingredients.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No ingredients found to adjust.')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AdjustStockDialog(
        initialIngredient: item,
        ingredients: _ingredients,
        onAdjusted: _loadIngredients,
      ),
    );
  }
}
