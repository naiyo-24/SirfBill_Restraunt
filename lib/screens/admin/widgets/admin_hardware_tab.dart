import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/hardware_product_model.dart';
import '../../../services/hardware/hardware_service.dart';
import 'admin_hardware_dialogs.dart';

class AdminHardwareTab extends StatefulWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;

  const AdminHardwareTab({
    super.key,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  State<AdminHardwareTab> createState() => _AdminHardwareTabState();
}

class _AdminHardwareTabState extends State<AdminHardwareTab> {
  int _currentViewIndex = 0; // 0: Products Table, 1: Orders Table
  List<HardwareProduct> _products = [];
  List<HardwareOrderModel> _orders = [];
  bool _isLoading = true;
  String _selectedCategory = 'ALL';
  String _searchQuery = '';

  final List<String> _categoryFilters = [
    'ALL',
    'PRINTER',
    'POS_TERMINAL',
    'HANDHELD_PDA',
    'KDS_DISPLAY',
    'CASH_DRAWER',
    'SCANNER',
    'PAPER_ROLLS',
  ];

  @override
  void initState() {
    super.initState();
    _loadHardwareData();
  }

  Future<void> _loadHardwareData() async {
    setState(() => _isLoading = true);
    final products = await HardwareService.fetchProducts(
      category: _selectedCategory,
      search: _searchQuery,
    );
    final orders = await HardwareService.fetchOrders();
    if (mounted) {
      setState(() {
        _products = products;
        _orders = orders;
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSeedCatalog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.inventory_2_rounded, color: Color(0xFF10B981)),
            SizedBox(width: 8),
            Text('Seed Certified Hardware Catalog'),
          ],
        ),
        content: const Text(
          'This will populate the database with certified restaurant hardware products (80mm KOT Printers, Dual-Screen Touch Terminals, Handheld Waiter POS, Electronic Cash Drawers, Scanners, and Paper Rolls).\n\nContinue?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Seed Catalog'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      await HardwareService.seedCatalog();
      await _loadHardwareData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Hardware catalog seeded successfully!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    }
  }

  Future<void> _handleDeleteProduct(HardwareProduct product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Deactivate Hardware Product'),
        content: Text('Are you sure you want to remove "${product.name}" from public listing?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deactivate'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final ok = await HardwareService.deleteProduct(product.id);
      if (ok) {
        _loadHardwareData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Product deactivated.'), backgroundColor: Colors.orange),
          );
        }
      }
    }
  }

  void _showAddProductDialog([HardwareProduct? product]) {
    showDialog(
      context: context,
      builder: (ctx) => AddEditHardwareProductDialog(
        existingProduct: product,
        onSaved: _loadHardwareData,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    return Column(
      children: [
        // Top Action Bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            color: widget.cardBg,
            border: Border(bottom: BorderSide(color: widget.borderColor)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Buy Hardware & Equipment Marketplace',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: widget.textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Certified thermal printers, touch terminals, cash drawers & restaurant POS supplies',
                        style: TextStyle(fontSize: 12, color: widget.subtitleColor),
                      ),
                    ],
                  ),
                  Wrap(
                    spacing: 10,
                    children: [
                      SegmentedButton<int>(
                        segments: const [
                          ButtonSegment(value: 0, label: Text('Products Catalog'), icon: Icon(Icons.table_chart_rounded, size: 16)),
                          ButtonSegment(value: 1, label: Text('Orders & Inquiries'), icon: Icon(Icons.local_shipping_rounded, size: 16)),
                        ],
                        selected: {_currentViewIndex},
                        onSelectionChanged: (val) => setState(() => _currentViewIndex = val.first),
                        style: SegmentedButton.styleFrom(
                          selectedBackgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                          selectedForegroundColor: const Color(0xFF10B981),
                        ),
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.cloud_download_rounded, size: 16),
                        label: const Text('Seed Catalog'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF10B981),
                          side: const BorderSide(color: Color(0xFF10B981)),
                        ),
                        onPressed: _handleSeedCatalog,
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('List New Product'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () => _showAddProductDialog(),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Search & Filter row
              if (_currentViewIndex == 0)
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          onChanged: (val) {
                            _searchQuery = val;
                            _loadHardwareData();
                          },
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search, size: 18),
                            hintText: 'Search by product name, SKU or model...',
                            hintStyle: const TextStyle(fontSize: 12),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                            filled: true,
                            fillColor: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _categoryFilters.map((cat) {
                            final isSel = _selectedCategory == cat;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(cat.replaceAll('_', ' '), style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                                selected: isSel,
                                onSelected: (_) {
                                  setState(() => _selectedCategory = cat);
                                  _loadHardwareData();
                                },
                                selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),

        // Main Content Area
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : _currentViewIndex == 0
                  ? _buildProductsTable(inFormat)
                  : _buildOrdersTable(inFormat),
        ),
      ],
    );
  }

  Widget _buildProductsTable(NumberFormat inFormat) {
    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            const Text('No hardware products found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            const Text('Seed the certified catalog or add a new hardware item.', style: TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.cloud_download_rounded),
              label: const Text('Seed Official Catalog'),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              onPressed: _handleSeedCatalog,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.borderColor),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          columnSpacing: 20,
          horizontalMargin: 16,
          columns: const [
            DataColumn(label: Text('PRODUCT & MODEL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('SKU / CATEGORY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('PRICE & MRP', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('STOCK', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('WARRANTY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('ACTIONS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: _products.map((p) {
            return DataRow(
              cells: [
                // Product & Model
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${p.brand} • ${p.modelNumber.isNotEmpty ? p.modelNumber : 'Standard'}',
                          style: TextStyle(fontSize: 10, color: widget.subtitleColor),
                        ),
                      ],
                    ),
                  ),
                ),
                // SKU / Category
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.sku, style: const TextStyle(fontSize: 11, fontFamily: 'monospace', fontWeight: FontWeight.w600)),
                      Text(p.categoryDisplay, style: TextStyle(fontSize: 10, color: widget.subtitleColor)),
                    ],
                  ),
                ),
                // Price & MRP
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(inFormat.format(p.price), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          if (p.discountPercentage > 0) ...[
                            const SizedBox(width: 4),
                            Text('${p.discountPercentage}% OFF', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.orange)),
                          ],
                        ],
                      ),
                      Text('MRP: ${inFormat.format(p.mrp)} (GST ${p.taxRate.toStringAsFixed(0)}%)', style: TextStyle(fontSize: 10, color: widget.subtitleColor)),
                    ],
                  ),
                ),
                // Stock
                DataCell(
                  Text('${p.stockQuantity} units', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.stockQuantity > 5 ? const Color(0xFF10B981) : Colors.red)),
                ),
                // Warranty
                DataCell(Text('${p.warrantyMonths} Months', style: const TextStyle(fontSize: 11))),
                // Status
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: (p.isActive ? const Color(0xFF10B981) : Colors.grey).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(p.isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: p.isActive ? const Color(0xFF10B981) : Colors.grey)),
                  ),
                ),
                // Actions
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(icon: const Icon(Icons.edit_rounded, size: 16, color: Color(0xFF3B82F6)), tooltip: 'Edit', onPressed: () => _showAddProductDialog(p)),
                      IconButton(icon: const Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red), tooltip: 'Deactivate', onPressed: () => _handleDeleteProduct(p)),
                    ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersTable(NumberFormat inFormat) {
    if (_orders.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.local_shipping_outlined, size: 48, color: Colors.grey),
            SizedBox(height: 12),
            Text('No hardware purchase orders yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text('Orders placed by restaurant branches will appear here with fulfillment status.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Container(
        decoration: BoxDecoration(
          color: widget.cardBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: widget.borderColor),
        ),
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC)),
          columns: const [
            DataColumn(label: Text('ORDER #', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('PRODUCT & QTY', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('TOTAL PRICE', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('CONTACT & DESTINATION', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('STATUS', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
            DataColumn(label: Text('DISPATCH TRACKING', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
          ],
          rows: _orders.map((o) {
            Color statusColor = const Color(0xFF3B82F6);
            if (o.status == 'DELIVERED') statusColor = const Color(0xFF10B981);
            if (o.status == 'SHIPPED') statusColor = Colors.orange;

            return DataRow(
              cells: [
                DataCell(Text(o.orderNumber, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, fontFamily: 'monospace'))),
                DataCell(Text('${o.productName ?? 'Hardware'} (x${o.quantity})', style: const TextStyle(fontSize: 12))),
                DataCell(Text(inFormat.format(o.totalPrice), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)))),
                DataCell(Text('${o.contactName} (${o.contactPhone})\n${o.city} - ${o.pincode}', style: const TextStyle(fontSize: 11))),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(6)),
                    child: Text(o.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor)),
                  ),
                ),
                DataCell(Text(o.trackingNumber != null ? '${o.courierPartner ?? 'Courier'}: ${o.trackingNumber}' : 'Processing', style: const TextStyle(fontSize: 11))),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
