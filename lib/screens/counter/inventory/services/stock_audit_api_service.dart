import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_client.dart';
import '../models/stock_audit_models.dart';

class StockAuditApiService {
  static Future<String> getResolvedOutletId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getString('restaurant_selected_outlet_id') ??
          prefs.getString('selected_outlet_id') ??
          '';
      return saved;
    } catch (_) {
      return '';
    }
  }

  static Future<List<StockAuditBatchSummary>> getStockAudits({
    String? search,
    int limit = 50,
    int offset = 0,
  }) async {
    final outletId = await getResolvedOutletId();
    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/audits',
        queryParameters: {
          if (outletId.isNotEmpty) 'outlet_id': outletId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => StockAuditBatchSummary.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[StockAuditApiService] getStockAudits failed: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('[StockAuditApiService] getStockAudits error: $e');
      return [];
    }
  }

  static Future<StockAuditBatchDetail?> getStockAuditDetail(String batchId) async {
    final outletId = await getResolvedOutletId();
    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/audits/$batchId',
        queryParameters: {
          if (outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return StockAuditBatchDetail.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[StockAuditApiService] getStockAuditDetail failed: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      debugPrint('[StockAuditApiService] getStockAuditDetail error: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> submitStockAudit({
    required String outletId,
    required String notes,
    required List<Map<String, dynamic>> items,
    DateTime? auditStartedAt,
  }) async {
    try {
      final payload = {
        'outlet_id': outletId,
        'notes': notes,
        'items': items,
        if (auditStartedAt != null) 'audit_started_at': auditStartedAt.toIso8601String(),
      };

      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/audits/submit',
        data: payload,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'success': true};
      }
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      debugPrint('[StockAuditApiService] submitStockAudit failed: $msg');
      throw Exception(msg);
    } catch (e) {
      debugPrint('[StockAuditApiService] submitStockAudit error: $e');
      rethrow;
    }
  }
}
