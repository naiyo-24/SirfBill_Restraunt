import 'package:flutter/material.dart';

// ignore: unused_field
class SubscriptionPlanItem {
  final String id;
  final String planCode;
  final String name;
  final String tag;
  final double price; // Base price from database
  final double? basePrice;
  final double? gstAmount;
  final double? totalPrice;
  final String gstNote;
  final String? priceDisplay;
  final String? totalDisplay;
  final String discountLabel;
  final String currency;
  final String billingCycle;
  final int durationDays;
  final int durationMonths;
  final String description;
  final List<String> features;
  final bool isActive;
  final bool isPopular;
  final bool isCurrent;
  final Color accentColor;
  final IconData icon;

  const SubscriptionPlanItem({
    required this.id,
    this.planCode = 'RESTAURANT_PRO_299',
    required this.name,
    required this.tag,
    required this.price,
    this.basePrice,
    this.gstAmount,
    this.totalPrice,
    this.gstNote = 'GST (18%) Excluded',
    this.priceDisplay,
    this.totalDisplay,
    this.discountLabel = '',
    this.currency = 'INR',
    this.billingCycle = '1 Month',
    this.durationDays = 30,
    this.durationMonths = 1,
    required this.description,
    required this.features,
    this.isActive = true,
    this.isPopular = false,
    this.isCurrent = false,
    required this.accentColor,
    required this.icon,
  });

  double get safeBasePrice {
    if (basePrice != null && basePrice! > 0) return basePrice!;
    return price;
  }

  double get safeGstAmount {
    if (gstAmount != null && gstAmount! > 0) return gstAmount!;
    return double.parse((safeBasePrice * 0.18).toStringAsFixed(2));
  }

  double get safeTotalPrice {
    if (totalPrice != null && totalPrice! > 0) return totalPrice!;
    return double.parse((safeBasePrice + safeGstAmount).toStringAsFixed(2));
  }

  factory SubscriptionPlanItem.fromJson(Map<String, dynamic> json) {
    final code = json['plan_code']?.toString() ?? json['id']?.toString() ?? 'RESTAURANT_PRO_299';
    final rawBase = (json['base_price'] is num)
        ? (json['base_price'] as num).toDouble()
        : ((json['price'] is num) ? (json['price'] as num).toDouble() : 299.0);
    final rawGst = (json['gst_amount'] is num)
        ? (json['gst_amount'] as num).toDouble()
        : double.parse((rawBase * 0.18).toStringAsFixed(2));
    final rawTotal = (json['total_price'] is num)
        ? (json['total_price'] as num).toDouble()
        : double.parse((rawBase + rawGst).toStringAsFixed(2));

    final daysVal = (json['duration_days'] is num) ? (json['duration_days'] as num).toInt() : 30;

    int months = 1;
    if (daysVal >= 360) {
      months = 12;
    } else if (daysVal >= 170) {
      months = 6;
    } else if (daysVal >= 80) {
      months = 3;
    }

    String discount;
    Color accent;
    IconData planIcon;
    String tagLabel;

    if (code.contains('12M') || months == 12) {
      discount = '10% OFF';
      accent = const Color(0xFF8B5CF6);
      planIcon = Icons.stars_rounded;
      tagLabel = 'Best Value • 10% OFF';
    } else if (code.contains('6M') || months == 6) {
      discount = '5% OFF';
      accent = const Color(0xFF6366F1);
      planIcon = Icons.trending_up_rounded;
      tagLabel = 'Save 5% • Semi-Annual';
    } else if (code.contains('3M') || months == 3) {
      discount = 'Quarterly';
      accent = const Color(0xFF0EA5E9);
      planIcon = Icons.date_range_rounded;
      tagLabel = 'Popular • 3 Months';
    } else {
      discount = 'Standard';
      accent = const Color(0xFF10B981);
      planIcon = Icons.workspace_premium_rounded;
      tagLabel = 'Standard Monthly';
    }

    return SubscriptionPlanItem(
      id: json['id']?.toString() ?? code,
      planCode: code,
      name: json['name']?.toString() ?? 'SirfBill Restaurant Pro',
      tag: json['tag']?.toString() ?? tagLabel,
      price: rawBase,
      basePrice: rawBase,
      gstAmount: rawGst,
      totalPrice: rawTotal,
      gstNote: json['gst_note']?.toString() ?? 'GST (18%) Excluded',
      priceDisplay: json['price_display']?.toString(),
      totalDisplay: json['total_display']?.toString(),
      discountLabel: discount,
      currency: json['currency']?.toString() ?? 'INR',
      billingCycle: json['billing_cycle']?.toString() ?? '$months Month${months > 1 ? "s" : ""}',
      durationDays: daysVal,
      durationMonths: months,
      description: json['description']?.toString() ??
          'Complete operational ecosystem with live POS, KDS, recipe consumption & inventory control.',
      features: (json['features'] is List)
          ? (json['features'] as List).map((e) => e.toString()).toList()
          : List<String>.from(kDefaultProFeatures),
      isActive: json['is_active'] == true || json['is_active'] == null,
      isPopular: json['is_popular'] == true || months == 3,
      isCurrent: false,
      accentColor: accent,
      icon: planIcon,
    );
  }

  SubscriptionPlanItem copyWith({
    bool? isCurrent,
    double? price,
    double? basePrice,
    double? gstAmount,
    double? totalPrice,
  }) {
    return SubscriptionPlanItem(
      id: id,
      planCode: planCode,
      name: name,
      tag: tag,
      price: price ?? this.price,
      basePrice: basePrice ?? this.basePrice,
      gstAmount: gstAmount ?? this.gstAmount,
      totalPrice: totalPrice ?? this.totalPrice,
      gstNote: gstNote,
      priceDisplay: priceDisplay,
      totalDisplay: totalDisplay,
      discountLabel: discountLabel,
      currency: currency,
      billingCycle: billingCycle,
      durationDays: durationDays,
      durationMonths: durationMonths,
      description: description,
      features: features,
      isActive: isActive,
      isPopular: isPopular,
      isCurrent: isCurrent ?? this.isCurrent,
      accentColor: accentColor,
      icon: icon,
    );
  }
}

class SubscriptionStatusModel {
  final bool hasSubscription;
  final bool isActive;
  final String status;
  final String planName;
  final String? planCode;
  final double price;
  final String billingCycle;
  final DateTime? expiresAt;
  final int daysRemaining;
  final List<String> features;
  final String? outletId;
  final String? tenantId;
  final String? invoiceNumber;

  const SubscriptionStatusModel({
    required this.hasSubscription,
    required this.isActive,
    required this.status,
    required this.planName,
    this.planCode,
    required this.price,
    this.billingCycle = 'MONTHLY',
    this.expiresAt,
    this.daysRemaining = 30,
    required this.features,
    this.outletId,
    this.tenantId,
    this.invoiceNumber,
  });

  factory SubscriptionStatusModel.fromJson(Map<String, dynamic> json) {
    DateTime? expDate;
    if (json['expires_at'] != null) {
      expDate = DateTime.tryParse(json['expires_at'].toString());
    }

    int remaining = 0;
    if (json['days_remaining'] is num) {
      remaining = (json['days_remaining'] as num).toInt();
    }
    if (expDate != null && expDate.isAfter(DateTime.now())) {
      final diff = expDate.difference(DateTime.now()).inDays;
      if (diff > remaining) remaining = diff;
    }

    final rawStatus = (json['status']?.toString().toUpperCase()) ?? 'ACTIVE';
    final isActuallyActive = json['is_active'] == true ||
        (expDate != null && expDate.isAfter(DateTime.now())) ||
        (rawStatus == 'ACTIVE' && remaining > 0);

    return SubscriptionStatusModel(
      hasSubscription: json['has_subscription'] == true || isActuallyActive,
      isActive: isActuallyActive,
      status: isActuallyActive ? (rawStatus == 'TRIAL' ? 'TRIAL' : 'ACTIVE') : 'EXPIRED',
      planName: json['plan_name']?.toString() ?? 'SirfBill Restaurant Pro',
      planCode: json['plan_code']?.toString() ?? 'RESTAURANT_PRO_299',
      price: (json['price'] is num) ? (json['price'] as num).toDouble() : 299.0,
      billingCycle: json['billing_cycle']?.toString() ?? '1 Month',
      expiresAt: expDate ?? (isActuallyActive ? DateTime.now().add(Duration(days: remaining > 0 ? remaining : 30)) : null),
      daysRemaining: remaining,
      features: (json['features'] is List)
          ? (json['features'] as List).map((e) => e.toString()).toList()
          : List<String>.from(kDefaultProFeatures),
      outletId: json['outlet_id']?.toString(),
      tenantId: json['tenant_id']?.toString(),
      invoiceNumber: json['invoice_number']?.toString() ?? json['latest_invoice_number']?.toString(),
    );
  }

  static SubscriptionStatusModel defaultActive() {
    return SubscriptionStatusModel(
      hasSubscription: true,
      isActive: true,
      status: 'ACTIVE',
      planName: 'SirfBill Restaurant Pro (1 Month)',
      planCode: 'RESTAURANT_PRO_299',
      price: 299.0,
      billingCycle: '1 Month',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      daysRemaining: 30,
      features: kDefaultProFeatures,
      invoiceNumber: 'INV-SUB-202611-4A9F',
    );
  }
}

class SubscriptionInvoiceItem {
  final String invoiceId;
  final String date;
  final String planName;
  final double amount;
  final String status;
  final String paymentMethod;
  final String? paymentReference;
  final String? notes;
  final String? invoiceUrl;
  final String? pdfUrl;

  const SubscriptionInvoiceItem({
    required this.invoiceId,
    required this.date,
    required this.planName,
    required this.amount,
    required this.status,
    required this.paymentMethod,
    this.paymentReference,
    this.notes,
    this.invoiceUrl,
    this.pdfUrl,
  });

  String getViewUrl(String baseUrl) {
    if (invoiceUrl != null && invoiceUrl!.trim().isNotEmpty) {
      if (invoiceUrl!.startsWith('http')) return invoiceUrl!.trim();
      return '$baseUrl${invoiceUrl!.startsWith('/') ? '' : '/'}${invoiceUrl!.trim()}';
    }
    return '$baseUrl/api/subscriptions/invoices/$invoiceId/view';
  }

  String getPdfUrl(String baseUrl) {
    if (pdfUrl != null && pdfUrl!.trim().isNotEmpty) {
      if (pdfUrl!.startsWith('http')) return pdfUrl!.trim();
      return '$baseUrl${pdfUrl!.startsWith('/') ? '' : '/'}${pdfUrl!.trim()}';
    }
    return '$baseUrl/api/subscriptions/invoices/$invoiceId/pdf';
  }

  factory SubscriptionInvoiceItem.fromJson(Map<String, dynamic> json) {
    return SubscriptionInvoiceItem(
      invoiceId: json['invoice_number']?.toString() ?? json['id']?.toString() ?? 'INV-${DateTime.now().millisecondsSinceEpoch}',
      date: json['payment_date']?.toString() ?? json['created_at']?.toString() ?? 'Recently',
      planName: json['plan_name']?.toString() ?? 'SirfBill Restaurant Pro',
      amount: (json['amount'] is num)
          ? (json['amount'] as num).toDouble()
          : (json['price_paid'] is num ? (json['price_paid'] as num).toDouble() : 299.0),
      status: json['status']?.toString().toUpperCase() ?? 'SUCCESS',
      paymentMethod: json['payment_gateway']?.toString() ?? json['payment_method']?.toString() ?? 'RAZORPAY',
      paymentReference: json['gateway_payment_id']?.toString() ?? json['payment_reference']?.toString(),
      notes: json['notes']?.toString(),
      invoiceUrl: json['invoice_url']?.toString() ?? json['view_url']?.toString(),
      pdfUrl: json['pdf_url']?.toString() ?? json['download_url']?.toString(),
    );
  }
}

const List<String> kDefaultProFeatures = [
  'Fast Touch POS Billing & Multi-Station KOT Printing',
  'Complete Recipe Management & Automatic BOM Inventory Deductions',
  'Multi-Branch Real-Time Inventory & Stock Transfers',
  'Physical Stock Audit & Variance Reconciliation',
  'Wastage & Spoilage Loss Tracking with Rupee Costing',
  'Interactive Table Layout & Live Kitchen Display (KDS)',
  'Automated Purchase Orders & Vendor GRN Inwarding',
  'Role-Based Multi-Staff Logins & Daily Shift Closure Reports',
];

const List<SubscriptionPlanItem> kMonthlySubscriptionPlans = [
  SubscriptionPlanItem(
    id: 'RESTAURANT_PRO_299',
    planCode: 'RESTAURANT_PRO_299',
    name: 'SirfBill Restaurant Pro (1 Month)',
    tag: 'Standard Monthly',
    price: 299.0,
    basePrice: 299.0,
    gstAmount: 53.82,
    totalPrice: 352.82,
    gstNote: 'GST (18%) Excluded',
    priceDisplay: '₹299 (GST Excluded)',
    totalDisplay: '₹352.82 (Incl. 18% GST)',
    discountLabel: 'Standard',
    billingCycle: '1 Month',
    durationDays: 30,
    durationMonths: 1,
    isPopular: false,
    isCurrent: true,
    description: 'Standard 1 Month plan: ₹299 base + 18% GST. Complete POS, Recipe BOM, KDS & Inventory.',
    accentColor: Color(0xFF10B981),
    icon: Icons.workspace_premium_rounded,
    features: kDefaultProFeatures,
  ),
  SubscriptionPlanItem(
    id: 'RESTAURANT_PRO_3M',
    planCode: 'RESTAURANT_PRO_3M',
    name: 'SirfBill Restaurant Pro (3 Months)',
    tag: 'Popular • 3 Months',
    price: 897.0,
    basePrice: 897.0,
    gstAmount: 161.46,
    totalPrice: 1058.46,
    gstNote: 'GST (18%) Excluded',
    priceDisplay: '₹897 (GST Excluded)',
    totalDisplay: '₹1058.46 (Incl. 18% GST)',
    discountLabel: 'Quarterly',
    billingCycle: '3 Months',
    durationDays: 90,
    durationMonths: 3,
    isPopular: true,
    isCurrent: false,
    description: '3 Months plan: ₹897 base + 18% GST (Total ₹1,058). Full POS & perpetual inventory for 90 days.',
    accentColor: Color(0xFF0EA5E9),
    icon: Icons.date_range_rounded,
    features: kDefaultProFeatures,
  ),
  SubscriptionPlanItem(
    id: 'RESTAURANT_PRO_6M',
    planCode: 'RESTAURANT_PRO_6M',
    name: 'SirfBill Restaurant Pro (6 Months)',
    tag: 'Save 5% • Semi-Annual',
    price: 1704.30,
    basePrice: 1704.30,
    gstAmount: 306.77,
    totalPrice: 2011.07,
    gstNote: 'GST (18%) Excluded',
    priceDisplay: '₹1704.30 (GST Excluded)',
    totalDisplay: '₹2011.07 (Incl. 18% GST)',
    discountLabel: '5% OFF',
    billingCycle: '6 Months',
    durationDays: 180,
    durationMonths: 6,
    isPopular: false,
    isCurrent: false,
    description: '6 Months plan: ₹1,704.30 base + 18% GST (Total ₹2,012). 5% discount applied.',
    accentColor: Color(0xFF6366F1),
    icon: Icons.trending_up_rounded,
    features: kDefaultProFeatures,
  ),
  SubscriptionPlanItem(
    id: 'RESTAURANT_PRO_12M',
    planCode: 'RESTAURANT_PRO_12M',
    name: 'SirfBill Restaurant Pro (12 Months)',
    tag: 'Best Value • 10% OFF',
    price: 3229.20,
    basePrice: 3229.20,
    gstAmount: 581.26,
    totalPrice: 3810.46,
    gstNote: 'GST (18%) Excluded',
    priceDisplay: '₹3229.20 (GST Excluded)',
    totalDisplay: '₹3810.46 (Incl. 18% GST)',
    discountLabel: '10% OFF',
    billingCycle: '12 Months (1 Year)',
    durationDays: 365,
    durationMonths: 12,
    isPopular: false,
    isCurrent: false,
    description: 'Annual 12 Months plan: ₹3,229.20 base + 18% GST (Total ₹3,823). 10% discount applied.',
    accentColor: Color(0xFF8B5CF6),
    icon: Icons.stars_rounded,
    features: kDefaultProFeatures,
  ),
];
