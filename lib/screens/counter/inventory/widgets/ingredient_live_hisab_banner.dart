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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = UnitConversionHelper.getBreakdown(
      price: cost,
      currentUnit: purchaseUom,
      purchaseUom: purchaseUom,
      recipeUom: recipeUom,
      conversionFactor: factor,
    );

    if (items.isEmpty && cost <= 0) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B).withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.tune_rounded,
                size: 13,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                'UNIT RATE EQUIVALENTS (BOM COST)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item.formattedPrice,
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
