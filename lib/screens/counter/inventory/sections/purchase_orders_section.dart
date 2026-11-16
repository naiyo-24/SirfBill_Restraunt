import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_ops_models.dart';
import '../services/procurement_api_service.dart';
import '../utils/purchase_order_pdf_helper.dart';
import '../widgets/create_purchase_order_dialog.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_status_badge.dart';
import '../widgets/po_email_dispatch_dialog.dart';
import '../widgets/purchase_order_details_dialog.dart';

class PurchaseOrdersSection extends StatefulWidget {
  const PurchaseOrdersSection({super.key});

  @override
  State<PurchaseOrdersSection> createState() => _PurchaseOrdersSectionState();
}

class _PurchaseOrdersSectionState extends State<PurchaseOrdersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  POStatus? _statusFilter;
  bool _isLoading = true;
  List<PurchaseOrder> _orders = [];

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadOrders() async {
    setState(() => _isLoading = true);
    try {
      final list = await ProcurementApiService.getPurchaseOrders();
      if (mounted) setState(() => _orders = list);
    } catch (_) {
      if (mounted) setState(() => _orders = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _orders.where((po) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          po.poNumber.toLowerCase().contains(q) ||
          po.supplierName.toLowerCase().contains(q);
      final matchesStatus = _statusFilter == null || po.status == _statusFilter;
      return matchesSearch && matchesStatus;
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Purchase Orders (PO)',
          subtitle: 'Generate, approve and dispatch procurement orders to kitchen suppliers',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search PO number or supplier...',
          trailing: ElevatedButton.icon(
            onPressed: () => _openCreatePODialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Create Purchase Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        _buildStatusFilterRow(isDark),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final po = filtered[index];
                        return _buildPOCard(context, po, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildStatusFilterRow(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _buildChip('All Orders', _statusFilter == null, () => setState(() => _statusFilter = null), isDark),
          ...POStatus.values.map((status) {
            return _buildChip(
              status.label,
              _statusFilter == status,
              () => setState(() => _statusFilter = status),
              isDark,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildChip(String label, bool isSelected, VoidCallback onSelected, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
        backgroundColor: Colors.transparent,
        selectedColor: const Color(0xFF10B981),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(
            color: isSelected ? const Color(0xFF10B981) : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
          ),
        ),
        onSelected: (_) => onSelected(),
      ),
    );
  }

  Widget _buildPOCard(BuildContext context, PurchaseOrder po, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openPODetailsDialog(context, po),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: Color(0xFF3B82F6), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            po.poNumber,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(width: 10),
                          InventoryStatusBadge.status(po.status.label, color: po.status.color),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vendor: ${po.supplierName}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Created: ${dateFormat.format(po.orderDate)} • Expected: ${dateFormat.format(po.expectedDeliveryDate)}',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${po.items.length} line items',
                        style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${po.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.email_outlined, size: 18, color: Color(0xFF3B82F6)),
                      tooltip: 'Email PO to Vendor',
                      onPressed: () async {
                        final sent = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => PoEmailDispatchDialog(po: po),
                        );
                        if (sent == true) _loadOrders();
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.print_outlined, size: 18, color: Color(0xFF10B981)),
                      tooltip: 'Print / Download PDF (Backend Template)',
                      onPressed: () => PurchaseOrderPdfHelper.printOrDownloadPo(context, po),
                    ),
                    IconButton(
                      icon: const Icon(Icons.open_in_new_rounded, size: 17, color: Color(0xFF64748B)),
                      tooltip: 'Open HTML Bill in Browser',
                      onPressed: () => PurchaseOrderPdfHelper.openBackendPrintView(po.id),
                    ),
                  ],
                ),
                const SizedBox(width: 4),
                const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No purchase orders found', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Create purchase bills or orders to begin tracking kitchen procurement',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Future<void> _openCreatePODialog(BuildContext context) async {
    final result = await showDialog<PurchaseOrder>(
      context: context,
      builder: (ctx) => const CreatePurchaseOrderDialog(),
    );
    if (result != null) {
      _loadOrders();
    }
  }

  Future<void> _openPODetailsDialog(BuildContext context, PurchaseOrder po) async {
    final result = await showDialog(
      context: context,
      builder: (ctx) => PurchaseOrderDetailsDialog(po: po),
    );
    if (result != null) {
      _loadOrders();
    }
  }
}
