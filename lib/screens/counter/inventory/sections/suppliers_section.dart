import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';
import '../services/procurement_api_service.dart';
import '../widgets/add_supplier_dialog.dart';
import '../widgets/inventory_header.dart';
import '../widgets/supplier_details_dialog.dart';

class SuppliersSection extends StatefulWidget {
  const SuppliersSection({super.key});

  @override
  State<SuppliersSection> createState() => _SuppliersSectionState();
}

class _SuppliersSectionState extends State<SuppliersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<Supplier> _suppliers = const [];
  List<PurchaseOrder> _orders = const [];

  @override
  void initState() {
    super.initState();
    _suppliers = [];
    _orders = [];
    _loadSuppliers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _isLoading = true);
    try {
      final list = await InventoryApiService.getSuppliers(search: _searchQuery);
      final orders = await ProcurementApiService.getPurchaseOrders();
      if (mounted) {
        setState(() {
          _suppliers = list;
          _orders = orders;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _suppliers = [];
          _orders = [];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  List<PurchaseOrder> _getSupplierOrders(Supplier s) {
    // Defend against null on Flutter Web hot reload state
    final ordersList = _orders;
    // ignore: unnecessary_null_comparison
    if (ordersList == null || ordersList.isEmpty) return [];
    return ordersList.where((po) {
      if (po.supplierId.isNotEmpty && po.supplierId == s.id) return true;
      final poSupp = po.supplierName.trim().toLowerCase();
      final supp = s.name.trim().toLowerCase();
      return poSupp.isNotEmpty && (poSupp == supp || poSupp.contains(supp) || supp.contains(poSupp));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;

    final filtered = _suppliers.where((s) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          s.name.toLowerCase().contains(q) ||
          s.contactPerson.toLowerCase().contains(q) ||
          s.gstin.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Suppliers & Vendors Directory',
          subtitle: 'Manage supplier contacts, credit terms, GSTIN compliance and active orders',
          searchController: _searchController,
          onSearchChanged: (v) {
            setState(() => _searchQuery = v);
            _loadSuppliers();
          },
          searchHint: 'Search supplier, contact, or GSTIN...',
          onRefresh: _loadSuppliers,
          isRefreshing: _isLoading,
          trailing: ElevatedButton.icon(
            onPressed: () => _openAddSupplierDialog(context),
            icon: const Icon(Icons.person_add_outlined, size: 16),
            label: const Text('Add Supplier'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : filtered.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12 : 24,
                        vertical: isMobile ? 12 : 24,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final supplier = filtered[index];
                        return _buildSupplierTile(context, supplier, isDark, isMobile);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.storefront_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No suppliers registered', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Click "Add Supplier" to register your first kitchen vendor',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildSupplierTile(
    BuildContext context,
    Supplier s,
    bool isDark,
    bool isMobile,
  ) {
    final initialChar = s.name.isNotEmpty ? s.name.substring(0, 1).toUpperCase() : 'V';
    final matchingOrders = _getSupplierOrders(s);
    final orderCount = matchingOrders.length;
    final totalSpend = matchingOrders.fold(0.0, (sum, po) => sum + po.totalAmount);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          hoverColor: const Color(0xFF10B981).withValues(alpha: 0.05),
          onTap: () => _openSupplierDetails(context, s),
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 12 : 18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircleAvatar(
                  radius: isMobile ? 18 : 22,
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.12),
                  child: Text(
                    initialChar,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF10B981),
                      fontSize: isMobile ? 14 : 16,
                    ),
                  ),
                ),
                SizedBox(width: isMobile ? 10 : 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              s.name,
                              style: TextStyle(
                                fontSize: isMobile ? 14 : 15,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${s.paymentTermsDays}d Credit',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Contact: ${s.contactPerson.isNotEmpty ? s.contactPerson : s.name}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Phone: ${s.phone.isNotEmpty ? s.phone : 'Not provided'} • GST: ${s.gstin.isNotEmpty ? s.gstin : 'Unregistered'}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (s.email.isNotEmpty || s.address.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (s.email.isNotEmpty) s.email,
                            if (s.address.isNotEmpty) s.address,
                          ].join(' • '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: orderCount > 0
                        ? const Color(0xFF10B981).withValues(alpha: 0.12)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$orderCount ${orderCount == 1 ? 'Purchase' : 'Purchases'}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: orderCount > 0
                              ? const Color(0xFF10B981)
                              : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                        ),
                      ),
                      if (totalSpend > 0) ...[
                        const SizedBox(height: 2),
                        Text(
                          '₹${totalSpend.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openSupplierDetails(BuildContext context, Supplier s) {
    showDialog(
      context: context,
      builder: (_) => SupplierDetailsDialog(
        supplier: s,
        orders: _orders,
        onUpdated: _loadSuppliers,
      ),
    );
  }

  void _openAddSupplierDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AddSupplierDialog(onCreated: _loadSuppliers),
    );
  }
}
