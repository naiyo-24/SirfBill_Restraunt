import 'package:dio/dio.dart';
import '../config/api_client.dart';
import 'inventory_service.dart';

class BillingService {
  static Future<Map<String, dynamic>> checkout({
    required List<Map<String, dynamic>> items,
    required double totalAmount,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? customerLocation,
    String? customerGstin,
    String? invoiceNo,
    String paymentMethod = 'CASH',
  }) async {
    try {
      final shopId = await InventoryService.getShopId();

      final requestData = {
        'shop_id': shopId,
        'tenant_id': shopId,
        'items': items
            .map(
              (item) {
                final rawInvId = item['inventory_item_id']?.toString();
                final isCustom = rawInvId == null ||
                    rawInvId.startsWith('custom_') ||
                    (item['is_custom'] == true);
                return {
                  'inventory_item_id': isCustom ? null : item['inventory_item_id'],
                  'item_name': item['name'] ?? item['item_name'] ?? 'Custom Item',
                  'unit_price': (item['price'] ?? item['unit_price'] ?? item['mrp'] ?? 0.0).toDouble(),
                  'quantity': item['qty'] ?? item['quantity'] ?? 1,
                  'is_loose': item['is_loose'] ?? false,
                  'discount': (item['discount'] ?? item['disc'] ?? 0.0).toDouble(),
                  'gst': (item['gst'] ?? 0.0).toDouble(),
                };
              },
            )
            .toList(),
        'total_amount': totalAmount,
        'payment_method': paymentMethod,
      };

      if (customerId != null && customerId.isNotEmpty) {
        requestData['user_id'] = customerId;
      }
      if (customerName != null && customerName.isNotEmpty) {
        requestData['customer_name'] = customerName;
      }
      if (customerPhone != null && customerPhone.isNotEmpty) {
        requestData['customer_phone'] = customerPhone;
      }
      if (customerLocation != null && customerLocation.isNotEmpty) {
        requestData['customer_location'] = customerLocation;
      }
      if (customerGstin != null && customerGstin.isNotEmpty) {
        requestData['customer_gstin'] = customerGstin;
      }
      if (invoiceNo != null && invoiceNo.isNotEmpty) {
        requestData['invoice_no'] = invoiceNo;
      }

      final response = await ApiClient().dio.post(
        '/api/admin/pos/checkout',
        data: requestData,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return response.data;
      } else {
        throw Exception('Checkout failed: ${response.data}');
      }
    } on DioException catch (e) {
      final resData = e.response?.data;
      if (resData != null) {
        throw Exception('Validation error: $resData');
      }
      throw Exception('Network error during checkout: ${e.message}');
    } catch (e) {
      throw Exception('Error during checkout: $e');
    }
  }

  static Future<Map<String, dynamic>> getPosHistory() async {
    try {
      final shopId = await InventoryService.getShopId();

      // In restaurant backend, live and settled orders are served at /api/restaurant/orders
      final response = await ApiClient().dio.get(
        '/api/restaurant/orders',
        queryParameters: {
          if (shopId.isNotEmpty) 'outlet_id': shopId,
          'limit': 1000,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final List list = response.data is List
            ? response.data
            : (response.data['orders'] ?? response.data['items'] ?? []);

        final mappedHistory = list.map((o) {
          final billNo = (o['order_number'] ?? o['order_no'] ?? o['bill_no'] ?? o['id'] ?? '').toString();
          final total = (o['total_amount'] as num?)?.toDouble() ??
              (o['grand_total'] as num?)?.toDouble() ??
              (o['total'] as num?)?.toDouble() ??
              0.0;
          final items = o['items'] ?? o['order_items'] ?? o['lines'] ?? [];

          return <String, dynamic>{
            'id': o['id']?.toString() ?? billNo,
            'bill_no': billNo,
            'order_number': billNo,
            'invoice_no': billNo,
            'amount': total,
            'total': total,
            'grand_total': total,
            'subtotal': (o['subtotal'] as num?)?.toDouble() ?? total,
            'discount': (o['discount'] as num?)?.toDouble() ?? 0.0,
            'tax': (o['tax'] as num?)?.toDouble() ?? (o['gst'] as num?)?.toDouble() ?? 0.0,
            'date': o['created_at'] ?? o['date'] ?? DateTime.now().toIso8601String(),
            'created_at': o['created_at'] ?? o['date'] ?? DateTime.now().toIso8601String(),
            'payment_mode': (o['payment_method'] ?? o['payment_mode'] ?? 'CASH').toString().toUpperCase(),
            'payment_method': (o['payment_method'] ?? o['payment_mode'] ?? 'CASH').toString().toUpperCase(),
            'customer_name': o['customer_name'] ?? 'Walk-in Guest',
            'customer_phone': o['customer_phone'] ?? '',
            'items': items,
            'items_detail': items,
            'status': o['status'] ?? 'COMPLETED',
          };
        }).toList();

        return <String, dynamic>{
          'history': mappedHistory,
          'summary': response.data is Map ? (response.data['summary'] ?? <String, dynamic>{}) : <String, dynamic>{},
        };
      }

      return <String, dynamic>{
        'history': <dynamic>[],
        'summary': <String, dynamic>{},
      };
    } catch (_) {
      return <String, dynamic>{
        'history': <dynamic>[],
        'summary': <String, dynamic>{},
      };
    }
  }
}
