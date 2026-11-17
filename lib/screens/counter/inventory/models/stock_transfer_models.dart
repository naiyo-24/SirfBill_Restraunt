import 'package:flutter/material.dart';

enum StockTransferType {
  interBranch(label: 'Inter-Branch', description: 'Central Commissary ➔ Outlet Branch'),
  interStation(label: 'Inter-Station', description: 'Central Chiller ➔ Prep / Kitchen Station');

  final String label;
  final String description;
  const StockTransferType({required this.label, required this.description});

  static StockTransferType fromString(String? val) {
    if (val != null && val.toUpperCase().contains('STATION')) {
      return StockTransferType.interStation;
    }
    return StockTransferType.interBranch;
  }
}

enum StockTransferStatus {
  draft(label: 'Draft', color: Colors.grey),
  inTransit(label: 'In Transit', color: Colors.blue),
  completed(label: 'Completed', color: Colors.teal),
  cancelled(label: 'Cancelled', color: Colors.red);

  final String label;
  final MaterialColor color;
  const StockTransferStatus({required this.label, required this.color});

  static StockTransferStatus fromString(String? val) {
    final s = (val ?? '').toUpperCase();
    if (s.contains('TRANSIT')) return StockTransferStatus.inTransit;
    if (s.contains('COMPLETE') || s.contains('RECEIVE')) return StockTransferStatus.completed;
    if (s.contains('CANCEL')) return StockTransferStatus.cancelled;
    return StockTransferStatus.draft;
  }
}

class StockTransferItem {
  final String id;
  final String transferId;
  final String ingredientId;
  final String? destinationIngredientId;
  final String ingredientName;
  final String sku;
  final String unit; // Recipe UOM (G, ML, PCS)
  final double quantityRequested;
  final double quantityDispatched;
  final double quantityReceived;
  final double quantityVariance; // Dispatched - Received
  final double unitCost;
  final double totalCost;
  final String varianceReason;
  final String? batchNumber;
  final DateTime? expiryDate;

  const StockTransferItem({
    required this.id,
    required this.transferId,
    required this.ingredientId,
    this.destinationIngredientId,
    required this.ingredientName,
    this.sku = '',
    required this.unit,
    this.quantityRequested = 0.0,
    this.quantityDispatched = 0.0,
    this.quantityReceived = 0.0,
    this.quantityVariance = 0.0,
    this.unitCost = 0.0,
    this.totalCost = 0.0,
    this.varianceReason = '',
    this.batchNumber,
    this.expiryDate,
  });

  factory StockTransferItem.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v, [double def = 0.0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    return StockTransferItem(
      id: json['id']?.toString() ?? '',
      transferId: json['transfer_id']?.toString() ?? '',
      ingredientId: json['ingredient_id']?.toString() ?? '',
      destinationIngredientId: json['destination_ingredient_id']?.toString(),
      ingredientName: json['ingredient_name']?.toString() ?? 'Commodity',
      sku: json['sku']?.toString() ?? '',
      unit: json['unit']?.toString() ?? 'G',
      quantityRequested: parseNum(json['quantity_requested'] ?? json['quantity']),
      quantityDispatched: parseNum(json['quantity_dispatched'] ?? json['quantity']),
      quantityReceived: parseNum(json['quantity_received']),
      quantityVariance: parseNum(json['quantity_variance']),
      unitCost: parseNum(json['unit_cost']),
      totalCost: parseNum(json['total_cost']),
      varianceReason: json['variance_reason']?.toString() ?? '',
      batchNumber: json['batch_number']?.toString(),
      expiryDate: json['expiry_date'] != null ? DateTime.tryParse(json['expiry_date'].toString()) : null,
    );
  }
}

class StockTransferHeader {
  final String id;
  final String tenantId;
  final String transferNumber;
  final StockTransferType transferType;
  final String fromOutletId;
  final String fromOutletName;
  final String toOutletId;
  final String toOutletName;
  final String fromStation;
  final String toStation;
  final StockTransferStatus status;
  final String vehicleNumber;
  final String driverName;
  final String driverPhone;
  final int totalItems;
  final double totalValuation;
  final String notes;
  final DateTime createdAt;
  final DateTime? dispatchedAt;
  final DateTime? receivedAt;
  final String transferredBy;
  final List<StockTransferItem> items;

  const StockTransferHeader({
    required this.id,
    this.tenantId = '',
    required this.transferNumber,
    required this.transferType,
    this.fromOutletId = '',
    this.fromOutletName = '',
    this.toOutletId = '',
    this.toOutletName = '',
    this.fromStation = '',
    this.toStation = '',
    this.status = StockTransferStatus.draft,
    this.vehicleNumber = '',
    this.driverName = '',
    this.driverPhone = '',
    this.totalItems = 0,
    this.totalValuation = 0.0,
    this.notes = '',
    required this.createdAt,
    this.dispatchedAt,
    this.receivedAt,
    this.transferredBy = 'Store Staff',
    this.items = const [],
  });

  factory StockTransferHeader.fromJson(Map<String, dynamic> json) {
    double parseNum(dynamic v, [double def = 0.0]) {
      if (v == null) return def;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? def;
    }

    final List rawItems = json['items'] is List ? json['items'] : [];
    final itemsList = rawItems.map((it) => StockTransferItem.fromJson(Map<String, dynamic>.from(it))).toList();

    return StockTransferHeader(
      id: json['id']?.toString() ?? '',
      tenantId: json['tenant_id']?.toString() ?? '',
      transferNumber: json['transfer_number']?.toString() ?? 'ST-000',
      transferType: StockTransferType.fromString(json['transfer_type']?.toString()),
      fromOutletId: json['from_outlet_id']?.toString() ?? '',
      fromOutletName: json['from_outlet_name']?.toString() ?? json['from_location'] ?? '',
      toOutletId: json['to_outlet_id']?.toString() ?? '',
      toOutletName: json['to_outlet_name']?.toString() ?? json['to_location'] ?? '',
      fromStation: json['from_station']?.toString() ?? json['from_location'] ?? 'Main Store',
      toStation: json['to_station']?.toString() ?? json['to_location'] ?? 'Destination Station',
      status: StockTransferStatus.fromString(json['status']?.toString()),
      vehicleNumber: json['vehicle_number']?.toString() ?? '',
      driverName: json['driver_name']?.toString() ?? '',
      driverPhone: json['driver_phone']?.toString() ?? '',
      totalItems: json['total_items'] is int ? json['total_items'] : (json['total_items_count'] is int ? json['total_items_count'] : itemsList.length),
      totalValuation: parseNum(json['total_valuation']),
      notes: json['notes']?.toString() ?? '',
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
      dispatchedAt: json['dispatched_at'] != null ? DateTime.tryParse(json['dispatched_at'].toString()) : null,
      receivedAt: json['received_at'] != null ? DateTime.tryParse(json['received_at'].toString()) : null,
      transferredBy: json['transferred_by']?.toString() ?? json['initiated_by_name']?.toString() ?? 'Store Manager',
      items: itemsList,
    );
  }

  String get fromDisplayLocation {
    if (transferType == StockTransferType.interBranch) {
      return fromOutletName.isNotEmpty ? fromOutletName : (fromStation.isNotEmpty ? fromStation : 'Source Branch');
    }
    return fromStation.isNotEmpty ? fromStation : 'Central Store';
  }

  String get toDisplayLocation {
    if (transferType == StockTransferType.interBranch) {
      return toOutletName.isNotEmpty ? toOutletName : (toStation.isNotEmpty ? toStation : 'Target Branch');
    }
    return toStation.isNotEmpty ? toStation : 'Destination Station';
  }
}
