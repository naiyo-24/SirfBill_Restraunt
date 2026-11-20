import 'package:flutter/material.dart';
import '../../../../models/restaurant_executive_report_models.dart';

class ShrinkageLeakageTab extends StatelessWidget {
  final ShrinkageReport? report;
  final bool isLoading;

  const ShrinkageLeakageTab({
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
      return const Center(child: Text('No shrinkage loss records logged for this period'));
    }

    final r = report!;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return ListView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          children: [
            // Row 1: Total Shrinkage Hero Banner
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEF4444)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'TOTAL COST LEAKAGE & SHRINKAGE LOSSES',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '₹${r.totalShrinkageRupees.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                      ),
                      Text(
                        'Wastage loss across spoilage, kitchen errors, and physical stock deficits',
                        style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : Colors.black54),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.delete_sweep_rounded, color: Color(0xFFEF4444), size: 28),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Row 2: 4 Primary Leakage Drivers
            _buildDriverGrid(r, isDark, isMobile),
            const SizedBox(height: 16),

            // Row 3: Top Leaking Ingredients Ranking
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
                      'TOP COST-LEAKING INGREDIENTS RANKING (${r.topLeakingIngredients.length})',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  const Divider(height: 1),

                  if (r.topLeakingIngredients.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No ingredient shrinkage losses logged for this period')),
                    )
                  else if (isMobile)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: r.topLeakingIngredients.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                      itemBuilder: (ctx, i) => _buildMobileCard(r.topLeakingIngredients[i], i + 1, isDark),
                    )
                  else
                    _buildDesktopTable(r.topLeakingIngredients, isDark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDriverGrid(ShrinkageReport r, bool isDark, bool isMobile) {
    final drivers = [
      _buildCard('SPOILAGE LOSS', '₹${r.spoilageTotal.toStringAsFixed(0)}', 'Expired / bad storage', const Color(0xFFF59E0B), isDark),
      _buildCard('BURNT / RUINED', '₹${r.burntRuinedTotal.toStringAsFixed(0)}', 'Kitchen preparation error', const Color(0xFFEF4444), isDark),
      _buildCard('CUSTOMER RETURNS', '₹${r.customerReturnTotal.toStringAsFixed(0)}', 'Disliked or cold dish', const Color(0xFF8B5CF6), isDark),
      _buildCard('AUDIT DEFICIT', '₹${r.auditDeficitTotal.toStringAsFixed(0)}', 'Unaccounted shrinkage', const Color(0xFF3B82F6), isDark),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.8,
        children: drivers,
      );
    }

    return Row(
      children: drivers.map((d) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: d))).toList(),
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

  Widget _buildDesktopTable(List<ShrinkageIngredientItem> items, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('#', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('INGREDIENT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('COST / UNIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('LOST QUANTITY', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('TOTAL LOSS (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('SPOILAGE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('BURNT / RUINED', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('AUDIT DEFICIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
        rows: items.asMap().entries.map((entry) {
          final i = entry.key + 1;
          final it = entry.value;
          final spoilage = it.lossBreakdown['SPOILAGE'] ?? 0.0;
          final burnt = it.lossBreakdown['BURNT_RUINED'] ?? 0.0;
          final deficit = it.lossBreakdown['AUDIT_DEFICIT'] ?? 0.0;

          return DataRow(
            cells: [
              DataCell(
                Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: i <= 3 ? const Color(0xFFEF4444).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '$i',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: i <= 3 ? const Color(0xFFEF4444) : Colors.grey.shade700,
                    ),
                  ),
                ),
              ),
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
              DataCell(Text('${it.totalLostQty.toStringAsFixed(2)} ${it.unit}')),
              DataCell(
                Text(
                  '₹${it.totalLossRupees.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                ),
              ),
              DataCell(Text('₹${spoilage.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFF59E0B)))),
              DataCell(Text('₹${burnt.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFFEF4444)))),
              DataCell(Text('₹${deficit.toStringAsFixed(0)}', style: const TextStyle(color: Color(0xFF3B82F6)))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCard(ShrinkageIngredientItem it, int rank, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: rank <= 3 ? const Color(0xFFEF4444).withValues(alpha: 0.15) : Colors.grey.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$rank',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: rank <= 3 ? const Color(0xFFEF4444) : Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(it.ingredientName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                    Text(
                      '₹${it.totalLossRupees.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFFEF4444)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Lost: ${it.totalLostQty.toStringAsFixed(1)} ${it.unit} • Rate: ₹${it.costPerUnit.toStringAsFixed(1)}/${it.unit}',
                  style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
