import 'package:flutter/material.dart';
export 'inventory_ops_models.dart';

/// 13 Inventory Subsystem Sections
enum InventorySection {
  dashboard(
    title: 'Dashboard',
    subtitle: 'Stock overview, alerts & critical indicators',
    icon: Icons.dashboard_outlined,
    selectedIcon: Icons.dashboard_rounded,
    group: 'Overview',
  ),
  ingredients(
    title: 'Ingredients',
    subtitle: 'Manage raw materials, spices, dairy & meat',
    icon: Icons.inventory_2_outlined,
    selectedIcon: Icons.inventory_2_rounded,
    group: 'Master Data',
  ),
  categories(
    title: 'Categories',
    subtitle: 'Storage zones, cold chain & ingredient classes',
    icon: Icons.category_outlined,
    selectedIcon: Icons.category_rounded,
    group: 'Master Data',
  ),
  suppliers(
    title: 'Suppliers',
    subtitle: 'Vendor contacts, payment terms & catalogues',
    icon: Icons.local_shipping_outlined,
    selectedIcon: Icons.local_shipping_rounded,
    group: 'Master Data',
  ),
  purchaseOrders(
    title: 'Purchase Orders',
    subtitle: 'Generate & track procurement orders',
    icon: Icons.assignment_outlined,
    selectedIcon: Icons.assignment_rounded,
    group: 'Procurement',
  ),
  goodsReceived(
    title: 'Goods Received (GRN)',
    subtitle: 'Inspect & accept vendor deliveries',
    icon: Icons.fact_check_outlined,
    selectedIcon: Icons.fact_check_rounded,
    group: 'Procurement',
  ),
  stockManagement(
    title: 'Stock Management',
    subtitle: 'Live balances, re-order par & manual adjustments',
    icon: Icons.warehouse_outlined,
    selectedIcon: Icons.warehouse_rounded,
    group: 'Stock Control',
  ),
  stockTransfers(
    title: 'Stock Transfers',
    subtitle: 'Inter-outlet & store-to-kitchen allocations',
    icon: Icons.swap_horiz_outlined,
    selectedIcon: Icons.swap_horiz_rounded,
    group: 'Stock Control',
  ),
  recipeManagement(
    title: 'Recipe (BOM)',
    subtitle: 'Ingredient breakdown & food costing per dish',
    icon: Icons.restaurant_menu_outlined,
    selectedIcon: Icons.restaurant_menu_rounded,
    group: 'Culinary',
  ),
  stockConsumption(
    title: 'Stock Consumption',
    subtitle: 'POS order auto-depletions & batch logs',
    icon: Icons.auto_mode_outlined,
    selectedIcon: Icons.auto_mode_rounded,
    group: 'Culinary',
  ),
  wastage(
    title: 'Wastage & Spoilage',
    subtitle: 'Track kitchen waste, expiry & prep loss',
    icon: Icons.delete_sweep_outlined,
    selectedIcon: Icons.delete_sweep_rounded,
    group: 'Quality & Compliance',
  ),
  stockAudit(
    title: 'Stock Audit',
    subtitle: 'Physical counting & variance reconciliation',
    icon: Icons.checklist_rtl_outlined,
    selectedIcon: Icons.checklist_rtl_rounded,
    group: 'Quality & Compliance',
  ),
  reports(
    title: 'Reports & Costing',
    subtitle: 'Valuation, COGS, food cost % & ABC analysis',
    icon: Icons.analytics_outlined,
    selectedIcon: Icons.analytics_rounded,
    group: 'Analytics',
  );

  const InventorySection({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.selectedIcon,
    required this.group,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final IconData selectedIcon;
  final String group;
}

/// Unit of Measure definitions
enum UomCategory { weight, volume, count, pack }

class UnitOfMeasure {
  final String code;
  final String name;
  final UomCategory category;
  final double baseConversionRatio; // e.g., 1 KG = 1000 G

  const UnitOfMeasure({
    required this.code,
    required this.name,
    required this.category,
    this.baseConversionRatio = 1.0,
  });

  static const List<UnitOfMeasure> standardUnits = [
    UnitOfMeasure(code: 'KG', name: 'Kilogram', category: UomCategory.weight, baseConversionRatio: 1000),
    UnitOfMeasure(code: 'G', name: 'Gram', category: UomCategory.weight, baseConversionRatio: 1),
    UnitOfMeasure(code: 'L', name: 'Liter', category: UomCategory.volume, baseConversionRatio: 1000),
    UnitOfMeasure(code: 'ML', name: 'Milliliter', category: UomCategory.volume, baseConversionRatio: 1),
    UnitOfMeasure(code: 'PCS', name: 'Pieces', category: UomCategory.count, baseConversionRatio: 1),
    UnitOfMeasure(code: 'DOZ', name: 'Dozen', category: UomCategory.count, baseConversionRatio: 12),
    UnitOfMeasure(code: 'BAG', name: 'Bag (25kg)', category: UomCategory.pack, baseConversionRatio: 25000),
    UnitOfMeasure(code: 'BOX', name: 'Box/Carton', category: UomCategory.pack, baseConversionRatio: 1),
  ];
}

/// Ingredient Model
class Ingredient {
  final String id;
  final String name;
  final String code;
  final String categoryId;
  final String categoryName;
  final String purchaseUom;
  final String recipeUom;
  final double uomConversionFactor; // 1 purchaseUom = X recipeUom
  final double currentStock; // in recipeUom
  final double minParLevel;
  final double idealParLevel;
  final double costPerPurchaseUnit;
  final String primarySupplierId;
  final String primarySupplierName;
  final String storageLocation;
  final bool isPerishable;
  final int? shelfLifeDays;
  final String? imageUrl;
  final DateTime lastRestockedAt;

  const Ingredient({
    required this.id,
    required this.name,
    required this.code,
    required this.categoryId,
    required this.categoryName,
    required this.purchaseUom,
    required this.recipeUom,
    this.uomConversionFactor = 1.0,
    required this.currentStock,
    required this.minParLevel,
    required this.idealParLevel,
    required this.costPerPurchaseUnit,
    required this.primarySupplierId,
    required this.primarySupplierName,
    required this.storageLocation,
    this.isPerishable = false,
    this.shelfLifeDays,
    this.imageUrl,
    required this.lastRestockedAt,
  });

  double get costPerRecipeUnit =>
      uomConversionFactor > 0 ? (costPerPurchaseUnit / uomConversionFactor) : costPerPurchaseUnit;

  /// Monetary value of current on-hand stock:
  /// (currentStock in recipe UOM / uomConversionFactor) * costPerPurchaseUnit
  double get totalStockValue =>
      uomConversionFactor > 0
          ? ((currentStock / uomConversionFactor) * costPerPurchaseUnit)
          : (currentStock * costPerPurchaseUnit);

  bool get isLowStock => currentStock <= minParLevel && currentStock > 0;
  bool get isOutOfStock => currentStock <= 0;
  double get stockHealthPercent =>
      idealParLevel > 0 ? ((currentStock / idealParLevel) * 100).clamp(0, 100) : 100;

  factory Ingredient.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v, [double fallback = 0.0]) {
      if (v == null) return fallback;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    int? parseInt(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    return Ingredient(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? json['sku']?.toString() ?? '',
      categoryId: json['category_id']?.toString() ?? '',
      categoryName: json['category_name']?.toString() ??
          (json['category'] != null ? json['category']['name']?.toString() ?? '' : ''),
      purchaseUom: json['purchase_uom']?.toString() ?? 'KG',
      recipeUom: json['recipe_uom']?.toString() ?? json['unit']?.toString() ?? 'G',
      uomConversionFactor: parseDouble(json['uom_conversion_factor'], 1.0),
      currentStock: parseDouble(json['current_stock'], 0.0),
      minParLevel: parseDouble(json['min_par_level'] ?? json['reorder_level'], 0.0),
      idealParLevel: parseDouble(json['ideal_par_level'], 0.0),
      costPerPurchaseUnit: parseDouble(json['cost_per_purchase_unit'] ?? json['cost_per_unit'], 0.0),
      primarySupplierId: json['primary_supplier_id']?.toString() ?? '',
      primarySupplierName: json['primary_supplier_name']?.toString() ?? '',
      storageLocation: json['storage_location']?.toString() ?? json['storage_zone']?.toString() ?? '',
      isPerishable: json['is_perishable'] == true,
      shelfLifeDays: parseInt(json['shelf_life_days']),
      imageUrl: json['image_url']?.toString(),
      lastRestockedAt: json['last_restocked_at'] != null
          ? DateTime.tryParse(json['last_restocked_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson({String? outletId}) => {
        if (outletId != null) 'outlet_id': outletId,
        'name': name,
        'code': code,
        if (categoryId.isNotEmpty) 'category_id': categoryId,
        'purchase_uom': purchaseUom,
        'recipe_uom': recipeUom,
        'uom_conversion_factor': uomConversionFactor,
        'current_stock': currentStock,
        'min_par_level': minParLevel,
        'ideal_par_level': idealParLevel,
        'cost_per_purchase_unit': costPerPurchaseUnit,
        if (primarySupplierId.isNotEmpty) 'primary_supplier_id': primarySupplierId,
        'storage_zone': storageLocation,
        'storage_location': storageLocation,
        'is_perishable': isPerishable,
        if (shelfLifeDays != null) 'shelf_life_days': shelfLifeDays,
        if (imageUrl != null && imageUrl!.isNotEmpty) 'image_url': imageUrl,
      };
}

/// Ingredient Category Model
class IngredientCategory {
  final String id;
  final String name;
  final String code;
  final String storageZone; // Ambient, Chilled (0-4°C), Frozen (-18°C), Bar Store
  final int itemCount;
  final Color accentColor;

  const IngredientCategory({
    required this.id,
    required this.name,
    required this.code,
    required this.storageZone,
    this.itemCount = 0,
    this.accentColor = Colors.teal,
  });

  factory IngredientCategory.fromJson(Map<String, dynamic> json) {
    Color parseColor(String? hex) {
      if (hex == null || hex.isEmpty) return const Color(0xFF10B981);
      try {
        final clean = hex.replaceAll('#', '').trim();
        if (clean.length == 6) {
          return Color(int.parse('FF$clean', radix: 16));
        } else if (clean.length == 8) {
          return Color(int.parse(clean, radix: 16));
        }
      } catch (_) {}
      return const Color(0xFF10B981);
    }

    int parseCount(dynamic v) {
      if (v == null) return 0;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? 0;
    }

    return IngredientCategory(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      storageZone: json['storage_zone_temp']?.toString() ?? json['storage_zone']?.toString() ?? 'Ambient',
      itemCount: parseCount(json['items_count'] ?? json['item_count']),
      accentColor: parseColor(json['color_code']?.toString()),
    );
  }

  Map<String, dynamic> toJson({String? outletId}) => {
        if (outletId != null) 'outlet_id': outletId,
        'name': name,
        if (code.isNotEmpty) 'code': code,
        'storage_zone_temp': storageZone,
        'color_code': '#${accentColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
      };
}

/// Supplier Model
class Supplier {
  final String id;
  final String name;
  final String contactPerson;
  final String phone;
  final String email;
  final String gstin;
  final String address;
  final int paymentTermsDays;
  final double rating;
  final int activeOrderCount;

  const Supplier({
    required this.id,
    required this.name,
    required this.contactPerson,
    required this.phone,
    required this.email,
    required this.gstin,
    required this.address,
    this.paymentTermsDays = 15,
    this.rating = 4.5,
    this.activeOrderCount = 0,
  });

  factory Supplier.fromJson(Map<String, dynamic> json) {
    return Supplier(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? json['company_name']?.toString() ?? '',
      contactPerson: json['contact_person']?.toString() ?? json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      gstin: json['gstin']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      paymentTermsDays: json['payment_terms_days'] is int ? json['payment_terms_days'] : 15,
      rating: (json['rating'] is num) ? (json['rating'] as num).toDouble() : 4.5,
      activeOrderCount: json['active_order_count'] is int ? json['active_order_count'] : 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'contact_person': contactPerson,
    'phone': phone,
    'email': email,
    'gstin': gstin,
    'address': address,
    'payment_terms_days': paymentTermsDays,
    'rating': rating,
    'active_order_count': activeOrderCount,
  };
}

/// Recipe Bill of Materials (BOM) Item
class RecipeIngredient {
  final String ingredientId;
  final String ingredientName;
  final double quantity; // in recipeUom
  final String recipeUom;
  final double costPerUnit;
  final double prepYieldPercent; // e.g. 90% for trimmed chicken

  const RecipeIngredient({
    required this.ingredientId,
    required this.ingredientName,
    required this.quantity,
    required this.recipeUom,
    required this.costPerUnit,
    this.prepYieldPercent = 100.0,
  });

  double get effectiveCost {
    final yieldFactor = (prepYieldPercent > 0 ? prepYieldPercent : 100.0) / 100.0;
    return (quantity * costPerUnit) / yieldFactor;
  }
}

/// Recipe Model mapped to POS Dishes
class DishRecipe {
  final String id;
  final String menuItemId;
  final String dishName;
  final String category;
  final double sellingPrice;
  final List<RecipeIngredient> ingredients;
  final int standardPortions;
  final double wastageAllowancePercent;
  final DateTime updatedAt;

  const DishRecipe({
    required this.id,
    required this.menuItemId,
    required this.dishName,
    required this.category,
    required this.sellingPrice,
    required this.ingredients,
    this.standardPortions = 1,
    this.wastageAllowancePercent = 2.0,
    required this.updatedAt,
  });

  double get totalBatchCost =>
      ingredients.fold(0.0, (sum, item) => sum + item.effectiveCost);

  double get costPerPortion =>
      standardPortions > 0 ? (totalBatchCost / standardPortions) : totalBatchCost;

  double get totalCost => costPerPortion;

  double get foodCostPercentage =>
      sellingPrice > 0 ? ((costPerPortion / sellingPrice) * 100) : 0.0;

  double get grossMarginPercentage =>
      sellingPrice > 0 ? (((sellingPrice - costPerPortion) / sellingPrice) * 100) : 0.0;
}
