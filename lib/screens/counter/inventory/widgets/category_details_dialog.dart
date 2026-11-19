import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import 'category_ingredient_row.dart';

class CategoryDetailsDialog extends StatefulWidget {
  final IngredientCategory category;
  final VoidCallback? onEdit;

  const CategoryDetailsDialog({
    super.key,
    required this.category,
    this.onEdit,
  });

  @override
  State<CategoryDetailsDialog> createState() => _CategoryDetailsDialogState();
}

class _CategoryDetailsDialogState extends State<CategoryDetailsDialog> {
  bool _isLoading = true;
  List<Ingredient> _ingredients = [];

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    final items = await InventoryApiService.getIngredients(
      categoryId: widget.category.id,
    );
    if (mounted) {
      setState(() {
        _ingredients = items;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cat = widget.category;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final totalValuation = _ingredients.fold<double>(
      0.0,
      (sum, item) => sum + item.totalStockValue,
    );
    final lowStockCount =
        _ingredients.where((i) => i.isLowStock || i.isOutOfStock).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: 720,
        constraints: BoxConstraints(
          maxWidth: 760,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header
            _buildHeader(context, cat, isDark),
            const SizedBox(height: 18),

            // 2. Summary KPI Cards
            _buildKpis(cat, totalValuation, lowStockCount, isDark),
            const SizedBox(height: 20),

            // 3. Section Title
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text(
                  'Commodities in this Category (${_ingredients.length})',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                if (!_isLoading)
                  Text(
                    'Storage: ${cat.storageZone}',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),

            // 4. Ingredient List
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: Color(0xFF10B981)),
                    )
                  : _ingredients.isEmpty
                      ? _buildEmptyIngredients(isDark)
                      : _buildIngredientsList(isDark),
            ),
            const SizedBox(height: 16),

            // 5. Footer Actions
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Close'),
                ),
                const SizedBox(width: 12),
                if (widget.onEdit != null)
                  ElevatedButton.icon(
                    onPressed: widget.onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Edit Category'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, IngredientCategory cat, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: cat.accentColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.category_rounded, size: 24, color: cat.accentColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      cat.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: cat.accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'CODE: ${cat.code}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: cat.accentColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.thermostat_outlined,
                    size: 14,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      cat.storageZone,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close, size: 20),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildKpis(
    IngredientCategory cat,
    double totalValuation,
    int lowStockCount,
    bool isDark,
  ) {
    final currencyFmt = NumberFormat('#,##,##0.00', 'en_IN');

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 520;

        if (isNarrow) {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: _kpiCard(
                      label: 'Total Items',
                      value: '${_ingredients.length}',
                      icon: Icons.inventory_2_outlined,
                      color: const Color(0xFF3B82F6),
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _kpiCard(
                      label: 'Stock Health',
                      value: lowStockCount > 0 ? '$lowStockCount Need Par' : 'Healthy',
                      icon: lowStockCount > 0
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      color: lowStockCount > 0
                          ? const Color(0xFFF97316)
                          : const Color(0xFF10B981),
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              _kpiCard(
                label: 'Stock Value',
                value: '₹${currencyFmt.format(totalValuation)}',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _kpiCard(
                label: 'Total Items',
                value: '${_ingredients.length}',
                icon: Icons.inventory_2_outlined,
                color: const Color(0xFF3B82F6),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                label: 'Stock Value',
                value: '₹${currencyFmt.format(totalValuation)}',
                icon: Icons.account_balance_wallet_outlined,
                color: const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpiCard(
                label: 'Stock Health',
                value: lowStockCount > 0 ? '$lowStockCount Need Par' : 'Healthy',
                icon: lowStockCount > 0
                    ? Icons.warning_amber_rounded
                    : Icons.check_circle_outline_rounded,
                color: lowStockCount > 0
                    ? const Color(0xFFF97316)
                    : const Color(0xFF10B981),
                isDark: isDark,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _kpiCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyIngredients(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2_outlined, size: 36, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text(
            'No ingredients linked to this category yet',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsList(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ListView.separated(
          itemCount: _ingredients.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          itemBuilder: (context, index) {
            return CategoryIngredientRow(
              ingredient: _ingredients[index],
              isDark: isDark,
            );
          },
        ),
      ),
    );
  }
}
