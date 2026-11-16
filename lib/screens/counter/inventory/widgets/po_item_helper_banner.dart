import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../models/po_line_item_input.dart';

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
    final isGram = item.unit.toUpperCase() == 'G';
    final isKg = item.unit.toUpperCase() == 'KG';
    final isMl = item.unit.toUpperCase() == 'ML';
    final isLiter = item.unit.toUpperCase() == 'L';

    String? hisabSummary;
    bool isLikelyMistake = false;
    double? suggestedGramRate;

    if (isGram && currentPrice > 0) {
      final per100g = currentPrice * 100;
      final perKg = currentPrice * 1000;
      if (currentPrice >= 5.0) {
        isLikelyMistake = true;
        suggestedGramRate = currentPrice >= 100 ? (currentPrice / 1000) : (currentPrice / 100);
      }
      hisabSummary = '⚖️ Gm Hisab: ₹${per100g.toStringAsFixed(1)} / 100g  •  ₹${perKg.toStringAsFixed(0)} / KG  (₹${currentPrice.toStringAsFixed(2)} / g)';
    } else if (isKg && currentPrice > 0) {
      final per100g = currentPrice / 10;
      final perG = currentPrice / 1000;
      hisabSummary = '⚖️ Gm Hisab: ₹${currentPrice.toStringAsFixed(0)} / KG  •  ₹${per100g.toStringAsFixed(1)} / 100g  (₹${perG.toStringAsFixed(2)} / g)';
    } else if (isMl && currentPrice > 0) {
      final per100ml = currentPrice * 100;
      final perL = currentPrice * 1000;
      hisabSummary = '⚖️ ML Hisab: ₹${per100ml.toStringAsFixed(1)} / 100ml  •  ₹${perL.toStringAsFixed(0)} / L';
    } else if (isLiter && currentPrice > 0) {
      final per100ml = currentPrice / 10;
      hisabSummary = '⚖️ ML Hisab: ₹${currentPrice.toStringAsFixed(0)} / L  •  ₹${per100ml.toStringAsFixed(1)} / 100ml';
    }

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

        // 2. Dual-UOM Gm Hisab rate banner
        if (hisabSummary != null)
          Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isLikelyMistake
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.12)
                  : const Color(0xFF10B981).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isLikelyMistake
                    ? const Color(0xFFF59E0B).withValues(alpha: 0.4)
                    : const Color(0xFF10B981).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    isLikelyMistake
                        ? '⚠️ Alert: ₹${currentPrice.toStringAsFixed(0)}/g equals ₹${(currentPrice * 1000).toStringAsFixed(0)}/KG! Did you mean ₹${suggestedGramRate?.toStringAsFixed(2)}/g (₹${((suggestedGramRate ?? 0) * 100).toStringAsFixed(1)} per 100g)?'
                        : hisabSummary,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isLikelyMistake ? FontWeight.bold : FontWeight.w600,
                      color: isLikelyMistake ? const Color(0xFFD97706) : const Color(0xFF10B981),
                    ),
                  ),
                ),
                if (isLikelyMistake && suggestedGramRate != null) ...[
                  const SizedBox(width: 8),
                  InkWell(
                    onTap: () {
                      item.priceController.text = suggestedGramRate!.toStringAsFixed(2);
                      onItemChanged();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Fix to ₹${suggestedGramRate.toStringAsFixed(2)}/g',
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
