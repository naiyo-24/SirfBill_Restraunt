import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_ops_models.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_status_badge.dart';

class StockTransfersSection extends StatefulWidget {
  const StockTransfersSection({super.key});

  @override
  State<StockTransfersSection> createState() => _StockTransfersSectionState();
}

class _StockTransfersSectionState extends State<StockTransfersSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<StockTransferRecord> _transfers = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _transfers.where((t) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          t.transferNumber.toLowerCase().contains(q) ||
          t.fromLocation.toLowerCase().contains(q) ||
          t.toLocation.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Stock Transfers',
          subtitle: 'Internal inventory movement across Central Store, Kitchen Stations, Bar & Outlets',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search transfer # or station...',
          onRefresh: () => setState(() {}),
          trailing: ElevatedButton.icon(
            onPressed: () => _openCreateTransferDialog(context),
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
        Expanded(
          child: filtered.isEmpty
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.swap_horiz_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No internal transfers recorded', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Transfer commodities between dry pantry, cold stores and prep counters',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildTransferCard(BuildContext context, StockTransferRecord t, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF3B82F6), size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      t.transferNumber,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InventoryStatusBadge.status(t.status.label.toUpperCase(), color: t.status.color),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${t.fromLocation} ➔ ${t.toLocation}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  dateFormat.format(t.transferDate),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${t.items.isNotEmpty ? t.items.length : t.totalItemsCount} item(s)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'By ${t.transferredBy}',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openCreateTransferDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Initiate Stock Transfer'),
        content: const SizedBox(
          width: 400,
          child: Text('Move items between Central Store, Line Chiller, Tandoor or Bar.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
