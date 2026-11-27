import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../config/api_constants.dart';
import '../../services/restaurant/customer_dining_service.dart';
import 'widgets/customer_menu_card.dart';
import 'widgets/customer_cart_sheet.dart';
import 'widgets/customer_dish_detail_sheet.dart';
import 'widgets/customer_menu_filters.dart';
import 'widgets/customer_menu_header.dart';
import 'widgets/customer_order_status_view.dart';

class TableOrderScreen extends StatefulWidget {
  final String? outletId;
  final String? tableId;

  const TableOrderScreen({
    super.key,
    this.outletId,
    this.tableId,
  });

  @override
  State<TableOrderScreen> createState() => _TableOrderScreenState();
}

class _TableOrderScreenState extends State<TableOrderScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  Map<String, dynamic>? _tableInfo;
  List<Map<String, dynamic>> _menuItems = [];
  List<String> _categories = ['All'];
  String _selectedCategory = 'All';
  String _searchQuery = '';
  bool _vegOnly = false;

  final Map<String, int> _cart = {};
  Map<String, dynamic>? _activePlacedOrder;
  Map<String, dynamic>? _lastOrder;
  String? _savedCustomerName;
  String? _savedCustomerPhone;
  final ScrollController _scrollController = ScrollController();
  int _visibleCount = 12;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadData();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      final total = _filteredItems.length;
      if (_visibleCount < total) {
        setState(() => _visibleCount = (_visibleCount + 12).clamp(12, total));
      }
    }
  }

  Future<void> _loadData() async {
    final tId = widget.tableId;
    if (tId == null || tId.isEmpty) {
      setState(() {
        _errorMessage = 'Invalid QR code. Please scan the QR code located on your dining table.';
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);
    final tableData = await CustomerDiningService.fetchTableInfo(tId);
    if (tableData == null) {
      setState(() {
        _errorMessage = 'Could not find this table. Please ask restaurant staff for assistance.';
        _isLoading = false;
      });
      return;
    }

    final outId = widget.outletId ?? tableData['outlet_id']?.toString() ?? '';
    final menuData = await CustomerDiningService.fetchMenu(outId);

    Map<String, dynamic>? existingOrder;
    final activeOrdId = tableData['active_order_id']?.toString();
    if (activeOrdId != null && activeOrdId.isNotEmpty) {
      existingOrder = await CustomerDiningService.fetchOrderStatus(activeOrdId);
    }

    List<Map<String, dynamic>> allItems = [];
    final Set<String> catSet = {'All'};

    if (menuData != null) {
      final rawCats = menuData['categories'] is List ? (menuData['categories'] as List) : [];
      for (final c in rawCats) {
        if (c is Map) {
          final cName = c['category_name']?.toString() ?? c['name']?.toString() ?? 'Other';
          catSet.add(cName);
          final items = c['items'] is List ? (c['items'] as List) : [];
          for (final it in items) {
            if (it is Map) {
              final mapItem = Map<String, dynamic>.from(it);
              mapItem['category_name'] = cName;
              allItems.add(mapItem);
            }
          }
        }
      }
    }

    if (mounted) {
      setState(() {
        _tableInfo = tableData;
        _menuItems = allItems;
        _categories = catSet.toList();
        if (existingOrder != null) {
          _lastOrder = existingOrder;
          _savedCustomerName = existingOrder['customer_name']?.toString();
          _savedCustomerPhone = existingOrder['customer_phone']?.toString();
        }
        _isLoading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filteredItems {
    return _menuItems.where((it) {
      final name = (it['name'] ?? '').toString().toLowerCase();
      final cat = (it['category_name'] ?? '').toString();
      final isVeg = it['is_veg'] == true || it['food_type'] == 'VEG';

      if (_vegOnly && !isVeg) return false;
      if (_selectedCategory != 'All' && cat != _selectedCategory) return false;
      if (_searchQuery.isNotEmpty && !name.contains(_searchQuery.toLowerCase())) return false;
      return true;
    }).toList();
  }

  int get _cartItemCount => _cart.values.fold(0, (sum, count) => sum + count);

  double get _cartSubtotal {
    double total = 0.0;
    for (final e in _cart.entries) {
      final item = _menuItems.firstWhere(
        (m) => m['id']?.toString() == e.key,
        orElse: () => <String, dynamic>{},
      );
      final price = double.tryParse((item['price'] ?? 0).toString()) ?? 0.0;
      total += price * e.value;
    }
    return total;
  }

  Future<void> _handlePlaceOrder({
    required String customerName,
    required String customerPhone,
    required String notes,
  }) async {
    final tId = widget.tableId ?? _tableInfo?['table_id']?.toString();
    final outId = widget.outletId ?? _tableInfo?['outlet_id']?.toString();
    if (tId == null || outId == null) return;

    final orderItems = <Map<String, dynamic>>[];
    for (final e in _cart.entries) {
      if (e.value <= 0) continue;
      final item = _menuItems.firstWhere(
        (m) => m['id']?.toString() == e.key,
        orElse: () => <String, dynamic>{},
      );
      orderItems.add({
        'item_id': e.key,
        'name': item['name'] ?? 'Dish',
        'quantity': e.value,
        'unit_price': double.tryParse((item['price'] ?? 0).toString()) ?? 0.0,
      });
    }

    try {
      final placed = await CustomerDiningService.placeOrder(
        outletId: outId,
        tableId: tId,
        customerName: customerName,
        customerPhone: customerPhone,
        notes: notes,
        items: orderItems,
      );

      if (placed != null && mounted) {
        setState(() {
          _activePlacedOrder = placed;
          _lastOrder = placed;
          if (customerName.trim().isNotEmpty) _savedCustomerName = customerName.trim();
          if (customerPhone.trim().isNotEmpty) _savedCustomerPhone = customerPhone.trim();
          _cart.clear();
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order failed: $e'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8FAFC),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    if (_errorMessage != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.qr_code_scanner_rounded, size: 56, color: Color(0xFF94A3B8)),
                const SizedBox(height: 16),
                Text(_errorMessage!, style: const TextStyle(fontSize: 14, color: Color(0xFF475569)), textAlign: TextAlign.center),
                const SizedBox(height: 18),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  child: const Text('Try Again'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_activePlacedOrder != null) {
      return CustomerOrderStatusView(
        initialOrder: _activePlacedOrder!,
        tableInfo: _tableInfo!,
        onOrderMore: () => setState(() => _activePlacedOrder = null),
        onStartNewOrder: () => setState(() {
          _activePlacedOrder = null;
          _lastOrder = null;
          _savedCustomerName = null;
          _savedCustomerPhone = null;
        }),
      );
    }

    final outletName = _tableInfo?['outlet_name']?.toString() ?? 'SirfBill Restaurant';
    final outletAddress = _tableInfo?['outlet_address']?.toString() ?? '';
    final rawLogo = _tableInfo?['outlet_logo']?.toString().trim() ?? '';
    final outletLogo = rawLogo.isEmpty
        ? ''
        : (rawLogo.startsWith('http') ? rawLogo : '${ApiConstants.baseUrl}${rawLogo.startsWith('/') ? '' : '/'}$rawLogo');
    final tableCode = _tableInfo?['table_code']?.toString() ?? 'T1';
    final section = _tableInfo?['section']?.toString() ?? 'Main Hall';
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: CustomerMenuHeader(
        outletName: outletName,
        outletAddress: outletAddress,
        outletLogo: outletLogo,
        tableCode: tableCode,
        section: section,
      ),
      body: Column(
        children: [
          CustomerMenuFilters(
            categories: _categories,
            selectedCategory: _selectedCategory,
            vegOnly: _vegOnly,
            onSearchChanged: (q) => setState(() {
              _searchQuery = q;
              _visibleCount = 12;
            }),
            onVegChanged: (val) => setState(() {
              _vegOnly = val;
              _visibleCount = 12;
            }),
            onCategorySelected: (c) => setState(() {
              _selectedCategory = c;
              _visibleCount = 12;
            }),
          ),

          if (_lastOrder != null)
            GestureDetector(
              onTap: () => setState(() => _activePlacedOrder = _lastOrder),
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFECFDF5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_rounded, size: 18, color: Color(0xFF059669)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Active Order ${_lastOrder!['order_number'] ?? ''} • Tap to View Status',
                        style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF065F46)),
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 13, color: Color(0xFF059669)),
                  ],
                ),
              ),
            ),

          // Menu items list
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No dishes found in this category.', style: TextStyle(color: Color(0xFF94A3B8))),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    scrollCacheExtent: const ScrollCacheExtent.pixels(250),
                    itemCount: items.length > _visibleCount ? _visibleCount + 1 : items.length,
                    padding: const EdgeInsets.only(bottom: 90),
                    itemBuilder: (context, idx) {
                      if (idx >= _visibleCount) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 18),
                          child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981))),
                        );
                      }
                      final item = items[idx];
                      final itemId = item['id']?.toString() ?? '';
                      final qty = _cart[itemId] ?? 0;
                      void updateQty(int newQty) {
                        setState(() {
                          if (newQty <= 0) {
                            _cart.remove(itemId);
                          } else {
                            _cart[itemId] = newQty;
                          }
                        });
                      }
                      return CustomerMenuCard(
                        item: item,
                        quantity: qty,
                        onTap: () => CustomerDishDetailSheet.show(
                          context,
                          item: item,
                          initialQuantity: qty,
                          onQuantityChanged: updateQty,
                        ),
                        onQuantityChanged: updateQty,
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: _cartItemCount > 0
          ? SafeArea(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF064E3B)]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.25),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$_cartItemCount ITEM${_cartItemCount > 1 ? "S" : ""} ADDED',
                          style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: Color(0xFF34D399), letterSpacing: 0.5),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          '₹${_cartSubtotal.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900, color: Colors.white),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        CustomerCartSheet.show(
                          context,
                          tableInfo: _tableInfo!,
                          cart: _cart,
                          menuItems: _menuItems,
                          initialCustomerName: _savedCustomerName,
                          initialCustomerPhone: _savedCustomerPhone,
                          onCartUpdated: (newCart) => setState(() => _cart..clear()..addAll(newCart)),
                          onPlaceOrder: _handlePlaceOrder,
                        );
                      },
                      icon: const Icon(Icons.shopping_bag_rounded, size: 16),
                      label: const Text('View Cart & Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
