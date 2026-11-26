import 'package:flutter/material.dart';
import '../../services/restaurant/customer_dining_service.dart';
import 'widgets/customer_menu_card.dart';
import 'widgets/customer_cart_sheet.dart';
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

  @override
  void initState() {
    super.initState();
    _loadData();
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
      );
    }

    final outletName = _tableInfo?['outlet_name']?.toString() ?? 'SirfBill Restaurant';
    final outletAddress = _tableInfo?['outlet_address']?.toString() ?? '';
    final tableCode = _tableInfo?['table_code']?.toString() ?? 'T1';
    final section = _tableInfo?['section']?.toString() ?? 'Main Hall';
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(outletAddress.isNotEmpty ? 92 : 76),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            boxShadow: [
              BoxShadow(color: Color(0x260F172A), blurRadius: 12, offset: Offset(0, 4)),
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (Navigator.of(context).canPop()) ...[
                    IconButton(
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Back to POS',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          outletName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (outletAddress.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            outletAddress,
                            style: const TextStyle(fontSize: 10.5, color: Color(0xFFCBD5E1)),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 3),
                        const Row(
                          children: [
                            Icon(Icons.verified_rounded, size: 12, color: Color(0xFF34D399)),
                            SizedBox(width: 4),
                            Text(
                              'Digital Table Menu • Contactless Dining',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF34D399)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.table_restaurant_rounded, size: 14, color: Color(0xFF34D399)),
                        const SizedBox(width: 5),
                        Text(
                          '$tableCode • $section',
                          style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Search & Veg filter
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (val) => setState(() => _searchQuery = val.trim()),
                    decoration: InputDecoration(
                      hintText: 'Search food dishes...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilterChip(
                  label: const Text('Veg', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  selected: _vegOnly,
                  onSelected: (val) => setState(() => _vegOnly = val),
                  selectedColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                  checkmarkColor: const Color(0xFF10B981),
                  labelStyle: TextStyle(color: _vegOnly ? const Color(0xFF10B981) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ),

          // Categories horizontal bar
          SizedBox(
            height: 38,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, idx) {
                final c = _categories[idx];
                final isSel = c == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(c),
                    selected: isSel,
                    onSelected: (_) => setState(() => _selectedCategory = c),
                    selectedColor: const Color(0xFF6366F1),
                    labelStyle: TextStyle(
                      color: isSel ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 6),

          // Menu items list
          Expanded(
            child: items.isEmpty
                ? const Center(
                    child: Text('No dishes found in this category.', style: TextStyle(color: Color(0xFF94A3B8))),
                  )
                : ListView.builder(
                    itemCount: items.length,
                    padding: const EdgeInsets.only(bottom: 90),
                    itemBuilder: (context, idx) {
                      final item = items[idx];
                      final itemId = item['id']?.toString() ?? '';
                      final qty = _cart[itemId] ?? 0;
                      return CustomerMenuCard(
                        item: item,
                        quantity: qty,
                        onQuantityChanged: (newQty) {
                          setState(() {
                            if (newQty <= 0) {
                              _cart.remove(itemId);
                            } else {
                              _cart[itemId] = newQty;
                            }
                          });
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      bottomSheet: _cartItemCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.08), blurRadius: 10, offset: const Offset(0, -2)),
                ],
              ),
              child: SafeArea(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$_cartItemCount ITEM${_cartItemCount > 1 ? "S" : ""}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B))),
                        Text('₹${_cartSubtotal.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        CustomerCartSheet.show(
                          context,
                          tableInfo: _tableInfo!,
                          cart: _cart,
                          menuItems: _menuItems,
                          onCartUpdated: (newCart) => setState(() => _cart..clear()..addAll(newCart)),
                          onPlaceOrder: _handlePlaceOrder,
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 16),
                      label: const Text('View Cart & Order', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
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
