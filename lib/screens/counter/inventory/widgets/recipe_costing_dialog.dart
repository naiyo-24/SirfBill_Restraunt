import 'package:flutter/material.dart';
import '../models/recipe_models.dart';
import '../services/recipe_api_service.dart';

class RecipeCostingDialog extends StatefulWidget {
  final RecipeModel recipe;

  const RecipeCostingDialog({super.key, required this.recipe});

  static Future<void> show(BuildContext context, {required RecipeModel recipe}) {
    return showDialog(
      context: context,
      builder: (_) => RecipeCostingDialog(recipe: recipe),
    );
  }

  @override
  State<RecipeCostingDialog> createState() => _RecipeCostingDialogState();
}

class _RecipeCostingDialogState extends State<RecipeCostingDialog> {
  final TextEditingController _priceSimController = TextEditingController();
  RecipeCostingModel? _costing;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.recipe.sellingPrice > 0) {
      _priceSimController.text = widget.recipe.sellingPrice.toStringAsFixed(0);
    }
    _loadCosting();
  }

  @override
  void dispose() {
    _priceSimController.dispose();
    super.dispose();
  }

  Future<void> _loadCosting({double? overridePrice}) async {
    if (widget.recipe.itemId == null) {
      setState(() => _isLoading = false);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final list = await RecipeApiService.getItemCosting(
        widget.recipe.itemId!,
        sellingPrice: overridePrice,
      );
      if (mounted) {
        setState(() {
          _costing = list.isNotEmpty ? list.first : null;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.recipe;
    final c = _costing;

    final plateCost = c?.plateCost ?? r.plateCost;
    final sellingPrice = c?.sellingPrice ?? r.sellingPrice;
    final foodCostPct = c?.foodCostPercentage ?? r.foodCostPercentage;
    final grossMarginPct = c?.grossMarginPercentage ?? r.grossMarginPercentage;
    final costStatus = c?.costStatus ?? r.costStatus;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Container(
        width: 780,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, r, isDark),
            const SizedBox(height: 16),
            _buildMetricsOverview(plateCost, sellingPrice, foodCostPct, grossMarginPct, costStatus, isDark),
            const SizedBox(height: 16),
            _buildSimulatorBar(isDark),
            const SizedBox(height: 16),
            const Text(
              'INGREDIENT COST CONTRIBUTION BREAKDOWN',
              style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildBreakdownList(c, isDark),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close Costing Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, RecipeModel r, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.analytics_rounded, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      r.itemName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        r.variantName,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Yield: ${r.yieldServings.toStringAsFixed(1)} Servings • Multi-Outlet WAC Ingredient Valuation',
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

  Widget _buildMetricsOverview(
    double plateCost,
    double sellingPrice,
    double foodCostPct,
    double grossMarginPct,
    RecipeCostStatus costStatus,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: costStatus.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetricCell('Plate Cost', '₹${plateCost.toStringAsFixed(2)}', const Color(0xFF3B82F6), isDark),
          _buildDivider(isDark),
          _buildMetricCell('Menu Price', '₹${sellingPrice.toStringAsFixed(0)}', isDark ? Colors.white : const Color(0xFF0F172A), isDark),
          _buildDivider(isDark),
          _buildMetricCell('Food Cost %', '${foodCostPct.toStringAsFixed(1)}%', costStatus.color, isDark, badge: costStatus.label),
          _buildDivider(isDark),
          _buildMetricCell('Gross Margin %', '${grossMarginPct.toStringAsFixed(1)}%', const Color(0xFF10B981), isDark),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(
      height: 38,
      width: 1,
      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildMetricCell(String label, String value, Color color, bool isDark, {String? badge}) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: color)),
        if (badge != null) ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
            child: Text(badge, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ],
    );
  }

  Widget _buildSimulatorBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.tune_rounded, size: 18, color: Color(0xFF6366F1)),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'What-If Price Simulator: Test new menu pricing to see immediate profit margin changes.',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF4F46E5)),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 110,
            height: 34,
            child: TextField(
              controller: _priceSimController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixText: '₹ ',
                hintText: 'Price',
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
              ),
              onSubmitted: (v) {
                final p = double.tryParse(v.trim());
                if (p != null && p > 0) _loadCosting(overridePrice: p);
              },
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              final p = double.tryParse(_priceSimController.text.trim());
              if (p != null && p > 0) _loadCosting(overridePrice: p);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Simulate', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownList(RecipeCostingModel? c, bool isDark) {
    final list = c?.breakdown ?? [];
    if (list.isEmpty) {
      return Center(
        child: Text(
          'No recipe lines breakdown available.',
          style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
      );
    }

    return ListView.separated(
      itemCount: list.length,
      separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      itemBuilder: (context, index) {
        final item = list[index];
        final pct = item.costContributionPct.clamp(0.0, 100.0);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      item.ingredientName,
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '${item.portionQuantity.toStringAsFixed(1)} ${item.unit} / serving',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      '₹${item.costPerUnit.toStringAsFixed(2)} / ${item.unit}',
                      style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        '₹${item.lineCost.toStringAsFixed(2)} (${pct.toStringAsFixed(1)}%)',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: pct / 100.0,
                  backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  color: pct > 50 ? const Color(0xFFEF4444) : (pct > 25 ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                  minHeight: 5,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
