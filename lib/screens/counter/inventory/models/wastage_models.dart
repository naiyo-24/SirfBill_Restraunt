import 'package:flutter/material.dart';

double _toDouble(dynamic val, [double defaultVal = 0.0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? defaultVal;
  return defaultVal;
}

enum WastageReasonType {
  spoilage(label: 'Spoilage / Souring', code: 'SPOILAGE', color: Color(0xFFEF4444), icon: Icons.pest_control_rounded),
  burntRuined(label: 'Burnt / Overcooked', code: 'BURNT_RUINED', color: Color(0xFFEA580C), icon: Icons.local_fire_department_rounded),
  expiry(label: 'Expired Shelf-Life', code: 'EXPIRY', color: Color(0xFFD97706), icon: Icons.timer_off_rounded),
  droppedSpill(label: 'Dropped / Container Spill', code: 'DROPPED_SPILL', color: Color(0xFFB45309), icon: Icons.do_not_disturb_on_total_silence_rounded),
  customerReturn(label: 'Customer Return (Void)', code: 'CUSTOMER_RETURN', color: Color(0xFF7C3AED), icon: Icons.assignment_return_rounded),
  prepTrim(label: 'Prep & Butchery Trim', code: 'PREP_TRIM', color: Color(0xFF0D9488), icon: Icons.content_cut_rounded);

  final String label;
  final String code;
  final Color color;
  final IconData icon;

  const WastageReasonType({
    required this.label,
    required this.code,
    required this.color,
    required this.icon,
  });

  static WastageReasonType fromCode(String? code) {
    final c = (code ?? '').toUpperCase();
    if (c.contains('BURN') || c.contains('RUIN')) return WastageReasonType.burntRuined;
    if (c.contains('EXPIR')) return WastageReasonType.expiry;
    if (c.contains('DROP') || c.contains('SPILL')) return WastageReasonType.droppedSpill;
    if (c.contains('RETURN') || c.contains('VOID')) return WastageReasonType.customerReturn;
    if (c.contains('TRIM') || c.contains('CUT')) return WastageReasonType.prepTrim;
    return WastageReasonType.spoilage;
  }
}

class WastageItemRecord {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final double quantity;
  final String unit;
  final double unitCost;
  final double cost;
  final String wasteReason;
  final String sourceType;
  final String sourceId;
  final String notes;
  final String reportedBy;
  final DateTime reportedAt;

  const WastageItemRecord({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.unit,
    required this.unitCost,
    required this.cost,
    required this.wasteReason,
    required this.sourceType,
    required this.sourceId,
    required this.notes,
    required this.reportedBy,
    required this.reportedAt,
  });

  factory WastageItemRecord.fromJson(Map<String, dynamic> json) {
    return WastageItemRecord(
      id: json['id']?.toString() ?? '',
      ingredientId: json['ingredient_id']?.toString() ?? '',
      ingredientName: json['ingredient_name']?.toString() ?? 'Ingredient',
      quantity: _toDouble(json['quantity']),
      unit: json['unit']?.toString() ?? 'G',
      unitCost: _toDouble(json['unit_cost']),
      cost: _toDouble(json['cost']),
      wasteReason: json['waste_reason']?.toString() ?? 'SPOILAGE',
      sourceType: json['source_type']?.toString() ?? 'waste_log',
      sourceId: json['source_id']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
      reportedBy: json['reported_by']?.toString() ?? 'Staff',
      reportedAt: DateTime.tryParse(json['reported_at']?.toString() ?? '') ?? DateTime.now(),
    );
  }
}

class WastageTopIngredient {
  final String ingredientId;
  final String ingredientName;
  final String unit;
  final double totalQuantityWasted;
  final double totalLossInr;
  final int incidentsCount;

  const WastageTopIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.unit,
    required this.totalQuantityWasted,
    required this.totalLossInr,
    required this.incidentsCount,
  });

  factory WastageTopIngredient.fromJson(Map<String, dynamic> json) {
    return WastageTopIngredient(
      ingredientId: json['ingredient_id']?.toString() ?? '',
      ingredientName: json['ingredient_name']?.toString() ?? 'Ingredient',
      unit: json['unit']?.toString() ?? 'G',
      totalQuantityWasted: _toDouble(json['total_quantity_wasted']),
      totalLossInr: _toDouble(json['total_loss_inr']),
      incidentsCount: (json['incidents_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class WastageSummaryData {
  final bool isActive;
  final int timeframeDays;
  final int totalWasteIncidents;
  final double totalFinancialLossInr;
  final Map<String, double> lossByReasonInr;
  final List<WastageTopIngredient> topWastedIngredients;

  const WastageSummaryData({
    required this.isActive,
    required this.timeframeDays,
    required this.totalWasteIncidents,
    required this.totalFinancialLossInr,
    required this.lossByReasonInr,
    required this.topWastedIngredients,
  });

  factory WastageSummaryData.fromJson(Map<String, dynamic> json) {
    final rawByReason = json['loss_by_reason_inr'] is Map ? (json['loss_by_reason_inr'] as Map) : {};
    final Map<String, double> reasonsMap = {};
    rawByReason.forEach((k, v) {
      reasonsMap[k.toString()] = _toDouble(v);
    });

    final rawTop = json['top_wasted_ingredients'] is List ? (json['top_wasted_ingredients'] as List) : [];

    return WastageSummaryData(
      isActive: (json['status']?.toString().toUpperCase() == 'ACTIVE'),
      timeframeDays: (json['timeframe_days'] as num?)?.toInt() ?? 30,
      totalWasteIncidents: (json['total_waste_incidents'] as num?)?.toInt() ?? 0,
      totalFinancialLossInr: _toDouble(json['total_financial_loss_inr']),
      lossByReasonInr: reasonsMap,
      topWastedIngredients: rawTop.map((e) => WastageTopIngredient.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
