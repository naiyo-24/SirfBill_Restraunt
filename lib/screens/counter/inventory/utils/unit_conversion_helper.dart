class UnitConversionHelper {
  /// Converts unit price when switching from [oldUnit] to [newUnit].
  static double convertUnitPrice({
    required double currentPrice,
    required String oldUnit,
    required String newUnit,
    required String purchaseUom,
    required String recipeUom,
    required double conversionFactor,
  }) {
    if (currentPrice <= 0) return currentPrice;
    final o = oldUnit.trim().toUpperCase();
    final n = newUnit.trim().toUpperCase();
    final p = purchaseUom.trim().toUpperCase();
    final r = recipeUom.trim().toUpperCase();
    final factor = conversionFactor > 0 ? conversionFactor : 1.0;

    if (o == n) return currentPrice;

    // 1. Direct Purchase <-> Recipe UOM match
    if (o == p && n == r) {
      return currentPrice / factor;
    }
    if (o == r && n == p) {
      return currentPrice * factor;
    }

    // 2. Weight: KG <-> G
    if (o == 'KG' && n == 'G') return currentPrice / 1000.0;
    if (o == 'G' && n == 'KG') return currentPrice * 1000.0;

    // 3. Volume: L <-> ML
    if (o == 'L' && n == 'ML') return currentPrice / 1000.0;
    if (o == 'ML' && n == 'L') return currentPrice * 1000.0;

    // 4. Count: DOZ <-> PCS
    if (o == 'DOZ' && n == 'PCS') return currentPrice / 12.0;
    if (o == 'PCS' && n == 'DOZ') return currentPrice * 12.0;

    // 5. Bulk Bag: BAG <-> KG or G
    if (o == 'BAG' && n == 'KG') {
      final bagKg = (p == 'BAG' && r == 'KG') ? factor : (p == 'BAG' && r == 'G' ? factor / 1000.0 : 25.0);
      return currentPrice / bagKg;
    }
    if (o == 'KG' && n == 'BAG') {
      final bagKg = (p == 'BAG' && r == 'KG') ? factor : (p == 'BAG' && r == 'G' ? factor / 1000.0 : 25.0);
      return currentPrice * bagKg;
    }
    if (o == 'BAG' && n == 'G') {
      final bagG = (p == 'BAG' && r == 'G') ? factor : (p == 'BAG' && r == 'KG' ? factor * 1000.0 : 25000.0);
      return currentPrice / bagG;
    }
    if (o == 'G' && n == 'BAG') {
      final bagG = (p == 'BAG' && r == 'G') ? factor : (p == 'BAG' && r == 'KG' ? factor * 1000.0 : 25000.0);
      return currentPrice * bagG;
    }

    // 6. Box / Pack: BOX <-> PCS
    if (o == 'BOX' && n == 'PCS') {
      final boxPcs = (p == 'BOX' && r == 'PCS') ? factor : 24.0;
      return currentPrice / boxPcs;
    }
    if (o == 'PCS' && n == 'BOX') {
      final boxPcs = (p == 'BOX' && r == 'PCS') ? factor : 24.0;
      return currentPrice * boxPcs;
    }

    return currentPrice;
  }

  /// Returns a user-friendly live hisab summary breakdown for any unit.
  static String? getHisabSummary({
    required double price,
    required String currentUnit,
    required String purchaseUom,
    required String recipeUom,
    required double conversionFactor,
  }) {
    if (price <= 0) return null;
    final u = currentUnit.trim().toUpperCase();
    final p = purchaseUom.trim().toUpperCase();
    final r = recipeUom.trim().toUpperCase();
    final factor = conversionFactor > 0 ? conversionFactor : 1.0;

    // 1. Grams
    if (u == 'G') {
      final per100g = price * 100.0;
      final perKg = price * 1000.0;
      return '⚖️ Gm Hisab: ₹${per100g.toStringAsFixed(1)} / 100g  •  ₹${perKg.toStringAsFixed(0)} / KG  (₹${price.toStringAsFixed(2)} / g)';
    }

    // 2. Kilograms
    if (u == 'KG') {
      final per100g = price / 10.0;
      final perG = price / 1000.0;
      return '⚖️ Gm Hisab: ₹${price.toStringAsFixed(0)} / KG  •  ₹${per100g.toStringAsFixed(1)} / 100g  (₹${perG.toStringAsFixed(2)} / g)';
    }

    // 3. Milliliters
    if (u == 'ML') {
      final per100ml = price * 100.0;
      final perL = price * 1000.0;
      return '⚖️ ML Hisab: ₹${per100ml.toStringAsFixed(1)} / 100ml  •  ₹${perL.toStringAsFixed(0)} / L  (₹${price.toStringAsFixed(2)} / ml)';
    }

    // 4. Liters
    if (u == 'L') {
      final per100ml = price / 10.0;
      final perMl = price / 1000.0;
      return '⚖️ ML Hisab: ₹${price.toStringAsFixed(0)} / L  •  ₹${per100ml.toStringAsFixed(1)} / 100ml  (₹${perMl.toStringAsFixed(2)} / ml)';
    }

    // 5. Dozen
    if (u == 'DOZ') {
      final perPiece = price / 12.0;
      return '🥚 Dozen Hisab: ₹${price.toStringAsFixed(0)} / DOZ  •  ₹${perPiece.toStringAsFixed(2)} / Piece (PCS)';
    }

    // 6. Pieces (when bought in Dozen or Box)
    if (u == 'PCS') {
      if (p == 'DOZ') {
        final perDoz = price * 12.0;
        return '🥚 Piece Hisab: ₹${price.toStringAsFixed(2)} / Piece  •  ₹${perDoz.toStringAsFixed(0)} / DOZ';
      }
      if (p == 'BOX') {
        final perBox = price * factor;
        return '📦 Piece Hisab: ₹${price.toStringAsFixed(2)} / Piece  •  ₹${perBox.toStringAsFixed(0)} / BOX (${factor.toInt()} pcs/box)';
      }
    }

    // 7. Bag (Rice, Flour, Sugar)
    if (u == 'BAG') {
      final bagKg = (p == 'BAG' && r == 'KG') ? factor : (p == 'BAG' && r == 'G' ? factor / 1000.0 : 25.0);
      final perKg = price / bagKg;
      final per100g = perKg / 10.0;
      return '📦 Bag Hisab: ₹${price.toStringAsFixed(0)} / BAG  •  ₹${perKg.toStringAsFixed(1)} / KG  •  ₹${per100g.toStringAsFixed(1)} / 100g (${bagKg.toStringAsFixed(0)} KG bag)';
    }

    // 8. Box
    if (u == 'BOX') {
      final perRecipe = price / factor;
      return '📦 Box Hisab: ₹${price.toStringAsFixed(0)} / BOX  •  ₹${perRecipe.toStringAsFixed(2)} / $recipeUom (1 BOX = ${factor.toInt()} $recipeUom)';
    }

    // 9. Generic Dual-UOM item
    if (p != r && factor > 1) {
      if (u == p) {
        final perRecipe = price / factor;
        return '⚖️ Unit Hisab: ₹${price.toStringAsFixed(2)} / $purchaseUom  •  ₹${perRecipe.toStringAsFixed(2)} / $recipeUom (1 $purchaseUom = ${factor == factor.roundToDouble() ? factor.toInt() : factor} $recipeUom)';
      } else if (u == r) {
        final perPurchase = price * factor;
        return '⚖️ Unit Hisab: ₹${price.toStringAsFixed(2)} / $recipeUom  •  ₹${perPurchase.toStringAsFixed(2)} / $purchaseUom (1 $purchaseUom = ${factor == factor.roundToDouble() ? factor.toInt() : factor} $recipeUom)';
      }
    }

    return null;
  }

  /// Detects whether user entered a bulk rate for a small unit by mistake.
  /// Returns a suggested corrected rate if a mistake is detected, or null.
  static MistakeAlert? detectMistake({
    required double price,
    required String currentUnit,
    required String purchaseUom,
    required String recipeUom,
    required double conversionFactor,
  }) {
    if (price <= 0) return null;
    final u = currentUnit.trim().toUpperCase();
    final p = purchaseUom.trim().toUpperCase();
    final factor = conversionFactor > 0 ? conversionFactor : 1.0;

    // Grams mistake: e.g. entered ₹38 or ₹380 for 1 gram
    if (u == 'G' && price >= 5.0) {
      final suggested = price >= 100.0 ? (price / 1000.0) : (price / 100.0);
      final equivKg = price * 1000.0;
      return MistakeAlert(
        message: '⚠️ Alert: ₹${price.toStringAsFixed(0)}/g equals ₹${equivKg.toStringAsFixed(0)}/KG! Did you mean ₹${suggested.toStringAsFixed(2)}/g (₹${(suggested * 100).toStringAsFixed(1)} per 100g)?',
        suggestedRate: suggested,
        unitLabel: '/g',
      );
    }

    // ML mistake: e.g. entered ₹45 or ₹120 for 1 ml
    if (u == 'ML' && price >= 5.0) {
      final suggested = price >= 100.0 ? (price / 1000.0) : (price / 100.0);
      final equivL = price * 1000.0;
      return MistakeAlert(
        message: '⚠️ Alert: ₹${price.toStringAsFixed(0)}/ml equals ₹${equivL.toStringAsFixed(0)}/L! Did you mean ₹${suggested.toStringAsFixed(2)}/ml (₹${(suggested * 100).toStringAsFixed(1)} per 100ml)?',
        suggestedRate: suggested,
        unitLabel: '/ml',
      );
    }

    // Piece mistake when item is purchased in DOZ: e.g. entered ₹84 for 1 piece
    if (u == 'PCS' && p == 'DOZ' && price >= 25.0) {
      final suggested = price / 12.0;
      final equivDoz = price * 12.0;
      return MistakeAlert(
        message: '⚠️ Alert: ₹${price.toStringAsFixed(0)}/Piece equals ₹${equivDoz.toStringAsFixed(0)}/Dozen! Did you mean ₹${suggested.toStringAsFixed(2)}/Piece?',
        suggestedRate: suggested,
        unitLabel: '/Piece',
      );
    }

    // Piece mistake when item is purchased in BOX: e.g. entered ₹240 for 1 piece
    if (u == 'PCS' && p == 'BOX' && factor > 1 && price >= 50.0) {
      final suggested = price / factor;
      final equivBox = price * factor;
      return MistakeAlert(
        message: '⚠️ Alert: ₹${price.toStringAsFixed(0)}/Piece equals ₹${equivBox.toStringAsFixed(0)}/BOX! Did you mean ₹${suggested.toStringAsFixed(2)}/Piece?',
        suggestedRate: suggested,
        unitLabel: '/Piece',
      );
    }

    // KG mistake when item is purchased in BAG: e.g. entered ₹1500 for 1 KG
    if (u == 'KG' && p == 'BAG' && factor > 1 && price >= 500.0) {
      final suggested = price / factor;
      return MistakeAlert(
        message: '⚠️ Alert: ₹${price.toStringAsFixed(0)}/KG equals ₹${(price * factor).toStringAsFixed(0)}/BAG! Did you mean ₹${suggested.toStringAsFixed(1)}/KG?',
        suggestedRate: suggested,
        unitLabel: '/KG',
      );
    }

    return null;
  }
}

class MistakeAlert {
  final String message;
  final double suggestedRate;
  final String unitLabel;

  const MistakeAlert({
    required this.message,
    required this.suggestedRate,
    required this.unitLabel,
  });
}
