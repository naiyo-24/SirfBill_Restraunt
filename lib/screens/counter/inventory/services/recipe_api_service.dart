import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_client.dart';
import '../../../../services/inventory_service.dart';
import '../models/recipe_models.dart';

class RecipeApiService {
  static Future<String> getResolvedOutletId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString('selected_shop_id');
      if (selectedId != null && selectedId.isNotEmpty) return selectedId;
      final assignedId = prefs.getString('assigned_outlet_id');
      if (assignedId != null && assignedId.isNotEmpty) return assignedId;
      return await InventoryService.getShopId();
    } catch (_) {
      return '';
    }
  }

  static Future<List<RecipeModel>> getRecipes({
    String? outletId,
    String? itemId,
    String? search,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/recipes',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          if (itemId != null && itemId.isNotEmpty) 'item_id': itemId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => RecipeModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[RecipeApiService] getRecipes failed: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('[RecipeApiService] getRecipes error: $e');
      return [];
    }
  }

  static Future<List<RecipeCostingModel>> getItemCosting(
    String itemId, {
    double? sellingPrice,
  }) async {
    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/recipes/$itemId/costing',
        queryParameters: {
          if (sellingPrice != null && sellingPrice > 0) 'selling_price': sellingPrice,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => RecipeCostingModel.fromJson(item as Map<String, dynamic>))
            .toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[RecipeApiService] getItemCosting failed: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('[RecipeApiService] getItemCosting error: $e');
      return [];
    }
  }

  static Future<RecipeModel?> createOrUpdateRecipe(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/recipes',
        data: payload,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        return RecipeModel.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      debugPrint('[RecipeApiService] createOrUpdateRecipe failed: $msg');
      throw Exception(msg);
    } catch (e) {
      debugPrint('[RecipeApiService] createOrUpdateRecipe error: $e');
      rethrow;
    }
  }

  static Future<bool> deleteRecipe(String recipeId) async {
    try {
      final response = await ApiClient().dio.delete(
        '/api/restaurant/inventory/recipes/$recipeId',
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[RecipeApiService] deleteRecipe error: $e');
      return false;
    }
  }
}
