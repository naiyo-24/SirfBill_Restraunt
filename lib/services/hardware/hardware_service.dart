import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_client.dart';
import '../../models/hardware_product_model.dart';
import '../inventory_service.dart';

class HardwareService {
  static Dio get _dio => ApiClient().dio;

  /// 1. Fetch hardware categories
  static Future<List<HardwareCategoryInfo>> fetchCategories() async {
    try {
      final res = await _dio.get('/api/hardware/categories');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['categories'] ?? []);
        return list.map((json) => HardwareCategoryInfo.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Error fetching hardware categories: $e');
    }
    return [];
  }

  /// 2. Fetch hardware products list
  static Future<List<HardwareProduct>> fetchProducts({
    String? category,
    String? search,
    bool? inStockOnly,
    bool? popularOnly,
  }) async {
    try {
      final res = await _dio.get(
        '/api/hardware/products',
        queryParameters: {
          if (category != null && category.isNotEmpty && category != 'ALL') 'category': category,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (inStockOnly == true) 'in_stock_only': true,
          if (popularOnly == true) 'popular_only': true,
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['products'] ?? res.data['items'] ?? []);
        return list.map((json) => HardwareProduct.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Error fetching hardware products: $e');
    }
    return [];
  }

  /// 2b. Fetch Influencer Marketing & Website Service Plans from backend
  static Future<List<Map<String, dynamic>>> fetchServicePlans() async {
    try {
      final res = await _dio.get('/api/service-plans');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List
            ? res.data
            : (res.data['plans'] ?? res.data['items'] ?? res.data['data'] ?? []);
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching service plans: $e');
    }
    return [];
  }

  /// 3. Fetch single hardware product details
  static Future<HardwareProduct?> fetchProductDetails(String productId) async {
    try {
      final res = await _dio.get('/api/hardware/products/$productId');
      if (res.statusCode == 200 && res.data != null) {
        return HardwareProduct.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error fetching product details ($productId): $e');
    }
    return null;
  }

  /// 4. Admin: Create new hardware product
  static Future<HardwareProduct?> createProduct(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/api/hardware/products', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return HardwareProduct.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error creating hardware product: $e');
      rethrow;
    }
    return null;
  }

  /// 5. Admin: Update hardware product
  static Future<HardwareProduct?> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch('/api/hardware/products/$productId', data: data);
      if (res.statusCode == 200) {
        return HardwareProduct.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error updating hardware product: $e');
      rethrow;
    }
    return null;
  }

  /// 6. Admin: Soft delete / deactivate hardware product
  static Future<bool> deleteProduct(String productId) async {
    try {
      final res = await _dio.delete('/api/hardware/products/$productId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting hardware product: $e');
      return false;
    }
  }

  /// 7. Admin / Setup: Seed hardware catalog
  static Future<bool> seedCatalog() async {
    try {
      final res = await _dio.post('/api/hardware/seed');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error seeding hardware catalog: $e');
      return false;
    }
  }

  /// 8. Place Hardware Order / Demo Inquiry
  static Future<HardwareOrderModel?> createOrder({
    required String productId,
    String? productName,
    double? price,
    double? totalPrice,
    required int quantity,
    required String contactName,
    required String contactPhone,
    required String shippingAddress,
    required String city,
    required String pincode,
  }) async {
    try {
      String outletId = '';
      try {
        final prefs = await SharedPreferences.getInstance();
        outletId = prefs.getString('selected_shop_id') ??
            prefs.getString('assigned_outlet_id') ??
            '';
        if (outletId.isEmpty) {
          outletId = await InventoryService.getShopId();
        }
      } catch (_) {}

      final parsedProductId = int.tryParse(productId);
      final calcTotal = totalPrice ?? ((price ?? 0) * quantity);

      final payload = <String, dynamic>{
        'product_id': parsedProductId ?? productId,
        if (parsedProductId != null) 'product': parsedProductId,
        if (productName != null && productName.isNotEmpty) ...{
          'product_name': productName,
          'item_name': productName,
        },
        'quantity': quantity,
        if (price != null && price > 0) ...{
          'price': price,
          'unit_price': price,
        },
        if (calcTotal > 0) ...{
          'total_price': calcTotal,
          'total_amount': calcTotal,
        },
        'contact_name': contactName,
        'name': contactName,
        'contact_phone': contactPhone,
        'phone': contactPhone,
        'shipping_address': shippingAddress,
        'address': shippingAddress,
        'city': city,
        'pincode': pincode,
        'status': 'NEW',
        if (outletId.isNotEmpty) ...{
          'outlet_id': outletId,
          'tenant_id': outletId,
          'shop_id': outletId,
        },
      };

      debugPrint('Placing Hardware Order payload: $payload');

      Response res;
      try {
        res = await _dio.post('/api/hardware/orders', data: payload);
      } on DioException catch (dioErr) {
        if (dioErr.response?.statusCode == 404 || dioErr.response?.statusCode == 301) {
          res = await _dio.post('/api/hardware/orders/', data: payload);
        } else {
          rethrow;
        }
      }

      if (res.statusCode == 200 || res.statusCode == 201) {
        debugPrint('Hardware Order created successfully: ${res.data}');
        Map<String, dynamic> dataMap = {};
        if (res.data is Map) {
          if (res.data['order'] is Map) {
            dataMap = Map<String, dynamic>.from(res.data['order']);
          } else if (res.data['data'] is Map) {
            dataMap = Map<String, dynamic>.from(res.data['data']);
          } else {
            dataMap = Map<String, dynamic>.from(res.data);
          }
        }
        return HardwareOrderModel.fromJson(dataMap);
      }
    } catch (e) {
      debugPrint('Error placing hardware order: $e');
      rethrow;
    }
    return null;
  }

  /// 9. Fetch hardware orders placed by current restaurant tenant
  static Future<List<HardwareOrderModel>> fetchOrders() async {
    try {
      final res = await _dio.get('/api/hardware/orders');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['orders'] ?? []);
        return list.map((json) => HardwareOrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Error fetching hardware orders: $e');
    }
    return [];
  }

  /// 10. Update hardware order fulfillment status (Admin)
  static Future<bool> updateOrderStatus(
    String orderId, {
    required String status,
    String? trackingNumber,
    String? courierPartner,
  }) async {
    try {
      final res = await _dio.patch(
        '/api/hardware/orders/$orderId',
        data: {
          'status': status,
          if (trackingNumber != null) 'tracking_number': trackingNumber,
          if (courierPartner != null) 'courier_partner': courierPartner,
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

}
