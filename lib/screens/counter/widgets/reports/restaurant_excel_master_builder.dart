import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import '../../../../models/restaurant_report_models.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../models/restaurant_executive_report_models.dart';
import '../../../../models/restaurant_crm_models.dart';

class RestaurantExcelMasterBuilder {
  static List<int>? buildMasterWorkbook({
    required String periodLabel,
    required SalesReportSummary summary,
    required List<TopSellingDish> topDishes,
    required List<RestaurantOrder> orders,
    required List<AuditLogEntry> auditLogs,
    FoodCostVarianceReport? foodCostReport,
    StockMovementReport? stockReport,
    MenuEngineeringReport? menuEngineeringReport,
    ProcurementReport? procurementReport,
    ShrinkageReport? shrinkageReport,
    List<RestaurantCustomer>? customers,
  }) {
    final excel = Excel.createExcel();

    // 1. Sheet: Executive Financials
    const s1 = 'Financial Summary';
    final sheet1 = excel[s1];
    excel.setDefaultSheet(s1);
    sheet1.appendRow([TextCellValue('SIRFBILL RESTAURANT - EXECUTIVE FINANCIAL SUMMARY')]);
    sheet1.appendRow([TextCellValue('Period:'), TextCellValue(periodLabel)]);
    sheet1.appendRow([TextCellValue('Exported At:'), TextCellValue(DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now()))]);
    sheet1.appendRow([TextCellValue('')]);
    sheet1.appendRow([TextCellValue('Metric'), TextCellValue('Value (Rs.)')]);
    sheet1.appendRow([TextCellValue('Gross Revenue'), DoubleCellValue(summary.grossSales)]);
    sheet1.appendRow([TextCellValue('Net Revenue'), DoubleCellValue(summary.netSales)]);
    sheet1.appendRow([TextCellValue('GST / Tax Collected'), DoubleCellValue(summary.totalTax)]);
    sheet1.appendRow([TextCellValue('Discounts Given'), DoubleCellValue(summary.totalDiscount)]);
    sheet1.appendRow([TextCellValue('Total Orders Completed'), IntCellValue(summary.totalOrders)]);
    sheet1.appendRow([TextCellValue('Average Order Value (AOV)'), DoubleCellValue(summary.averageOrderValue)]);
    sheet1.appendRow([TextCellValue('Total Portions Cooked'), IntCellValue(summary.totalItemsSold)]);
    sheet1.appendRow([TextCellValue('Distinct Guests Served'), IntCellValue(summary.uniqueCustomers)]);
    sheet1.appendRow([TextCellValue('')]);
    sheet1.appendRow([TextCellValue('Payment Tender Breakup')]);
    sheet1.appendRow([TextCellValue('UPI / QR Payments'), DoubleCellValue(summary.upiSales)]);
    sheet1.appendRow([TextCellValue('Cash Tendered'), DoubleCellValue(summary.cashSales)]);
    sheet1.appendRow([TextCellValue('Card Swipes'), DoubleCellValue(summary.cardSales)]);
    sheet1.appendRow([TextCellValue('Due / Credit (Khata)'), DoubleCellValue(summary.creditSales)]);

    // 2. Sheet: Customer Master (CRM)
    if (customers != null && customers.isNotEmpty) {
      final sheetCrm = excel['Customer Master'];
      sheetCrm.appendRow([TextCellValue('GUEST DIRECTORY & KHATA LEDGER')]);
      sheetCrm.appendRow([TextCellValue('Name'), TextCellValue('Phone'), TextCellValue('Segment'), TextCellValue('Visits'), TextCellValue('Total Spent'), TextCellValue('AOV'), TextCellValue('Khata Due'), TextCellValue('Loyalty Pts')]);
      for (final c in customers) {
        sheetCrm.appendRow([
          TextCellValue(c.name),
          TextCellValue(c.phone),
          TextCellValue(c.segment.name.toUpperCase()),
          IntCellValue(c.totalVisits),
          DoubleCellValue(c.totalSpent),
          DoubleCellValue(c.avgOrderValue),
          DoubleCellValue(c.creditBalance),
          IntCellValue(c.loyaltyPoints),
        ]);
      }
    }

    // 3. Sheet: Item-wise Sales
    final sheet2 = excel['Item-wise Sales'];
    sheet2.appendRow([TextCellValue('Rank'), TextCellValue('Dish Name'), TextCellValue('Category'), TextCellValue('Portions Sold'), TextCellValue('Total Revenue (Rs.)'), TextCellValue('Sales Share %')]);
    for (int i = 0; i < topDishes.length; i++) {
      final d = topDishes[i];
      final share = summary.grossSales > 0 ? (d.revenue / summary.grossSales * 100) : 0.0;
      sheet2.appendRow([IntCellValue(i + 1), TextCellValue(d.name), TextCellValue(d.category), IntCellValue(d.quantitySold), DoubleCellValue(d.revenue), DoubleCellValue(double.parse(share.toStringAsFixed(1)))]);
    }

    // 4. Sheet: Food Cost Variance
    if (foodCostReport != null) {
      final sheetFcv = excel['Food Cost Variance'];
      sheetFcv.appendRow([TextCellValue('FOOD COST VARIANCE & COGS AUDIT')]);
      sheetFcv.appendRow([TextCellValue('Total Food Sales'), DoubleCellValue(foodCostReport.totalFoodSales)]);
      sheetFcv.appendRow([TextCellValue('Theoretical COGS'), DoubleCellValue(foodCostReport.theoreticalCogs)]);
      sheetFcv.appendRow([TextCellValue('Actual COGS'), DoubleCellValue(foodCostReport.actualCogs)]);
      sheetFcv.appendRow([TextCellValue('Wastage Loss'), DoubleCellValue(foodCostReport.loggedWastageLoss)]);
      sheetFcv.appendRow([TextCellValue('Audit Deficit'), DoubleCellValue(foodCostReport.physicalAuditShrinkage)]);
      sheetFcv.appendRow([TextCellValue('Variance % of Sales'), DoubleCellValue(foodCostReport.variancePctOfSales)]);
      sheetFcv.appendRow([TextCellValue('')]);
      sheetFcv.appendRow([TextCellValue('Ingredient'), TextCellValue('Unit'), TextCellValue('Theo Qty'), TextCellValue('Theo Cost'), TextCellValue('Actual Qty'), TextCellValue('Actual Cost'), TextCellValue('Variance Cost (Rs.)'), TextCellValue('Variance %')]);
      for (final item in foodCostReport.breakdown) {
        sheetFcv.appendRow([
          TextCellValue(item.ingredientName),
          TextCellValue(item.unit),
          DoubleCellValue(item.theoreticalConsumedQty),
          DoubleCellValue(item.theoreticalCost),
          DoubleCellValue(item.actualConsumedQty),
          DoubleCellValue(item.actualCost),
          DoubleCellValue(item.varianceCost),
          DoubleCellValue(item.variancePct),
        ]);
      }
    }

    // 5. Sheet: Stock Movement & Valuation
    if (stockReport != null) {
      final sheetSm = excel['Stock Movement'];
      sheetSm.appendRow([TextCellValue('STOCK VALUATION & CLOSING INVENTORY')]);
      sheetSm.appendRow([TextCellValue('Total Valuation: Rs.'), DoubleCellValue(stockReport.totalClosingValuation)]);
      sheetSm.appendRow([TextCellValue('')]);
      sheetSm.appendRow([TextCellValue('Ingredient'), TextCellValue('Category'), TextCellValue('Unit'), TextCellValue('Opening'), TextCellValue('GRN Received'), TextCellValue('Sold'), TextCellValue('Wasted'), TextCellValue('Closing'), TextCellValue('Cost/Unit'), TextCellValue('Closing Valuation (Rs.)')]);
      for (final item in stockReport.items) {
        sheetSm.appendRow([
          TextCellValue(item.ingredientName),
          TextCellValue(item.categoryName),
          TextCellValue(item.unit),
          DoubleCellValue(item.openingQty),
          DoubleCellValue(item.receivedGrnQty),
          DoubleCellValue(item.kotSoldQty),
          DoubleCellValue(item.wastageQty),
          DoubleCellValue(item.closingQty),
          DoubleCellValue(item.costPerUnit),
          DoubleCellValue(item.closingValuation),
        ]);
      }
    }

    // 6. Sheet: Menu Engineering BCG Matrix
    if (menuEngineeringReport != null) {
      final sheetBcg = excel['Menu BCG Matrix'];
      sheetBcg.appendRow([TextCellValue('BCG MENU MATRIX: STARS, PLOWHORSES, PUZZLES & DOGS')]);
      sheetBcg.appendRow([TextCellValue('Dish Name'), TextCellValue('Category'), TextCellValue('Selling Price'), TextCellValue('Plate Cost'), TextCellValue('Food Cost %'), TextCellValue('Qty Sold'), TextCellValue('Margin (Rs.)'), TextCellValue('BCG Quadrant')]);
      for (final item in menuEngineeringReport.items) {
        sheetBcg.appendRow([
          TextCellValue(item.itemName),
          TextCellValue(item.categoryName),
          DoubleCellValue(item.sellingPrice),
          DoubleCellValue(item.plateCost),
          DoubleCellValue(item.foodCostPct),
          IntCellValue(item.quantitySold),
          DoubleCellValue(item.grossMarginRupees),
          TextCellValue(item.quadrant),
        ]);
      }
    }

    // 7. Sheet: Procurement & GST Register
    if (procurementReport != null) {
      final sheetProc = excel['Procurement & GST'];
      sheetProc.appendRow([TextCellValue('PROCUREMENT & INPUT TAX CREDIT (ITC) REGISTER')]);
      sheetProc.appendRow([TextCellValue('Total Purchases'), DoubleCellValue(procurementReport.totalPurchaseSpend)]);
      sheetProc.appendRow([TextCellValue('Total ITC Claimable'), DoubleCellValue(procurementReport.totalInputGstPaid)]);
      sheetProc.appendRow([TextCellValue('')]);
      sheetProc.appendRow([TextCellValue('Vendor Name'), TextCellValue('GSTIN'), TextCellValue('Total GRNs'), TextCellValue('Taxable Spend'), TextCellValue('Tax Paid'), TextCellValue('Gross Invoiced (Rs.)')]);
      for (final v in procurementReport.suppliers) {
        sheetProc.appendRow([
          TextCellValue(v.supplierName),
          TextCellValue(v.gstin ?? '-'),
          IntCellValue(v.grnCount),
          DoubleCellValue(v.netPurchaseAmount),
          DoubleCellValue(v.totalTaxPaid),
          DoubleCellValue(v.totalAmount),
        ]);
      }
    }

    // 8. Sheet: Shrinkage & Leakage
    if (shrinkageReport != null) {
      final sheetShrink = excel['Shrinkage & Wastage'];
      sheetShrink.appendRow([TextCellValue('TOP SHRINKAGE & INGREDIENT LEAKAGE RANKING')]);
      sheetShrink.appendRow([TextCellValue('Total Wastage Loss'), DoubleCellValue(shrinkageReport.totalShrinkageRupees)]);
      sheetShrink.appendRow([TextCellValue('Total Audit Deficit'), DoubleCellValue(shrinkageReport.auditDeficitTotal)]);
      sheetShrink.appendRow([TextCellValue('')]);
      sheetShrink.appendRow([TextCellValue('Rank'), TextCellValue('Ingredient'), TextCellValue('Unit'), TextCellValue('Loss Qty'), TextCellValue('Total Loss Value (Rs.)'), TextCellValue('Primary Cause')]);
      for (int i = 0; i < shrinkageReport.topLeakingIngredients.length; i++) {
        final lk = shrinkageReport.topLeakingIngredients[i];
        sheetShrink.appendRow([
          IntCellValue(i + 1),
          TextCellValue(lk.ingredientName),
          TextCellValue(lk.unit),
          DoubleCellValue(lk.totalLostQty),
          DoubleCellValue(lk.totalLossRupees),
          TextCellValue(lk.categoryName),
        ]);
      }
    }

    // 9. Sheet: Orders Register
    final sheetOrders = excel['Orders Register'];
    sheetOrders.appendRow([TextCellValue('Order Number'), TextCellValue('Date Time'), TextCellValue('Order Type'), TextCellValue('Table / Token'), TextCellValue('Customer'), TextCellValue('Subtotal'), TextCellValue('Tax'), TextCellValue('Total (Rs.)'), TextCellValue('Payment Method')]);
    for (final o in orders) {
      sheetOrders.appendRow([
        TextCellValue(o.orderNumber),
        TextCellValue(DateFormat('dd-MM-yy HH:mm').format(o.createdAt.toLocal())),
        TextCellValue(o.orderType.name.toUpperCase()),
        TextCellValue(o.tableLabel ?? '-'),
        TextCellValue(o.customerName),
        DoubleCellValue(o.subtotal),
        DoubleCellValue(o.gstAmount),
        DoubleCellValue(o.grandTotal),
        TextCellValue(o.paymentMethod.toUpperCase()),
      ]);
    }

    // 10. Sheet: Compliance Audit Trail
    final sheetAudit = excel['Audit Trail'];
    sheetAudit.appendRow([TextCellValue('Timestamp'), TextCellValue('Action Event'), TextCellValue('Staff / Actor'), TextCellValue('Details'), TextCellValue('Severity')]);
    for (final log in auditLogs) {
      sheetAudit.appendRow([
        TextCellValue(DateFormat('dd-MM-yy HH:mm:ss').format(log.timestamp.toLocal())),
        TextCellValue(log.action),
        TextCellValue(log.actorName),
        TextCellValue(log.details),
        TextCellValue(log.severity.toUpperCase()),
      ]);
    }

    return excel.save();
  }
}
