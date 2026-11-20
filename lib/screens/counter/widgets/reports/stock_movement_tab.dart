import 'package:flutter/material.dart';
import '../../../../models/restaurant_executive_report_models.dart';

class StockMovementTab extends StatelessWidget {
  final StockMovementReport? report;
  final bool isLoading;

  const StockMovementTab({
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
      return const Center(child: Text('No stock movement records found for this period'));
    }

    final r = report!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return ListView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          children: [
            // Total Closing Valuation Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF10B981)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL INVENTORY CLOSING VALUATION',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF10B981)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${r.totalClosingValuation.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                      ),
                      Text(
                        'Valued across ${r.items.length} trackable raw materials & ingredients',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.inventory_2_rounded, color: Color(0xFF10B981), size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Stock Table Container
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
                    child: Text(
                      'STOCK AUDIT & RECONCILIATION LEDGER (${r.items.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  if (r.items.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No stock movement items recorded')),
                    )
                  else if (isMobile)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: r.items.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                      itemBuilder: (ctx, i) => _buildMobileCard(r.items[i], isDark),
                    )
                  else
                    _buildDesktopTable(r.items, isDark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDesktopTable(List<StockMovementItem> items, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('INGREDIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('COST / UNIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('OPENING', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('GRN IN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('KOT SOLD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('WASTAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('AUDIT ADJ', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('CLOSING STOCK', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('VALUATION (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
        rows: items.map((it) {
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
              DataCell(Text('₹${it.costPerUnit.toStringAsFixed(2)} / ${it.unit}')),
              DataCell(Text('${it.openingQty.toStringAsFixed(1)} ${it.unit}')),
              DataCell(Text('+${it.receivedGrnQty.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFF10B981)))),
              DataCell(Text('-${it.kotSoldQty.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFF3B82F6)))),
              DataCell(Text('-${it.wastageQty.toStringAsFixed(1)}', style: const TextStyle(color: Color(0xFFEF4444)))),
              DataCell(
                Text(
                  '${it.auditAdjustQty >= 0 ? "+" : ""}${it.auditAdjustQty.toStringAsFixed(1)}',
                  style: TextStyle(
                    color: it.auditAdjustQty < 0 ? const Color(0xFFEF4444) : Colors.grey.shade700,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${it.closingQty.toStringAsFixed(1)} ${it.unit}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataCell(
                Text(
                  '₹${it.closingValuation.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCard(StockMovementItem it, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(it.ingredientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Text(
                '₹${it.closingValuation.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Closing: ${it.closingQty.toStringAsFixed(1)} ${it.unit} • Rate: ₹${it.costPerUnit.toStringAsFixed(1)}/${it.unit}',
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          Text(
            'Open: ${it.openingQty.toStringAsFixed(1)} | GRN: +${it.receivedGrnQty.toStringAsFixed(1)} | Sold: -${it.kotSoldQty.toStringAsFixed(1)} | Waste: -${it.wastageQty.toStringAsFixed(1)}',
            style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
