import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/api_client.dart';
import '../models/stock_transfer_models.dart';
import 'inventory_api_service.dart';

class StockTransferApiService {
  static const String _baseEndpoint = '/api/restaurant/inventory/transfers';

  /// Lists stock transfers with outlet filtering and status filtering
  static Future<List<StockTransferHeader>> getTransfers({
    String? outletId,
    String? status,
    String? transferType,
    int limit = 50,
    int offset = 0,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await InventoryApiService.getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        _baseEndpoint,
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          if (status != null && status.isNotEmpty) 'status': status,
          if (transferType != null && transferType.isNotEmpty) 'transfer_type': transferType,
          'limit': limit,
          'offset': offset,
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => StockTransferHeader.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } on DioException catch (e) {
      debugPrint('[StockTransferApiService] getTransfers dio error: ${e.response?.data ?? e.message}');
    } catch (e) {
      debugPrint('[StockTransferApiService] getTransfers error: $e');
    }
    return [];
  }

  /// Fetches next auto-incremented transfer number for current month
  static Future<String> getNextTransferNumber() async {
    try {
      final response = await ApiClient().dio.get('$_baseEndpoint/next-number');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['transfer_number']?.toString() ?? 'ST-0001';
      }
    } catch (e) {
      debugPrint('[StockTransferApiService] getNextTransferNumber error: $e');
    }
    final now = DateTime.now();
    return 'ST-${now.year}${now.month.toString().padLeft(2, '0')}-0001';
  }

  /// Creates a new stock transfer in DRAFT state
  static Future<StockTransferHeader?> createTransfer(Map<String, dynamic> payload) async {
    try {
      final response = await ApiClient().dio.post(
        _baseEndpoint,
        data: payload,
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        return StockTransferHeader.fromJson(Map<String, dynamic>.from(response.data));
      }
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw detail ?? 'Failed to create transfer';
    } catch (e) {
      throw 'Error creating transfer: $e';
    }
    return null;
  }

  /// Dispatches a DRAFT transfer to IN_TRANSIT
  static Future<bool> dispatchTransfer(
    String id, {
    String? vehicleNumber,
    String? driverName,
    String? notes,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '$_baseEndpoint/$id/dispatch',
        data: {
          if (vehicleNumber != null && vehicleNumber.isNotEmpty) 'vehicle_number': vehicleNumber,
          if (driverName != null && driverName.isNotEmpty) 'driver_name': driverName,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw detail ?? 'Failed to dispatch transfer';
    } catch (e) {
      throw 'Dispatch error: $e';
    }
  }

  /// Receives an IN_TRANSIT transfer, reconciling received counts and logging shrinkage
  static Future<bool> receiveTransfer(
    String id, {
    required List<Map<String, dynamic>> items,
    String? notes,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '$_baseEndpoint/$id/receive',
        data: {
          'items': items,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw detail ?? 'Failed to receive and reconcile transfer';
    } catch (e) {
      throw 'Receive error: $e';
    }
  }

  /// Cancels a transfer in DRAFT or IN_TRANSIT
  static Future<bool> cancelTransfer(String id, {String? reason}) async {
    try {
      final response = await ApiClient().dio.post(
        '$_baseEndpoint/$id/cancel',
        queryParameters: {
          if (reason != null && reason.isNotEmpty) 'reason': reason,
        },
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      final detail = e.response?.data?['detail'] ?? e.message;
      throw detail ?? 'Failed to cancel transfer';
    } catch (e) {
      throw 'Cancel error: $e';
    }
  }
}
