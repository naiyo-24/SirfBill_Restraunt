import 'package:flutter/material.dart';
import '../models/food_cost_models.dart';

class FoodCostBreakdownTable extends StatelessWidget {
  final List<FoodCostCommodityBreakdown> items;
  final bool isDark;

  const FoodCostBreakdownTable({
    super.key,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 28),
        alignment: Alignment.center,
        child: Text(
          'No commodity depletion records found for the selected timeframe.',
          style: TextStyle(
            fontSize: 13,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowHeight: 40,
        dataRowMinHeight: 44,
        dataRowMaxHeight: 52,
        horizontalMargin: 12,
        columnSpacing: 20,
        columns: const [
          DataColumn(label: Text('Commodity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          DataColumn(label: Text('Unit Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          DataColumn(label: Text('Theoretical Cons.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          DataColumn(label: Text('Waste Log', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          DataColumn(label: Text('Audit Shrinkage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          DataColumn(label: Text('Actual Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          DataColumn(label: Text('Variance Loss', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
          DataColumn(label: Text('Health Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
        ],
        rows: items.map((item) {
          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.ingredientName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      item.category,
                      style: TextStyle(
                        fontSize: 10,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              DataCell(Text('₹${item.unitCost.toStringAsFixed(2)}/${item.recipeUom}', style: const TextStyle(fontSize: 11))),
              DataCell(
                Text(
                  '${item.theoreticalQty.toStringAsFixed(2)} ${item.recipeUom}\n(₹${item.theoreticalCost.toStringAsFixed(2)})',
                  style: const TextStyle(fontSize: 11),
                ),
              ),
              DataCell(
                Text(
                  '${item.wasteQty.toStringAsFixed(2)} ${item.recipeUom}\n(₹${item.wasteCost.toStringAsFixed(2)})',
                  style: TextStyle(
                    fontSize: 11,
                    color: item.wasteCost > 0 ? const Color(0xFFF59E0B) : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${item.auditVarianceQty.toStringAsFixed(2)} ${item.recipeUom}\n(₹${item.auditVarianceCost.toStringAsFixed(2)})',
                  style: TextStyle(
                    fontSize: 11,
                    color: item.auditVarianceCost > 0 ? const Color(0xFF8B5CF6) : (isDark ? Colors.white70 : Colors.black87),
                  ),
                ),
              ),
              DataCell(
                Text(
                  '₹${item.actualDepletionCost.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  '+₹${item.varianceLossInr.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: item.varianceLossInr > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                  ),
                ),
              ),
              DataCell(_buildStatusBadge(item.healthStatus)),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status.toUpperCase()) {
      case 'BALANCED':
        bg = const Color(0xFF10B981).withValues(alpha: 0.12);
        fg = const Color(0xFF10B981);
        label = 'BALANCED';
        break;
      case 'CONTROLLED':
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.12);
        fg = const Color(0xFFF59E0B);
        label = 'CONTROLLED';
        break;
      case 'LEAKAGE_ALERT':
      default:
        bg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        fg = const Color(0xFFEF4444);
        label = 'LEAKAGE ALERT';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}
