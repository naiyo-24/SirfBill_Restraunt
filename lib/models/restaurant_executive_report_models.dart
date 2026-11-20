import 'package:intl/intl.dart';

// ---------------------------------------------------------------------------
// 1. Food Cost Variance Report Models
// ---------------------------------------------------------------------------
class FoodCostVarianceItem {
  final String ingredientId;
  final String ingredientName;
  final String categoryName;
  final String unit;
  final double theoreticalConsumedQty;
  final double theoreticalCost;
  final double actualConsumedQty;
  final double actualCost;
  final double kitchenWastageQty;
  final double kitchenWastageCost;
  final double auditShrinkageQty;
  final double auditShrinkageCost;
  final double varianceCost;
  final double variancePct;

  const FoodCostVarianceItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.categoryName,
    required this.unit,
    required this.theoreticalConsumedQty,
    required this.theoreticalCost,
    required this.actualConsumedQty,
    required this.actualCost,
    required this.kitchenWastageQty,
    required this.kitchenWastageCost,
    required this.auditShrinkageQty,
    required this.auditShrinkageCost,
    required this.varianceCost,
    required this.variancePct,
  });

  factory FoodCostVarianceItem.fromJson(Map<String, dynamic> json) => FoodCostVarianceItem(
        ingredientId: (json['ingredient_id'] ?? '').toString(),
        ingredientName: (json['ingredient_name'] ?? '').toString(),
        categoryName: (json['category_name'] ?? 'General').toString(),
        unit: (json['unit'] ?? 'kg').toString(),
        theoreticalConsumedQty: double.tryParse((json['theoretical_consumed_qty'] ?? 0).toString()) ?? 0.0,
        theoreticalCost: double.tryParse((json['theoretical_cost'] ?? 0).toString()) ?? 0.0,
        actualConsumedQty: double.tryParse((json['actual_consumed_qty'] ?? 0).toString()) ?? 0.0,
        actualCost: double.tryParse((json['actual_cost'] ?? 0).toString()) ?? 0.0,
        kitchenWastageQty: double.tryParse((json['kitchen_wastage_qty'] ?? 0).toString()) ?? 0.0,
        kitchenWastageCost: double.tryParse((json['kitchen_wastage_cost'] ?? 0).toString()) ?? 0.0,
        auditShrinkageQty: double.tryParse((json['audit_shrinkage_qty'] ?? 0).toString()) ?? 0.0,
        auditShrinkageCost: double.tryParse((json['audit_shrinkage_cost'] ?? 0).toString()) ?? 0.0,
        varianceCost: double.tryParse((json['variance_cost'] ?? 0).toString()) ?? 0.0,
        variancePct: double.tryParse((json['variance_pct'] ?? 0).toString()) ?? 0.0,
      );
}

class FoodCostVarianceReport {
  final double totalFoodSales;
  final double theoreticalCogs;
  final double actualCogs;
  final double loggedWastageLoss;
  final double physicalAuditShrinkage;
  final double unexplainedVariance;
  final double variancePctOfSales;
  final double theoreticalCogsPct;
  final double actualCogsPct;
  final List<FoodCostVarianceItem> breakdown;

  const FoodCostVarianceReport({
    required this.totalFoodSales,
    required this.theoreticalCogs,
    required this.actualCogs,
    required this.loggedWastageLoss,
    required this.physicalAuditShrinkage,
    required this.unexplainedVariance,
    required this.variancePctOfSales,
    required this.theoreticalCogsPct,
    required this.actualCogsPct,
    required this.breakdown,
  });

  factory FoodCostVarianceReport.fromJson(Map<String, dynamic> json) => FoodCostVarianceReport(
        totalFoodSales: double.tryParse((json['total_food_sales'] ?? 0).toString()) ?? 0.0,
        theoreticalCogs: double.tryParse((json['theoretical_cogs'] ?? 0).toString()) ?? 0.0,
        actualCogs: double.tryParse((json['actual_cogs'] ?? 0).toString()) ?? 0.0,
        loggedWastageLoss: double.tryParse((json['logged_wastage_loss'] ?? 0).toString()) ?? 0.0,
        physicalAuditShrinkage: double.tryParse((json['physical_audit_shrinkage'] ?? 0).toString()) ?? 0.0,
        unexplainedVariance: double.tryParse((json['unexplained_variance'] ?? 0).toString()) ?? 0.0,
        variancePctOfSales: double.tryParse((json['variance_pct_of_sales'] ?? 0).toString()) ?? 0.0,
        theoreticalCogsPct: double.tryParse((json['theoretical_cogs_pct'] ?? 0).toString()) ?? 0.0,
        actualCogsPct: double.tryParse((json['actual_cogs_pct'] ?? 0).toString()) ?? 0.0,
        breakdown: (json['breakdown'] as List? ?? []).map((x) => FoodCostVarianceItem.fromJson(x)).toList(),
      );
}

// ---------------------------------------------------------------------------
// 2. Stock Movement & Valuation Report Models
// ---------------------------------------------------------------------------
class StockMovementItem {
  final String ingredientId;
  final String ingredientName;
  final String categoryName;
  final String unit;
  final double costPerUnit;
  final double openingQty;
  final double receivedGrnQty;
  final double transfersNetQty;
  final double kotSoldQty;
  final double wastageQty;
  final double auditAdjustQty;
  final double closingQty;
  final double closingValuation;

  const StockMovementItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.categoryName,
    required this.unit,
    required this.costPerUnit,
    required this.openingQty,
    required this.receivedGrnQty,
    required this.transfersNetQty,
    required this.kotSoldQty,
    required this.wastageQty,
    required this.auditAdjustQty,
    required this.closingQty,
    required this.closingValuation,
  });

  factory StockMovementItem.fromJson(Map<String, dynamic> json) => StockMovementItem(
        ingredientId: (json['ingredient_id'] ?? '').toString(),
        ingredientName: (json['ingredient_name'] ?? '').toString(),
        categoryName: (json['category_name'] ?? 'General').toString(),
        unit: (json['unit'] ?? 'kg').toString(),
        costPerUnit: double.tryParse((json['cost_per_unit'] ?? 0).toString()) ?? 0.0,
        openingQty: double.tryParse((json['opening_qty'] ?? 0).toString()) ?? 0.0,
        receivedGrnQty: double.tryParse((json['received_grn_qty'] ?? 0).toString()) ?? 0.0,
        transfersNetQty: double.tryParse((json['transfers_net_qty'] ?? 0).toString()) ?? 0.0,
        kotSoldQty: double.tryParse((json['kot_sold_qty'] ?? 0).toString()) ?? 0.0,
        wastageQty: double.tryParse((json['wastage_qty'] ?? 0).toString()) ?? 0.0,
        auditAdjustQty: double.tryParse((json['audit_adjust_qty'] ?? 0).toString()) ?? 0.0,
        closingQty: double.tryParse((json['closing_qty'] ?? 0).toString()) ?? 0.0,
        closingValuation: double.tryParse((json['closing_valuation'] ?? 0).toString()) ?? 0.0,
      );
}

class StockMovementReport {
  final double totalClosingValuation;
  final List<StockMovementItem> items;

  const StockMovementReport({
    required this.totalClosingValuation,
    required this.items,
  });

  factory StockMovementReport.fromJson(Map<String, dynamic> json) => StockMovementReport(
        totalClosingValuation: double.tryParse((json['total_closing_valuation'] ?? 0).toString()) ?? 0.0,
        items: (json['items'] as List? ?? []).map((x) => StockMovementItem.fromJson(x)).toList(),
      );
}

// ---------------------------------------------------------------------------
// 3. Menu Engineering BCG Matrix Report Models
// ---------------------------------------------------------------------------
class MenuEngineeringItem {
  final String itemId;
  final String itemName;
  final String categoryName;
  final String variantName;
  final double sellingPrice;
  final double plateCost;
  final double grossMarginRupees;
  final double foodCostPct;
  final int quantitySold;
  final double totalRevenue;
  final double totalMargin;
  final String quadrant; // STAR, PLOWHORSE, PUZZLE, DOG
  final bool isCostAlert; // Food cost > 35%

  const MenuEngineeringItem({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.variantName,
    required this.sellingPrice,
    required this.plateCost,
    required this.grossMarginRupees,
    required this.foodCostPct,
    required this.quantitySold,
    required this.totalRevenue,
    required this.totalMargin,
    required this.quadrant,
    required this.isCostAlert,
  });

  factory MenuEngineeringItem.fromJson(Map<String, dynamic> json) => MenuEngineeringItem(
        itemId: (json['item_id'] ?? '').toString(),
        itemName: (json['item_name'] ?? '').toString(),
        categoryName: (json['category_name'] ?? 'General').toString(),
        variantName: (json['variant_name'] ?? 'Regular').toString(),
        sellingPrice: double.tryParse((json['selling_price'] ?? 0).toString()) ?? 0.0,
        plateCost: double.tryParse((json['plate_cost'] ?? 0).toString()) ?? 0.0,
        grossMarginRupees: double.tryParse((json['gross_margin_rupees'] ?? 0).toString()) ?? 0.0,
        foodCostPct: double.tryParse((json['food_cost_pct'] ?? 0).toString()) ?? 0.0,
        quantitySold: int.tryParse((json['quantity_sold'] ?? 0).toString()) ?? 0,
        totalRevenue: double.tryParse((json['total_revenue'] ?? 0).toString()) ?? 0.0,
        totalMargin: double.tryParse((json['total_margin'] ?? 0).toString()) ?? 0.0,
        quadrant: (json['quadrant'] ?? 'PUZZLE').toString().toUpperCase(),
        isCostAlert: json['is_cost_alert'] ?? false,
      );
}

class MenuEngineeringReport {
  final int totalMenuItemsAnalyzed;
  final double avgFoodCostPct;
  final int starsCount;
  final int plowhorsesCount;
  final int puzzlesCount;
  final int dogsCount;
  final List<MenuEngineeringItem> items;

  const MenuEngineeringReport({
    required this.totalMenuItemsAnalyzed,
    required this.avgFoodCostPct,
    required this.starsCount,
    required this.plowhorsesCount,
    required this.puzzlesCount,
    required this.dogsCount,
    required this.items,
  });

  factory MenuEngineeringReport.fromJson(Map<String, dynamic> json) => MenuEngineeringReport(
        totalMenuItemsAnalyzed: int.tryParse((json['total_menu_items_analyzed'] ?? 0).toString()) ?? 0,
        avgFoodCostPct: double.tryParse((json['avg_food_cost_pct'] ?? 0).toString()) ?? 0.0,
        starsCount: int.tryParse((json['stars_count'] ?? 0).toString()) ?? 0,
        plowhorsesCount: int.tryParse((json['plowhorses_count'] ?? 0).toString()) ?? 0,
        puzzlesCount: int.tryParse((json['puzzles_count'] ?? 0).toString()) ?? 0,
        dogsCount: int.tryParse((json['dogs_count'] ?? 0).toString()) ?? 0,
        items: (json['items'] as List? ?? []).map((x) => MenuEngineeringItem.fromJson(x)).toList(),
      );
}

// ---------------------------------------------------------------------------
// 4. Procurement & GST Register Models
// ---------------------------------------------------------------------------
class ProcurementSupplierSummary {
  final String supplierId;
  final String supplierName;
  final String? gstin;
  final int grnCount;
  final double netPurchaseAmount;
  final double gst5Amount;
  final double gst12Amount;
  final double gst18Amount;
  final double totalTaxPaid;
  final double totalAmount;
  final double paidAmount;
  final double unpaidBalance;

  const ProcurementSupplierSummary({
    required this.supplierId,
    required this.supplierName,
    this.gstin,
    required this.grnCount,
    required this.netPurchaseAmount,
    required this.gst5Amount,
    required this.gst12Amount,
    required this.gst18Amount,
    required this.totalTaxPaid,
    required this.totalAmount,
    required this.paidAmount,
    required this.unpaidBalance,
  });

  factory ProcurementSupplierSummary.fromJson(Map<String, dynamic> json) => ProcurementSupplierSummary(
        supplierId: (json['supplier_id'] ?? '').toString(),
        supplierName: (json['supplier_name'] ?? 'Vendor').toString(),
        gstin: json['gstin']?.toString(),
        grnCount: int.tryParse((json['grnCount'] ?? json['grn_count'] ?? 0).toString()) ?? 0,
        netPurchaseAmount: double.tryParse((json['net_purchase_amount'] ?? 0).toString()) ?? 0.0,
        gst5Amount: double.tryParse((json['gst_5_amount'] ?? 0).toString()) ?? 0.0,
        gst12Amount: double.tryParse((json['gst_12_amount'] ?? 0).toString()) ?? 0.0,
        gst18Amount: double.tryParse((json['gst_18_amount'] ?? 0).toString()) ?? 0.0,
        totalTaxPaid: double.tryParse((json['total_tax_paid'] ?? 0).toString()) ?? 0.0,
        totalAmount: double.tryParse((json['total_amount'] ?? 0).toString()) ?? 0.0,
        paidAmount: double.tryParse((json['paid_amount'] ?? 0).toString()) ?? 0.0,
        unpaidBalance: double.tryParse((json['unpaid_balance'] ?? 0).toString()) ?? 0.0,
      );
}

class ProcurementAgingBucket {
  final String agingBracket;
  final double unpaidAmount;
  final int invoiceCount;

  const ProcurementAgingBucket({
    required this.agingBracket,
    required this.unpaidAmount,
    required this.invoiceCount,
  });

  factory ProcurementAgingBucket.fromJson(Map<String, dynamic> json) => ProcurementAgingBucket(
        agingBracket: (json['aging_bracket'] ?? '').toString(),
        unpaidAmount: double.tryParse((json['unpaid_amount'] ?? 0).toString()) ?? 0.0,
        invoiceCount: int.tryParse((json['invoice_count'] ?? 0).toString()) ?? 0,
      );
}

class ProcurementReport {
  final double totalPurchaseSpend;
  final double totalInputGstPaid;
  final double totalUnpaidPayables;
  final double gst5Total;
  final double gst12Total;
  final double gst18Total;
  final List<ProcurementSupplierSummary> suppliers;
  final List<ProcurementAgingBucket> agingBuckets;

  const ProcurementReport({
    required this.totalPurchaseSpend,
    required this.totalInputGstPaid,
    required this.totalUnpaidPayables,
    required this.gst5Total,
    required this.gst12Total,
    required this.gst18Total,
    required this.suppliers,
    required this.agingBuckets,
  });

  factory ProcurementReport.fromJson(Map<String, dynamic> json) => ProcurementReport(
        totalPurchaseSpend: double.tryParse((json['total_purchase_spend'] ?? 0).toString()) ?? 0.0,
        totalInputGstPaid: double.tryParse((json['total_input_gst_paid'] ?? 0).toString()) ?? 0.0,
        totalUnpaidPayables: double.tryParse((json['total_unpaid_payables'] ?? 0).toString()) ?? 0.0,
        gst5Total: double.tryParse((json['gst_5_total'] ?? 0).toString()) ?? 0.0,
        gst12Total: double.tryParse((json['gst_12_total'] ?? 0).toString()) ?? 0.0,
        gst18Total: double.tryParse((json['gst_18_total'] ?? 0).toString()) ?? 0.0,
        suppliers: (json['suppliers'] as List? ?? []).map((x) => ProcurementSupplierSummary.fromJson(x)).toList(),
        agingBuckets: (json['aging_buckets'] as List? ?? []).map((x) => ProcurementAgingBucket.fromJson(x)).toList(),
      );
}

// ---------------------------------------------------------------------------
// 5. Shrinkage & Leakage Report Models
// ---------------------------------------------------------------------------
class ShrinkageIngredientItem {
  final String ingredientId;
  final String ingredientName;
  final String categoryName;
  final String unit;
  final double costPerUnit;
  final double totalLostQty;
  final double totalLossRupees;
  final Map<String, double> lossBreakdown;

  const ShrinkageIngredientItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.categoryName,
    required this.unit,
    required this.costPerUnit,
    required this.totalLostQty,
    required this.totalLossRupees,
    required this.lossBreakdown,
  });

  factory ShrinkageIngredientItem.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['loss_breakdown'] as Map? ?? {};
    final Map<String, double> bd = {};
    rawBreakdown.forEach((k, v) {
      bd[k.toString()] = double.tryParse(v.toString()) ?? 0.0;
    });

    return ShrinkageIngredientItem(
      ingredientId: (json['ingredient_id'] ?? '').toString(),
      ingredientName: (json['ingredient_name'] ?? '').toString(),
      categoryName: (json['category_name'] ?? 'General').toString(),
      unit: (json['unit'] ?? 'kg').toString(),
      costPerUnit: double.tryParse((json['cost_per_unit'] ?? 0).toString()) ?? 0.0,
      totalLostQty: double.tryParse((json['total_lost_qty'] ?? 0).toString()) ?? 0.0,
      totalLossRupees: double.tryParse((json['total_loss_rupees'] ?? 0).toString()) ?? 0.0,
      lossBreakdown: bd,
    );
  }
}

class ShrinkageReport {
  final double totalShrinkageRupees;
  final double spoilageTotal;
  final double burntRuinedTotal;
  final double customerReturnTotal;
  final double auditDeficitTotal;
  final List<ShrinkageIngredientItem> topLeakingIngredients;

  const ShrinkageReport({
    required this.totalShrinkageRupees,
    required this.spoilageTotal,
    required this.burntRuinedTotal,
    required this.customerReturnTotal,
    required this.auditDeficitTotal,
    required this.topLeakingIngredients,
  });

  factory ShrinkageReport.fromJson(Map<String, dynamic> json) => ShrinkageReport(
        totalShrinkageRupees: double.tryParse((json['total_shrinkage_rupees'] ?? 0).toString()) ?? 0.0,
        spoilageTotal: double.tryParse((json['spoilage_total'] ?? 0).toString()) ?? 0.0,
        burntRuinedTotal: double.tryParse((json['burnt_ruined_total'] ?? 0).toString()) ?? 0.0,
        customerReturnTotal: double.tryParse((json['customer_return_total'] ?? 0).toString()) ?? 0.0,
        auditDeficitTotal: double.tryParse((json['audit_deficit_total'] ?? 0).toString()) ?? 0.0,
        topLeakingIngredients: (json['top_leaking_ingredients'] as List? ?? [])
            .map((x) => ShrinkageIngredientItem.fromJson(x))
            .toList(),
      );
}
