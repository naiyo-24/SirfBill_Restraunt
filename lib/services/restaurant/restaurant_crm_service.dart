import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_client.dart';
import '../../models/restaurant_crm_models.dart';
import '../inventory_service.dart';

class RestaurantCrmService {
  static Dio get _dio => ApiClient().dio;

  /// 1. Fetch Customers with filtering, search, and dynamic segments
  static Future<List<RestaurantCustomer>> fetchCustomers({
    String? search,
    CustomerSegment segment = CustomerSegment.all,
    bool? hasDue,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final outletId = await InventoryService.getShopId();
      String? segmentParam;
      switch (segment) {
        case CustomerSegment.vip:
          segmentParam = 'VIP';
          break;
        case CustomerSegment.regular:
          segmentParam = 'REGULAR';
          break;
        case CustomerSegment.newGuest:
          segmentParam = 'NEW';
          break;
        case CustomerSegment.atRisk:
          segmentParam = 'AT_RISK';
          break;
        case CustomerSegment.hasDue:
          hasDue = true;
          break;
        case CustomerSegment.all:
          segmentParam = null;
          break;
      }

      final res = await _dio.get(
        '/api/restaurant/crm/customers',
        queryParameters: {
          'outlet_id': outletId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (segmentParam != null) 'segment': segmentParam,
          if (hasDue == true) 'has_due': true,
          'limit': limit,
          'offset': offset,
        },
      );

      if (res.statusCode == 200 && res.data is List) {
        return (res.data as List)
            .map((json) => RestaurantCustomer.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
    } catch (e) {
      debugPrint('Error fetching CRM customers: $e');
    }
    return [];
  }

  /// 2. Create New Customer Profile
  static Future<RestaurantCustomer?> createCustomer(Map<String, dynamic> data) async {
    try {
      final outletId = await InventoryService.getShopId();
      final payload = Map<String, dynamic>.from(data);
      payload['outlet_id'] = outletId;

      final res = await _dio.post('/api/restaurant/crm/customers', data: payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return RestaurantCustomer.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error creating CRM customer: $e');
      rethrow;
    }
    return null;
  }

  /// 3. Update Existing Customer Profile
  static Future<RestaurantCustomer?> updateCustomer(String customerId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch(
        '/api/restaurant/crm/customers/$customerId',
        data: data,
      );
      if (res.statusCode == 200) {
        return RestaurantCustomer.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error updating CRM customer: $e');
      rethrow;
    }
    return null;
  }

  /// 4. Delete Customer Profile
  static Future<bool> deleteCustomer(String customerId) async {
    try {
      final res = await _dio.delete('/api/restaurant/crm/customers/$customerId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting CRM customer: $e');
      return false;
    }
  }

  /// 5. Fetch Customer 360° Insights
  static Future<CustomerInsights?> fetchCustomerInsights(String customerId) async {
    try {
      final res = await _dio.get('/api/restaurant/crm/customers/$customerId/insights');
      if (res.statusCode == 200 && res.data != null) {
        return CustomerInsights.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error fetching customer insights: $e');
    }
    return null;
  }

  /// 6. Fetch Khata (Store Credit) Ledger Statement
  static Future<List<KhataLedgerEntry>> fetchKhataStatement(String customerId) async {
    try {
      final res = await _dio.get('/api/restaurant/crm/customers/$customerId/khata');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data['ledger'] ?? res.data['transactions'] ?? [];
        return list.map((x) => KhataLedgerEntry.fromJson(Map<String, dynamic>.from(x))).toList();
      }
    } catch (e) {
      debugPrint('Error fetching Khata statement: $e');
    }
    return [];
  }

  /// 7. Settle Khata Dues
  static Future<bool> settleKhataDues({
    required String customerId,
    required double amount,
    required String paymentMode,
    String? notes,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/crm/customers/$customerId/khata/settle',
        data: {
          'amount': amount,
          'payment_mode': paymentMode,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error settling Khata dues: $e');
      rethrow;
    }
  }

  /// 8. Adjust Loyalty Points Manually
  static Future<bool> adjustLoyaltyPoints({
    required String customerId,
    required int points,
    required String reason,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/crm/customers/$customerId/loyalty/adjust',
        data: {
          'points': points,
          'reason': reason,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error adjusting loyalty points: $e');
      rethrow;
    }
  }

  /// 9. Send Multi-Channel Notification (WhatsApp / SMS / Email)
  static Future<bool> sendCustomerNotification({
    required String customerId,
    required String channel,
    required String messageType,
    String? customMessage,
  }) async {
    try {
      final res = await _dio.post(
        '/api/restaurant/crm/customers/$customerId/notify',
        data: {
          'channel': channel,
          'message_type': messageType,
          if (customMessage != null && customMessage.isNotEmpty) 'custom_message': customMessage,
        },
      );
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error sending customer notification: $e');
      return false;
    }
  }
}
