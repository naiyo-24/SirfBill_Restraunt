import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../../models/restaurant_pos_models.dart';
import '../../../../../providers/restaurant_order_provider.dart';
import '../../../../../providers/restaurant_pos_provider.dart';
import '../../../../../providers/restaurant_table_provider.dart';
import '../../../../../services/inventory_service.dart';
import '../../../../../services/restaurant_pos_service.dart';
import '../../../../../services/shop_service.dart';
import '../../../../../utils/kot_printer_helper.dart';
import '../../../../../utils/restaurant_bill_pdf_generator.dart';
import '../pos_bill_receipt_modal.dart';

/// Handles customer bill / pre-settlement check generation and display for POS
class PosCustomerBillController {
  /// Generates and previews/prints the Table Bill / Pre-Settlement Check for the customer before payment.
  /// The order remains active and the table remains occupied/reserved!
  static Future<void> handlePrintCustomerBill({
    required BuildContext context,
    required WidgetRef ref,
    required RestaurantPosState posState,
    required List<DiningTable> liveTables,
    required Map<String, dynamic>? shopSettings,
    required Shop? activeOutlet,
    required VoidCallback onReloadMenu,
    required Future<void> Function(String tableId, RestaurantPosNotifier posNotifier, {bool showFeedback}) onSelectTable,
  }) async {
    if (posState.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cart is empty. Add items to print bill.')),
      );
      return;
    }

    final cartSnapshot = List<PosCartItem>.from(posState.cart);
    String orderId = posState.activeOrderId ?? '';
    String orderNumber = posState.activeOrderNumber ?? '';

    // If order is not yet created on backend, save it first so table is officially occupied
    if (orderId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Saving table order & generating customer bill...')),
      );

      final res = await RestaurantPosService.sendToKitchen(
        orderType: posState.orderType.name,
        tableId: posState.orderType == OrderType.dineIn ? posState.selectedTableId : null,
        cartItems: cartSnapshot,
        customerName: posState.customerName,
        customerPhone: posState.customerPhone,
        orderNotes: posState.orderNotes,
      );

      if (res != null && res['id'] != null) {
        orderId = res['id'].toString();
        orderNumber = res['order_number']?.toString() ?? 'ORD-$orderId';

        ref.read(restaurantOrderProvider.notifier).loadOrders();
        ref.read(restaurantTableProvider.notifier).loadTables();
        onReloadMenu();

        if (posState.orderType == OrderType.dineIn && posState.selectedTableId != null) {
          await onSelectTable(
            posState.selectedTableId!,
            ref.read(restaurantPosProvider.notifier),
            showFeedback: false,
          );
        }
      } else {
        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not generate customer bill: Failed to register order'),
            backgroundColor: Color(0xFFEF4444),
          ),
        );
        return;
      }
    }

    // Resolve outlet info
    Shop? outlet = activeOutlet;
    if (outlet == null) {
      try {
        final shops = await ShopService.getShops();
        final currentShopId = await InventoryService.getShopId();
        if (shops.isNotEmpty) {
          outlet = shops.firstWhere((s) => s.id == currentShopId, orElse: () => shops.first);
        }
      } catch (_) {}
    }

    final shopName = (outlet?.name.trim().isNotEmpty ?? false)
        ? outlet!.name.trim()
        : ((shopSettings?['shop_name']?.toString().trim().isNotEmpty ?? false)
            ? shopSettings!['shop_name'].toString()
            : 'SirfBill Restaurant');

    final hasOutletLocation = outlet != null && outlet.location.trim().isNotEmpty && outlet.location != 'N/A';
    final address = hasOutletLocation
        ? outlet.location
        : (shopSettings?['address']?.toString() ?? shopSettings?['shop_address']?.toString() ?? '');

    final hasOutletContact = outlet != null && outlet.contact.trim().isNotEmpty && outlet.contact != 'N/A';
    final phone = hasOutletContact
        ? outlet.contact
        : (shopSettings?['phone']?.toString() ?? shopSettings?['mobile']?.toString() ?? '');

    final shopGstNo = (outlet?.gstin?.trim().isNotEmpty ?? false)
        ? outlet!.gstin!
        : (shopSettings?['gst_number']?.toString() ??
            shopSettings?['shop_gst_no']?.toString() ??
            shopSettings?['gstin']?.toString() ??
            '');

    final fssaiNo = outlet?.fssai ??
        shopSettings?['fssai']?.toString() ??
        shopSettings?['cin_number']?.toString() ??
        shopSettings?['drug_licence']?.toString() ??
        '';

    final upiId = (outlet?.upiId != null && outlet!.upiId!.trim().isNotEmpty)
        ? outlet.upiId!.trim()
        : (shopSettings?['upi_id']?.toString() ?? '');

    // Resolve Table Label
    String? tableLabel;
    String? floor;
    if (posState.selectedTableId != null) {
      final matchingTable = liveTables.where((t) => t.id == posState.selectedTableId).firstOrNull;
      if (matchingTable != null) {
        tableLabel = matchingTable.label;
        if (matchingTable.floor.isNotEmpty) floor = matchingTable.floor;
      } else {
        tableLabel = posState.selectedTableId;
      }
    }

    Uint8List? billDocBytes;
    Uint8List? kotDocBytes;
    final kotNumber = 'KOT-${orderNumber.replaceAll("#", "").replaceAll("ORD-", "")}';

    try {
      // 1. Generate clean standalone Customer Bill (72mm)
      billDocBytes = await RestaurantBillPdfGenerator.generateBillPdf(
        orderNumber: orderNumber,
        orderType: posState.orderType == OrderType.dineIn ? 'Dine-in (Pre-Bill)' : 'Customer Bill',
        tableLabel: tableLabel,
        customerName: posState.customerName.isNotEmpty ? posState.customerName : 'Guest',
        customerPhone: posState.customerPhone,
        items: cartSnapshot,
        subtotal: posState.subtotal,
        discount: posState.discountAmount,
        tax: posState.gstAmount,
        grandTotal: posState.grandTotal,
        shopName: shopName,
        address: address,
        phone: phone,
        shopGstNo: shopGstNo,
        fssaiNo: fssaiNo,
        upiId: upiId,
        logoUrl: outlet?.logoUrl ?? shopSettings?['logo_url'],
      );

      // 2. Generate clean standalone KOT (72mm) for independent auto-cut
      kotDocBytes = await KotPrinterHelper.generateKotPdf(
        kotNumber: kotNumber,
        orderNumber: orderNumber,
        orderType: posState.orderType == OrderType.dineIn ? 'DINE-IN' : 'TAKEAWAY',
        tableLabel: tableLabel,
        floor: floor,
        customerName: posState.customerName.isNotEmpty ? posState.customerName : 'Guest',
        orderNotes: posState.orderNotes,
        items: cartSnapshot,
      );
    } catch (e) {
      debugPrint('Warning: Local thermal bill generation failed: $e');
      try {
        billDocBytes = await RestaurantPosService.fetchBackendBillPdfBytes(orderId);
      } catch (_) {}
    }

    if (context.mounted && billDocBytes != null) {
      await PosBillReceiptModal.show(
        context,
        orderNumber: orderNumber,
        title: tableLabel != null ? 'Table $tableLabel • Customer Bill' : 'Customer Bill',
        pdfBytes: billDocBytes,
        kotBytes: kotDocBytes,
        kotNumber: kotNumber,
      );
    }
  }
}
