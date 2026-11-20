import 'package:intl/intl.dart';

enum CustomerSegment {
  all,
  vip,
  regular,
  newGuest,
  atRisk,
  hasDue;

  String get label {
    switch (this) {
      case CustomerSegment.all:
        return 'All Guests';
      case CustomerSegment.vip:
        return 'VIP Members';
      case CustomerSegment.regular:
        return 'Regulars';
      case CustomerSegment.newGuest:
        return 'New Guests';
      case CustomerSegment.atRisk:
        return 'At Risk';
      case CustomerSegment.hasDue:
        return 'Khata Dues';
    }
  }
}

class RestaurantCustomer {
  final String id;
  final String outletId;
  final String name;
  final String phone;
  final String email;
  final DateTime? dob;
  final DateTime? anniversary;
  final String? gstNumber;
  final Map<String, dynamic> preferences;
  final List<String> tags;
  final double creditLimit;
  final double creditBalance;
  final int loyaltyPoints;
  final int totalVisits;
  final double totalSpent;
  final double avgOrderValue;
  final DateTime? lastVisitAt;
  final bool optInMarketing;
  final String notes;
  final bool isActive;
  final DateTime? createdAt;

  const RestaurantCustomer({
    required this.id,
    required this.outletId,
    required this.name,
    required this.phone,
    this.email = '',
    this.dob,
    this.anniversary,
    this.gstNumber,
    this.preferences = const {},
    this.tags = const [],
    this.creditLimit = 0.0,
    this.creditBalance = 0.0,
    this.loyaltyPoints = 0,
    this.totalVisits = 0,
    this.totalSpent = 0.0,
    this.avgOrderValue = 0.0,
    this.lastVisitAt,
    this.optInMarketing = true,
    this.notes = '',
    this.isActive = true,
    this.createdAt,
  });

  CustomerSegment get segment {
    if (creditBalance > 0) {
      // Has store credit outstanding
    }
    if (totalVisits >= 10 || totalSpent >= 5000) {
      return CustomerSegment.vip;
    }
    if (lastVisitAt != null && DateTime.now().difference(lastVisitAt!).inDays > 30) {
      return CustomerSegment.atRisk;
    }
    if (totalVisits >= 3) {
      return CustomerSegment.regular;
    }
    return CustomerSegment.newGuest;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length > 1 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'G';
  }

  factory RestaurantCustomer.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic v) {
      if (v == null || v.toString().isEmpty) return null;
      try {
        return DateTime.parse(v.toString()).toLocal();
      } catch (_) {
        return null;
      }
    }

    return RestaurantCustomer(
      id: (json['id'] ?? '').toString(),
      outletId: (json['outlet_id'] ?? '').toString(),
      name: (json['name'] ?? 'Guest').toString(),
      phone: (json['phone'] ?? '').toString(),
      email: (json['email'] ?? '').toString(),
      dob: parseDate(json['dob']),
      anniversary: parseDate(json['anniversary']),
      gstNumber: json['gst_number']?.toString(),
      preferences: json['preferences'] is Map ? Map<String, dynamic>.from(json['preferences']) : {},
      tags: json['tags'] is List ? List<String>.from(json['tags']) : [],
      creditLimit: double.tryParse((json['credit_limit'] ?? 0).toString()) ?? 0.0,
      creditBalance: double.tryParse((json['credit_balance'] ?? 0).toString()) ?? 0.0,
      loyaltyPoints: int.tryParse((json['loyalty_points'] ?? 0).toString()) ?? 0,
      totalVisits: int.tryParse((json['total_visits'] ?? 0).toString()) ?? 0,
      totalSpent: double.tryParse((json['total_spent'] ?? 0).toString()) ?? 0.0,
      avgOrderValue: double.tryParse((json['avg_order_value'] ?? 0).toString()) ?? 0.0,
      lastVisitAt: parseDate(json['last_visit_at']),
      optInMarketing: json['opt_in_marketing'] ?? true,
      notes: (json['notes'] ?? '').toString(),
      isActive: json['is_active'] ?? true,
      createdAt: parseDate(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'outlet_id': outletId,
        'name': name,
        'phone': phone,
        'email': email,
        'dob': dob != null ? DateFormat('yyyy-MM-dd').format(dob!) : null,
        'anniversary': anniversary != null ? DateFormat('yyyy-MM-dd').format(anniversary!) : null,
        'gst_number': gstNumber,
        'preferences': preferences,
        'tags': tags,
        'credit_limit': creditLimit,
        'notes': notes,
        'opt_in_marketing': optInMarketing,
        'is_active': isActive,
      };
}

class CustomerTopDish {
  final String itemName;
  final String? variantName;
  final int orderCount;
  final double totalSpent;

  const CustomerTopDish({
    required this.itemName,
    this.variantName,
    required this.orderCount,
    required this.totalSpent,
  });

  factory CustomerTopDish.fromJson(Map<String, dynamic> json) => CustomerTopDish(
        itemName: (json['item_name'] ?? '').toString(),
        variantName: json['variant_name']?.toString(),
        orderCount: int.tryParse((json['order_count'] ?? 0).toString()) ?? 0,
        totalSpent: double.tryParse((json['total_spent'] ?? 0).toString()) ?? 0.0,
      );
}

class CustomerRecentBill {
  final String orderId;
  final String orderNumber;
  final DateTime createdAt;
  final double grandTotal;
  final String paymentMethod;
  final String status;
  final int itemsCount;

  const CustomerRecentBill({
    required this.orderId,
    required this.orderNumber,
    required this.createdAt,
    required this.grandTotal,
    required this.paymentMethod,
    required this.status,
    this.itemsCount = 1,
  });

  factory CustomerRecentBill.fromJson(Map<String, dynamic> json) => CustomerRecentBill(
        orderId: (json['order_id'] ?? json['id'] ?? '').toString(),
        orderNumber: (json['order_number'] ?? json['bill_no'] ?? 'ORD').toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? json['date'] ?? '').toString())?.toLocal() ?? DateTime.now(),
        grandTotal: double.tryParse((json['grand_total'] ?? json['amount'] ?? 0).toString()) ?? 0.0,
        paymentMethod: (json['payment_method'] ?? json['payment_mode'] ?? 'CASH').toString(),
        status: (json['status'] ?? 'COMPLETED').toString(),
        itemsCount: int.tryParse((json['items_count'] ?? json['lines']?.length ?? 1).toString()) ?? 1,
      );
}

class CustomerInsights {
  final RestaurantCustomer customer;
  final List<CustomerTopDish> topDishes;
  final List<CustomerRecentBill> recentBills;
  final int loyaltyBalance;
  final double creditBalance;
  final double creditLimit;

  const CustomerInsights({
    required this.customer,
    required this.topDishes,
    required this.recentBills,
    required this.loyaltyBalance,
    required this.creditBalance,
    required this.creditLimit,
  });

  factory CustomerInsights.fromJson(Map<String, dynamic> json) => CustomerInsights(
        customer: RestaurantCustomer.fromJson(json['customer'] ?? {}),
        topDishes: (json['top_dishes'] as List? ?? []).map((x) => CustomerTopDish.fromJson(x)).toList(),
        recentBills: (json['recent_bills'] as List? ?? []).map((x) => CustomerRecentBill.fromJson(x)).toList(),
        loyaltyBalance: int.tryParse((json['loyalty_balance'] ?? json['loyalty_points'] ?? 0).toString()) ?? 0,
        creditBalance: double.tryParse((json['credit_balance'] ?? 0).toString()) ?? 0.0,
        creditLimit: double.tryParse((json['credit_limit'] ?? 0).toString()) ?? 0.0,
      );
}

class KhataLedgerEntry {
  final String id;
  final String customerId;
  final String entryType; // DEBIT / CREDIT
  final double amount;
  final double balanceAfter;
  final String referenceType;
  final String? referenceId;
  final String? notes;
  final DateTime createdAt;

  const KhataLedgerEntry({
    required this.id,
    required this.customerId,
    required this.entryType,
    required this.amount,
    required this.balanceAfter,
    required this.referenceType,
    this.referenceId,
    this.notes,
    required this.createdAt,
  });

  factory KhataLedgerEntry.fromJson(Map<String, dynamic> json) => KhataLedgerEntry(
        id: (json['id'] ?? '').toString(),
        customerId: (json['customer_id'] ?? '').toString(),
        entryType: (json['entry_type'] ?? 'DEBIT').toString(),
        amount: double.tryParse((json['amount'] ?? 0).toString()) ?? 0.0,
        balanceAfter: double.tryParse((json['balance_after'] ?? 0).toString()) ?? 0.0,
        referenceType: (json['reference_type'] ?? 'ORDER').toString(),
        referenceId: json['reference_id']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: DateTime.tryParse((json['created_at'] ?? '').toString())?.toLocal() ?? DateTime.now(),
      );
}
