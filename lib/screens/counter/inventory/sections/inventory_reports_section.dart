import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import '../services/food_cost_api_service.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_kpi_card.dart';
import '../widgets/food_cost_reconciliation_card.dart';

class InventoryReportsSection extends StatefulWidget {
  final String? outletId;

  const InventoryReportsSection({
    super.key,
    this.outletId,
  });

  @override
  State<InventoryReportsSection> createState() => _InventoryReportsSectionState();
}

class _InventoryReportsSectionState extends State<InventoryReportsSection> {
  bool _isLoading = true;
  bool _isExporting = false;
  List<Ingredient> _ingredients = [];
  List<IngredientCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didUpdateWidget(covariant InventoryReportsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outletId != widget.outletId) {
      _loadData();
    }
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        InventoryApiService.getIngredients(outletId: widget.outletId),
        InventoryApiService.getCategories(outletId: widget.outletId),
      ]);
      if (mounted) {
        setState(() {
          _ingredients = results[0] as List<Ingredient>;
          _categories = results[1] as List<IngredientCategory>;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleExportValuation() async {
    setState(() => _isExporting = true);
    try {
      final success = await FoodCostApiService.exportValuationCsv(
        outletId: widget.outletId,
      );
      if (!mounted) return;
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock Valuation CSV exported successfully.'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to export valuation CSV. Please try again.'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export error: $e'),
          backgroundColor: const Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalValuation = _ingredients.fold<double>(
      0.0,
      (sum, item) => sum + item.totalStockValue,
    );

    return Column(
      children: [
        InventoryHeader(
          title: 'Inventory Reports & Food Cost Analysis',
          subtitle: 'Stock valuation, Cost of Goods Sold (COGS), actual vs theoretical food cost & ABC analysis',
          onRefresh: _loadData,
          isRefreshing: _isLoading,
          actions: [
            OutlinedButton.icon(
              onPressed: _isExporting ? null : _handleExportValuation,
              icon: _isExporting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                    )
                  : const Icon(Icons.file_download_outlined, size: 16),
              label: Text(_isExporting ? 'Exporting...' : 'Export Valuation'),
            ),
          ],
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : LayoutBuilder(
                  builder: (context, constraints) {
                    final isMobileOrTablet = constraints.maxWidth < 900;
                    return ListView(
                      padding: EdgeInsets.all(isMobileOrTablet ? 14 : 24),
                      children: [
                        _buildReportKpiGrid(context, totalValuation),
                        const SizedBox(height: 20),
                        if (isMobileOrTablet) ...[
                          _buildCategoryValuationCard(context, isDark),
                          const SizedBox(height: 16),
                          _buildAbcClassificationCard(context, isDark, totalValuation),
                        ] else ...[
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 6,
                                child: _buildCategoryValuationCard(context, isDark),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 5,
                                child: _buildAbcClassificationCard(context, isDark, totalValuation),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 20),
                        FoodCostReconciliationCard(outletId: widget.outletId),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildReportKpiGrid(BuildContext context, double totalValuation) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final int crossAxisCount;
        final double childAspectRatio;

        if (width >= 1100) {
          crossAxisCount = 4;
          childAspectRatio = 1.95;
        } else if (width >= 600) {
          crossAxisCount = 2;
          childAspectRatio = 2.1;
        } else {
          crossAxisCount = 1;
          childAspectRatio = 3.2;
        }

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: childAspectRatio,
          children: [
            InventoryKpiCard(
              title: 'Current Inventory Value',
              value: '₹${totalValuation.toStringAsFixed(2)}',
              subtitle: 'Based on FIFO purchase cost',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: const Color(0xFF10B981),
            ),
            InventoryKpiCard(
              title: 'Total Commodities',
              value: '${_ingredients.length}',
              subtitle: 'Active raw materials in stock',
              icon: Icons.inventory_2_outlined,
              accentColor: const Color(0xFF3B82F6),
            ),
            InventoryKpiCard(
              title: 'Storage Categories',
              value: '${_categories.length}',
              subtitle: 'Configured temperature zones',
              icon: Icons.category_outlined,
              accentColor: const Color(0xFF8B5CF6),
            ),
            InventoryKpiCard(
              title: 'Out of Stock Items',
              value: '${_ingredients.where((i) => i.isOutOfStock).length}',
              subtitle: 'Requires immediate PO replenishment',
              icon: Icons.warning_amber_rounded,
              accentColor: const Color(0xFFEF4444),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryValuationCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Valuation by Category Zone',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 16),
          if (_categories.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'No categories created yet.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ),
            )
          else
            ..._categories.map((cat) {
              final catIngredients = _ingredients.where((i) => i.categoryId == cat.id).toList();
              final valuation = catIngredients.fold<double>(
                0.0,
                (sum, i) => sum + i.totalStockValue,
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(color: cat.accentColor, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        cat.name,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                    Text(
                      '${catIngredients.length} items  ·  ₹${valuation.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildAbcClassificationCard(BuildContext context, bool isDark, double totalValuation) {
    final classAItems = _ingredients.where((i) => i.totalStockValue >= 1000).toList();
    final classBItems = _ingredients.where((i) => i.totalStockValue < 1000 && i.totalStockValue >= 200).toList();
    final classCItems = _ingredients.where((i) => i.totalStockValue < 200).toList();

    final classAVal = classAItems.fold<double>(0.0, (s, i) => s + i.totalStockValue);
    final classBVal = classBItems.fold<double>(0.0, (s, i) => s + i.totalStockValue);
    final classCVal = classCItems.fold<double>(0.0, (s, i) => s + i.totalStockValue);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ABC Inventory Analysis',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildAbcRow('Class A (High Value Tier)', '${classAItems.length} Commodities', '₹${classAVal.toStringAsFixed(2)}', Colors.redAccent, isDark),
          _buildAbcRow('Class B (Moderate Value Tier)', '${classBItems.length} Commodities', '₹${classBVal.toStringAsFixed(2)}', Colors.amber, isDark),
          _buildAbcRow('Class C (Low Value Bulk Tier)', '${classCItems.length} Commodities', '₹${classCVal.toStringAsFixed(2)}', Colors.teal, isDark),
        ],
      ),
    );
  }

  Widget _buildAbcRow(String title, String desc, String value, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                const SizedBox(height: 2),
                Text(desc, style: TextStyle(fontSize: 10, color: isDark ? Colors.grey : Colors.blueGrey)),
              ],
            ),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
