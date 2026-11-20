import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/restaurant_report_provider.dart';
import '../../providers/restaurant_executive_report_provider.dart';
import 'widgets/reports/report_filter_header.dart';
import 'widgets/reports/sales_overview_tab.dart';
import 'widgets/reports/item_wise_sales_tab.dart';
import 'widgets/reports/audit_logs_tab.dart';
import 'widgets/reports/food_cost_variance_tab.dart';
import 'widgets/reports/stock_movement_tab.dart';
import 'widgets/reports/menu_engineering_bcg_tab.dart';
import 'widgets/reports/procurement_gst_tab.dart';
import 'widgets/reports/shrinkage_leakage_tab.dart';
import 'widgets/reports/restaurant_report_export_helper.dart';

class ReportsScreen extends ConsumerWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportState = ref.watch(restaurantReportProvider);
    final reportNotifier = ref.read(restaurantReportProvider.notifier);
    final execState = ref.watch(executiveReportProvider);
    final execNotifier = ref.read(executiveReportProvider.notifier);

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    Widget content;
    switch (reportState.activeTab) {
      case 0:
        content = SalesOverviewTab(summary: reportState.summary);
        break;
      case 1:
        content = ItemWiseSalesTab(
          topDishes: reportState.topDishes,
          summary: reportState.summary,
          orders: reportState.orders,
        );
        break;
      case 2:
        content = FoodCostVarianceTab(
          report: execState.foodCostReport,
          isLoading: execState.isLoading,
        );
        break;
      case 3:
        content = StockMovementTab(
          report: execState.stockReport,
          isLoading: execState.isLoading,
        );
        break;
      case 4:
        content = MenuEngineeringBcgTab(
          report: execState.menuEngineeringReport,
          isLoading: execState.isLoading,
        );
        break;
      case 5:
        content = ProcurementGstTab(
          report: execState.procurementReport,
          isLoading: execState.isLoading,
        );
        break;
      case 6:
        content = ShrinkageLeakageTab(
          report: execState.shrinkageReport,
          isLoading: execState.isLoading,
        );
        break;
      case 7:
        content = AuditLogsTab(
          logs: reportState.filteredAuditLogs,
          onSearch: reportNotifier.setAuditSearchQuery,
        );
        break;
      default:
        content = SalesOverviewTab(summary: reportState.summary);
    }

    final isOverallLoading = reportState.activeTab >= 2 && reportState.activeTab <= 6
        ? execState.isLoading
        : reportState.isLoading;

    return Scaffold(
      backgroundColor: screenBg,
      body: Column(
        children: [
          // 1. Report Filters Header (Date Range Presets & Custom Picker, Segmented Tabs, Export PDF)
          ReportFilterHeader(
            datePreset: reportState.datePreset,
            customRange: reportState.customRange,
            activeTab: reportState.activeTab,
            isLoading: isOverallLoading,
            onSelectDatePreset: (preset) {
              reportNotifier.setDatePreset(preset);
              execNotifier.setDatePreset(preset);
            },
            onSelectCustomRange: (range) {
              if (range != null) {
                reportNotifier.setCustomRange(range);
                execNotifier.setCustomRange(range);
              }
            },
            onSelectTab: (idx) {
              reportNotifier.setActiveTab(idx);
              if (idx >= 2 && idx <= 6) {
                execNotifier.setActiveReportIndex(idx - 2);
              }
            },
            onRefresh: () {
              reportNotifier.loadReportData();
              execNotifier.loadActiveReport();
            },
            onExportPdf: () {
              RestaurantReportExportHelper.showExportOptions(
                context: context,
                periodLabel: reportState.dateRangeLabel,
                summary: reportState.summary,
                topDishes: reportState.topDishes,
                orders: reportState.orders,
                auditLogs: reportState.auditLogs,
                activeTab: reportState.activeTab,
              );
            },
          ),

          // 2. Tab Content View
          Expanded(
            child: isOverallLoading
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF10B981)),
                  )
                : content,
          ),
        ],
      ),
    );
  }
}
