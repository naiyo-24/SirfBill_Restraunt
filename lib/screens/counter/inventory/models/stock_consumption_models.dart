double _toDouble(dynamic val, [double defaultVal = 0.0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? defaultVal;
  return defaultVal;
}

class StockConsumptionItem {
  final String id;
  final String orderId;
  final String orderNumber;
  final String dishName;
  final int portions;
  final String ingredientId;
  final String ingredientName;
  final double quantityConsumed;
  final double signedQuantity;
  final String unit;
  final double unitCost;
  final double totalCost;
  final String reason;
  final String notes;
  final DateTime timestamp;

  const StockConsumptionItem({
    required this.id,
    required this.orderId,
    required this.orderNumber,
    required this.dishName,
    required this.portions,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityConsumed,
    required this.signedQuantity,
    required this.unit,
    required this.unitCost,
    required this.totalCost,
    required this.reason,
    required this.notes,
    required this.timestamp,
  });

  factory StockConsumptionItem.fromJson(Map<String, dynamic> json) {
    return StockConsumptionItem(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? '',
      orderNumber: json['order_number']?.toString() ?? 'ORDER',
      dishName: json['dish_name']?.toString() ?? 'Dish Consumption',
      portions: (json['portions'] as num?)?.toInt() ?? 1,
      ingredientId: json['ingredient_id']?.toString() ?? '',
      ingredientName: json['ingredient_name']?.toString() ?? 'Ingredient',
      quantityConsumed: _toDouble(json['quantity_consumed']),
      signedQuantity: _toDouble(json['signed_quantity']),
      unit: json['unit']?.toString() ?? 'G',
      unitCost: _toDouble(json['unit_cost']),
      totalCost: _toDouble(json['total_cost']),
      reason: json['reason']?.toString() ?? 'ORDER_CONSUMPTION',
      notes: json['notes']?.toString() ?? '',
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class StockConsumptionGroup {
  final String id;
  final String orderId;
  final String rawOrderId;
  final String dishName;
  final int portionsPrepared;
  final DateTime timestamp;
  final String reason;
  final double totalBatchCost;
  final List<String> deductions;

  const StockConsumptionGroup({
    required this.id,
    required this.orderId,
    required this.rawOrderId,
    required this.dishName,
    required this.portionsPrepared,
    required this.timestamp,
    required this.reason,
    required this.totalBatchCost,
    required this.deductions,
  });

  factory StockConsumptionGroup.fromJson(Map<String, dynamic> json) {
    final rawDeductions = json['deductions'] is List ? (json['deductions'] as List) : [];
    return StockConsumptionGroup(
      id: json['id']?.toString() ?? '',
      orderId: json['order_id']?.toString() ?? 'KOT',
      rawOrderId: json['raw_order_id']?.toString() ?? '',
      dishName: json['dish_name']?.toString() ?? 'Dish',
      portionsPrepared: (json['portions_prepared'] as num?)?.toInt() ?? 1,
      timestamp: DateTime.tryParse(json['timestamp']?.toString() ?? '') ?? DateTime.now(),
      reason: json['reason']?.toString() ?? 'ORDER_CONSUMPTION',
      totalBatchCost: _toDouble(json['total_batch_cost']),
      deductions: rawDeductions.map((e) => e.toString()).toList(),
    );
  }
}

class StockConsumptionStreamData {
  final bool isActive;
  final int totalRecords;
  final double totalConsumptionInr;
  final double totalReversalsInr;
  final double totalWastageInr;
  final List<StockConsumptionGroup> events;
  final List<StockConsumptionItem> ledgerStream;

  const StockConsumptionStreamData({
    required this.isActive,
    required this.totalRecords,
    required this.totalConsumptionInr,
    required this.totalReversalsInr,
    required this.totalWastageInr,
    required this.events,
    required this.ledgerStream,
  });

  factory StockConsumptionStreamData.fromJson(Map<String, dynamic> json) {
    final summary = json['summary'] as Map<String, dynamic>? ?? {};
    final rawEvents = json['events'] is List ? (json['events'] as List) : [];
    final rawLedger = json['ledger_stream'] is List ? (json['ledger_stream'] as List) : [];

    return StockConsumptionStreamData(
      isActive: (json['status']?.toString().toUpperCase() == 'ACTIVE'),
      totalRecords: (json['total_records'] as num?)?.toInt() ?? 0,
      totalConsumptionInr: _toDouble(summary['total_consumption_inr']),
      totalReversalsInr: _toDouble(summary['total_reversals_inr']),
      totalWastageInr: _toDouble(summary['total_wastage_inr']),
      events: rawEvents.map((e) => StockConsumptionGroup.fromJson(e as Map<String, dynamic>)).toList(),
      ledgerStream: rawLedger.map((e) => StockConsumptionItem.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
