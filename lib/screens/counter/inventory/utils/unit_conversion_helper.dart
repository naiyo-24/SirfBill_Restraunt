class UnitRateItem {
  final String label;
  final String formattedPrice;

  const UnitRateItem(this.label, this.formattedPrice);
}

class UnitConversionHelper {
  static String _fmt(double val) {
    if (val == val.roundToDouble()) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  static String _fmtDec(double val) {
    if (val < 0.01) {
      return val.toStringAsFixed(4);
    }
    return val.toStringAsFixed(2);
  }

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

  /// Returns structured list of rate equivalent pills for clean enterprise UI.
  static List<UnitRateItem> getBreakdown({
    required double price,
    required String currentUnit,
    required String purchaseUom,
    required String recipeUom,
    required double conversionFactor,
  }) {
    if (price <= 0) return const [];
    final u = currentUnit.trim().toUpperCase();
    final p = purchaseUom.trim().toUpperCase();
    final r = recipeUom.trim().toUpperCase();
    final factor = conversionFactor > 0 ? conversionFactor : 1.0;

    final items = <UnitRateItem>[];

    // Weight commodities (KG / G)
    if (u == 'KG' || u == 'G' || (p == 'KG' && r == 'G') || (p == 'G' && r == 'KG')) {
      double pricePerKg = 0.0;
      if (u == 'KG') {
        pricePerKg = price;
      } else if (u == 'G') {
        pricePerKg = price * 1000.0;
      } else {
        pricePerKg = price;
      }

      final per100g = pricePerKg / 10.0;
      final perG = pricePerKg / 1000.0;

      items.add(UnitRateItem('1 KG', '₹${_fmt(pricePerKg)}'));
      items.add(UnitRateItem('100g', '₹${_fmt(per100g)}'));
      items.add(UnitRateItem('1g (BOM)', '₹${_fmtDec(perG)}'));
      return items;
    }

    // Liquid commodities (L / ML)
    if (u == 'L' || u == 'ML' || (p == 'L' && r == 'ML')) {
      double pricePerL = 0.0;
      if (u == 'L') {
        pricePerL = price;
      } else if (u == 'ML') {
        pricePerL = price * 1000.0;
      } else {
        pricePerL = price;
      }

      final per100ml = pricePerL / 10.0;
      final perMl = pricePerL / 1000.0;

      items.add(UnitRateItem('1 L', '₹${_fmt(pricePerL)}'));
      items.add(UnitRateItem('100ml', '₹${_fmt(per100ml)}'));
      items.add(UnitRateItem('1ml (BOM)', '₹${_fmtDec(perMl)}'));
      return items;
    }

    // Dozen commodities (DOZ / PCS)
    if (u == 'DOZ' || p == 'DOZ') {
      double pricePerDoz = u == 'DOZ' ? price : (price * 12.0);
      final perPcs = pricePerDoz / 12.0;

      items.add(UnitRateItem('1 DOZ', '₹${_fmt(pricePerDoz)}'));
      items.add(UnitRateItem('1 Piece (BOM)', '₹${_fmt(perPcs)}'));
      return items;
    }

    // Bags (Rice, Flour, Sugar)
    if (u == 'BAG' || p == 'BAG') {
      final bagKg = (p == 'BAG' && r == 'KG') ? factor : (p == 'BAG' && r == 'G' ? factor / 1000.0 : 25.0);
      double pricePerBag = u == 'BAG' ? price : (price * bagKg);
      final perKg = pricePerBag / bagKg;
      final per100g = perKg / 10.0;

      items.add(UnitRateItem('1 BAG (${bagKg.toInt()} KG)', '₹${_fmt(pricePerBag)}'));
      items.add(UnitRateItem('1 KG', '₹${_fmt(perKg)}'));
      items.add(UnitRateItem('100g', '₹${_fmt(per100g)}'));
      return items;
    }

    // Boxes
    if (u == 'BOX' || p == 'BOX') {
      final boxPcs = factor > 0 ? factor : 24.0;
      double pricePerBox = u == 'BOX' ? price : (price * boxPcs);
      final perPcs = pricePerBox / boxPcs;

      items.add(UnitRateItem('1 BOX (${boxPcs.toInt()} $recipeUom)', '₹${_fmt(pricePerBox)}'));
      items.add(UnitRateItem('1 $recipeUom (BOM)', '₹${_fmt(perPcs)}'));
      return items;
    }

    // Generic Dual-UOM item
    if (p != r && factor > 1) {
      double pricePerPur = u == p ? price : (price * factor);
      double pricePerRec = u == r ? price : (price / factor);

      items.add(UnitRateItem('1 $purchaseUom', '₹${_fmt(pricePerPur)}'));
      items.add(UnitRateItem('1 $recipeUom (BOM)', '₹${_fmt(pricePerRec)}'));
      return items;
    }

    return items;
  }

  /// Detects whether user entered a bulk rate for a small unit by mistake.
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
        message: 'Entered rate is ₹${price.toStringAsFixed(0)}/g (₹${equivKg.toStringAsFixed(0)}/KG). Did you mean ₹${suggested.toStringAsFixed(2)}/g (₹${(suggested * 100).toStringAsFixed(1)} per 100g)?',
        suggestedRate: suggested,
        unitLabel: '/g',
      );
    }

    // ML mistake: e.g. entered ₹45 or ₹120 for 1 ml
    if (u == 'ML' && price >= 5.0) {
      final suggested = price >= 100.0 ? (price / 1000.0) : (price / 100.0);
      final equivL = price * 1000.0;
      return MistakeAlert(
        message: 'Entered rate is ₹${price.toStringAsFixed(0)}/ml (₹${equivL.toStringAsFixed(0)}/L). Did you mean ₹${suggested.toStringAsFixed(2)}/ml (₹${(suggested * 100).toStringAsFixed(1)} per 100ml)?',
        suggestedRate: suggested,
        unitLabel: '/ml',
      );
    }

    // Piece mistake when item is purchased in DOZ: e.g. entered ₹84 for 1 piece
    if (u == 'PCS' && p == 'DOZ' && price >= 25.0) {
      final suggested = price / 12.0;
      final equivDoz = price * 12.0;
      return MistakeAlert(
        message: 'Entered rate is ₹${price.toStringAsFixed(0)}/Piece (₹${equivDoz.toStringAsFixed(0)}/Dozen). Did you mean ₹${suggested.toStringAsFixed(2)}/Piece?',
        suggestedRate: suggested,
        unitLabel: '/Piece',
      );
    }

    // Piece mistake when item is purchased in BOX: e.g. entered ₹240 for 1 piece
    if (u == 'PCS' && p == 'BOX' && factor > 1 && price >= 50.0) {
      final suggested = price / factor;
      final equivBox = price * factor;
      return MistakeAlert(
        message: 'Entered rate is ₹${price.toStringAsFixed(0)}/Piece (₹${equivBox.toStringAsFixed(0)}/BOX). Did you mean ₹${suggested.toStringAsFixed(2)}/Piece?',
        suggestedRate: suggested,
        unitLabel: '/Piece',
      );
    }

    // KG mistake when item is purchased in BAG: e.g. entered ₹1500 for 1 KG
    if (u == 'KG' && p == 'BAG' && factor > 1 && price >= 500.0) {
      final suggested = price / factor;
      return MistakeAlert(
        message: 'Entered rate is ₹${price.toStringAsFixed(0)}/KG (₹${(price * factor).toStringAsFixed(0)}/BAG). Did you mean ₹${suggested.toStringAsFixed(1)}/KG?',
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
