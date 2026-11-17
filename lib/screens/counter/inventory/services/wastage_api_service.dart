import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/api_client.dart';
import '../models/wastage_models.dart';
import 'recipe_api_service.dart';

class WastageApiService {
  static Future<List<WastageItemRecord>> getWastageLogs({
    String? outletId,
    int limit = 150,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await RecipeApiService.getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/waste',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          'limit': limit,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => WastageItemRecord.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[WastageApiService] getWastageLogs failed: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('[WastageApiService] getWastageLogs error: $e');
      return [];
    }
  }

  static Future<WastageSummaryData?> getWastageSummary({
    String? outletId,
    int days = 30,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await RecipeApiService.getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/waste/summary',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          'days': days,
        },
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        return WastageSummaryData.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[WastageApiService] getWastageSummary failed: ${e.response?.data ?? e.message}');
      return null;
    } catch (e) {
      debugPrint('[WastageApiService] getWastageSummary error: $e');
      return null;
    }
  }

  static Future<bool> logRawMaterialWaste(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/waste',
        data: payload,
      );
      return response.statusCode == 201 || response.statusCode == 200;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      debugPrint('[WastageApiService] logRawMaterialWaste failed: $msg');
      throw Exception(msg);
    } catch (e) {
      debugPrint('[WastageApiService] logRawMaterialWaste error: $e');
      rethrow;
    }
  }

  static Future<Map<String, dynamic>?> logCookedDishWaste(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/waste/dish',
        data: payload,
      );
      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data as Map<String, dynamic>?;
      }
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      debugPrint('[WastageApiService] logCookedDishWaste failed: $msg');
      throw Exception(msg);
    } catch (e) {
      debugPrint('[WastageApiService] logCookedDishWaste error: $e');
      rethrow;
    }
  }
}
