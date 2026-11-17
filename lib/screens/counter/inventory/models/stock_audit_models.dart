import 'package:flutter/material.dart';

double _toDouble(dynamic val, [double defaultVal = 0.0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? defaultVal;
  return defaultVal;
}

enum AuditItemStatus {
  matched(label: 'MATCHED', color: Color(0xFF10B981)),
  surplus(label: 'SURPLUS', color: Color(0xFF0EA5E9)),
  deficit(label: 'DEFICIT', color: Color(0xFFEF4444));

  final String label;
  final Color color;
  const AuditItemStatus({required this.label, required this.color});

  static AuditItemStatus fromString(String? val) {
    final s = (val ?? '').toUpperCase();
    if (s.contains('SURPLUS')) return AuditItemStatus.surplus;
    if (s.contains('DEFICIT')) return AuditItemStatus.deficit;
    return AuditItemStatus.matched;
  }
}

class StockAuditBatchSummary {
  final String auditBatchId;
  final DateTime auditDate;
  final DateTime createdAt;
  final String outletId;
  final String auditorName;
  final int itemsAdjusted;
  final double totalSurplusRupees;
  final double totalDeficitRupees;
  final double netVarianceRupees;

  const StockAuditBatchSummary({
    required this.auditBatchId,
    required this.auditDate,
    required this.createdAt,
    required this.outletId,
    required this.auditorName,
    required this.itemsAdjusted,
    required this.totalSurplusRupees,
    required this.totalDeficitRupees,
    required this.netVarianceRupees,
  });

  factory StockAuditBatchSummary.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    return StockAuditBatchSummary(
      auditBatchId: json['audit_batch_id']?.toString() ?? '',
      auditDate: parseDt(json['audit_date']),
      createdAt: parseDt(json['created_at']),
      outletId: json['outlet_id']?.toString() ?? '',
      auditorName: json['auditor_name']?.toString() ?? 'Manager / Auditor',
      itemsAdjusted: (json['items_adjusted'] as num?)?.toInt() ?? 0,
      totalSurplusRupees: _toDouble(json['total_surplus_rupees']),
      totalDeficitRupees: _toDouble(json['total_deficit_rupees']),
      netVarianceRupees: _toDouble(json['net_variance_rupees']),
    );
  }
}

class StockAuditItemResult {
  final String ingredientId;
  final String ingredientName;
  final String recipeUom;
  final String purchaseUom;
  final double previousStock;
  final double? expectedStock;
  final double physicalCount;
  final double? rawInputCount;
  final double variance;
  final double varianceRupees;
  final AuditItemStatus status;
  final String? notes;

  const StockAuditItemResult({
    required this.ingredientId,
    required this.ingredientName,
    required this.recipeUom,
    required this.purchaseUom,
    required this.previousStock,
    this.expectedStock,
    required this.physicalCount,
    this.rawInputCount,
    required this.variance,
    required this.varianceRupees,
    required this.status,
    this.notes,
  });

  factory StockAuditItemResult.fromJson(Map<String, dynamic> json) {
    return StockAuditItemResult(
      ingredientId: json['ingredient_id']?.toString() ?? '',
      ingredientName: json['ingredient_name']?.toString() ?? 'Ingredient',
      recipeUom: json['recipe_uom']?.toString() ?? 'G',
      purchaseUom: json['purchase_uom']?.toString() ?? '',
      previousStock: _toDouble(json['previous_stock']),
      expectedStock: json['expected_stock'] != null ? _toDouble(json['expected_stock']) : null,
      physicalCount: _toDouble(json['physical_count']),
      rawInputCount: json['raw_input_count'] != null ? _toDouble(json['raw_input_count']) : null,
      variance: _toDouble(json['variance']),
      varianceRupees: _toDouble(json['variance_rupees']),
      status: AuditItemStatus.fromString(json['status']?.toString()),
      notes: json['notes']?.toString(),
    );
  }
}

class StockAuditBatchDetail {
  final String auditBatchId;
  final DateTime auditDate;
  final DateTime? auditStartedAt;
  final String outletId;
  final int totalItemsAudited;
  final int itemsAdjusted;
  final double totalSurplusRupees;
  final double totalDeficitRupees;
  final double netVarianceRupees;
  final String? notes;
  final List<StockAuditItemResult> results;

  const StockAuditBatchDetail({
    required this.auditBatchId,
    required this.auditDate,
    this.auditStartedAt,
    required this.outletId,
    required this.totalItemsAudited,
    required this.itemsAdjusted,
    required this.totalSurplusRupees,
    required this.totalDeficitRupees,
    required this.netVarianceRupees,
    this.notes,
    required this.results,
  });

  factory StockAuditBatchDetail.fromJson(Map<String, dynamic> json) {
    DateTime parseDt(dynamic val) {
      if (val == null) return DateTime.now();
      return DateTime.tryParse(val.toString()) ?? DateTime.now();
    }

    final rawResults = json['results'] is List ? (json['results'] as List) : [];

    return StockAuditBatchDetail(
      auditBatchId: json['audit_batch_id']?.toString() ?? '',
      auditDate: parseDt(json['audit_date']),
      auditStartedAt: json['audit_started_at'] != null ? DateTime.tryParse(json['audit_started_at'].toString()) : null,
      outletId: json['outlet_id']?.toString() ?? '',
      totalItemsAudited: (json['total_items_audited'] as num?)?.toInt() ?? rawResults.length,
      itemsAdjusted: (json['items_adjusted'] as num?)?.toInt() ?? 0,
      totalSurplusRupees: _toDouble(json['total_surplus_rupees']),
      totalDeficitRupees: _toDouble(json['total_deficit_rupees']),
      netVarianceRupees: _toDouble(json['net_variance_rupees']),
      notes: json['notes']?.toString(),
      results: rawResults.map((e) => StockAuditItemResult.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
