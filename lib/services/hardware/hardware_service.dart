import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_client.dart';
import '../../models/hardware_product_model.dart';
import '../inventory_service.dart';

class HardwareService {
  static Dio get _dio => ApiClient().dio;

  /// 1. Fetch hardware categories
  static Future<List<HardwareCategoryInfo>> fetchCategories() async {
    try {
      final res = await _dio.get('/api/hardware/categories');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['categories'] ?? []);
        return list.map((json) => HardwareCategoryInfo.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Error fetching hardware categories: $e');
    }
    return _fallbackCategories;
  }

  /// 2. Fetch hardware products list
  static Future<List<HardwareProduct>> fetchProducts({
    String? category,
    String? search,
    bool? inStockOnly,
    bool? popularOnly,
  }) async {
    try {
      final res = await _dio.get(
        '/api/hardware/products',
        queryParameters: {
          if (category != null && category.isNotEmpty && category != 'ALL') 'category': category,
          if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
          if (inStockOnly == true) 'in_stock_only': true,
          if (popularOnly == true) 'popular_only': true,
        },
      );

      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['products'] ?? res.data['items'] ?? []);
        if (list.isNotEmpty) {
          return list.map((json) => HardwareProduct.fromJson(Map<String, dynamic>.from(json))).toList();
        }
      }
    } catch (e) {
      debugPrint('Error fetching hardware products: $e');
    }
    return _fallbackProducts(category: category, search: search);
  }

  /// 3. Fetch single hardware product details
  static Future<HardwareProduct?> fetchProductDetails(String productId) async {
    try {
      final res = await _dio.get('/api/hardware/products/$productId');
      if (res.statusCode == 200 && res.data != null) {
        return HardwareProduct.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error fetching product details ($productId): $e');
    }
    return null;
  }

  /// 4. Admin: Create new hardware product
  static Future<HardwareProduct?> createProduct(Map<String, dynamic> data) async {
    try {
      final res = await _dio.post('/api/hardware/products', data: data);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return HardwareProduct.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error creating hardware product: $e');
      rethrow;
    }
    return null;
  }

  /// 5. Admin: Update hardware product
  static Future<HardwareProduct?> updateProduct(String productId, Map<String, dynamic> data) async {
    try {
      final res = await _dio.patch('/api/hardware/products/$productId', data: data);
      if (res.statusCode == 200) {
        return HardwareProduct.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error updating hardware product: $e');
      rethrow;
    }
    return null;
  }

  /// 6. Admin: Soft delete / deactivate hardware product
  static Future<bool> deleteProduct(String productId) async {
    try {
      final res = await _dio.delete('/api/hardware/products/$productId');
      return res.statusCode == 200 || res.statusCode == 204;
    } catch (e) {
      debugPrint('Error deleting hardware product: $e');
      return false;
    }
  }

  /// 7. Admin / Setup: Seed hardware catalog
  static Future<bool> seedCatalog() async {
    try {
      final res = await _dio.post('/api/hardware/seed');
      return res.statusCode == 200 || res.statusCode == 201;
    } catch (e) {
      debugPrint('Error seeding hardware catalog: $e');
      return false;
    }
  }

  /// 8. Place Hardware Order / Demo Inquiry
  static Future<HardwareOrderModel?> createOrder({
    required String productId,
    required int quantity,
    required String contactName,
    required String contactPhone,
    required String shippingAddress,
    required String city,
    required String pincode,
  }) async {
    try {
      String outletId = '';
      try {
        outletId = await InventoryService.getShopId();
      } catch (_) {}

      final payload = {
        'product_id': productId,
        'quantity': quantity,
        'contact_name': contactName,
        'contact_phone': contactPhone,
        'shipping_address': shippingAddress,
        'city': city,
        'pincode': pincode,
        if (outletId.isNotEmpty) 'outlet_id': outletId,
      };

      final res = await _dio.post('/api/hardware/orders', data: payload);
      if (res.statusCode == 200 || res.statusCode == 201) {
        return HardwareOrderModel.fromJson(Map<String, dynamic>.from(res.data));
      }
    } catch (e) {
      debugPrint('Error placing hardware order: $e');
      rethrow;
    }
    return null;
  }

  /// 9. Fetch hardware orders placed by current restaurant tenant
  static Future<List<HardwareOrderModel>> fetchOrders() async {
    try {
      final res = await _dio.get('/api/hardware/orders');
      if (res.statusCode == 200 && res.data != null) {
        final List list = res.data is List ? res.data : (res.data['orders'] ?? []);
        return list.map((json) => HardwareOrderModel.fromJson(Map<String, dynamic>.from(json))).toList();
      }
    } catch (e) {
      debugPrint('Error fetching hardware orders: $e');
    }
    return [];
  }

  /// 10. Update hardware order fulfillment status (Admin)
  static Future<bool> updateOrderStatus(
    String orderId, {
    required String status,
    String? trackingNumber,
    String? courierPartner,
  }) async {
    try {
      final res = await _dio.patch(
        '/api/hardware/orders/$orderId',
        data: {
          'status': status,
          if (trackingNumber != null) 'tracking_number': trackingNumber,
          if (courierPartner != null) 'courier_partner': courierPartner,
        },
      );
      return res.statusCode == 200;
    } catch (e) {
      debugPrint('Error updating order status: $e');
      return false;
    }
  }

  // Fallback defaults aligned with backend seed catalog
  static const List<HardwareCategoryInfo> _fallbackCategories = [
    HardwareCategoryInfo(key: 'ALL', name: 'All Products', deviceCount: 6, icon: 'storefront'),
    HardwareCategoryInfo(key: 'PRINTER', name: 'Printers', deviceCount: 1, icon: 'print'),
    HardwareCategoryInfo(key: 'POS_TERMINAL', name: 'POS Terminals', deviceCount: 1, icon: 'point_of_sale'),
    HardwareCategoryInfo(key: 'HANDHELD_PDA', name: 'Handhelds', deviceCount: 1, icon: 'phone_android'),
    HardwareCategoryInfo(key: 'CASH_DRAWER', name: 'Cash Drawers', deviceCount: 1, icon: 'archive'),
    HardwareCategoryInfo(key: 'SCANNER', name: 'Scanners', deviceCount: 1, icon: 'qr_code_scanner'),
    HardwareCategoryInfo(key: 'PAPER_ROLLS', name: 'Paper Rolls', deviceCount: 1, icon: 'receipt_long'),
  ];

  static List<HardwareProduct> _fallbackProducts({String? category, String? search}) {
    final list = [
      const HardwareProduct(
        id: 'seed-printer-80mm',
        sku: 'SB-PRN-80MM-PRO',
        name: 'SirfBill 80mm High-Speed Thermal Receipt & KOT Printer',
        category: 'PRINTER',
        brand: 'SirfBill',
        modelNumber: 'SB-80T Pro',
        shortDescription: 'Triple interface (USB + LAN + Bluetooth) auto-cutter thermal printer for bills & kitchen KOTs.',
        description: 'Industrial grade 80mm thermal receipt printer engineered specifically for high-volume restaurants. High-speed 260mm/s dispatch, auto-cutter with 1.5M cut lifespan, and native ESC/POS compatibility.',
        price: 6999,
        mrp: 11999,
        taxRate: 18.0,
        stockQuantity: 45,
        inStock: true,
        warrantyMonths: 12,
        isPopular: true,
        isFeatured: true,
        features: [
          '260mm/s Ultra-Fast Printing Speed',
          'Triple Interface: USB + LAN (Ethernet) + Bluetooth',
          'Heavy-Duty Japanese Auto Cutter (1.5 Million Cuts)',
          '100% Plug & Play with SirfBill POS, KOT & Windows/Android/iOS',
        ],
        specifications: {
          'Interfaces': 'USB, LAN RJ45 100Mbps, Bluetooth 4.2',
          'Print Speed': '260 mm/sec',
          'Paper Width': '80mm / 3 inch',
          'Cutter': 'Auto-cutter (Full & Partial cut)',
          'Power': '24V DC / 2.5A adapter',
          'Cash Drawer Kick': 'RJ11 standard trigger',
        },
      ),
      const HardwareProduct(
        id: 'seed-touch-pos',
        sku: 'SB-POS-DUAL-156',
        name: 'All-in-One 15.6" Dual Screen Touch POS Terminal',
        category: 'POS_TERMINAL',
        brand: 'SirfBill',
        modelNumber: 'SB-Touch 15D',
        shortDescription: 'Intel Quad-Core 8GB RAM, 128GB SSD with 10.1" customer-facing UPI QR screen.',
        description: 'Flagship commercial billing terminal. Full HD capacitive multi-touch front screen with a second 10.1" customer display for dynamic bill preview and instant UPI payment QR display.',
        price: 28999,
        mrp: 42000,
        taxRate: 18.0,
        stockQuantity: 18,
        inStock: true,
        warrantyMonths: 12,
        isPopular: true,
        isFeatured: true,
        features: [
          '15.6" HD Capacitive True-Flat Multi-Touch Main Display',
          '10.1" Customer-Facing Secondary Screen for Live Dynamic UPI QR',
          'Spill & Dust Resistant Commercial Metal Alloy Body',
          'Pre-Loaded & Optimized for SirfBill Restaurant Desktop & Web',
        ],
      ),
      const HardwareProduct(
        id: 'seed-handheld-pda',
        sku: 'SB-PDA-55-PRN',
        name: '5.5" Handheld Captain Tablet with Built-in 58mm Printer',
        category: 'HANDHELD_PDA',
        brand: 'SirfBill',
        modelNumber: 'SB-Captain 55',
        shortDescription: 'Android 12, 5000mAh shift battery, 4G LTE/WiFi table captain ordering & billing.',
        description: 'Compact wireless handheld POS for table captains and steward mobile billing. Takes orders at tables, prints instant KOT/receipts with the built-in Seiko printer, and accepts UPI scan payments.',
        price: 13499,
        mrp: 19500,
        taxRate: 18.0,
        stockQuantity: 28,
        inStock: true,
        warrantyMonths: 12,
        isPopular: true,
        features: [
          '5.5" IPS High-Brightness Touchscreen (Readable under sun)',
          'Integrated 58mm High-Speed Thermal Seiko Printer',
          'Dual-Band 2.4G/5G WiFi + 4G SIM Card slot for roving staff',
          'Long-life 5000mAh Battery lasting full 14-hour restaurant shifts',
        ],
      ),
      const HardwareProduct(
        id: 'seed-cash-drawer',
        sku: 'SB-DRW-5B8C-HD',
        name: 'Heavy-Duty Electronic Cash Drawer with RJ11 Trigger',
        category: 'CASH_DRAWER',
        brand: 'SirfBill',
        modelNumber: 'SB-Draw 410',
        shortDescription: '5 Note / 8 Coin slots, reinforced steel ball-bearing rollers, auto-open on receipt.',
        description: 'Robust restaurant cash drawer with emergency lock and auto-kick RJ11 cable that connects directly to the 80mm thermal receipt printer. Springs open automatically upon bill settlement.',
        price: 3499,
        mrp: 5500,
        taxRate: 18.0,
        stockQuantity: 35,
        inStock: true,
        warrantyMonths: 12,
        features: [
          '5 Adjustable Currency Note Slots & 8 Removable Coin Cups',
          'RJ11 Auto-Kick Solenoid triggered on Bill Settlement',
          '3-Position Security Key Lock (Locked, Manual Open, Auto)',
          'Heavy Gauge Steel with Ball-Bearing Rollers (1M+ cycles)',
        ],
      ),
      const HardwareProduct(
        id: 'seed-scanner-2d',
        sku: 'SB-SCN-2D-CRD',
        name: 'Wireless 2D Barcode & QR Code Scanner with Charging Cradle',
        category: 'SCANNER',
        brand: 'SirfBill',
        modelNumber: 'SB-Scan 2D Pro',
        shortDescription: '2.4GHz + Bluetooth, 100m range, rapid screen & paper QR scanning.',
        description: 'Cordless 2D handheld scanner designed for fast grocery items, bottle barcodes, and digital QR vouchers on phone screens. Comes with charging dock and instant auto-pairing.',
        price: 3299,
        mrp: 5200,
        taxRate: 18.0,
        stockQuantity: 50,
        inStock: true,
        warrantyMonths: 12,
        features: [
          'High Precision CMOS sensor reads scratched barcodes & mobile screens',
          'Dual-Mode: 2.4GHz Wireless (100m range) + Bluetooth',
          'Includes USB Charging Cradle & Auto-Sensing Stand',
          'Zero Drivers Required: 100% Plug & Play with SirfBill POS',
        ],
      ),
      const HardwareProduct(
        id: 'seed-paper-rolls',
        sku: 'SB-PPR-80MM-B50',
        name: 'Premium 80mm Thermal Paper Rolls (Box of 50 Rolls)',
        category: 'PAPER_ROLLS',
        brand: 'SirfBill',
        modelNumber: 'SB-Roll 80x50',
        shortDescription: 'BPA-Free, 55 GSM lint-free smooth paper, 10-year print longevity.',
        description: 'High-density top-coated thermal receipt rolls that protect printer thermal print-heads from premature wear. Clean cutting, deep black contrast, and moisture resistant.',
        price: 1899,
        mrp: 2750,
        taxRate: 12.0,
        stockQuantity: 120,
        inStock: true,
        warrantyMonths: 0,
        features: [
          'Box of 50 Standard 80mm x 50m Thermal Paper Rolls',
          'BPA-Free Eco Formula with Pure White 55 GSM Base',
          'Ultra-Dark Contrast Output preventing Head Jam & Carbon Wear',
          'End-of-Roll Red Warning Indicator line',
        ],
      ),
    ];

    return list.where((p) {
      if (category != null && category.isNotEmpty && category != 'ALL') {
        if (p.category.toUpperCase() != category.toUpperCase()) return false;
      }
      if (search != null && search.trim().isNotEmpty) {
        final q = search.trim().toLowerCase();
        return p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.brand.toLowerCase().contains(q) ||
            p.category.toLowerCase().contains(q);
      }
      return true;
    }).toList();
  }
}
