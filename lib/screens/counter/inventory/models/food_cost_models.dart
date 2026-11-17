class FoodCostSummaryData {
  final double totalSalesInr;
  final double theoreticalCostInr;
  final double theoreticalCostPct;
  final double recordedWasteInr;
  final double auditShrinkageInr;
  final double actualCogsInr;
  final double actualCostPct;
  final double varianceLossInr;
  final double variancePct;
  final double targetBenchmarkPct;

  const FoodCostSummaryData({
    required this.totalSalesInr,
    required this.theoreticalCostInr,
    required this.theoreticalCostPct,
    required this.recordedWasteInr,
    required this.auditShrinkageInr,
    required this.actualCogsInr,
    required this.actualCostPct,
    required this.varianceLossInr,
    required this.variancePct,
    this.targetBenchmarkPct = 30.0,
  });

  factory FoodCostSummaryData.fromJson(Map<String, dynamic> json) {
    return FoodCostSummaryData(
      totalSalesInr: _toDouble(json['total_sales_inr']),
      theoreticalCostInr: _toDouble(json['theoretical_cost_inr']),
      theoreticalCostPct: _toDouble(json['theoretical_cost_pct']),
      recordedWasteInr: _toDouble(json['recorded_waste_inr']),
      auditShrinkageInr: _toDouble(json['audit_shrinkage_inr']),
      actualCogsInr: _toDouble(json['actual_cogs_inr']),
      actualCostPct: _toDouble(json['actual_cost_pct']),
      varianceLossInr: _toDouble(json['variance_loss_inr']),
      variancePct: _toDouble(json['variance_pct']),
      targetBenchmarkPct: _toDouble(json['target_benchmark_pct'], fallback: 30.0),
    );
  }

  factory FoodCostSummaryData.empty() {
    return const FoodCostSummaryData(
      totalSalesInr: 0.0,
      theoreticalCostInr: 0.0,
      theoreticalCostPct: 0.0,
      recordedWasteInr: 0.0,
      auditShrinkageInr: 0.0,
      actualCogsInr: 0.0,
      actualCostPct: 0.0,
      varianceLossInr: 0.0,
      variancePct: 0.0,
      targetBenchmarkPct: 30.0,
    );
  }
}

class FoodCostCommodityBreakdown {
  final String ingredientId;
  final String ingredientName;
  final String category;
  final String recipeUom;
  final double unitCost;
  final double theoreticalQty;
  final double theoreticalCost;
  final double wasteQty;
  final double wasteCost;
  final double auditVarianceQty;
  final double auditVarianceCost;
  final double actualDepletionCost;
  final double varianceLossInr;
  final String healthStatus; // BALANCED, CONTROLLED, LEAKAGE_ALERT

  const FoodCostCommodityBreakdown({
    required this.ingredientId,
    required this.ingredientName,
    required this.category,
    required this.recipeUom,
    required this.unitCost,
    required this.theoreticalQty,
    required this.theoreticalCost,
    required this.wasteQty,
    required this.wasteCost,
    required this.auditVarianceQty,
    required this.auditVarianceCost,
    required this.actualDepletionCost,
    required this.varianceLossInr,
    required this.healthStatus,
  });

  factory FoodCostCommodityBreakdown.fromJson(Map<String, dynamic> json) {
    return FoodCostCommodityBreakdown(
      ingredientId: json['ingredient_id']?.toString() ?? '',
      ingredientName: json['ingredient_name']?.toString() ?? 'Unnamed Commodity',
      category: json['category']?.toString() ?? 'Pantry',
      recipeUom: json['recipe_uom']?.toString() ?? 'G',
      unitCost: _toDouble(json['unit_cost']),
      theoreticalQty: _toDouble(json['theoretical_qty']),
      theoreticalCost: _toDouble(json['theoretical_cost']),
      wasteQty: _toDouble(json['waste_qty']),
      wasteCost: _toDouble(json['waste_cost']),
      auditVarianceQty: _toDouble(json['audit_variance_qty']),
      auditVarianceCost: _toDouble(json['audit_variance_cost']),
      actualDepletionCost: _toDouble(json['actual_depletion_cost']),
      varianceLossInr: _toDouble(json['variance_loss_inr']),
      healthStatus: json['health_status']?.toString() ?? 'BALANCED',
    );
  }
}

class FoodCostReconciliationReport {
  final String status;
  final String outletId;
  final String outletName;
  final int timeframeDays;
  final FoodCostSummaryData summary;
  final List<FoodCostCommodityBreakdown> breakdown;

  const FoodCostReconciliationReport({
    required this.status,
    required this.outletId,
    required this.outletName,
    required this.timeframeDays,
    required this.summary,
    required this.breakdown,
  });

  factory FoodCostReconciliationReport.fromJson(Map<String, dynamic> json) {
    final summaryJson = json['summary'] is Map<String, dynamic>
        ? json['summary'] as Map<String, dynamic>
        : <String, dynamic>{};

    final rawBreakdown = json['breakdown'] is List ? json['breakdown'] as List : [];
    final parsedBreakdown = rawBreakdown
        .whereType<Map<String, dynamic>>()
        .map((item) => FoodCostCommodityBreakdown.fromJson(item))
        .toList();

    return FoodCostReconciliationReport(
      status: json['status']?.toString() ?? 'ACTIVE',
      outletId: json['outlet_id']?.toString() ?? '',
      outletName: json['outlet_name']?.toString() ?? '',
      timeframeDays: (json['timeframe_days'] is num) ? (json['timeframe_days'] as num).toInt() : 30,
      summary: FoodCostSummaryData.fromJson(summaryJson),
      breakdown: parsedBreakdown,
    );
  }

  factory FoodCostReconciliationReport.empty() {
    return FoodCostReconciliationReport(
      status: 'ACTIVE',
      outletId: '',
      outletName: '',
      timeframeDays: 30,
      summary: FoodCostSummaryData.empty(),
      breakdown: const [],
    );
  }
}

double _toDouble(dynamic val, {double fallback = 0.0}) {
  if (val == null) return fallback;
  if (val is num) return val.toDouble();
  if (val is String) {
    return double.tryParse(val) ?? fallback;
  }
  return fallback;
}
