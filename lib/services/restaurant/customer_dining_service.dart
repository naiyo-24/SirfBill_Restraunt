import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_client.dart';

class CustomerDiningService {
  static final Dio _dio = ApiClient().dio;

  /// Fetches public restaurant & table details by tableId
  static Future<Map<String, dynamic>?> fetchTableInfo(String tableId) async {
    try {
      final res = await _dio.get('/api/restaurant/customer/table/$tableId');
      if (res.statusCode == 200 && res.data != null) {
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (e) {
      debugPrint('[CustomerDiningService] fetchTableInfo error: $e');
    }
    return null;
  }

  /// Fetches customer digital menu
  static Future<Map<String, dynamic>?> fetchMenu(String outletId) async {
    try {
      final res = await _dio.get(
        '/api/restaurant/customer/menu',
        queryParameters: {'outlet_id': outletId},
      );
      if (res.statusCode == 200 && res.data != null) {
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (e) {
      debugPrint('[CustomerDiningService] fetchMenu error: $e');
    }
    return null;
  }

  /// Customer places table order
  static Future<Map<String, dynamic>?> placeOrder({
    required String outletId,
    required String tableId,
    String? customerName,
    String? customerPhone,
    String? notes,
    required List<Map<String, dynamic>> items,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/customer/orders',
        data: {
          'outlet_id': outletId,
          'table_id': tableId,
          if (customerName != null && customerName.isNotEmpty) 'customer_name': customerName,
          if (customerPhone != null && customerPhone.isNotEmpty) 'customer_phone': customerPhone,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
          'items': items,
        },
      );
      if ((res.statusCode == 200 || res.statusCode == 201) && res.data != null) {
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (e) {
      debugPrint('[CustomerDiningService] placeOrder error: $e');
      rethrow;
    }
    return null;
  }

  /// Checks order status for customer view
  static Future<Map<String, dynamic>?> fetchOrderStatus(String orderId) async {
    try {
      final res = await _dio.get('/api/restaurant/customer/orders/$orderId');
      if (res.statusCode == 200 && res.data != null) {
        return Map<String, dynamic>.from(res.data as Map);
      }
    } catch (e) {
      debugPrint('[CustomerDiningService] fetchOrderStatus error: $e');
    }
    return null;
  }

  /// POS Cashier Queue: Fetches pending QR orders
  static Future<List<Map<String, dynamic>>> fetchPendingQrOrders({String? outletId}) async {
    try {
      final res = await _dio.get(
        '/api/restaurant/orders/pending-qr',
        queryParameters: {
          if (outletId != null && outletId.isNotEmpty) 'outlet_id': outletId,
        },
      );
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : [];
        return list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      debugPrint('[CustomerDiningService] fetchPendingQrOrders error: $e');
    }
    return [];
  }

  /// POS Cashier Action: Confirms order and automatically fires KOT to kitchen
  static Future<bool> confirmQrOrder(String orderId) async {
    try {
      final res = await _dio.post('/api/restaurant/orders/$orderId/confirm-qr');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[CustomerDiningService] confirmQrOrder error: $e');
      return false;
    }
  }

  /// POS Cashier Action: Rejects unverified order
  static Future<bool> rejectQrOrder(String orderId, {String? reason}) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/orders/$orderId/reject-qr',
        data: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('[CustomerDiningService] rejectQrOrder error: $e');
      return false;
    }
  }
}
