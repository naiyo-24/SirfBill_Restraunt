import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_transfer_models.dart';
import '../services/inventory_api_service.dart';
import '../services/stock_transfer_api_service.dart';
import '../widgets/create_stock_transfer_dialog.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_status_badge.dart';
import '../widgets/receive_stock_transfer_dialog.dart';
import '../widgets/stock_transfer_details_dialog.dart';

class StockTransfersSection extends StatefulWidget {
  const StockTransfersSection({super.key});

  @override
  State<StockTransfersSection> createState() => _StockTransfersSectionState();
}

class _StockTransfersSectionState extends State<StockTransfersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StockTransferStatus? _selectedStatus;
  StockTransferType? _selectedType;
  bool _isLoading = true;
  List<StockTransferHeader> _transfers = [];
  String _currentOutletId = '';

  @override
  void initState() {
    super.initState();
    _loadTransfers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTransfers() async {
    setState(() => _isLoading = true);
    try {
      final currentOutlet = await InventoryApiService.getResolvedOutletId();
      final list = await StockTransferApiService.getTransfers();
      if (mounted) {
        setState(() {
          _currentOutletId = currentOutlet;
          _transfers = list;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _transfers = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _transfers.where((t) {
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          t.transferNumber.toLowerCase().contains(q) ||
          t.fromDisplayLocation.toLowerCase().contains(q) ||
          t.toDisplayLocation.toLowerCase().contains(q) ||
          t.driverName.toLowerCase().contains(q);
      final matchesStatus = _selectedStatus == null || t.status == _selectedStatus;
      final matchesType = _selectedType == null || t.transferType == _selectedType;
      return matchesSearch && matchesStatus && matchesType;
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Stock Transfers',
          subtitle: 'Commodity routing across Central Commissary, Outlet Branches & Kitchen Stations',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search transfer #, station or driver...',
          onRefresh: _loadTransfers,
          isRefreshing: _isLoading,
          trailing: ElevatedButton.icon(
            onPressed: () => CreateStockTransferDialog.show(context, onCreated: _loadTransfers),
            icon: const Icon(Icons.swap_horiz_rounded, size: 16),
            label: const Text('Initiate Stock Transfer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        _buildFiltersBar(isDark),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final item = filtered[index];
                        return _buildTransferCard(context, item, isDark);
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildFiltersBar(bool isDark) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        children: [
          _filterChip(label: 'All Statuses', isSelected: _selectedStatus == null, onSelected: () => setState(() => _selectedStatus = null), isDark: isDark),
          _filterChip(label: 'Draft', isSelected: _selectedStatus == StockTransferStatus.draft, onSelected: () => setState(() => _selectedStatus = StockTransferStatus.draft), isDark: isDark),
          _filterChip(label: 'In Transit', isSelected: _selectedStatus == StockTransferStatus.inTransit, onSelected: () => setState(() => _selectedStatus = StockTransferStatus.inTransit), isDark: isDark, badgeColor: Colors.blue),
          _filterChip(label: 'Completed', isSelected: _selectedStatus == StockTransferStatus.completed, onSelected: () => setState(() => _selectedStatus = StockTransferStatus.completed), isDark: isDark, badgeColor: Colors.teal),
          _filterChip(label: 'Cancelled', isSelected: _selectedStatus == StockTransferStatus.cancelled, onSelected: () => setState(() => _selectedStatus = StockTransferStatus.cancelled), isDark: isDark),
          const SizedBox(width: 14),
          VerticalDivider(width: 1, indent: 10, endIndent: 10, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(width: 14),
          _filterChip(label: 'All Modes', isSelected: _selectedType == null, onSelected: () => setState(() => _selectedType = null), isDark: isDark),
          _filterChip(label: 'Inter-Branch', isSelected: _selectedType == StockTransferType.interBranch, onSelected: () => setState(() => _selectedType = StockTransferType.interBranch), isDark: isDark),
          _filterChip(label: 'Inter-Station', isSelected: _selectedType == StockTransferType.interStation, onSelected: () => setState(() => _selectedType = StockTransferType.interStation), isDark: isDark),
        ],
      ),
    );
  }

  Widget _filterChip({required String label, required bool isSelected, required VoidCallback onSelected, required bool isDark, Color? badgeColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        selected: isSelected,
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)))),
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        selectedColor: badgeColor ?? const Color(0xFF10B981),
        onSelected: (_) => onSelected(),
        side: BorderSide(color: isSelected ? (badgeColor ?? const Color(0xFF10B981)) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No stock transfers found', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Requisition and transfer commodities across Commissary, Stations and Outlets', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTransferCard(BuildContext context, StockTransferHeader t, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: InkWell(
        onTap: () => StockTransferDetailsDialog.show(context, transfer: t, onUpdated: _loadTransfers),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (t.status == StockTransferStatus.inTransit ? Colors.blue : const Color(0xFF10B981)).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.swap_horiz_rounded, color: t.status == StockTransferStatus.inTransit ? Colors.blue : const Color(0xFF10B981), size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 4,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(t.transferNumber, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        const SizedBox(width: 8),
                        InventoryStatusBadge.status(t.status.label.toUpperCase(), color: t.status.color),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(4)),
                          child: Text(t.transferType.label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text('${t.fromDisplayLocation} ➔ ${t.toDisplayLocation}', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                    const SizedBox(height: 2),
                    Text(
                      '${dateFormat.format(t.createdAt)} • By ${t.transferredBy}${t.vehicleNumber.isNotEmpty ? ' • Van: ${t.vehicleNumber}' : ''}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${t.totalItems} item${t.totalItems == 1 ? '' : 's'}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    if (t.totalValuation > 0) ...[
                      const SizedBox(height: 2),
                      Text('₹${t.totalValuation.toStringAsFixed(0)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (t.status == StockTransferStatus.inTransit) ...[
                if (_currentOutletId.isEmpty || t.toOutletId == _currentOutletId)
                  ElevatedButton(
                    onPressed: () => ReceiveStockTransferDialog.show(context, transfer: t, onReceived: _loadTransfers),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Receive'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_shipping_outlined, size: 14, color: Colors.blue),
                        SizedBox(width: 4),
                        Text('En Route', style: TextStyle(color: Colors.blue, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
              ] else if (t.status == StockTransferStatus.draft) ...[
                if (_currentOutletId.isEmpty || t.fromOutletId == _currentOutletId)
                  ElevatedButton(
                    onPressed: () => StockTransferDetailsDialog.show(context, transfer: t, onUpdated: _loadTransfers),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    child: const Text('Dispatch'),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                    ),
                    child: const Text('Pending Dispatch', style: TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ] else ...[
                IconButton(
                  tooltip: 'Digital Bill / Challan',
                  onPressed: () => StockTransferApiService.openTransferBillView(t.id),
                  icon: const Icon(Icons.receipt_long_outlined, size: 20, color: Color(0xFF10B981)),
                ),
                const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
