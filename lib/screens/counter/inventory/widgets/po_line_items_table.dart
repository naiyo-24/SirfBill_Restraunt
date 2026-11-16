import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../models/po_line_item_input.dart';
import '../utils/unit_conversion_helper.dart';
import 'po_item_helper_banner.dart';

class PoLineItemsTable extends StatelessWidget {
  final List<PoLineItemInput> items;
  final List<Ingredient> ingredients;
  final VoidCallback onAddItem;
  final ValueChanged<int> onRemoveItem;
  final void Function(PoLineItemInput item, String? ingredientId) onIngredientSelected;
  final VoidCallback onItemChanged;
  final bool isDark;

  const PoLineItemsTable({
    super.key,
    required this.items,
    required this.ingredients,
    required this.onAddItem,
    required this.onRemoveItem,
    required this.onIngredientSelected,
    required this.onItemChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.format_list_bulleted_rounded, size: 16, color: Color(0xFF10B981)),
                const SizedBox(width: 6),
                Text(
                  'ORDER REQUISITION ITEMS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${items.length} ${items.length == 1 ? "item" : "items"}',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6)),
                  ),
                ),
              ],
            ),
            ElevatedButton.icon(
              onPressed: onAddItem,
              icon: const Icon(Icons.add_circle_outline_rounded, size: 15),
              label: const Text('Add Ingredient Row', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                foregroundColor: const Color(0xFF10B981),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.35) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      flex: 7,
                      child: Text(
                        'INGREDIENT / COMMODITY',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'QTY',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Text(
                        'UNIT',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'EST. UNIT PRICE (₹)',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 3,
                      child: Text(
                        'BASE TOTAL (₹)',
                        textAlign: TextAlign.right,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 36),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  children: items.asMap().entries.map((entry) {
                    final idx = entry.key;
                    final item = entry.value;

                    final matchingIng = ingredients.where((i) => i.id == item.ingredientId).toList();
                    final ing = matchingIng.isNotEmpty ? matchingIng.first : null;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                flex: 7,
                                // ignore: deprecated_member_use
                                child: DropdownButtonFormField<String>(
                                  initialValue: item.ingredientId,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                  ),
                                  items: ingredients.map((ing) => DropdownMenuItem(
                                    value: ing.id,
                                    child: Text(
                                      ing.name,
                                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )).toList(),
                                  onChanged: (v) => onIngredientSelected(item, v),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: item.qtyController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => onItemChanged(),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                // ignore: deprecated_member_use
                                child: DropdownButtonFormField<String>(
                                  initialValue: item.unit,
                                  isExpanded: true,
                                  decoration: InputDecoration(
                                    isDense: true,
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                  ),
                                  items: ['KG', 'G', 'L', 'ML', 'PCS', 'DOZ', 'BAG', 'BOX'].map((u) => DropdownMenuItem(
                                    value: u,
                                    child: Text(u, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                                  )).toList(),
                                  onChanged: (v) {
                                    final newUnit = v ?? 'KG';
                                    final oldUnit = item.unit;
                                    if (newUnit != oldUnit && ing != null) {
                                      final currentPrice = double.tryParse(item.priceController.text.trim()) ?? 0.0;
                                      final factor = ing.uomConversionFactor > 0 ? ing.uomConversionFactor : 1000.0;
                                      final converted = UnitConversionHelper.convertUnitPrice(
                                        currentPrice: currentPrice > 0 ? currentPrice : ing.costPerPurchaseUnit,
                                        oldUnit: oldUnit,
                                        newUnit: newUnit,
                                        purchaseUom: ing.purchaseUom,
                                        recipeUom: ing.recipeUom,
                                        conversionFactor: factor,
                                      );
                                      if (converted > 0) {
                                        item.priceController.text = converted == converted.roundToDouble()
                                            ? converted.toInt().toString()
                                            : (converted < 0.01 ? converted.toStringAsFixed(4) : converted.toStringAsFixed(2));
                                      }
                                    }
                                    item.unit = newUnit;
                                    onItemChanged();
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: item.priceController,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => onItemChanged(),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                  decoration: InputDecoration(
                                    isDense: true,
                                    prefixText: '₹ ',
                                    suffixText: '/ ${item.unit}',
                                    suffixStyle: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  '₹${item.subtotal == item.subtotal.roundToDouble() ? item.subtotal.toInt().toString() : item.subtotal.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                                ),
                              ),
                              const SizedBox(width: 4),
                              SizedBox(
                                width: 32,
                                child: IconButton(
                                  onPressed: items.length > 1 ? () => onRemoveItem(idx) : null,
                                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                  tooltip: 'Remove row',
                                  visualDensity: VisualDensity.compact,
                                ),
                              ),
                            ],
                          ),
                          if (ing != null)
                            PoItemHelperBanner(
                              ing: ing,
                              item: item,
                              isDark: isDark,
                              onItemChanged: onItemChanged,
                            ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
