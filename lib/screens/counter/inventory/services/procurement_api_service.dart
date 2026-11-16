import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../../../config/api_client.dart';
import '../models/inventory_ops_models.dart';
import '../models/grn_models.dart';
import 'inventory_api_service.dart';

class ProcurementApiService {
  static Future<List<PurchaseOrder>> getPurchaseOrders({
    String? status,
    String? search,
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await InventoryApiService.getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/procurement/purchase-orders',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          if (status != null && status.isNotEmpty) 'status': status,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        final list = (response.data as List)
            .map((item) => PurchaseOrder.fromPurchaseBill(Map<String, dynamic>.from(item)))
            .toList();
        return list;
      }
    } on DioException catch (e) {
      debugPrint('[ProcurementApiService] getPurchaseOrders failed: ${e.response?.data ?? e.message}');
    } catch (e) {
      debugPrint('[ProcurementApiService] getPurchaseOrders error: $e');
    }
    return [];
  }

  static Future<PurchaseOrder?> getPurchaseOrderById(String poId) async {
    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/procurement/purchase-orders/$poId',
      );
      if (response.statusCode == 200 && response.data != null) {
        return PurchaseOrder.fromPurchaseBill(Map<String, dynamic>.from(response.data));
      }
    } catch (e) {
      debugPrint('[ProcurementApiService] getPurchaseOrderById error: $e');
    }
    return null;
  }

  static Future<PurchaseOrder?> createPurchaseOrder(
    Map<String, dynamic> data, {
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await InventoryApiService.getResolvedOutletId();

    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('outlet_id') || payload['outlet_id'] == null) {
      payload['outlet_id'] = targetOutlet;
    }

    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/procurement/purchase-orders',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return PurchaseOrder.fromPurchaseBill(Map<String, dynamic>.from(response.data));
      }
    } on DioException catch (e) {
      final detail = e.response?.data?['detail']?.toString() ?? e.message ?? '';

      // Auto-heal: If supplier was created under another branch, link distributor to this outlet and retry
      if (detail.contains('another branch') || detail.contains('Supplier not found')) {
        final supplierId = payload['supplier_id']?.toString();
        if (supplierId != null && supplierId.isNotEmpty && targetOutlet.isNotEmpty) {
          try {
            await ApiClient().dio.patch(
              '/api/admin/distributors/$supplierId',
              data: {'shop_id': targetOutlet, 'tenant_id': targetOutlet},
            );
            final retry = await ApiClient().dio.post(
              '/api/restaurant/procurement/purchase-orders',
              data: payload,
            );
            if (retry.statusCode == 200 || retry.statusCode == 201) {
              return PurchaseOrder.fromPurchaseBill(Map<String, dynamic>.from(retry.data));
            }
          } catch (_) {}
        }
      }

      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to create purchase order';
    } catch (e) {
      debugPrint('[ProcurementApiService] createPurchaseOrder error: $e');
      rethrow;
    }
    return null;
  }

  static Future<PurchaseOrder?> issuePurchaseOrder(String poId) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/procurement/purchase-orders/$poId/issue',
      );
      if (response.statusCode == 200 && response.data != null) {
        return PurchaseOrder.fromPurchaseBill(Map<String, dynamic>.from(response.data));
      }
    } on DioException catch (e) {
      throw e.response?.data?['detail'] ?? 'Failed to send PO to vendor';
    } catch (e) {
      debugPrint('[ProcurementApiService] issuePurchaseOrder error: $e');
      rethrow;
    }
    return null;
  }

  static Future<PurchaseOrder?> cancelPurchaseOrder(String poId) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/procurement/purchase-orders/$poId/cancel',
      );
      if (response.statusCode == 200 && response.data != null) {
        return PurchaseOrder.fromPurchaseBill(Map<String, dynamic>.from(response.data));
      }
    } on DioException catch (e) {
      throw e.response?.data?['detail'] ?? 'Failed to cancel PO';
    } catch (e) {
      debugPrint('[ProcurementApiService] cancelPurchaseOrder error: $e');
      rethrow;
    }
    return null;
  }

  static Future<bool> deletePurchaseOrder(String poId) async {
    try {
      final response = await ApiClient().dio.delete(
        '/api/restaurant/procurement/purchase-orders/$poId',
      );
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('[ProcurementApiService] deletePurchaseOrder error: $e');
      return false;
    }
  }

  static Future<Map<String, dynamic>> emailPurchaseOrder(
    String poId, {
    String? recipientEmail,
    String? customMessage,
  }) async {
    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/procurement/purchase-orders/$poId/email',
        data: {
          if (recipientEmail != null && recipientEmail.isNotEmpty) 'email': recipientEmail,
          if (customMessage != null && customMessage.isNotEmpty) 'message': customMessage,
        },
      );
      if (response.statusCode == 200 && response.data != null) {
        return Map<String, dynamic>.from(response.data);
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to email purchase order';
    } catch (e) {
      debugPrint('[ProcurementApiService] emailPurchaseOrder error: $e');
      rethrow;
    }
    return {'success': false, 'message': 'Unknown response'};
  }

  static Future<String> getNextGrnNumber({String? outletId}) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await InventoryApiService.getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/procurement/grn/next-number',
        queryParameters: targetOutlet.isNotEmpty ? {'outlet_id': targetOutlet} : null,
      );
      if (response.statusCode == 200 && response.data != null) {
        return (response.data['grn_number'] ?? 'GRN-AUTO').toString();
      }
    } catch (e) {
      debugPrint('[ProcurementApiService] getNextGrnNumber error: $e');
    }
    return 'GRN-AUTO';
  }

  static Future<List<GrnRecord>> getGRNList({
    String? poId,
    String? search,
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await InventoryApiService.getResolvedOutletId();

    try {
      final response = await ApiClient().dio.get(
        '/api/restaurant/procurement/grn',
        queryParameters: {
          if (targetOutlet.isNotEmpty) 'outlet_id': targetOutlet,
          if (poId != null && poId.isNotEmpty) 'po_id': poId,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        },
      );

      if (response.statusCode == 200 && response.data is List) {
        return (response.data as List)
            .map((item) => GrnRecord.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      }
    } on DioException catch (e) {
      debugPrint('[ProcurementApiService] getGRNList failed: ${e.response?.data ?? e.message}');
    } catch (e) {
      debugPrint('[ProcurementApiService] getGRNList error: $e');
    }
    return [];
  }

  static Future<GrnRecord?> createGRN(
    Map<String, dynamic> data, {
    String? outletId,
  }) async {
    final targetOutlet = (outletId != null && outletId.isNotEmpty)
        ? outletId
        : await InventoryApiService.getResolvedOutletId();

    final payload = Map<String, dynamic>.from(data);
    if (!payload.containsKey('outlet_id') || payload['outlet_id'] == null) {
      payload['outlet_id'] = targetOutlet;
    }

    try {
      final response = await ApiClient().dio.post(
        '/api/restaurant/procurement/grn/receive',
        data: payload,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return GrnRecord.fromJson(Map<String, dynamic>.from(response.data));
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['detail'] ?? e.message;
      throw msg ?? 'Failed to receive goods (GRN)';
    } catch (e) {
      debugPrint('[ProcurementApiService] createGRN error: $e');
      rethrow;
    }
    return null;
  }

  /// Uploads physical supplier invoice document / scan (PDF, JPG, PNG)
  static Future<String?> uploadVendorInvoiceDocument({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      });

      final response = await ApiClient().dio.post(
        '/api/restaurant/procurement/grn/upload-invoice',
        data: formData,
      );

      if (response.statusCode == 200 && response.data != null) {
        return response.data['invoice_document_url']?.toString();
      }
    } catch (e) {
      debugPrint('[ProcurementApiService] uploadVendorInvoiceDocument error: $e');
    }
    return null;
  }

  /// Streams binary PDF compiled from backend Jinja2 HTML template via weasyprint
  static Future<Uint8List?> fetchPurchaseOrderPdf(String poId, {bool download = false}) async {
    try {
      final response = await ApiClient().dio.get<List<int>>(
        '/api/restaurant/procurement/purchase-orders/$poId/pdf',
        queryParameters: {'download': download},
        options: Options(responseType: ResponseType.bytes),
      );
      if (response.statusCode == 200 && response.data != null) {
        return Uint8List.fromList(response.data!);
      }
    } catch (e) {
      debugPrint('[ProcurementApiService] fetchPurchaseOrderPdf error: $e');
    }
    return null;
  }

  /// URL for direct browser HTML template rendering with optional native auto-print
  static String getPurchaseOrderPrintUrl(String poId, {bool autoprint = true}) {
    final base = ApiClient().dio.options.baseUrl.replaceAll(RegExp(r'/+$'), '');
    return '$base/api/restaurant/procurement/purchase-orders/$poId/print?autoprint=$autoprint';
  }
}
