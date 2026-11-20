import 'package:flutter/material.dart';
import '../../../../models/restaurant_executive_report_models.dart';

class FoodCostVarianceTab extends StatelessWidget {
  final FoodCostVarianceReport? report;
  final bool isLoading;

  const FoodCostVarianceTab({
    super.key,
    required this.report,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    if (report == null) {
      return const Center(child: Text('No food cost variance data found for this period'));
    }

    final r = report!;
    final isVarianceHigh = r.variancePctOfSales > 5.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return ListView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          children: [
            // KPI Summary Row
            _buildKpiGrid(r, isVarianceHigh, isDark, isMobile),
            const SizedBox(height: 16),

            // Cost Variance Formula Banner
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Actual COGS = Theoretical BOM (${r.theoreticalCogsPct.toStringAsFixed(1)}%) + '
                      'Kitchen Wastage (₹${r.loggedWastageLoss.toStringAsFixed(0)}) + '
                      'Audit Shrinkage (₹${r.physicalAuditShrinkage.toStringAsFixed(0)}). '
                      'Target benchmark is ≤ 30% of sales.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Breakdown Table / Cards
            Container(
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'INGREDIENT-WISE COST VARIANCE (${r.breakdown.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          'Total Sales: ₹${r.totalFoodSales.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  if (r.breakdown.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No ingredient deductions logged for this date range')),
                    )
                  else if (isMobile)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: r.breakdown.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                      itemBuilder: (ctx, i) => _buildMobileItemCard(r.breakdown[i], isDark),
                    )
                  else
                    _buildDesktopTable(r.breakdown, isDark, borderColor),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildKpiGrid(FoodCostVarianceReport r, bool isVarianceHigh, bool isDark, bool isMobile) {
    final kpis = [
      _buildCard('THEORETICAL COGS', '₹${r.theoreticalCogs.toStringAsFixed(0)}', '${r.theoreticalCogsPct.toStringAsFixed(1)}% of Sales', const Color(0xFF3B82F6), isDark),
      _buildCard('ACTUAL COGS', '₹${r.actualCogs.toStringAsFixed(0)}', '${r.actualCogsPct.toStringAsFixed(1)}% of Sales', const Color(0xFF8B5CF6), isDark),
      _buildCard('LOGGED WASTAGE', '₹${r.loggedWastageLoss.toStringAsFixed(0)}', 'Kitchen prep & spoilage', const Color(0xFFF59E0B), isDark),
      _buildCard('UNEXPLAINED VARIANCE', '₹${r.unexplainedVariance.toStringAsFixed(0)}', '${r.variancePctOfSales.toStringAsFixed(1)}% variance leak', isVarianceHigh ? const Color(0xFFEF4444) : const Color(0xFF10B981), isDark),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: kpis,
      );
    }

    return Row(
      children: kpis
          .map((k) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: k,
                ),
              ))
          .toList(),
    );
  }

  Widget _buildCard(String label, String value, String sub, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.grey.shade500)),
          const SizedBox(height: 2),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color)),
          Text(sub, style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildDesktopTable(List<FoodCostVarianceItem> items, bool isDark, Color borderColor) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('INGREDIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('THEO QTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ACTUAL QTY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('THEO COST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('ACTUAL COST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('WASTE COST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('VARIANCE (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('VARIANCE %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
        rows: items.map((it) {
          final isOver = it.varianceCost > 0;
          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(it.ingredientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Text(it.categoryName, style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              DataCell(Text('${it.theoreticalConsumedQty.toStringAsFixed(2)} ${it.unit}')),
              DataCell(Text('${it.actualConsumedQty.toStringAsFixed(2)} ${it.unit}')),
              DataCell(Text('₹${it.theoreticalCost.toStringAsFixed(2)}')),
              DataCell(Text('₹${it.actualCost.toStringAsFixed(2)}')),
              DataCell(Text('₹${it.kitchenWastageCost.toStringAsFixed(2)}')),
              DataCell(
                Text(
                  '${isOver ? "+" : ""}₹${it.varianceCost.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isOver ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (isOver ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${it.variancePct.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isOver ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    ),
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileItemCard(FoodCostVarianceItem it, bool isDark) {
    final isOver = it.varianceCost > 0;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(it.ingredientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isOver ? const Color(0xFFEF4444) : const Color(0xFF10B981)).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${isOver ? "+" : ""}₹${it.varianceCost.toStringAsFixed(0)} (${it.variancePct.toStringAsFixed(0)}%)',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isOver ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Theo: ${it.theoreticalConsumedQty.toStringAsFixed(1)}${it.unit} (₹${it.theoreticalCost.toStringAsFixed(0)}) • '
            'Actual: ${it.actualConsumedQty.toStringAsFixed(1)}${it.unit} (₹${it.actualCost.toStringAsFixed(0)})',
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }
}
