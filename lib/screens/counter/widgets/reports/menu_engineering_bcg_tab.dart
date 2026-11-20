import 'package:flutter/material.dart';
import '../../../../models/restaurant_executive_report_models.dart';

class MenuEngineeringBcgTab extends StatefulWidget {
  final MenuEngineeringReport? report;
  final bool isLoading;

  const MenuEngineeringBcgTab({
    super.key,
    required this.report,
    this.isLoading = false,
  });

  @override
  State<MenuEngineeringBcgTab> createState() => _MenuEngineeringBcgTabState();
}

class _MenuEngineeringBcgTabState extends State<MenuEngineeringBcgTab> {
  String _selectedQuadrant = 'ALL';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (widget.isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    if (widget.report == null) {
      return const Center(child: Text('No menu engineering data available for this period'));
    }

    final r = widget.report!;
    final filteredItems = _selectedQuadrant == 'ALL'
        ? r.items
        : _selectedQuadrant == 'ALERT'
            ? r.items.where((it) => it.isCostAlert).toList()
            : r.items.where((it) => it.quadrant == _selectedQuadrant).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 700;

        return ListView(
          padding: EdgeInsets.all(isMobile ? 12 : 20),
          children: [
            // BCG 4-Quadrant KPI Summary Grid
            _buildQuadrantKpis(r, isDark, isMobile),
            const SizedBox(height: 16),

            // Quadrant Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('ALL', 'All Items (${r.items.length})', isDark),
                  const SizedBox(width: 8),
                  _buildFilterChip('STAR', 'Stars (${r.starsCount})', isDark, const Color(0xFF10B981)),
                  const SizedBox(width: 8),
                  _buildFilterChip('PLOWHORSE', 'Plowhorses (${r.plowhorsesCount})', isDark, const Color(0xFFF59E0B)),
                  const SizedBox(width: 8),
                  _buildFilterChip('PUZZLE', 'Puzzles (${r.puzzlesCount})', isDark, const Color(0xFF8B5CF6)),
                  const SizedBox(width: 8),
                  _buildFilterChip('DOG', 'Dogs (${r.dogsCount})', isDark, const Color(0xFFEF4444)),
                  const SizedBox(width: 8),
                  _buildFilterChip('ALERT', 'Food Cost > 35%', isDark, Colors.red),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Dishes Table Container
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
                          'MENU RECIPE & PLATE COST MATRIX (${filteredItems.length})',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          'Avg Food Cost: ${r.avgFoodCostPct.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: r.avgFoodCostPct > 35 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1),

                  if (filteredItems.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: Center(child: Text('No menu items in this quadrant')),
                    )
                  else if (isMobile)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: filteredItems.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                      itemBuilder: (ctx, i) => _buildMobileCard(filteredItems[i], isDark),
                    )
                  else
                    _buildDesktopTable(filteredItems, isDark),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuadrantKpis(MenuEngineeringReport r, bool isDark, bool isMobile) {
    final cards = [
      _buildQuadrantCard('STARS ⭐', '${r.starsCount} Dishes', 'High Volume • High Margin', 'Promote & maintain standard', const Color(0xFF10B981), isDark),
      _buildQuadrantCard('PLOWHORSES 🐎', '${r.plowhorsesCount} Dishes', 'High Volume • Low Margin', 'Re-engineer recipe or increase price', const Color(0xFFF59E0B), isDark),
      _buildQuadrantCard('PUZZLES 🧩', '${r.puzzlesCount} Dishes', 'Low Volume • High Margin', 'Reposition on menu & upsell', const Color(0xFF8B5CF6), isDark),
      _buildQuadrantCard('DOGS 🐕', '${r.dogsCount} Dishes', 'Low Volume • Low Margin', 'Consider eliminating from menu', const Color(0xFFEF4444), isDark),
    ];

    if (isMobile) {
      return GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1.5,
        children: cards,
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: c))).toList(),
    );
  }

  Widget _buildQuadrantCard(String title, String count, String sub, String action, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
          const SizedBox(height: 2),
          Text(count, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          Text(sub, style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
          const SizedBox(height: 4),
          Text('Action: $action', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 8.5, fontStyle: FontStyle.italic, color: color)),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String key, String label, bool isDark, [Color? color]) {
    final isSelected = _selectedQuadrant == key;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: (color ?? const Color(0xFF10B981)).withValues(alpha: 0.2),
      labelStyle: TextStyle(
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? (color ?? const Color(0xFF10B981)) : null,
      ),
      onSelected: (selected) {
        if (selected) setState(() => _selectedQuadrant = key);
      },
    );
  }

  Widget _buildDesktopTable(List<MenuEngineeringItem> items, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
        columns: const [
          DataColumn(label: Text('DISH / VARIANT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('QUADRANT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('PRICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('PLATE COST', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('MARGIN (₹)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('FOOD COST %', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('SOLD', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
          DataColumn(label: Text('REVENUE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold))),
        ],
        rows: items.map((it) {
          final color = _getQuadrantColor(it.quadrant);
          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(it.itemName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    Text('${it.categoryName} • ${it.variantName}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              DataCell(
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: Text(it.quadrant, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
                ),
              ),
              DataCell(Text('₹${it.sellingPrice.toStringAsFixed(0)}')),
              DataCell(Text('₹${it.plateCost.toStringAsFixed(2)}')),
              DataCell(Text('₹${it.grossMarginRupees.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold))),
              DataCell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('${it.foodCostPct.toStringAsFixed(1)}%'),
                    if (it.isCostAlert) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Colors.red),
                    ],
                  ],
                ),
              ),
              DataCell(Text('${it.quantitySold}')),
              DataCell(Text('₹${it.totalRevenue.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w800))),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMobileCard(MenuEngineeringItem it, bool isDark) {
    final color = _getQuadrantColor(it.quadrant);
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(it.itemName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(it.quadrant, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Price: ₹${it.sellingPrice.toStringAsFixed(0)} • Cost: ₹${it.plateCost.toStringAsFixed(1)} (${it.foodCostPct.toStringAsFixed(0)}%) • Margin: ₹${it.grossMarginRupees.toStringAsFixed(0)}',
            style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          Text('Sold: ${it.quantitySold} • Total Revenue: ₹${it.totalRevenue.toStringAsFixed(0)}', style: TextStyle(fontSize: 10, color: Colors.grey.shade500)),
        ],
      ),
    );
  }

  Color _getQuadrantColor(String quad) {
    switch (quad) {
      case 'STAR':
        return const Color(0xFF10B981);
      case 'PLOWHORSE':
        return const Color(0xFFF59E0B);
      case 'PUZZLE':
        return const Color(0xFF8B5CF6);
      case 'DOG':
        return const Color(0xFFEF4444);
      default:
        return Colors.grey;
    }
  }
}
