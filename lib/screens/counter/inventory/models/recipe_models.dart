import 'package:flutter/material.dart';

enum RecipeCostStatus {
  ideal(label: 'IDEAL (≤30%)', color: Color(0xFF10B981)),
  warning(label: 'WARNING (30-35%)', color: Color(0xFFF59E0B)),
  criticalSpike(label: 'CRITICAL SPIKE (>35%)', color: Color(0xFFEF4444));

  final String label;
  final Color color;
  const RecipeCostStatus({required this.label, required this.color});

  static RecipeCostStatus fromString(String? val) {
    final s = (val ?? '').toUpperCase();
    if (s.contains('WARN')) return RecipeCostStatus.warning;
    if (s.contains('CRIT') || s.contains('SPIKE')) return RecipeCostStatus.criticalSpike;
    return RecipeCostStatus.ideal;
  }
}

double _toDouble(dynamic val, [double defaultVal = 0.0]) {
  if (val == null) return defaultVal;
  if (val is num) return val.toDouble();
  if (val is String) return double.tryParse(val) ?? defaultVal;
  return defaultVal;
}

class RecipeLineModel {
  final String id;
  final String ingredientId;
  final String ingredientName;
  final double quantityRequired;
  final String unit;
  final double costPerUnit;
  final double lineCost;

  const RecipeLineModel({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityRequired,
    required this.unit,
    required this.costPerUnit,
    required this.lineCost,
  });

  factory RecipeLineModel.fromJson(Map<String, dynamic> json) {
    return RecipeLineModel(
      id: json['id']?.toString() ?? '',
      ingredientId: json['ingredient_id']?.toString() ?? '',
      ingredientName: json['ingredient_name']?.toString() ?? 'Ingredient',
      quantityRequired: _toDouble(json['quantity_required']),
      unit: json['unit']?.toString() ?? 'G',
      costPerUnit: _toDouble(json['cost_per_unit']),
      lineCost: _toDouble(json['line_cost']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'ingredient_id': ingredientId,
      'quantity_required': quantityRequired,
      'unit': unit,
    };
  }
}

class RecipeModel {
  final String id;
  final String? itemId;
  final String itemName;
  final String itemCategory;
  final String? modifierOptionId;
  final String? producedIngredientId;
  final String variantName;
  final double yieldServings;
  final double sellingPrice;
  final double plateCost;
  final double foodCostPercentage;
  final double grossMarginPercentage;
  final RecipeCostStatus costStatus;
  final String? instructions;
  final List<RecipeLineModel> lines;

  const RecipeModel({
    required this.id,
    this.itemId,
    required this.itemName,
    required this.itemCategory,
    this.modifierOptionId,
    this.producedIngredientId,
    required this.variantName,
    required this.yieldServings,
    required this.sellingPrice,
    required this.plateCost,
    required this.foodCostPercentage,
    required this.grossMarginPercentage,
    required this.costStatus,
    this.instructions,
    required this.lines,
  });

  factory RecipeModel.fromJson(Map<String, dynamic> json) {
    final rawLines = json['lines'] is List ? (json['lines'] as List) : [];
    return RecipeModel(
      id: json['id']?.toString() ?? '',
      itemId: json['item_id']?.toString(),
      itemName: json['item_name']?.toString() ?? 'Menu Dish',
      itemCategory: json['item_category']?.toString() ?? 'Culinary',
      modifierOptionId: json['modifier_option_id']?.toString(),
      producedIngredientId: json['produced_ingredient_id']?.toString(),
      variantName: json['variant_name']?.toString() ?? 'Standard',
      yieldServings: _toDouble(json['yield_servings'], 1.0),
      sellingPrice: _toDouble(json['selling_price']),
      plateCost: _toDouble(json['plate_cost']),
      foodCostPercentage: _toDouble(json['food_cost_percentage']),
      grossMarginPercentage: _toDouble(json['gross_margin_percentage']),
      costStatus: RecipeCostStatus.fromString(json['cost_status']?.toString()),
      instructions: json['instructions']?.toString(),
      lines: rawLines.map((e) => RecipeLineModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class RecipeCostBreakdownModel {
  final String ingredientId;
  final String ingredientName;
  final double quantityRequired;
  final String unit;
  final double portionQuantity;
  final double costPerUnit;
  final double lineCost;
  final double costContributionPct;

  const RecipeCostBreakdownModel({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantityRequired,
    required this.unit,
    required this.portionQuantity,
    required this.costPerUnit,
    required this.lineCost,
    required this.costContributionPct,
  });

  factory RecipeCostBreakdownModel.fromJson(Map<String, dynamic> json) {
    return RecipeCostBreakdownModel(
      ingredientId: json['ingredient_id']?.toString() ?? '',
      ingredientName: json['ingredient_name']?.toString() ?? 'Ingredient',
      quantityRequired: _toDouble(json['quantity_required']),
      unit: json['unit']?.toString() ?? 'G',
      portionQuantity: _toDouble(json['portion_quantity']),
      costPerUnit: _toDouble(json['cost_per_unit']),
      lineCost: _toDouble(json['line_cost']),
      costContributionPct: _toDouble(json['cost_contribution_pct']),
    );
  }
}

class RecipeCostingModel {
  final String recipeId;
  final String? itemId;
  final String itemName;
  final String variantName;
  final double yieldServings;
  final double sellingPrice;
  final double plateCost;
  final double foodCostPercentage;
  final double grossMarginPercentage;
  final RecipeCostStatus costStatus;
  final List<RecipeCostBreakdownModel> breakdown;

  const RecipeCostingModel({
    required this.recipeId,
    this.itemId,
    required this.itemName,
    required this.variantName,
    required this.yieldServings,
    required this.sellingPrice,
    required this.plateCost,
    required this.foodCostPercentage,
    required this.grossMarginPercentage,
    required this.costStatus,
    required this.breakdown,
  });

  factory RecipeCostingModel.fromJson(Map<String, dynamic> json) {
    final rawBreakdown = json['breakdown'] is List ? (json['breakdown'] as List) : [];
    return RecipeCostingModel(
      recipeId: json['recipe_id']?.toString() ?? '',
      itemId: json['item_id']?.toString(),
      itemName: json['item_name']?.toString() ?? 'Dish',
      variantName: json['variant_name']?.toString() ?? 'Standard',
      yieldServings: _toDouble(json['yield_servings'], 1.0),
      sellingPrice: _toDouble(json['selling_price']),
      plateCost: _toDouble(json['plate_cost']),
      foodCostPercentage: _toDouble(json['food_cost_percentage']),
      grossMarginPercentage: _toDouble(json['gross_margin_percentage']),
      costStatus: RecipeCostStatus.fromString(json['cost_status']?.toString()),
      breakdown: rawBreakdown.map((e) => RecipeCostBreakdownModel.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}
