import 'package:flutter/material.dart';

class IngredientFormGuideDialog extends StatelessWidget {
  const IngredientFormGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 680,
        constraints: BoxConstraints(
          maxWidth: 720,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.menu_book_rounded, color: Color(0xFF10B981), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Ingredient Setup & Dual-UOM Guide',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      Text(
                        'How supplier units, kitchen recipes, par levels and costs work together',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                ),
              ],
            ),
            const Divider(height: 24),

            // Content
            Expanded(
              child: ListView(
                children: [
                  _buildSection(
                    title: '1. Dual-UOM System (Purchasing vs Recipe)',
                    color: const Color(0xFF3B82F6),
                    icon: Icons.sync_alt_rounded,
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Restaurants buy in bulk (KG, LTR, CRATE) but cook in small portions (G, ML, PCS). The system handles this automatically:',
                          style: TextStyle(fontSize: 12.5, height: 1.4),
                        ),
                        const SizedBox(height: 10),
                        _buildRowGuide(
                          'Purchase Unit (Supplier)',
                          'Wholesale unit billed on the vendor invoice (e.g. KG, LTR, CRATE, BOX).',
                          isDark,
                        ),
                        _buildRowGuide(
                          'Recipe Unit (Kitchen BOM)',
                          'Kitchen portion unit used in dish preparation recipes (e.g. G, ML, PCS).',
                          isDark,
                        ),
                        _buildRowGuide(
                          'Conversion Factor',
                          'Exact multiplier: How many Recipe Units are in 1 Purchase Unit.\n'
                              '• 1 KG = 1000 G\n'
                              '• 1 LTR = 1000 ML\n'
                              '• 1 CRATE = 30 PCS (Eggs)\n'
                              '• 1 BOX = 24 PCS (Patties / Buns)',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildSection(
                    title: '2. Stock, Safety Par & Storage Capacity',
                    color: const Color(0xFF10B981),
                    icon: Icons.inventory_2_outlined,
                    isDark: isDark,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildRowGuide(
                          'Current Stock',
                          'Physical quantity on your kitchen shelf right now, measured in Recipe Units (e.g. 10,000 G = 10 KG).',
                          isDark,
                        ),
                        _buildRowGuide(
                          'Min Par Level (Alert)',
                          'Safety threshold. When stock falls below this, the system triggers a "Low Stock" restock alert.',
                          isDark,
                        ),
                        _buildRowGuide(
                          'Ideal Par Level (Max Capacity)',
                          'Maximum storage capacity of your fridge / store. When creating Purchase Orders, the system caps orders so you do not exceed shelf space.',
                          isDark,
                        ),
                        _buildRowGuide(
                          'Cost / Purchase Unit (₹)',
                          'Vendor contract rate per Purchase Unit (e.g. ₹380/KG). The system auto-calculates recipe cost (₹380 ÷ 1000 = ₹0.38/G).',
                          isDark,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  _buildSection(
                    title: '3. Real Restaurant Examples Cheatsheet',
                    color: const Color(0xFFF59E0B),
                    icon: Icons.table_chart_outlined,
                    isDark: isDark,
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(2.5),
                        1: FlexColumnWidth(1.5),
                        2: FlexColumnWidth(1.5),
                        3: FlexColumnWidth(1.8),
                        4: FlexColumnWidth(2.2),
                      },
                      border: TableBorder.all(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      children: [
                        TableRow(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          ),
                          children: const [
                            Padding(padding: EdgeInsets.all(8), child: Text('Commodity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Purchase', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Recipe', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Conversion', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                            Padding(padding: EdgeInsets.all(8), child: Text('Min / Max Par', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                          ],
                        ),
                        _buildTableRow('Chicken Breast', 'KG', 'G', '1000', '5k G / 20k G'),
                        _buildTableRow('Cooking Oil', 'L', 'ML', '1000', '5k ML / 30k ML'),
                        _buildTableRow('Basmati Rice', 'KG', 'G', '1000', '10k G / 50k G'),
                        _buildTableRow('Farm Eggs', 'BOX', 'PCS', '30', '60 / 300 PCS'),
                        _buildTableRow('Burger Buns', 'PACK', 'PCS', '12', '24 / 120 PCS'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Footer
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Color color,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  Widget _buildRowGuide(String term, String definition, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 175,
            child: Text(
              term,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          Expanded(
            child: Text(
              definition,
              style: TextStyle(
                fontSize: 12,
                height: 1.35,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  TableRow _buildTableRow(String name, String pur, String rec, String conv, String par) {
    return TableRow(
      children: [
        Padding(padding: const EdgeInsets.all(8), child: Text(name, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600))),
        Padding(padding: const EdgeInsets.all(8), child: Text(pur, style: const TextStyle(fontSize: 11.5))),
        Padding(padding: const EdgeInsets.all(8), child: Text(rec, style: const TextStyle(fontSize: 11.5))),
        Padding(padding: const EdgeInsets.all(8), child: Text(conv, style: const TextStyle(fontSize: 11.5))),
        Padding(padding: const EdgeInsets.all(8), child: Text(par, style: const TextStyle(fontSize: 11.5))),
      ],
    );
  }
}
