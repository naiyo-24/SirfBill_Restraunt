import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../../config/api_client.dart';
import '../../models/restaurant_executive_report_models.dart';
import '../inventory_service.dart';

class RestaurantExecutiveReportService {
  static Dio get _dio => ApiClient().dio;

  static Map<String, dynamic> _buildQueryParams(String outletId, DateTime? start, DateTime? end) {
    final df = DateFormat('yyyy-MM-dd');
    return {
      'outlet_id': outletId,
      if (start != null) 'start_date': df.format(start),
      if (end != null) 'end_date': df.format(end),
    };
  }

  /// 1. Food Cost Variance Report
  static Future<FoodCostVarianceReport?> fetchFoodCostVariance({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final outletId = await InventoryService.getShopId();
      final res = await _dio.get(
        '/api/restaurant/reports/food-cost-variance',
        queryParameters: _buildQueryParams(outletId, startDate, endDate),
      );
      if (res.statusCode == 200 && res.data != null) {
        return FoodCostVarianceReport.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error fetching food cost variance report: $e');
    }
    return null;
  }

  /// 2. Stock Movement & Valuation Report
  static Future<StockMovementReport?> fetchStockMovement({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final outletId = await InventoryService.getShopId();
      final res = await _dio.get(
        '/api/restaurant/reports/stock-movement',
        queryParameters: _buildQueryParams(outletId, startDate, endDate),
      );
      if (res.statusCode == 200 && res.data != null) {
        return StockMovementReport.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error fetching stock movement report: $e');
    }
    return null;
  }

  /// 3. Menu Engineering BCG Matrix Report
  static Future<MenuEngineeringReport?> fetchMenuEngineering({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final outletId = await InventoryService.getShopId();
      final res = await _dio.get(
        '/api/restaurant/reports/menu-engineering',
        queryParameters: _buildQueryParams(outletId, startDate, endDate),
      );
      if (res.statusCode == 200 && res.data != null) {
        return MenuEngineeringReport.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error fetching menu engineering report: $e');
    }
    return null;
  }

  /// 4. Procurement & GST Register Report
  static Future<ProcurementReport?> fetchProcurement({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final outletId = await InventoryService.getShopId();
      final res = await _dio.get(
        '/api/restaurant/reports/procurement',
        queryParameters: _buildQueryParams(outletId, startDate, endDate),
      );
      if (res.statusCode == 200 && res.data != null) {
        return ProcurementReport.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error fetching procurement report: $e');
    }
    return null;
  }

  /// 5. Shrinkage & Leakage Report
  static Future<ShrinkageReport?> fetchShrinkage({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final outletId = await InventoryService.getShopId();
      final res = await _dio.get(
        '/api/restaurant/reports/shrinkage',
        queryParameters: _buildQueryParams(outletId, startDate, endDate),
      );
      if (res.statusCode == 200 && res.data != null) {
        return ShrinkageReport.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error fetching shrinkage report: $e');
    }
    return null;
  }
}
