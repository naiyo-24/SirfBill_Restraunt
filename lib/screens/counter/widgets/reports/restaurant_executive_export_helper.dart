import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_saver/file_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';

import '../../../../models/restaurant_report_models.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../models/restaurant_executive_report_models.dart';
import '../../../../models/restaurant_crm_models.dart';
import '../../../../services/shop_settings_service.dart';
import '../../../../services/restaurant/restaurant_executive_report_service.dart';
import '../../../../services/restaurant/restaurant_crm_service.dart';
import 'restaurant_excel_master_builder.dart';
import 'restaurant_pdf_master_builder.dart';
import 'restaurant_report_export_helper.dart';

class RestaurantExecutiveExportHelper {
  /// Save bytes locally across Desktop (Downloads directory) and Web (browser download)
  static Future<String> _saveFileLocally({
    required String filename,
    required Uint8List bytes,
    required String ext,
    required MimeType mimeType,
  }) async {
    String savedLocation = '$filename.$ext';
    if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
      try {
        final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
        final file = File('${dir.path}${Platform.pathSeparator}$filename.$ext');
        await file.writeAsBytes(bytes);
        return file.path;
      } catch (e) {
        debugPrint('[Export] Desktop save error: $e');
      }
    }

    try {
      final res = await FileSaver.instance.saveFile(name: filename, bytes: bytes, fileExtension: ext, mimeType: mimeType);
      if (res.isNotEmpty) savedLocation = res;
    } catch (e) {
      try {
        final res = await FileSaver.instance.saveAs(name: filename, bytes: bytes, fileExtension: ext, mimeType: mimeType);
        if (res != null && res.isNotEmpty) savedLocation = res;
      } catch (_) {}
    }
    return savedLocation;
  }

  /// Resolve dynamic restaurant name & tax information
  static Future<Map<String, String>> _resolveRestaurantInfo() async {
    try {
      final s = await ShopSettingsService.getSettings();
      return {
        'name': (s['shop_name'] ?? 'SirfBill Restaurant').toString().toUpperCase(),
        'address': (s['address'] ?? '').toString(),
        'gstin': (s['gst_number'] ?? s['gstin'] ?? '').toString(),
      };
    } catch (_) {
      return {'name': 'SIRFBILL RESTAURANT', 'address': '', 'gstin': ''};
    }
  }

  /// Resolve all 10 modules in parallel if not already loaded in memory
  static Future<({
    FoodCostVarianceReport? foodCost,
    StockMovementReport? stock,
    MenuEngineeringReport? menu,
    ProcurementReport? procurement,
    ShrinkageReport? shrinkage,
    List<RestaurantCustomer>? customers,
  })> _resolveAllData({
    FoodCostVarianceReport? foodCostReport,
    StockMovementReport? stockReport,
    MenuEngineeringReport? menuEngineeringReport,
    ProcurementReport? procurementReport,
    ShrinkageReport? shrinkageReport,
    List<RestaurantCustomer>? customers,
  }) async {
    FoodCostVarianceReport? rFoodCost = foodCostReport;
    StockMovementReport? rStock = stockReport;
    MenuEngineeringReport? rMenu = menuEngineeringReport;
    ProcurementReport? rProcurement = procurementReport;
    ShrinkageReport? rShrinkage = shrinkageReport;
    List<RestaurantCustomer>? rCustomers = customers;

    final List<Future> tasks = [];
    if (rFoodCost == null) tasks.add(RestaurantExecutiveReportService.fetchFoodCostVariance().then((v) => rFoodCost = v));
    if (rStock == null) tasks.add(RestaurantExecutiveReportService.fetchStockMovement().then((v) => rStock = v));
    if (rMenu == null) tasks.add(RestaurantExecutiveReportService.fetchMenuEngineering().then((v) => rMenu = v));
    if (rProcurement == null) tasks.add(RestaurantExecutiveReportService.fetchProcurement().then((v) => rProcurement = v));
    if (rShrinkage == null) tasks.add(RestaurantExecutiveReportService.fetchShrinkage().then((v) => rShrinkage = v));
    if (rCustomers == null || rCustomers.isEmpty) tasks.add(RestaurantCrmService.fetchCustomers(limit: 500).then((v) => rCustomers = v));

    if (tasks.isNotEmpty) await Future.wait(tasks);

    return (foodCost: rFoodCost, stock: rStock, menu: rMenu, procurement: rProcurement, shrinkage: rShrinkage, customers: rCustomers);
  }

  /// Show comprehensive export options sheet for all reports & CRM data
  static void showExportSheet({
    required BuildContext context,
    required String periodLabel,
    required SalesReportSummary summary,
    required List<TopSellingDish> topDishes,
    required List<RestaurantOrder> orders,
    required List<AuditLogEntry> auditLogs,
    required int activeTab,
    FoodCostVarianceReport? foodCostReport,
    StockMovementReport? stockReport,
    MenuEngineeringReport? menuEngineeringReport,
    ProcurementReport? procurementReport,
    ShrinkageReport? shrinkageReport,
    List<RestaurantCustomer>? customers,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tabNames = [
      'Overview & Financials', 'Item-wise Sales', 'Food Cost Variance', 'Stock Movement & Valuation',
      'Menu Engineering BCG Matrix', 'Procurement & GST Register', 'Shrinkage & Wastage Leakage', 'Compliance Audit Trail',
    ];
    final activeTabName = (activeTab >= 0 && activeTab < tabNames.length) ? tabNames[activeTab] : 'Active Tab';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Export Restaurant & CRM Data', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        const SizedBox(height: 4),
                        Text('Period: $periodLabel • Active: $activeTabName', style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                      ]),
                      IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // Option 1: ALL DATA - Comprehensive Master Excel Workbook
                  _buildOptionTile(
                    color: const Color(0xFF10B981),
                    icon: Icons.table_chart_rounded,
                    title: 'Export ALL Data to Master Workbook (.xlsx)',
                    subtitle: 'Complete 10-sheet Excel with Financials, CRM, Orders, Sales, Food Costing, Stock, BCG Matrix & Audit',
                    badge: 'ALL 10 SHEETS EXCEL',
                    onTap: () {
                      Navigator.pop(ctx);
                      exportMasterWorkbookExcel(
                        context: context, periodLabel: periodLabel, summary: summary, topDishes: topDishes, orders: orders, auditLogs: auditLogs,
                        foodCostReport: foodCostReport, stockReport: stockReport, menuEngineeringReport: menuEngineeringReport,
                        procurementReport: procurementReport, shrinkageReport: shrinkageReport, customers: customers,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 2: ALL DATA - Full Executive Master PDF Report
                  _buildOptionTile(
                    color: const Color(0xFF6366F1),
                    icon: Icons.picture_as_pdf_rounded,
                    title: 'Export Executive PDF Master Report (.pdf)',
                    subtitle: 'Multi-page branded visual print report covering Financials, CRM Guests, Food Cost, Stock, BCG Matrix & Audit',
                    badge: 'ALL 10 MODULES PDF',
                    onTap: () {
                      Navigator.pop(ctx);
                      exportExecutiveMasterPdf(
                        context: context, periodLabel: periodLabel, summary: summary, topDishes: topDishes, orders: orders, auditLogs: auditLogs,
                        foodCostReport: foodCostReport, stockReport: stockReport, menuEngineeringReport: menuEngineeringReport,
                        procurementReport: procurementReport, shrinkageReport: shrinkageReport, customers: customers,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Option 3: Export Current Tab Only (.xlsx)
                  _buildOptionTile(
                    color: const Color(0xFF0EA5E9),
                    icon: Icons.download_rounded,
                    title: 'Export Current Tab: $activeTabName (.xlsx)',
                    subtitle: 'Quick single-sheet spreadsheet for the currently viewed report table',
                    onTap: () {
                      Navigator.pop(ctx);
                      if (activeTab == 1) {
                        RestaurantReportExportHelper.exportItemWiseSalesExcel(context: context, periodLabel: periodLabel, topDishes: topDishes, summary: summary);
                      } else if (activeTab == 7) {
                        RestaurantReportExportHelper.exportAuditTrailExcel(context: context, periodLabel: periodLabel, auditLogs: auditLogs);
                      } else {
                        exportMasterWorkbookExcel(
                          context: context, periodLabel: periodLabel, summary: summary, topDishes: topDishes, orders: orders, auditLogs: auditLogs,
                          foodCostReport: foodCostReport, stockReport: stockReport, menuEngineeringReport: menuEngineeringReport,
                          procurementReport: procurementReport, shrinkageReport: shrinkageReport, customers: customers,
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildOptionTile({
    required Color color,
    required IconData icon,
    required String title,
    required String subtitle,
    String? badge,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: color.withValues(alpha: 0.3))),
      tileColor: color.withValues(alpha: 0.08),
      leading: CircleAvatar(backgroundColor: color, child: Icon(icon, color: Colors.white, size: 20)),
      title: Row(children: [
        Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5))),
        if (badge != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
            child: Text(badge, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.bold)),
          ),
      ]),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 11)),
      trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
      onTap: onTap,
    );
  }

  /// Exports comprehensive 10-sheet Master Excel Workbook
  static Future<void> exportMasterWorkbookExcel({
    required BuildContext context,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gathering all modules & compiling 10-sheet Master Excel Workbook...'), duration: Duration(seconds: 3)),
    );

    try {
      final res = await _resolveAllData(
        foodCostReport: foodCostReport, stockReport: stockReport, menuEngineeringReport: menuEngineeringReport,
        procurementReport: procurementReport, shrinkageReport: shrinkageReport, customers: customers,
      );

      final fileBytes = RestaurantExcelMasterBuilder.buildMasterWorkbook(
        periodLabel: periodLabel, summary: summary, topDishes: topDishes, orders: orders, auditLogs: auditLogs,
        foodCostReport: res.foodCost, stockReport: res.stock, menuEngineeringReport: res.menu,
        procurementReport: res.procurement, shrinkageReport: res.shrinkage, customers: res.customers,
      );

      if (fileBytes == null) throw 'Excel generation failed';

      final sanitizedPeriod = periodLabel.replaceAll(' ', '_').replaceAll('/', '-');
      final filename = 'SirfBill_Master_Data_${sanitizedPeriod}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
      final savedPath = await _saveFileLocally(filename: filename, bytes: Uint8List.fromList(fileBytes), ext: 'xlsx', mimeType: MimeType.microsoftExcel);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Master Excel Workbook downloaded: $savedPath'), backgroundColor: const Color(0xFF10B981), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export Master Excel: $e'), backgroundColor: Colors.red));
      }
    }
  }

  /// Exports comprehensive branded visual Executive Master PDF report
  static Future<void> exportExecutiveMasterPdf({
    required BuildContext context,
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gathering all modules & generating Executive Master PDF...'), duration: Duration(seconds: 3)),
    );

    try {
      final res = await _resolveAllData(
        foodCostReport: foodCostReport, stockReport: stockReport, menuEngineeringReport: menuEngineeringReport,
        procurementReport: procurementReport, shrinkageReport: shrinkageReport, customers: customers,
      );

      final restaurant = await _resolveRestaurantInfo();
      final pdfBytes = await RestaurantPdfMasterBuilder.buildMasterPdf(
        restaurant: restaurant, periodLabel: periodLabel, summary: summary, topDishes: topDishes, orders: orders, auditLogs: auditLogs,
        foodCostReport: res.foodCost, stockReport: res.stock, menuEngineeringReport: res.menu,
        procurementReport: res.procurement, shrinkageReport: res.shrinkage, customers: res.customers,
      );

      final sanitizedPeriod = periodLabel.replaceAll(' ', '_').replaceAll('/', '-');
      final filename = 'SirfBill_Executive_Master_Report_${sanitizedPeriod}_${DateFormat('yyyyMMdd_HHmm').format(DateTime.now())}';
      final savedPath = await _saveFileLocally(filename: filename, bytes: Uint8List.fromList(pdfBytes), ext: 'pdf', mimeType: MimeType.pdf);

      if (!kIsWeb) {
        await Printing.sharePdf(bytes: Uint8List.fromList(pdfBytes), filename: '$filename.pdf');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Executive Master PDF downloaded: $savedPath'), backgroundColor: const Color(0xFF6366F1), behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to export PDF: $e'), backgroundColor: Colors.red));
      }
    }
  }
}
