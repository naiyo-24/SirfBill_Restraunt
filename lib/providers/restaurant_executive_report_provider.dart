import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/restaurant_executive_report_models.dart';
import '../services/restaurant/restaurant_executive_report_service.dart';
import '../widgets/common_filter_pills.dart';

class ExecutiveReportState {
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final int activeReportIndex; // 0: Food Cost, 1: Stock Movement, 2: Menu BCG, 3: Procurement, 4: Shrinkage
  final FoodCostVarianceReport? foodCostReport;
  final StockMovementReport? stockReport;
  final MenuEngineeringReport? menuEngineeringReport;
  final ProcurementReport? procurementReport;
  final ShrinkageReport? shrinkageReport;
  final bool isLoading;

  const ExecutiveReportState({
    this.datePreset = DateRangePreset.thisMonth,
    this.customRange,
    this.activeReportIndex = 0,
    this.foodCostReport,
    this.stockReport,
    this.menuEngineeringReport,
    this.procurementReport,
    this.shrinkageReport,
    this.isLoading = false,
  });

  String get dateRangeLabel {
    switch (datePreset) {
      case DateRangePreset.all:
        return 'All Time';
      case DateRangePreset.today:
        return 'Today (${DateFormat('dd MMM yyyy').format(DateTime.now())})';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.thisMonth:
        return 'This Month (${DateFormat('MMMM yyyy').format(DateTime.now())})';
      case DateRangePreset.thisYear:
        return 'This Year (${DateTime.now().year})';
      case DateRangePreset.custom:
        if (customRange != null) {
          final s = customRange!.start;
          final e = customRange!.end;
          return '${DateFormat('dd/MM/yyyy').format(s)} - ${DateFormat('dd/MM/yyyy').format(e)}';
        }
        return 'Custom Range';
    }
  }

  DateTime? get resolvedStartDate {
    final now = DateTime.now();
    switch (datePreset) {
      case DateRangePreset.all:
        return null;
      case DateRangePreset.today:
        return DateTime(now.year, now.month, now.day);
      case DateRangePreset.thisWeek:
        return DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
      case DateRangePreset.thisMonth:
        return DateTime(now.year, now.month, 1);
      case DateRangePreset.thisYear:
        return DateTime(now.year, 1, 1);
      case DateRangePreset.custom:
        return customRange?.start;
    }
  }

  DateTime? get resolvedEndDate {
    final now = DateTime.now();
    switch (datePreset) {
      case DateRangePreset.all:
        return null;
      case DateRangePreset.today:
        return DateTime(now.year, now.month, now.day, 23, 59, 59);
      case DateRangePreset.thisWeek:
        final startOfWeek = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
        return startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
      case DateRangePreset.thisMonth:
        final nextMonth = now.month == 12 ? DateTime(now.year + 1, 1, 1) : DateTime(now.year, now.month + 1, 1);
        return nextMonth.subtract(const Duration(seconds: 1));
      case DateRangePreset.thisYear:
        return DateTime(now.year, 12, 31, 23, 59, 59);
      case DateRangePreset.custom:
        return customRange?.end;
    }
  }

  ExecutiveReportState copyWith({
    DateRangePreset? datePreset,
    DateTimeRange? customRange,
    int? activeReportIndex,
    FoodCostVarianceReport? Function()? foodCostReport,
    StockMovementReport? Function()? stockReport,
    MenuEngineeringReport? Function()? menuEngineeringReport,
    ProcurementReport? Function()? procurementReport,
    ShrinkageReport? Function()? shrinkageReport,
    bool? isLoading,
  }) {
    return ExecutiveReportState(
      datePreset: datePreset ?? this.datePreset,
      customRange: customRange ?? this.customRange,
      activeReportIndex: activeReportIndex ?? this.activeReportIndex,
      foodCostReport: foodCostReport != null ? foodCostReport() : this.foodCostReport,
      stockReport: stockReport != null ? stockReport() : this.stockReport,
      menuEngineeringReport: menuEngineeringReport != null ? menuEngineeringReport() : this.menuEngineeringReport,
      procurementReport: procurementReport != null ? procurementReport() : this.procurementReport,
      shrinkageReport: shrinkageReport != null ? shrinkageReport() : this.shrinkageReport,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class ExecutiveReportNotifier extends Notifier<ExecutiveReportState> {
  @override
  ExecutiveReportState build() {
    Future.microtask(() => loadActiveReport());
    return const ExecutiveReportState(isLoading: true);
  }

  void setActiveReportIndex(int index) {
    if (state.activeReportIndex != index) {
      state = state.copyWith(activeReportIndex: index);
      loadActiveReport();
    }
  }

  void setDatePreset(DateRangePreset preset) {
    state = state.copyWith(datePreset: preset, customRange: null);
    loadActiveReport();
  }

  void setCustomRange(DateTimeRange range) {
    state = state.copyWith(datePreset: DateRangePreset.custom, customRange: range);
    loadActiveReport();
  }

  Future<void> loadActiveReport() async {
    state = state.copyWith(isLoading: true);
    final start = state.resolvedStartDate;
    final end = state.resolvedEndDate;

    switch (state.activeReportIndex) {
      case 0:
        final res = await RestaurantExecutiveReportService.fetchFoodCostVariance(
          startDate: start,
          endDate: end,
        );
        state = state.copyWith(foodCostReport: () => res, isLoading: false);
        break;
      case 1:
        final res = await RestaurantExecutiveReportService.fetchStockMovement(
          startDate: start,
          endDate: end,
        );
        state = state.copyWith(stockReport: () => res, isLoading: false);
        break;
      case 2:
        final res = await RestaurantExecutiveReportService.fetchMenuEngineering(
          startDate: start,
          endDate: end,
        );
        state = state.copyWith(menuEngineeringReport: () => res, isLoading: false);
        break;
      case 3:
        final res = await RestaurantExecutiveReportService.fetchProcurement(
          startDate: start,
          endDate: end,
        );
        state = state.copyWith(procurementReport: () => res, isLoading: false);
        break;
      case 4:
        final res = await RestaurantExecutiveReportService.fetchShrinkage(
          startDate: start,
          endDate: end,
        );
        state = state.copyWith(shrinkageReport: () => res, isLoading: false);
        break;
      default:
        state = state.copyWith(isLoading: false);
    }
  }
}

final executiveReportProvider = NotifierProvider<ExecutiveReportNotifier, ExecutiveReportState>(() {
  return ExecutiveReportNotifier();
});
