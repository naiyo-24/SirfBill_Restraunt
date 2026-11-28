class HardwareProduct {
  final String id;
  final String sku;
  final String name;
  final String category;
  final String brand;
  final String modelNumber;
  final String shortDescription;
  final String description;
  final Map<String, dynamic> specifications;
  final List<String> features;
  final double price;
  final double? offerPrice;
  final double mrp;
  final double taxRate;
  final String primaryImageUrl;
  final List<String> images;
  final int stockQuantity;
  final bool inStock;
  final int warrantyMonths;
  final bool isPopular;
  final bool isFeatured;
  final bool isActive;
  final int sortOrder;
  final DateTime? createdAt;

  const HardwareProduct({
    required this.id,
    required this.sku,
    required this.name,
    required this.category,
    this.brand = 'SirfBill',
    this.modelNumber = '',
    this.shortDescription = '',
    this.description = '',
    this.specifications = const {},
    this.features = const [],
    required this.price,
    this.offerPrice,
    required this.mrp,
    this.taxRate = 18.0,
    this.primaryImageUrl = '',
    this.images = const [],
    this.stockQuantity = 10,
    this.inStock = true,
    this.warrantyMonths = 12,
    this.isPopular = false,
    this.isFeatured = false,
    this.isActive = true,
    this.sortOrder = 0,
    this.createdAt,
  });

  double get effectivePrice =>
      (offerPrice != null && offerPrice! > 0) ? offerPrice! : price;

  double get strikePrice {
    if (offerPrice != null && offerPrice! > 0) {
      if (mrp > offerPrice!) return mrp;
      if (price > offerPrice!) return price;
    }
    return mrp;
  }

  int get discountPercentage {
    final base = strikePrice;
    final current = effectivePrice;
    if (base > current && base > 0) {
      return (((base - current) / base) * 100).round();
    }
    return 0;
  }

  String get categoryDisplay {
    switch (category.toUpperCase()) {
      case 'PRINTER':
        return 'Printers';
      case 'POS_TERMINAL':
        return 'POS Terminals';
      case 'HANDHELD_PDA':
        return 'Handhelds';
      case 'KDS_DISPLAY':
        return 'Kitchen KDS';
      case 'CASH_DRAWER':
        return 'Cash Drawers';
      case 'SCANNER':
        return 'Scanners';
      case 'PAPER_ROLLS':
        return 'Paper Rolls';
      case 'ACCESSORY':
        return 'Accessories';
      default:
        return category.replaceAll('_', ' ');
    }
  }

  factory HardwareProduct.fromJson(Map<String, dynamic> json) {
    List<String> parseList(dynamic val) {
      if (val is List) return val.map((e) => e.toString()).toList();
      return [];
    }

    Map<String, dynamic> parseMap(dynamic val) {
      if (val is Map) return Map<String, dynamic>.from(val);
      return {};
    }

    return HardwareProduct(
      id: (json['id'] ?? '').toString(),
      sku: (json['sku'] ?? '').toString(),
      name: (json['name'] ?? 'Hardware Item').toString(),
      category: (json['category'] ?? 'ACCESSORY').toString(),
      brand: (json['brand'] ?? 'SirfBill').toString(),
      modelNumber: (json['model_number'] ?? '').toString(),
      shortDescription: (json['short_description'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      specifications: parseMap(json['specifications']),
      features: parseList(json['features']),
      price: double.tryParse((json['price'] ?? 0).toString()) ?? 0.0,
      offerPrice: json['offer_price'] != null ? double.tryParse(json['offer_price'].toString()) : null,
      mrp: double.tryParse((json['mrp'] ?? json['price'] ?? 0).toString()) ?? 0.0,
      taxRate: double.tryParse((json['tax_rate'] ?? 18).toString()) ?? 18.0,
      primaryImageUrl: (json['primary_image_url'] ?? '').toString(),
      images: parseList(json['images']),
      stockQuantity: int.tryParse((json['stock_quantity'] ?? 0).toString()) ?? 0,
      inStock: json['in_stock'] ?? (int.tryParse((json['stock_quantity'] ?? 0).toString()) ?? 0) > 0,
      warrantyMonths: int.tryParse((json['warranty_months'] ?? 12).toString()) ?? 12,
      isPopular: json['is_popular'] ?? false,
      isFeatured: json['is_featured'] ?? false,
      isActive: json['is_active'] ?? true,
      sortOrder: int.tryParse((json['sort_order'] ?? 0).toString()) ?? 0,
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) : null,
    );
  }

  Map<String, dynamic> toJson() => {
        if (id.isNotEmpty) 'id': id,
        'sku': sku,
        'name': name,
        'category': category,
        'brand': brand,
        'model_number': modelNumber,
        'short_description': shortDescription,
        'description': description,
        'specifications': specifications,
        'features': features,
        'price': price,
        'mrp': mrp,
        'tax_rate': taxRate,
        'primary_image_url': primaryImageUrl,
        'images': images,
        'stock_quantity': stockQuantity,
        'in_stock': inStock,
        'warranty_months': warrantyMonths,
        'is_popular': isPopular,
        'is_featured': isFeatured,
        'is_active': isActive,
        'sort_order': sortOrder,
      };
}

class HardwareCategoryInfo {
  final String key;
  final String name;
  final int deviceCount;
  final String description;
  final String icon;

  const HardwareCategoryInfo({
    required this.key,
    required this.name,
    this.deviceCount = 0,
    this.description = '',
    this.icon = 'storefront',
  });

  factory HardwareCategoryInfo.fromJson(Map<String, dynamic> json) {
    return HardwareCategoryInfo(
      key: (json['key'] ?? json['category'] ?? json['id'] ?? '').toString(),
      name: (json['name'] ?? json['title'] ?? '').toString(),
      deviceCount: int.tryParse((json['device_count'] ?? json['count'] ?? 0).toString()) ?? 0,
      description: (json['description'] ?? '').toString(),
      icon: (json['icon'] ?? 'storefront').toString(),
    );
  }
}

class HardwareOrderModel {
  final String id;
  final String orderNumber;
  final String? tenantId;
  final String? outletId;
  final String productId;
  final String? productName;
  final int quantity;
  final double totalPrice;
  final String contactName;
  final String contactPhone;
  final String shippingAddress;
  final String city;
  final String pincode;
  final String status;
  final String? trackingNumber;
  final String? courierPartner;
  final DateTime createdAt;

  const HardwareOrderModel({
    required this.id,
    required this.orderNumber,
    this.tenantId,
    this.outletId,
    required this.productId,
    this.productName,
    required this.quantity,
    required this.totalPrice,
    required this.contactName,
    required this.contactPhone,
    required this.shippingAddress,
    required this.city,
    required this.pincode,
    this.status = 'NEW',
    this.trackingNumber,
    this.courierPartner,
    required this.createdAt,
  });

  factory HardwareOrderModel.fromJson(Map<String, dynamic> json) {
    return HardwareOrderModel(
      id: (json['id'] ?? '').toString(),
      orderNumber: (json['order_number'] ?? 'HWO-ORD').toString(),
      tenantId: json['tenant_id']?.toString(),
      outletId: json['outlet_id']?.toString(),
      productId: (json['product_id'] ?? '').toString(),
      productName: json['product_name']?.toString() ?? json['product']?['name']?.toString(),
      quantity: int.tryParse((json['quantity'] ?? 1).toString()) ?? 1,
      totalPrice: double.tryParse((json['total_price'] ?? 0).toString()) ?? 0.0,
      contactName: (json['contact_name'] ?? json['name'] ?? '').toString(),
      contactPhone: (json['contact_phone'] ?? json['phone'] ?? '').toString(),
      shippingAddress: (json['shipping_address'] ?? '').toString(),
      city: (json['city'] ?? '').toString(),
      pincode: (json['pincode'] ?? '').toString(),
      status: (json['status'] ?? 'NEW').toString(),
      trackingNumber: json['tracking_number']?.toString(),
      courierPartner: json['courier_partner']?.toString(),
      createdAt: json['created_at'] != null ? DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now() : DateTime.now(),
    );
  }
}
