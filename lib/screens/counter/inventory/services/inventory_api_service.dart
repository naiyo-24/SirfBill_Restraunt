import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/api_client.dart';
import '../../../../services/inventory_service.dart';
import '../models/inventory_models.dart';

class InventoryApiService {
  static Future<String> getResolvedOutletId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final assignedId = prefs.getString('assigned_outlet_id');
      if (assignedId != null && assignedId.isNotEmpty) {
        return assignedId;
      }
      final selectedId = prefs.getString('selected_shop_id');
      if (selectedId != null && selectedId.isNotEmpty) {
        return selectedId;
      }
      return await InventoryService.getShopId();
    } catch (e) {
      debugPrint('[InventoryApiService] Error resolving outlet ID: $e');
      return '';
    }
  }

  // ==========================================
  // CATEGORIES & STORAGE ZONES
  // ==========================================

  static Future<List<IngredientCategory>> getCategories({
    String? search,
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/categories',
        queryParameters: {
          'outlet_id': targetOutlet,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      if (response.statusCode == 200) {
        final List list = response.data is List ? response.data : [];
        return list.map((item) => IngredientCategory.fromJson(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[InventoryApiService] getCategories failed: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('[InventoryApiService] getCategories error: $e');
      return [];
    }
  }

  static Future<String> generateCategoryCode(
    String name, {
    String? outletId,
  }) async {
    if (name.trim().isEmpty) return '';

    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/categories/generate-code',
        queryParameters: {
          'name': name.trim(),
          'outlet_id': targetOutlet,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['code']?.toString() ?? '';
      }
    } catch (e) {
      debugPrint('[InventoryApiService] generateCategoryCode failed: $e');
    }

    // Local fallback heuristic if network drops
    final words = name.trim().split(RegExp(r'\s+'));
    return words.first.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toUpperCase();
  }

  static Future<IngredientCategory?> createCategory({
    required String name,
    String? code,
    required String storageZoneTemp,
    String? colorCode,
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await getResolvedOutletId();

    final payload = {
      'outlet_id': targetOutlet,
      'name': name.trim(),
      if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
      'storage_zone_temp': storageZoneTemp.trim(),
      if (colorCode != null && colorCode.trim().isNotEmpty)
        'color_code': colorCode.trim(),
    };

    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/categories',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return IngredientCategory.fromJson(response.data);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to create category';
    }
    return null;
  }

  static Future<IngredientCategory?> updateCategory(
    String id, {
    required String name,
    String? code,
    required String storageZoneTemp,
    String? colorCode,
  }) async {
    final payload = {
      'name': name.trim(),
      if (code != null && code.trim().isNotEmpty) 'code': code.trim(),
      'storage_zone_temp': storageZoneTemp.trim(),
      if (colorCode != null && colorCode.trim().isNotEmpty)
        'color_code': colorCode.trim(),
    };

    try {
      final response = await ApiClient().dio.put(
        '/api/restaurant/inventory/categories/$id',
        data: payload,
      );

      if (response.statusCode == 200) {
        return IngredientCategory.fromJson(response.data);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to update category';
    }
    return null;
  }

  static Future<bool> deleteCategory(String id) async {
    try {
      final response = await ApiClient().dio.delete(
        '/api/restaurant/inventory/categories/$id',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[InventoryApiService] deleteCategory failed: $e');
      return false;
    }
  }

  static Future<List<IngredientCategory>> seedDefaultCategories({
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await getResolvedOutletId();

    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/categories/seed-defaults',
        queryParameters: {'outlet_id': targetOutlet},
      );

      if (response.statusCode == 200) {
        final List list = response.data is List ? response.data : [];
        return list.map((item) => IngredientCategory.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('[InventoryApiService] seedDefaultCategories error: $e');
    }
    return [];
  }

  // ==========================================
  // INGREDIENTS
  // ==========================================

  static Future<List<Ingredient>> getIngredients({
    String? categoryId,
    String? search,
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/inventory/ingredients',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          if (categoryId != null && categoryId.isNotEmpty) 'category_id': categoryId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      if (response.statusCode == 200) {
        final List list = response.data is List ? response.data : [];
        return list.map((item) => Ingredient.fromJson(item)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[InventoryApiService] getIngredients failed: ${e.response?.data ?? e.message}');
      return [];
    } catch (e) {
      debugPrint('[InventoryApiService] getIngredients error: $e');
      return [];
    }
  }

  static Future<Ingredient?> createIngredient(
    Map<String, dynamic> data, {
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await getResolvedOutletId();

    final payload = Map<String, dynamic>.from(data);
    payload['outlet_id'] = targetOutlet;

    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/ingredients',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return Ingredient.fromJson(response.data);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to save ingredient';
    }
    return null;
  }

  static Future<Ingredient?> updateIngredient(
    String id,
    Map<String, dynamic> data,
  ) async {
    try {
      final response = await ApiClient().dio.put(
        '/api/restaurant/inventory/ingredients/$id',
        data: data,
      );

      if (response.statusCode == 200) {
        return Ingredient.fromJson(response.data);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to update ingredient';
    }
    return null;
  }

  static Future<bool> deleteIngredient(String id) async {
    try {
      final response = await ApiClient().dio.delete(
        '/api/restaurant/inventory/ingredients/$id',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[InventoryApiService] deleteIngredient error: $e');
      return false;
    }
  }

  static Future<String?> uploadIngredientImage(Uint8List bytes, String filename) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });

      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/ingredients/upload-image',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['image_url']?.toString();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to upload image';
    } catch (e) {
      debugPrint('[InventoryApiService] uploadIngredientImage error: $e');
      rethrow;
    }
    return null;
  }

  static Future<String?> uploadIngredientFromUrl(String url) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/ingredients/upload-from-url',
        data: {'url': url.trim()},
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['image_url']?.toString();
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to download image from link';
    } catch (e) {
      debugPrint('[InventoryApiService] uploadIngredientFromUrl error: $e');
      rethrow;
    }
    return null;
  }

  // ==========================================
  // SUPPLIERS / DISTRIBUTORS
  // ==========================================

  static Future<List<Supplier>> getSuppliers({String? search}) async {
    final targetOutlet = await getResolvedOutletId();
    try {
      final response = await ApiClient().dio.get(
        '/api/admin/distributors/',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'shop_id': targetOutlet,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );
      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List).map((d) => Supplier.fromJson(d)).toList();
      }
    } catch (e) {
      debugPrint('[InventoryApiService] getSuppliers error: $e');
    }
    return [];
  }

  static Future<Supplier?> createSupplier(Map<String, dynamic> data) async {
    final targetOutlet = await getResolvedOutletId();
    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('shop_id') || payload['shop_id'] == null) {
      payload['shop_id'] = targetOutlet;
    }

    try {
      final response = await ApiClient().dio.post(
        '/api/admin/distributors/',
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return Supplier.fromJson(response.data);
      }
    } on DioException catch (e) {
      throw e.response?.data?['detail'] ?? 'Failed to create supplier';
    }
    return null;
  }

  static Future<Supplier?> updateSupplier(String id, Map<String, dynamic> data) async {
    final targetOutlet = await getResolvedOutletId();
    final payload = Map<String, dynamic>.from(data);
    if (targetOutlet.isNotEmpty && (!payload.containsKey('shop_id') || payload['shop_id'] == null)) {
      payload['shop_id'] = targetOutlet;
      payload['tenant_id'] = targetOutlet;
    }
    try {
      final response = await ApiClient().dio.patch(
        '/api/admin/distributors/$id',
        data: payload,
      );
      if (response.statusCode == 200) {
        return Supplier.fromJson(response.data);
      }
    } on DioException catch (e) {
      throw e.response?.data?['detail'] ?? 'Failed to update supplier';
    }
    return null;
  }

  static Future<bool> deleteSupplier(String id) async {
    try {
      final res = await ApiClient().dio.delete('/api/admin/distributors/$id');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('[InventoryApiService] deleteSupplier error: $e');
      return false;
    }
  }

  // ==========================================
  // PURCHASES / POs
  // ==========================================

  static Future<List<PurchaseOrder>> getPurchaseOrders({String? shopId}) async {
    final targetOutlet = (shopId != null && shopId.isNotEmpty) ? shopId : await getResolvedOutletId();
    try {
      final res = await ApiClient().dio.get(
        '/api/restaurant/procurement/purchase-orders',
        queryParameters: {if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet},
      );
      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List).map((b) => PurchaseOrder.fromPurchaseBill(b)).toList();
      }
    } catch (e) {
      debugPrint('[InventoryApiService] getPurchaseOrders error: $e');
    }
    return [];
  }

  // ==========================================
  // STOCK ADJUSTMENTS & BULK AUDIT RECONCILIATION
  // ==========================================

  static Future<bool> recordStockAdjustment({
    required String ingredientId,
    required double signedQuantity,
    String inputUom = 'RECIPE',
    required String reason,
    String? notes,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/adjustments',
        data: {
          'ingredient_id': ingredientId,
          'signed_quantity': signedQuantity,
          'input_uom': inputUom,
          'reason': reason,
          'notes': notes ?? '',
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[InventoryApiService] recordStockAdjustment error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>?> submitStockAudit({
    required String outletId,
    required String notes,
    required List<Map<String, dynamic>> items,
    DateTime? auditStartedAt,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/inventory/audits/submit',
        data: {
          'outlet_id': outletId,
          'notes': notes,
          'items': items,
          if (auditStartedAt != null) 'audit_started_at': auditStartedAt.toIso8601String(),
        },
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data is Map<String, dynamic>) {
          return response.data as Map<String, dynamic>;
        }
        return {'success': true};
      }
    } catch (e) {
      debugPrint('[InventoryApiService] submitStockAudit error: $e');
    }
    return null;
  }
}
