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
  final String ingredientId;
  final String ingredientName;
  final double orderedQty;
  final double receivedQty;
  final String uom;
  final double unitPrice;

  const PurchaseOrderItem({
    required this.ingredientId,
    required this.ingredientName,
    required this.orderedQty,
    this.receivedQty = 0.0,
    required this.uom,
    required this.unitPrice,
  });

  double get totalPrice => orderedQty * unitPrice;
}

/// Purchase Order Model
class PurchaseOrder {
  final String id;
  final String poNumber;
  final String supplierId;
  final String supplierName;
  final DateTime orderDate;
  final DateTime expectedDeliveryDate;
  final POStatus status;
  final List<PurchaseOrderItem> items;
  final double totalAmount;
  final String notes;

  const PurchaseOrder({
    required this.id,
    required this.poNumber,
    required this.supplierId,
    required this.supplierName,
    required this.orderDate,
    required this.expectedDeliveryDate,
    required this.status,
    required this.items,
    required this.totalAmount,
    this.notes = '',
  });

  factory PurchaseOrder.fromPurchaseBill(Map<String, dynamic> json) {
    final statusStr = (json['payment_status'] ?? json['status'] ?? '').toString().toLowerCase();
    POStatus st = POStatus.sent;
    if (statusStr.contains('paid') || statusStr.contains('completed')) {
      st = POStatus.completed;
    } else if (statusStr.contains('partial')) {
      st = POStatus.partiallyReceived;
    } else if (statusStr.contains('cancel')) {
      st = POStatus.cancelled;
    }

    final billDateStr = json['bill_date'] ?? json['created_at'];
    final dt = billDateStr != null ? DateTime.tryParse(billDateStr.toString()) ?? DateTime.now() : DateTime.now();

    final List itemsJson = json['items'] is List ? json['items'] : [];
    final items = itemsJson.map((it) {
      return PurchaseOrderItem(
        ingredientId: (it['ingredient_id'] ?? it['item_id'] ?? '').toString(),
        ingredientName: (it['name'] ?? it['item_name'] ?? 'Raw Material').toString(),
        orderedQty: (it['quantity'] is num) ? (it['quantity'] as num).toDouble() : 1.0,
        receivedQty: (it['received_quantity'] is num) ? (it['received_quantity'] as num).toDouble() : 1.0,
        uom: (it['unit'] ?? 'KG').toString(),
        unitPrice: (it['cost_price'] is num) ? (it['cost_price'] as num).toDouble() : 0.0,
      );
    }).toList();

    return PurchaseOrder(
      id: json['id']?.toString() ?? '',
      poNumber: json['invoice_no']?.toString() ?? 'PO-${json['id']?.toString().substring(0, 6) ?? '001'}',
      supplierId: json['distributor_id']?.toString() ?? '',
      supplierName: json['distributor_name']?.toString() ?? json['supplier_name']?.toString() ?? 'Direct Supplier',
      orderDate: dt,
      expectedDeliveryDate: dt.add(const Duration(days: 2)),
      status: st,
      items: items,
      totalAmount: (json['total_amount'] is num) ? (json['total_amount'] as num).toDouble() : 0.0,
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
