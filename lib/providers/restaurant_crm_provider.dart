import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/restaurant_crm_models.dart';
import '../services/restaurant/restaurant_crm_service.dart';

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
    state = state.copyWith(customers: list, isLoading: false);
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

    state = state.copyWith(
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
