import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/api_client.dart';
import '../models/stock_consumption_models.dart';
import 'recipe_api_service.dart';

class StockConsumptionApiService {
  static Future<StockConsumptionStreamData> fetchConsumptionStream({
    String? outletId,
    String? reason,
    String? search,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await RecipeApiService.getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/consumption',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          if (reason != null && reason.trim().isNotEmpty) 'reason': reason.trim(),
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return StockConsumptionStreamData.fromJson(response.data as Map<String, dynamic>);
      }
      return const StockConsumptionStreamData(
        isActive: true,
        totalRecords: 0,
        totalConsumptionInr: 0.0,
        totalReversalsInr: 0.0,
        totalWastageInr: 0.0,
        events: [],
        ledgerStream: [],
      );
    } on DioException catch (e) {
      debugPrint('[StockConsumptionApiService] fetchConsumptionStream failed: ${e.response?.data ?? e.message}');
      return const StockConsumptionStreamData(
        isActive: false,
        totalRecords: 0,
        totalConsumptionInr: 0.0,
        totalReversalsInr: 0.0,
        totalWastageInr: 0.0,
        events: [],
        ledgerStream: [],
      );
    } catch (e) {
      debugPrint('[StockConsumptionApiService] fetchConsumptionStream error: $e');
      return const StockConsumptionStreamData(
        isActive: false,
        totalRecords: 0,
        totalConsumptionInr: 0.0,
        totalReversalsInr: 0.0,
        totalWastageInr: 0.0,
        events: [],
        ledgerStream: [],
      );
    }
  }
}
