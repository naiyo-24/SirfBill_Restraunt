import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../../models/restaurant_report_models.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../models/restaurant_executive_report_models.dart';
import '../../../../models/restaurant_crm_models.dart';

class RestaurantPdfMasterBuilder {
  static Future<List<int>> buildMasterPdf({
    required Map<String, String> restaurant,
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
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context ctx) {
          return [
            // 1. Header
            _buildHeader(restaurant, periodLabel),
            pw.SizedBox(height: 10),
            pw.Divider(color: PdfColors.indigo900, thickness: 1.5),
            pw.SizedBox(height: 10),

            // 2. Financial Overview
            _buildSectionHeader('1. Executive Financial Performance'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                  _buildCell('Gross Revenue', isHeader: true),
                  _buildCell('Net Revenue', isHeader: true),
                  _buildCell('GST Collected', isHeader: true),
                  _buildCell('Discounts', isHeader: true),
                  _buildCell('Orders', isHeader: true, alignCenter: true),
                  _buildCell('AOV (Check)', isHeader: true),
                ]),
                pw.TableRow(children: [
                  _buildCell('Rs. ${summary.grossSales.toStringAsFixed(2)}', isBold: true),
                  _buildCell('Rs. ${summary.netSales.toStringAsFixed(2)}'),
                  _buildCell('Rs. ${summary.totalGst.toStringAsFixed(2)}'),
                  _buildCell('Rs. ${summary.totalDiscount.toStringAsFixed(2)}'),
                  _buildCell('${summary.totalOrders}', alignCenter: true),
                  _buildCell('Rs. ${summary.averageOrderValue.toStringAsFixed(2)}'),
                ]),
              ],
            ),
            pw.SizedBox(height: 10),

            // 3. Payment Tender Breakdown
            _buildSectionHeader('2. Payment Tender Mix'),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
              children: [
                pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                  _buildCell('UPI / QR Pay', isHeader: true),
                  _buildCell('Cash Register', isHeader: true),
                  _buildCell('Card Swipes', isHeader: true),
                  _buildCell('Khata Tab Due', isHeader: true),
                ]),
                pw.TableRow(children: [
                  _buildCell('Rs. ${summary.upiSales.toStringAsFixed(2)}'),
                  _buildCell('Rs. ${summary.cashSales.toStringAsFixed(2)}'),
                  _buildCell('Rs. ${summary.cardSales.toStringAsFixed(2)}'),
                  _buildCell('Rs. ${summary.creditSales.toStringAsFixed(2)}'),
                ]),
              ],
            ),
            pw.SizedBox(height: 12),

            // 4. Customer Master CRM Directory (if available)
            if (customers != null && customers.isNotEmpty) ...[
              _buildSectionHeader('3. Guest CRM Directory & Khata Ledger (${customers.length} Guests)'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Guest Name', isHeader: true),
                    _buildCell('Phone', isHeader: true),
                    _buildCell('Segment', isHeader: true),
                    _buildCell('Visits', isHeader: true, alignCenter: true),
                    _buildCell('Total Spent', isHeader: true),
                    _buildCell('Khata Due', isHeader: true),
                    _buildCell('Loyalty Pts', isHeader: true, alignCenter: true),
                  ]),
                  ...customers.take(20).map((c) => pw.TableRow(children: [
                        _buildCell(c.name, isBold: true),
                        _buildCell(c.phone),
                        _buildCell(c.segment.name.toUpperCase()),
                        _buildCell('${c.totalVisits}', alignCenter: true),
                        _buildCell('Rs. ${c.totalSpent.toStringAsFixed(0)}'),
                        _buildCell('Rs. ${c.creditBalance.toStringAsFixed(0)}', isBold: c.creditBalance > 0),
                        _buildCell('${c.loyaltyPoints}', alignCenter: true),
                      ])),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 5. Item-wise Sales Leaderboard
            if (topDishes.isNotEmpty) ...[
              _buildSectionHeader('4. Menu Sales Leaderboard & Dish Contribution'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Rank', isHeader: true, alignCenter: true),
                    _buildCell('Dish Name', isHeader: true),
                    _buildCell('Category', isHeader: true),
                    _buildCell('Portions', isHeader: true, alignCenter: true),
                    _buildCell('Revenue', isHeader: true),
                    _buildCell('Share %', isHeader: true, alignCenter: true),
                  ]),
                  ...topDishes.take(15).toList().asMap().entries.map((entry) {
                    final d = entry.value;
                    final share = summary.grossSales > 0 ? (d.revenue / summary.grossSales * 100) : 0.0;
                    return pw.TableRow(children: [
                      _buildCell('#${entry.key + 1}', alignCenter: true),
                      _buildCell(d.name, isBold: true),
                      _buildCell(d.category),
                      _buildCell('${d.quantitySold}', alignCenter: true),
                      _buildCell('Rs. ${d.revenue.toStringAsFixed(2)}'),
                      _buildCell('${share.toStringAsFixed(1)}%', alignCenter: true),
                    ]);
                  }),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 6. Food Cost Variance & COGS Audit
            if (foodCostReport != null) ...[
              _buildSectionHeader('5. Food Cost Variance & COGS Audit'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Food Sales', isHeader: true),
                    _buildCell('Theo COGS', isHeader: true),
                    _buildCell('Actual COGS', isHeader: true),
                    _buildCell('Wastage Loss', isHeader: true),
                    _buildCell('Variance Cost', isHeader: true),
                    _buildCell('Variance %', isHeader: true, alignCenter: true),
                  ]),
                  pw.TableRow(children: [
                    _buildCell('Rs. ${foodCostReport.totalFoodSales.toStringAsFixed(2)}'),
                    _buildCell('Rs. ${foodCostReport.theoreticalCogs.toStringAsFixed(2)}'),
                    _buildCell('Rs. ${foodCostReport.actualCogs.toStringAsFixed(2)}'),
                    _buildCell('Rs. ${foodCostReport.loggedWastageLoss.toStringAsFixed(2)}'),
                    _buildCell('Rs. ${foodCostReport.unexplainedVariance.toStringAsFixed(2)}', isBold: true),
                    _buildCell('${foodCostReport.variancePctOfSales.toStringAsFixed(1)}%', alignCenter: true),
                  ]),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 7. Stock Movement & Inventory Valuation
            if (stockReport != null) ...[
              _buildSectionHeader('6. Stock Movement & Inventory Valuation (Total: Rs. ${stockReport.totalClosingValuation.toStringAsFixed(2)})'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Ingredient', isHeader: true),
                    _buildCell('Unit', isHeader: true, alignCenter: true),
                    _buildCell('Opening', isHeader: true, alignCenter: true),
                    _buildCell('GRN Inward', isHeader: true, alignCenter: true),
                    _buildCell('Sold', isHeader: true, alignCenter: true),
                    _buildCell('Closing', isHeader: true, alignCenter: true),
                    _buildCell('Valuation', isHeader: true),
                  ]),
                  ...stockReport.items.take(15).map((it) => pw.TableRow(children: [
                        _buildCell(it.ingredientName, isBold: true),
                        _buildCell(it.unit, alignCenter: true),
                        _buildCell(it.openingQty.toStringAsFixed(1), alignCenter: true),
                        _buildCell(it.receivedGrnQty.toStringAsFixed(1), alignCenter: true),
                        _buildCell(it.kotSoldQty.toStringAsFixed(1), alignCenter: true),
                        _buildCell(it.closingQty.toStringAsFixed(1), alignCenter: true),
                        _buildCell('Rs. ${it.closingValuation.toStringAsFixed(2)}'),
                      ])),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 8. Menu Engineering BCG Matrix
            if (menuEngineeringReport != null) ...[
              _buildSectionHeader('7. Menu Engineering BCG Quadrants (Stars, Plowhorses, Puzzles, Dogs)'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Dish Name', isHeader: true),
                    _buildCell('Price', isHeader: true),
                    _buildCell('Plate Cost', isHeader: true),
                    _buildCell('Margin', isHeader: true),
                    _buildCell('Sold', isHeader: true, alignCenter: true),
                    _buildCell('BCG Quadrant', isHeader: true, alignCenter: true),
                  ]),
                  ...menuEngineeringReport.items.take(15).map((m) => pw.TableRow(children: [
                        _buildCell(m.itemName, isBold: true),
                        _buildCell('Rs. ${m.sellingPrice.toStringAsFixed(2)}'),
                        _buildCell('Rs. ${m.plateCost.toStringAsFixed(2)}'),
                        _buildCell('Rs. ${m.grossMarginRupees.toStringAsFixed(2)}'),
                        _buildCell('${m.quantitySold}', alignCenter: true),
                        _buildCell(m.quadrant, alignCenter: true, isBold: true),
                      ])),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 9. Procurement & GST Register
            if (procurementReport != null) ...[
              _buildSectionHeader('8. Procurement Spend & GST Input Tax Credit (ITC)'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Supplier', isHeader: true),
                    _buildCell('GSTIN', isHeader: true),
                    _buildCell('GRNs', isHeader: true, alignCenter: true),
                    _buildCell('Net Spend', isHeader: true),
                    _buildCell('Tax Paid (ITC)', isHeader: true),
                    _buildCell('Gross Total', isHeader: true),
                  ]),
                  ...procurementReport.suppliers.take(10).map((s) => pw.TableRow(children: [
                        _buildCell(s.supplierName, isBold: true),
                        _buildCell(s.gstin ?? '-'),
                        _buildCell('${s.grnCount}', alignCenter: true),
                        _buildCell('Rs. ${s.netPurchaseAmount.toStringAsFixed(2)}'),
                        _buildCell('Rs. ${s.totalTaxPaid.toStringAsFixed(2)}'),
                        _buildCell('Rs. ${s.totalAmount.toStringAsFixed(2)}'),
                      ])),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 10. Shrinkage & Leakage Ranking
            if (shrinkageReport != null) ...[
              _buildSectionHeader('9. Ingredient Shrinkage & Leakage Rankings'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Rank', isHeader: true, alignCenter: true),
                    _buildCell('Ingredient', isHeader: true),
                    _buildCell('Unit', isHeader: true, alignCenter: true),
                    _buildCell('Lost Quantity', isHeader: true, alignCenter: true),
                    _buildCell('Loss Value (Rs.)', isHeader: true),
                    _buildCell('Category', isHeader: true),
                  ]),
                  ...shrinkageReport.topLeakingIngredients.take(10).toList().asMap().entries.map((entry) {
                    final it = entry.value;
                    return pw.TableRow(children: [
                      _buildCell('#${entry.key + 1}', alignCenter: true),
                      _buildCell(it.ingredientName, isBold: true),
                      _buildCell(it.unit, alignCenter: true),
                      _buildCell(it.totalLostQty.toStringAsFixed(1), alignCenter: true),
                      _buildCell('Rs. ${it.totalLossRupees.toStringAsFixed(2)}'),
                      _buildCell(it.categoryName),
                    ]);
                  }),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 11. Recent Orders Register
            if (orders.isNotEmpty) ...[
              _buildSectionHeader('10. Billing Orders Register (${orders.length} tickets)'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Order #', isHeader: true),
                    _buildCell('Date Time', isHeader: true),
                    _buildCell('Type', isHeader: true),
                    _buildCell('Table', isHeader: true, alignCenter: true),
                    _buildCell('Customer', isHeader: true),
                    _buildCell('Total', isHeader: true),
                    _buildCell('Tender', isHeader: true),
                  ]),
                  ...orders.take(15).map((o) => pw.TableRow(children: [
                        _buildCell(o.orderNumber, isBold: true),
                        _buildCell(DateFormat('dd-MM HH:mm').format(o.createdAt.toLocal())),
                        _buildCell(o.orderType.name.toUpperCase()),
                        _buildCell(o.tableLabel ?? '-', alignCenter: true),
                        _buildCell(o.customerName),
                        _buildCell('Rs. ${o.grandTotal.toStringAsFixed(2)}'),
                        _buildCell(o.paymentMethod.toUpperCase()),
                      ])),
                ],
              ),
              pw.SizedBox(height: 12),
            ],

            // 12. Compliance Audit Trail Log
            if (auditLogs.isNotEmpty) ...[
              _buildSectionHeader('11. Compliance Audit Trail Log (${auditLogs.length} events)'),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                children: [
                  pw.TableRow(decoration: const pw.BoxDecoration(color: PdfColors.grey100), children: [
                    _buildCell('Timestamp', isHeader: true),
                    _buildCell('Action Event', isHeader: true),
                    _buildCell('Staff / Actor', isHeader: true),
                    _buildCell('Severity', isHeader: true, alignCenter: true),
                    _buildCell('Details', isHeader: true),
                  ]),
                  ...auditLogs.take(15).map((l) => pw.TableRow(children: [
                        _buildCell(DateFormat('dd-MM HH:mm:ss').format(l.timestamp.toLocal())),
                        _buildCell(l.action, isBold: true),
                        _buildCell(l.actorName),
                        _buildCell(l.severity.toUpperCase(), alignCenter: true),
                        _buildCell(l.details),
                      ])),
                ],
              ),
            ],
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader(Map<String, String> restaurant, String periodLabel) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(restaurant['name'] ?? 'SIRFBILL RESTAURANT',
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
            if ((restaurant['address'] ?? '').isNotEmpty)
              pw.Text(restaurant['address']!, style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
            if ((restaurant['gstin'] ?? '').isNotEmpty)
              pw.Text('GSTIN: ${restaurant['gstin']!}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ],
        ),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Text('EXECUTIVE MASTER REPORT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            pw.Text('Period: $periodLabel', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
            pw.Text('Generated: ${DateFormat('dd-MMM-yyyy HH:mm').format(DateTime.now())}',
                style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
          ],
        ),
      ],
    );
  }

  static pw.Widget _buildSectionHeader(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 5, top: 4),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 10.5, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900),
      ),
    );
  }

  static pw.Widget _buildCell(String text, {bool isHeader = false, bool isBold = false, bool alignCenter = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      child: pw.Text(
        text,
        textAlign: alignCenter ? pw.TextAlign.center : pw.TextAlign.left,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: isHeader ? pw.FontWeight.bold : (isBold ? pw.FontWeight.bold : pw.FontWeight.normal),
          color: isHeader ? PdfColors.indigo900 : PdfColors.black,
        ),
      ),
    );
  }
}
