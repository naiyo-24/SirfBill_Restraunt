import 'package:flutter/material.dart';

/// Purchase Order Status
enum POStatus {
  draft(label: 'Draft', color: Colors.blueGrey),
  sent(label: 'Sent to Vendor', color: Colors.blue),
  partiallyReceived(label: 'Partial Delivery', color: Colors.amber),
  completed(label: 'Completed', color: Colors.teal),
  cancelled(label: 'Cancelled', color: Colors.red);

  const POStatus({required this.label, required this.color});
  final String label;
  final MaterialColor color;
}

/// PO Item
class PurchaseOrderItem {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final double orderedQty;
  final double receivedQty;
  final String uom;
  final double unitPrice;
  final double taxRate;
  final double taxAmount;
  final double totalPrice;

  const PurchaseOrderItem({
    this.id = '',
    required this.ingredientId,
    required this.ingredientName,
    required this.orderedQty,
    this.receivedQty = 0.0,
    required this.uom,
    required this.unitPrice,
    this.taxRate = 0.0,
    this.taxAmount = 0.0,
    this.totalPrice = 0.0,
  });
}

/// Purchase Order Model
class PurchaseOrder {
  final String id;
  final String poNumber;
  final String outletName;
  final String outletAddress;
  final String outletCity;
  final String outletPhone;
  final String outletEmail;
  final String outletGstin;
  final String supplierId;
  final String supplierName;
  final String supplierEmail;
  final String supplierPhone;
  final String supplierAddress;
  final DateTime orderDate;
  final DateTime expectedDeliveryDate;
  final POStatus status;
  final List<PurchaseOrderItem> items;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;
  final String notes;

  const PurchaseOrder({
    required this.id,
    required this.poNumber,
    this.outletName = '',
    this.outletAddress = '',
    this.outletCity = '',
    this.outletPhone = '',
    this.outletEmail = '',
    this.outletGstin = '',
    required this.supplierId,
    required this.supplierName,
    this.supplierEmail = '',
    this.supplierPhone = '',
    this.supplierAddress = '',
    required this.orderDate,
    required this.expectedDeliveryDate,
    required this.status,
    required this.items,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    required this.totalAmount,
    this.notes = '',
  });

  factory PurchaseOrder.fromPurchaseBill(Map<String, dynamic> json) {
    final statusStr = (json['status'] ?? json['payment_status'] ?? '').toString().toLowerCase();
    POStatus st = POStatus.sent;
    if (statusStr.contains('draft')) {
      st = POStatus.draft;
    } else if (statusStr.contains('paid') || statusStr.contains('completed')) {
      st = POStatus.completed;
    } else if (statusStr.contains('partial')) {
      st = POStatus.partiallyReceived;
    } else if (statusStr.contains('cancel')) {
      st = POStatus.cancelled;
    } else if (statusStr.contains('issued') || statusStr.contains('sent')) {
      st = POStatus.sent;
    }

    final billDateStr = json['order_date'] ?? json['bill_date'] ?? json['created_at'];
    final dt = billDateStr != null ? DateTime.tryParse(billDateStr.toString()) ?? DateTime.now() : DateTime.now();

    final expDeliveryStr = json['expected_delivery_date'];
    final expDt = expDeliveryStr != null ? DateTime.tryParse(expDeliveryStr.toString()) ?? dt.add(const Duration(days: 2)) : dt.add(const Duration(days: 2));

    double parseNum(dynamic v, [double def = 0.0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    final List itemsJson = json['items'] is List ? json['items'] : [];
    final items = itemsJson.map((it) {
      final qty = parseNum(it['quantity_ordered'] ?? it['quantity'], 1.0);
      final price = parseNum(it['unit_price'] ?? it['cost_price'], 0.0);
      final taxRate = parseNum(it['tax_rate'], 0.0);
      final taxAmt = parseNum(it['tax_amount'], (qty * price) * (taxRate / 100.0));
      final lineTot = parseNum(it['total_price'], (qty * price) + taxAmt);
      return PurchaseOrderItem(
        id: (it['id'] ?? '').toString(),
        ingredientId: (it['ingredient_id'] ?? it['item_id'] ?? '').toString(),
        ingredientName: (it['ingredient_name'] ?? it['name'] ?? it['item_name'] ?? 'Raw Material').toString(),
        orderedQty: qty,
        receivedQty: parseNum(it['quantity_received'] ?? it['received_quantity'], 0.0),
        uom: (it['unit'] ?? 'KG').toString(),
        unitPrice: price,
        taxRate: taxRate,
        taxAmount: taxAmt,
        totalPrice: lineTot,
      );
    }).toList();

    final totAmt = parseNum(json['total_amount']);
    final taxTot = parseNum(json['tax_amount'], items.fold(0.0, (sum, it) => sum + it.taxAmount));
    final subTot = parseNum(json['subtotal'], totAmt - taxTot);

    return PurchaseOrder(
      id: json['id']?.toString() ?? '',
      poNumber: json['po_number']?.toString() ?? json['invoice_no']?.toString() ?? 'PO-${json['id']?.toString().substring(0, 6) ?? '001'}',
      outletName: json['outlet_name']?.toString() ?? '',
      outletAddress: json['outlet_address']?.toString() ?? '',
      outletCity: json['outlet_city']?.toString() ?? '',
      outletPhone: json['outlet_phone']?.toString() ?? '',
      outletEmail: json['outlet_email']?.toString() ?? '',
      outletGstin: json['outlet_gstin']?.toString() ?? '',
      supplierId: json['supplier_id']?.toString() ?? json['distributor_id']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? json['distributor_name']?.toString() ?? 'Direct Supplier',
      supplierEmail: json['supplier_email']?.toString() ?? json['email']?.toString() ?? '',
      supplierPhone: json['supplier_phone']?.toString() ?? json['phone']?.toString() ?? '',
      supplierAddress: json['supplier_address']?.toString() ?? json['address']?.toString() ?? '',
      orderDate: dt,
      expectedDeliveryDate: expDt,
      status: st,
      items: items,
      subtotal: subTot,
      taxAmount: taxTot,
      totalAmount: totAmt,
      notes: json['notes']?.toString() ?? '',
    );
  }
}

/// Goods Received Note (GRN)
class GoodsReceivedNote {
  final String id;
  final String grnNumber;
  final String poNumber;
  final String supplierName;
  final String invoiceNumber;
  final DateTime receivedDate;
  final String receivedBy;
  final double totalBillAmount;
  final bool temperaturePass;
  final double? temperatureCelsius;
  final String remarks;

  const GoodsReceivedNote({
    required this.id,
    required this.grnNumber,
    required this.poNumber,
    required this.supplierName,
    required this.invoiceNumber,
    required this.receivedDate,
    required this.receivedBy,
    required this.totalBillAmount,
    this.temperaturePass = true,
    this.temperatureCelsius,
    this.remarks = '',
  });
}

/// Stock Transfer Status
enum StockTransferStatus {
  pending(label: 'Pending', color: Colors.amber),
  inTransit(label: 'In-Transit', color: Colors.blue),
  received(label: 'Received', color: Colors.teal);

  const StockTransferStatus({required this.label, required this.color});
  final String label;
  final MaterialColor color;
}

/// Stock Transfer Record
class StockTransferRecord {
  final String id;
  final String transferNumber;
  final String fromLocation; // e.g. Central Cold Store
  final String toLocation; // e.g. Kitchen A / Bar
  final DateTime transferDate;
  final String transferredBy;
  final int totalItemsCount;
  final StockTransferStatus status;
  final List<String> items;

  const StockTransferRecord({
    required this.id,
    required this.transferNumber,
    required this.fromLocation,
    required this.toLocation,
    required this.transferDate,
    required this.transferredBy,
    required this.totalItemsCount,
    this.status = StockTransferStatus.received,
    this.items = const [],
  });
}

/// Wastage Reason Codes
enum WastageReason {
  spoilage(label: 'Spoilage / Expiry', icon: Icons.warning_amber_rounded),
  burned(label: 'Burned / Cooking Error', icon: Icons.local_fire_department),
  spill(label: 'Dropped / Spilled', icon: Icons.water_drop_outlined),
  prepLoss(label: 'Excessive Trim Loss', icon: Icons.content_cut),
  tasting(label: 'Chef Tasting / Quality Check', icon: Icons.soup_kitchen);

  const WastageReason({required this.label, required this.icon});
  final String label;
  final IconData icon;
}

/// Wastage Log Record
class WastageRecord {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final String uom;
  final double cost;
  final WastageReason reason;
  final String reportedBy;
  final DateTime reportedAt;
  final String note;

  const WastageRecord({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.uom,
    required this.cost,
    required this.reason,
    required this.reportedBy,
    required this.reportedAt,
    this.note = '',
  });

  DateTime get timestamp => reportedAt;
}

/// Audit Status
enum AuditStatus {
  inProgress(label: 'In Progress', color: Colors.amber),
  completed(label: 'Completed', color: Colors.teal),
  discrepancy(label: 'Discrepancy Found', color: Colors.red);

  const AuditStatus({required this.label, required this.color});
  final String label;
  final MaterialColor color;
}

/// Stock Audit / Stock Taking Record
class StockAuditRecord {
  final String id;
  final String auditNumber;
  final String zone; // Ambient, Cold Store, Bar
  final DateTime auditDate;
  final String auditorName;
  final int totalCountedItems;
  final int discrepancyCount;
  final double netVarianceValue; // Negative is deficit, positive is surplus
  final bool isReconciled;
  final AuditStatus status;

  const StockAuditRecord({
    required this.id,
    required this.auditNumber,
    required this.zone,
    required this.auditDate,
    required this.auditorName,
    required this.totalCountedItems,
    required this.discrepancyCount,
    required this.netVarianceValue,
    this.isReconciled = false,
    this.status = AuditStatus.completed,
  });

  int get totalItemsCounted => totalCountedItems;
  double get totalDiscrepancyValue => netVarianceValue.abs();
}

typedef StockAuditSession = StockAuditRecord;

/// Stock Consumption Record (deductions from POS)
class StockConsumptionRecord {
  final String id;
  final String orderId;
  final String dishName;
  final int quantitySold;
  final DateTime timestamp;
  final List<String> depletedItemsSummary;
  final double estimatedCost;

  const StockConsumptionRecord({
    required this.id,
    required this.orderId,
    required this.dishName,
    required this.quantitySold,
    required this.timestamp,
    required this.depletedItemsSummary,
    required this.estimatedCost,
  });

  int get portionsPrepared => quantitySold;
  double get totalBatchCost => estimatedCost;
  List<String> get deductions => depletedItemsSummary;
}

typedef ConsumptionEvent = StockConsumptionRecord;
