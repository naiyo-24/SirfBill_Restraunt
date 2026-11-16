import 'package:flutter/material.dart';
import '../utils/unit_conversion_helper.dart';

class IngredientLiveHisabBanner extends StatelessWidget {
  final String purchaseUom;
  final String recipeUom;
  final String conversionText;
  final String costText;

  const IngredientLiveHisabBanner({
    super.key,
    required this.purchaseUom,
    required this.recipeUom,
    required this.conversionText,
    required this.costText,
  });

  @override
  Widget build(BuildContext context) {
    final cost = double.tryParse(costText.trim()) ?? 0.0;
    final factor = double.tryParse(conversionText.trim()) ?? 1.0;

    final summary = UnitConversionHelper.getHisabSummary(
      price: cost,
      currentUnit: purchaseUom,
      purchaseUom: purchaseUom,
      recipeUom: recipeUom,
      conversionFactor: factor,
    );

    if (summary == null && cost <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.calculate_outlined, size: 16, color: Color(0xFF10B981)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              summary ?? '⚖️ Live Hisab: ₹${cost.toStringAsFixed(2)} / $purchaseUom • ₹${(cost / (factor > 0 ? factor : 1.0)).toStringAsFixed(2)} / $recipeUom in Kitchen Recipes',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF047857),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
