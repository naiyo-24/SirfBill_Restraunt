import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../models/po_line_item_input.dart';
import '../utils/unit_conversion_helper.dart';

class PoItemHelperBanner extends StatelessWidget {
  final Ingredient ing;
  final PoLineItemInput item;
  final bool isDark;
  final VoidCallback onItemChanged;

  const PoItemHelperBanner({
    super.key,
    required this.ing,
    required this.item,
    required this.isDark,
    required this.onItemChanged,
  });

  @override
  Widget build(BuildContext context) {
    final factor = ing.uomConversionFactor > 0 ? ing.uomConversionFactor : 1.0;
    final isPurchase = item.unit.toUpperCase() == ing.purchaseUom.toUpperCase();
    final stockInUnit = isPurchase ? (ing.currentStock / factor) : ing.currentStock;
    final minParInUnit = isPurchase ? (ing.minParLevel / factor) : ing.minParLevel;
    final hasIdealPar = ing.idealParLevel > 0;
    final idealParInUnit = hasIdealPar
        ? (isPurchase ? (ing.idealParLevel / factor) : ing.idealParLevel)
        : 0.0;
    final availSpace = hasIdealPar
        ? (idealParInUnit - stockInUnit).clamp(0.0, double.infinity)
        : double.infinity;
    final orderQty = double.tryParse(item.qtyController.text.trim()) ?? 0.0;
    final isExceeded = hasIdealPar && (orderQty > availSpace);

    final currentPrice = double.tryParse(item.priceController.text.trim()) ?? 0.0;

    // Use UnitConversionHelper for universal hisab and mistake detection across all units
    final hisabSummary = UnitConversionHelper.getHisabSummary(
      price: currentPrice,
      currentUnit: item.unit,
      purchaseUom: ing.purchaseUom,
      recipeUom: ing.recipeUom,
      conversionFactor: factor,
    );

    final mistakeAlert = UnitConversionHelper.detectMistake(
      price: currentPrice,
      currentUnit: item.unit,
      purchaseUom: ing.purchaseUom,
      recipeUom: ing.recipeUom,
      conversionFactor: factor,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 1. Capacity widget
        Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isExceeded
                ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isExceeded
                  ? const Color(0xFFEF4444).withValues(alpha: 0.3)
                  : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
          ),
          child: Row(
            children: [
              Icon(
                isExceeded ? Icons.warning_amber_rounded : Icons.warehouse_outlined,
                size: 14,
                color: isExceeded ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  isExceeded
                      ? (availSpace <= 0
                          ? '🚫 Storage Full! Current: ${stockInUnit.toStringAsFixed(1)} ${item.unit} is at Max Cap (${idealParInUnit.toStringAsFixed(1)} ${item.unit}).'
                          : '⚠️ Exceeds Max Capacity! Current: ${stockInUnit.toStringAsFixed(1)} ${item.unit} • Max Cap: ${idealParInUnit.toStringAsFixed(1)} ${item.unit} • Remaining Space: ${availSpace.toStringAsFixed(1)} ${item.unit}')
                      : (hasIdealPar
                          ? 'Storage: Current ${stockInUnit.toStringAsFixed(1)} ${item.unit} • Min: ${minParInUnit.toStringAsFixed(1)} • Max Cap (Ideal Par): ${idealParInUnit.toStringAsFixed(1)} ${item.unit} • Space: ${availSpace.toStringAsFixed(1)} ${item.unit}'
                          : 'Storage: Current ${stockInUnit.toStringAsFixed(1)} ${item.unit} • Min Par: ${minParInUnit.toStringAsFixed(1)} ${item.unit} • Max Cap: Not set'),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isExceeded ? FontWeight.bold : FontWeight.w500,
                    color: isExceeded
                        ? const Color(0xFFEF4444)
                        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                ),
              ),
              if (hasIdealPar && availSpace > 0 && orderQty != availSpace) ...[
                InkWell(
                  onTap: () {
                    item.qtyController.text = availSpace.toStringAsFixed(1);
                    onItemChanged();
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Fill to Max (${availSpace.toStringAsFixed(1)})',
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),

        // 2. Dual-UOM Rate & Mistake Banner across ALL units
        if (mistakeAlert != null || hisabSummary != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: mistakeAlert != null
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                  : const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: mistakeAlert != null
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                    : const Color(0xFF10B981).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    mistakeAlert != null ? mistakeAlert.message : hisabSummary!,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: mistakeAlert != null ? FontWeight.bold : FontWeight.w600,
                      color: mistakeAlert != null ? const Color(0xFFD97706) : const Color(0xFF10B981),
                    ),
                  ),
                ),
                if (mistakeAlert != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      final suggested = mistakeAlert.suggestedRate;
                      item.priceController.text = suggested == suggested.roundToDouble()
                          ? suggested.toInt().toString()
                          : (suggested < 0.01 ? suggested.toStringAsFixed(4) : suggested.toStringAsFixed(2));
                      onItemChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Fix to ₹${mistakeAlert.suggestedRate < 0.01 ? mistakeAlert.suggestedRate.toStringAsFixed(4) : (mistakeAlert.suggestedRate == mistakeAlert.suggestedRate.roundToDouble() ? mistakeAlert.suggestedRate.toInt().toString() : mistakeAlert.suggestedRate.toStringAsFixed(2))}${mistakeAlert.unitLabel}',
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}
