import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_client.dart';
import '../../../../services/inventory_service.dart';
import '../models/food_cost_models.dart';

/// Production-grade API service for Restaurant Food Cost Analysis,
/// Actual vs. Theoretical (AvT) Reconciliation, and Stock Valuation Export.
class FoodCostApiService {
  FoodCostApiService._();

  // ===========================================================================
  // OUTLET RESOLUTION
  // ===========================================================================

  /// Resolves the target outlet ID with comprehensive fallback hierarchy:
  /// 1. Explicit [outletId] passed by caller
  /// 2. Active UI selection (`selected_shop_id`)
  /// 3. User profile assignment (`assigned_outlet_id`)
  /// 4. Legacy session keys (`restaurant_selected_outlet_id`, `selected_outlet_id`)
  /// 5. Global InventoryService shop ID
  static Future<String> getResolvedOutletId({String? outletId}) async {
    if (outletId != null && outletId.trim().isNotEmpty) {
      return outletId.trim();
    }

    try {
      final prefs = await SharedPreferences.getInstance();

      final selectedId = prefs.getString('selected_shop_id');
      if (selectedId != null && selectedId.trim().isNotEmpty) {
        return selectedId.trim();
      }

      final assignedId = prefs.getString('assigned_outlet_id');
      if (assignedId != null && assignedId.trim().isNotEmpty) {
        return assignedId.trim();
      }

      final legacyId = prefs.getString('restaurant_selected_outlet_id') ??
          prefs.getString('selected_outlet_id');
      if (legacyId != null && legacyId.trim().isNotEmpty) {
        return legacyId.trim();
      }

      final shopId = await InventoryService.getShopId();
      return shopId.trim();
    } catch (e) {
      debugPrint('[FoodCostApiService] Failed to resolve outlet ID: $e');
      return '';
    }
  }

  // ===========================================================================
  // FOOD COST RECONCILIATION (AvT)
  // ===========================================================================

  /// Fetches the Actual vs. Theoretical Food Cost Reconciliation Report for the given [days] window.
  ///
  /// - Sanitizes [days] between 1 and 365 to adhere to backend boundary validation.
  /// - Supports an optional [cancelToken] to cleanly abort in-flight requests on UI switches.
  /// - Returns a fallback [FoodCostReconciliationReport.empty()] on network failure or cancellation.
  static Future<FoodCostReconciliationReport> getFoodCostReconciliation({
    String? outletId,
    int days = 30,
    CancelToken? cancelToken,
  }) async {
    final sanitizedDays = days.clamp(1, 365);
    final targetOutlet = await getResolvedOutletId(outletId: outletId);

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/reports/reconciliation',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          'days': sanitizedDays,
        },
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        dynamic data = response.data;
        if (data is String) {
          data = jsonDecode(data);
        }

        if (data is Map<String, dynamic>) {
          return FoodCostReconciliationReport.fromJson(data);
        }
      }

      debugPrint('[FoodCostApiService] Unexpected reconciliation payload shape: ${response.data.runtimeType}');
      return FoodCostReconciliationReport.empty();
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[FoodCostApiService] getFoodCostReconciliation request cancelled.');
      } else {
        debugPrint(
          '[FoodCostApiService] getFoodCostReconciliation failed (${e.response?.statusCode}): '
          '${e.response?.data ?? e.message}',
        );
      }
      return FoodCostReconciliationReport.empty();
    } catch (e, stack) {
      debugPrint('[FoodCostApiService] getFoodCostReconciliation unexpected error: $e\n$stack');
      return FoodCostReconciliationReport.empty();
    }
  }

  // ===========================================================================
  // WAREHOUSE VALUATION CSV EXPORT
  // ===========================================================================

  /// Exports warehouse stock valuation snapshot to a standardized CSV file.
  ///
  /// - Streams binary bytes directly from `/api/restaurant/inventory/reports/export/valuation`.
  /// - Detects backend JSON error responses to avoid saving corrupted error text as CSV.
  /// - Uses [FileSaver] to trigger automatic web download or native desktop save dialog.
  /// - Returns `true` if file was successfully saved/downloaded, `false` otherwise.
  static Future<bool> exportValuationCsv({
    String? outletId,
    String? outletName,
    CancelToken? cancelToken,
  }) async {
    final targetOutlet = await getResolvedOutletId(outletId: outletId);

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/reports/export/valuation',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
        },
        options: Options(
          responseType: ResponseType.bytes,
          headers: const {
            'Accept': 'text/csv, application/octet-stream, application/json',
          },
        ),
        cancelToken: cancelToken,
      );

      if (response.statusCode == 200 && response.data != null) {
        final contentType = response.headers.value('content-type')?.toLowerCase() ?? '';

        // Guard: check if backend returned an error JSON disguised under 200
        if (contentType.contains('application/json')) {
          final errorBody = utf8.decode(response.data as List<int>);
          debugPrint('[FoodCostApiService] Valuation export returned error JSON: $errorBody');
          return false;
        }

        final Uint8List bytes;
        if (response.data is Uint8List) {
          bytes = response.data as Uint8List;
        } else if (response.data is List<int>) {
          bytes = Uint8List.fromList(response.data as List<int>);
        } else {
          bytes = Uint8List.fromList(utf8.encode(response.data.toString()));
        }

        if (bytes.isEmpty) {
          debugPrint('[FoodCostApiService] Valuation export returned empty bytes.');
          return false;
        }

        // Generate sanitized, ISO-compliant filename
        final now = DateTime.now();
        final dateStamp = '${now.year}'
            '${now.month.toString().padLeft(2, '0')}'
            '${now.day.toString().padLeft(2, '0')}_'
            '${now.hour.toString().padLeft(2, '0')}'
            '${now.minute.toString().padLeft(2, '0')}'
            '${now.second.toString().padLeft(2, '0')}';

        final cleanOutlet = (outletName ?? 'outlet')
            .trim()
            .replaceAll(RegExp(r'[^a-zA-Z0-9]+'), '_')
            .toLowerCase();

        final baseFilename = 'stock_valuation_${cleanOutlet}_$dateStamp';

        await FileSaver.instance.saveFile(
          name: baseFilename,
          bytes: bytes,
          fileExtension: 'csv',
          mimeType: MimeType.csv,
        );

        return true;
      }

      debugPrint('[FoodCostApiService] Valuation export returned unexpected status: ${response.statusCode}');
      return false;
    } on DioException catch (e) {
      if (CancelToken.isCancel(e)) {
        debugPrint('[FoodCostApiService] exportValuationCsv request cancelled.');
      } else {
        debugPrint(
          '[FoodCostApiService] exportValuationCsv failed (${e.response?.statusCode}): '
          '${e.response?.data ?? e.message}',
        );
      }
      return false;
    } catch (e, stack) {
      debugPrint('[FoodCostApiService] exportValuationCsv unexpected error: $e\n$stack');
      return false;
    }
  }
}
