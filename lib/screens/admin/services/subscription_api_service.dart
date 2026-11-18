import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../config/api_client.dart';
import '../../../services/inventory_service.dart';
import '../models/subscription_plan_models.dart';

class SubscriptionApiService {
  SubscriptionApiService._();

  static Future<String> getResolvedOutletId({String? outletId}) async {
    if (outletId != null && outletId.trim().isNotEmpty) {
      return outletId.trim();
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final selectedId = prefs.getString('selected_shop_id') ??
          prefs.getString('assigned_outlet_id') ??
          prefs.getString('restaurant_selected_outlet_id') ??
          prefs.getString('selected_outlet_id');
      if (selectedId != null && selectedId.trim().isNotEmpty) {
        return selectedId.trim();
      }
      return await InventoryService.getShopId();
    } catch (_) {
      return '';
    }
  }

  /// GET /api/subscriptions/plans
  /// Returns list of available subscription plans from DB catalog (all 4 tiers)
  static Future<List<SubscriptionPlanItem>> fetchPlans() async {
    try {
      final response = await ApiClient().dio.get('/api/subscriptions/plans');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['plans'] is List) {
          list = data['plans'];
        }

        if (list.isNotEmpty) {
          return list
              .map((item) => SubscriptionPlanItem.fromJson(Map<String, dynamic>.from(item as Map)))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionApiService] fetchPlans fallback to default: $e');
    }
    return List<SubscriptionPlanItem>.from(kMonthlySubscriptionPlans);
  }

  /// GET /api/subscriptions/status?outlet_id=...
  /// Fast status query for header badges and subscription tab
  static Future<SubscriptionStatusModel> fetchSubscriptionStatus({String? outletId}) async {
    try {
      final resolvedId = await getResolvedOutletId(outletId: outletId);
      final response = await ApiClient().dio.get(
        '/api/subscriptions/status',
        queryParameters: {
          if (resolvedId.isNotEmpty) 'outlet_id': resolvedId,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> data = (response.data is Map)
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        return SubscriptionStatusModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[SubscriptionApiService] fetchSubscriptionStatus fallback: $e');
    }
    return SubscriptionStatusModel.defaultActive();
  }

  /// POST /api/subscriptions/create-order
  static Future<String?> createRazorpayOrder({
    required double amount,
    String? planId,
    String? planCode,
    int? durationMonths,
    String? outletId,
  }) async {
    final resolvedId = await getResolvedOutletId(outletId: outletId);
    try {
      final response = await ApiClient().dio.post(
        '/api/subscriptions/create-order',
        data: {
          'amount': amount,
          if (planId != null) 'plan_id': planId,
          if (planCode != null) 'plan_code': planCode,
          if (durationMonths != null) 'duration_months': durationMonths,
          if (resolvedId.isNotEmpty) 'outlet_id': resolvedId,
        },
      ).timeout(const Duration(seconds: 4));

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data;
        if (data is Map) {
          return data['order_id']?.toString() ?? data['id']?.toString();
        }
      }
    } catch (e) {
      debugPrint('[SubscriptionApiService] createRazorpayOrder info: $e');
    }
    return null;
  }

  /// POST /api/subscriptions/verify-payment with fallback to /api/subscriptions/subscribe
  /// Supports all 4 plan tiers (+30, +90, +180, +365 days)
  static Future<SubscriptionStatusModel> verifyAndActivatePayment({
    String? planId,
    String? planCode,
    int? durationMonths,
    required String paymentReference,
    String? orderId,
    String? signature,
    String? outletId,
  }) async {
    final resolvedId = await getResolvedOutletId(outletId: outletId);

    // 1. Try official POST /api/subscriptions/verify-payment
    try {
      final verifyPayload = <String, dynamic>{
        'razorpay_payment_id': paymentReference.trim(),
        if (orderId != null && orderId.isNotEmpty) 'razorpay_order_id': orderId.trim(),
        if (signature != null && signature.isNotEmpty) 'razorpay_signature': signature.trim(),
        if (planId != null) 'plan_id': planId,
        if (planCode != null) 'plan_code': planCode,
        if (durationMonths != null) 'duration_months': durationMonths,
        if (resolvedId.isNotEmpty) 'outlet_id': resolvedId,
      };

      final response = await ApiClient().dio.post(
        '/api/subscriptions/verify-payment',
        data: verifyPayload,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> data = (response.data is Map)
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        return SubscriptionStatusModel.fromJson(data);
      }
    } catch (e) {
      debugPrint('[SubscriptionApiService] verify-payment fallback to subscribe: $e');
    }

    // 2. Fallback to POST /api/subscriptions/subscribe
    return subscribe(
      planId: planId,
      planCode: planCode,
      durationMonths: durationMonths,
      paymentMethod: 'RAZORPAY',
      paymentReference: paymentReference,
      gatewayOrderId: orderId,
      gatewaySignature: signature,
      outletId: resolvedId,
    );
  }

  /// POST /api/subscriptions/subscribe
  static Future<SubscriptionStatusModel> subscribe({
    String? planId,
    String? planCode,
    int? durationMonths,
    required String paymentMethod,
    required String paymentReference,
    String? gatewayOrderId,
    String? gatewaySignature,
    String? notes,
    String? outletId,
  }) async {
    final resolvedId = await getResolvedOutletId(outletId: outletId);
    final payload = <String, dynamic>{
      if (planId != null) 'plan_id': planId,
      if (planCode != null && planCode.isNotEmpty) 'plan_code': planCode,
      if (durationMonths != null) 'duration_months': durationMonths,
      'payment_method': paymentMethod.trim().isEmpty ? 'RAZORPAY' : paymentMethod.trim(),
      'payment_reference': paymentReference.trim(),
      'gateway_payment_id': paymentReference.trim(),
      if (gatewayOrderId != null && gatewayOrderId.isNotEmpty) 'gateway_order_id': gatewayOrderId.trim(),
      if (gatewaySignature != null && gatewaySignature.isNotEmpty) 'gateway_signature': gatewaySignature.trim(),
      'notes': notes?.trim() ?? 'Paid via Official Razorpay Payment Gateway',
      if (resolvedId.isNotEmpty) 'outlet_id': resolvedId,
    };

    try {
      final response = await ApiClient().dio.post(
        '/api/subscriptions/subscribe',
        data: payload,
      );

      if ((response.statusCode == 200 || response.statusCode == 201) && response.data != null) {
        final Map<String, dynamic> data = (response.data is Map)
            ? Map<String, dynamic>.from(response.data as Map)
            : <String, dynamic>{};
        return SubscriptionStatusModel.fromJson(data);
      }
    } on DioException catch (dioErr) {
      final errMsg = dioErr.response?.data?['detail'] ?? dioErr.message ?? 'Subscription request failed';
      throw Exception(errMsg);
    } catch (e) {
      debugPrint('[SubscriptionApiService] subscribe error: $e');
      rethrow;
    }

    throw Exception('Failed to process subscription');
  }

  /// GET /api/subscriptions/history
  static Future<List<SubscriptionInvoiceItem>> fetchInvoiceHistory() async {
    try {
      final response = await ApiClient().dio.get('/api/subscriptions/history');
      if (response.statusCode == 200 && response.data != null) {
        final dynamic data = response.data;
        List<dynamic> list = [];
        if (data is List) {
          list = data;
        } else if (data is Map && data['invoices'] is List) {
          list = data['invoices'];
        } else if (data is Map && data['payments'] is List) {
          list = data['payments'];
        }

        return list
            .map((item) => SubscriptionInvoiceItem.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    } catch (e) {
      debugPrint('[SubscriptionApiService] fetchInvoiceHistory error: $e');
    }
    return <SubscriptionInvoiceItem>[];
  }

  /// POST /api/subscriptions/grant-trial?days=30
  static Future<bool> grantTrial({int days = 14, String? outletId}) async {
    try {
      final resolvedId = await getResolvedOutletId(outletId: outletId);
      final response = await ApiClient().dio.post(
        '/api/subscriptions/grant-trial',
        queryParameters: {
          'days': days,
          if (resolvedId.isNotEmpty) 'outlet_id': resolvedId,
        },
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[SubscriptionApiService] grantTrial error: $e');
      return false;
    }
  }
}
