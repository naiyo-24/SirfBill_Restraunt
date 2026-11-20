import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_crm_models.dart';
import '../models/restaurant_pos_models.dart';
import '../services/restaurant/restaurant_crm_service.dart';
import '../services/restaurant_pos_service.dart';
import '../services/inventory_service.dart';

class RestaurantCrmState {
  final List<RestaurantCustomer> customers;
  final CustomerSegment selectedSegment;
  final String searchQuery;
  final bool isLoading;
  final RestaurantCustomer? selectedCustomer;
  final CustomerInsights? insights;
  final bool isInsightsLoading;
  final List<KhataLedgerEntry> khataLedger;
  final bool isKhataLoading;

  const RestaurantCrmState({
    this.customers = const [],
    this.selectedSegment = CustomerSegment.all,
    this.searchQuery = '',
    this.isLoading = false,
    this.selectedCustomer,
    this.insights,
    this.isInsightsLoading = false,
    this.khataLedger = const [],
    this.isKhataLoading = false,
  });

  int get totalGuests => customers.length;
  int get vipCount => customers.where((c) => c.segment == CustomerSegment.vip).length;
  int get regularCount => customers.where((c) => c.segment == CustomerSegment.regular).length;
  int get newCount => customers.where((c) => c.segment == CustomerSegment.newGuest).length;
  int get atRiskCount => customers.where((c) => c.segment == CustomerSegment.atRisk).length;
  double get totalKhataOutstanding =>
      customers.fold<double>(0.0, (sum, c) => sum + (c.creditBalance > 0 ? c.creditBalance : 0.0));
  int get totalLoyaltyPoints => customers.fold<int>(0, (sum, c) => sum + c.loyaltyPoints);

  List<RestaurantCustomer> get filteredCustomers {
    return customers.where((c) {
      final matchesSearch = searchQuery.isEmpty ||
          c.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          c.phone.contains(searchQuery) ||
          c.email.toLowerCase().contains(searchQuery.toLowerCase());

      bool matchesSegment = true;
      if (selectedSegment == CustomerSegment.vip) {
        matchesSegment = c.segment == CustomerSegment.vip;
      } else if (selectedSegment == CustomerSegment.regular) {
        matchesSegment = c.segment == CustomerSegment.regular;
      } else if (selectedSegment == CustomerSegment.newGuest) {
        matchesSegment = c.segment == CustomerSegment.newGuest;
      } else if (selectedSegment == CustomerSegment.atRisk) {
        matchesSegment = c.segment == CustomerSegment.atRisk;
      } else if (selectedSegment == CustomerSegment.hasDue) {
        matchesSegment = c.creditBalance > 0;
      }

      return matchesSearch && matchesSegment;
    }).toList();
  }

  RestaurantCrmState copyWith({
    List<RestaurantCustomer>? customers,
    CustomerSegment? selectedSegment,
    String? searchQuery,
    bool? isLoading,
    RestaurantCustomer? Function()? selectedCustomer,
    CustomerInsights? Function()? insights,
    bool? isInsightsLoading,
    List<KhataLedgerEntry>? khataLedger,
    bool? isKhataLoading,
  }) {
    return RestaurantCrmState(
      customers: customers ?? this.customers,
      selectedSegment: selectedSegment ?? this.selectedSegment,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      selectedCustomer: selectedCustomer != null ? selectedCustomer() : this.selectedCustomer,
      insights: insights != null ? insights() : this.insights,
      isInsightsLoading: isInsightsLoading ?? this.isInsightsLoading,
      khataLedger: khataLedger ?? this.khataLedger,
      isKhataLoading: isKhataLoading ?? this.isKhataLoading,
    );
  }
}

class RestaurantCrmNotifier extends Notifier<RestaurantCrmState> {
  @override
  RestaurantCrmState build() {
    Future.microtask(() => loadCustomers());
    return const RestaurantCrmState(isLoading: true);
  }

  Future<void> loadCustomers({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true);
    }
    final list = await RestaurantCrmService.fetchCustomers(
      search: state.searchQuery,
      segment: state.selectedSegment,
    );

    // Reconcile with live orders from backend
    List<RestaurantOrder> orders = [];
    try {
      final outletId = await InventoryService.getShopId();
      orders = await RestaurantPosService.fetchOrders(outletId: outletId, limit: 1000);
    } catch (_) {}

    // Enrich customers with real aggregate metrics
    final enrichedList = await Future.wait(list.map((c) async {
      int visits = c.totalVisits;
      double spent = c.totalSpent;
      double aov = c.avgOrderValue;
      DateTime? lastVisit = c.lastVisitAt;
      int loyalty = c.loyaltyPoints;
      double khataDue = c.creditBalance;

      final cPhone = c.phone.replaceAll(RegExp(r'\D'), '');
      final cPhone10 = cPhone.length >= 10 ? cPhone.substring(cPhone.length - 10) : cPhone;
      final cName = c.name.trim().toLowerCase();

      // 1. Check matching orders
      if (orders.isNotEmpty) {
        final custOrders = orders.where((o) {
          if (o.status == OrderStatus.cancelled) return false;
          final oPhone = o.customerPhone.replaceAll(RegExp(r'\D'), '');
          final oPhone10 = oPhone.length >= 10 ? oPhone.substring(oPhone.length - 10) : oPhone;
          if (cPhone10.isNotEmpty && oPhone10.isNotEmpty && cPhone10 == oPhone10) return true;
          final oName = o.customerName.trim().toLowerCase();
          if (cName.isNotEmpty &&
              cName != 'walk-in guest' &&
              oName.isNotEmpty &&
              (oName == cName || oName.contains(cName) || cName.contains(oName))) {
            return true;
          }
          return false;
        }).toList();

        if (custOrders.isNotEmpty) {
          visits = custOrders.length;
          spent = custOrders.fold(0.0, (s, o) => s + o.grandTotal);
          aov = visits > 0 ? (spent / visits) : 0.0;
          lastVisit = custOrders.map((o) => o.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);

          final dueOrders = custOrders.where((o) {
            final p = o.paymentMethod.toUpperCase();
            return p.contains('DUE') || p.contains('KHATA') || p.contains('CREDIT');
          }).toList();
          if (dueOrders.isNotEmpty && khataDue <= 0) {
            khataDue = dueOrders.fold(0.0, (s, o) => s + o.grandTotal);
          }
        }
      }

      // 2. Also check customer insights if visits is still 0
      if (visits == 0) {
        try {
          final ins = await RestaurantCrmService.fetchCustomerInsights(c.id);
          if (ins != null && ins.recentBills.isNotEmpty) {
            visits = ins.recentBills.length;
            spent = ins.recentBills.fold(0.0, (s, b) => s + b.grandTotal);
            aov = visits > 0 ? (spent / visits) : 0.0;
            lastVisit = ins.recentBills.map((b) => b.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
            if (ins.loyaltyBalance > 0) loyalty = ins.loyaltyBalance;
            if (ins.creditBalance > 0) khataDue = ins.creditBalance;
          }
        } catch (_) {}
      }

      if (loyalty == 0 && spent > 0) {
        loyalty = (spent / 50).round();
      }

      return c.copyWith(
        totalVisits: visits,
        totalSpent: spent,
        avgOrderValue: aov,
        lastVisitAt: lastVisit,
        loyaltyPoints: loyalty,
        creditBalance: khataDue,
      );
    }));

    state = state.copyWith(customers: enrichedList, isLoading: false);
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectSegment(CustomerSegment segment) {
    state = state.copyWith(selectedSegment: segment);
  }

  Future<void> selectCustomer(RestaurantCustomer? customer) async {
    if (customer == null) {
      state = state.copyWith(
        selectedCustomer: () => null,
        insights: () => null,
        khataLedger: const [],
      );
      return;
    }

    state = state.copyWith(
      selectedCustomer: () => customer,
      isInsightsLoading: true,
      isKhataLoading: true,
    );

    final insights = await RestaurantCrmService.fetchCustomerInsights(customer.id);
    final ledger = await RestaurantCrmService.fetchKhataStatement(customer.id);

    RestaurantCustomer updatedCust = customer;
    if (insights != null && insights.recentBills.isNotEmpty) {
      final bVisits = insights.recentBills.length;
      final bSpent = insights.recentBills.fold<double>(0.0, (s, b) => s + b.grandTotal);
      final bAov = bVisits > 0 ? (bSpent / bVisits) : 0.0;
      final bLast = insights.recentBills.map((b) => b.createdAt).reduce((a, b) => a.isAfter(b) ? a : b);
      int bLoyalty = insights.loyaltyBalance > 0 ? insights.loyaltyBalance : customer.loyaltyPoints;
      if (bLoyalty == 0 && bSpent > 0) bLoyalty = (bSpent / 50).round();

      updatedCust = customer.copyWith(
        totalVisits: customer.totalVisits > bVisits ? customer.totalVisits : bVisits,
        totalSpent: customer.totalSpent > bSpent ? customer.totalSpent : bSpent,
        avgOrderValue: customer.avgOrderValue > 0 ? customer.avgOrderValue : bAov,
        lastVisitAt: customer.lastVisitAt ?? bLast,
        loyaltyPoints: bLoyalty,
        creditBalance: insights.creditBalance > 0 ? insights.creditBalance : customer.creditBalance,
        creditLimit: insights.creditLimit > 0 ? insights.creditLimit : customer.creditLimit,
      );
    }

    state = state.copyWith(
      selectedCustomer: () => updatedCust,
      insights: () => insights,
      isInsightsLoading: false,
      khataLedger: ledger,
      isKhataLoading: false,
    );
  }

  Future<bool> settleKhataDues({
    required String customerId,
    required double amount,
    required String paymentMode,
    String? notes,
  }) async {
    final success = await RestaurantCrmService.settleKhataDues(
      customerId: customerId,
      amount: amount,
      paymentMode: paymentMode,
      notes: notes,
    );
    if (success) {
      await loadCustomers(silent: true);
      final current = state.selectedCustomer;
      if (current != null && current.id == customerId) {
        await selectCustomer(current);
      }
    }
    return success;
  }

  Future<bool> adjustLoyaltyPoints({
    required String customerId,
    required int points,
    required String reason,
  }) async {
    final success = await RestaurantCrmService.adjustLoyaltyPoints(
      customerId: customerId,
      points: points,
      reason: reason,
    );
    if (success) {
      await loadCustomers(silent: true);
      final current = state.selectedCustomer;
      if (current != null && current.id == customerId) {
        await selectCustomer(current);
      }
    }
    return success;
  }

  Future<bool> saveCustomer(Map<String, dynamic> data, {String? customerId}) async {
    RestaurantCustomer? result;
    if (customerId != null && customerId.isNotEmpty) {
      result = await RestaurantCrmService.updateCustomer(customerId, data);
    } else {
      result = await RestaurantCrmService.createCustomer(data);
    }
    if (result != null) {
      await loadCustomers(silent: true);
      return true;
    }
    return false;
  }

  Future<bool> deleteCustomer(String customerId) async {
    final ok = await RestaurantCrmService.deleteCustomer(customerId);
    if (ok) {
      if (state.selectedCustomer?.id == customerId) {
        selectCustomer(null);
      }
      await loadCustomers(silent: true);
    }
    return ok;
  }
}

final restaurantCrmProvider = NotifierProvider<RestaurantCrmNotifier, RestaurantCrmState>(() {
  return RestaurantCrmNotifier();
});
