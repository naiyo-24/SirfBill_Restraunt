import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_ops_models.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_status_badge.dart';

class GrnSection extends StatefulWidget {
  const GrnSection({super.key});

  @override
  State<GrnSection> createState() => _GrnSectionState();
}

class _GrnSectionState extends State<GrnSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<GoodsReceivedNote> _grns = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _grns.where((grn) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          grn.grnNumber.toLowerCase().contains(q) ||
          grn.invoiceNumber.toLowerCase().contains(q) ||
          grn.supplierName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Goods Received Notes (GRN)',
          subtitle: 'Verify inward supplier consignments, invoice accuracy & cold-chain temperature compliance',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search GRN #, Invoice #, Supplier...',
          trailing: ElevatedButton.icon(
            onPressed: () => _openRecordGRNDialog(context),
            icon: const Icon(Icons.receipt_long, size: 16),
            label: const Text('Record Inward GRN'),
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
                    final grn = filtered[index];
                    return _buildGRNTile(context, grn, isDark);
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
          Icon(Icons.inventory_rounded, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No Goods Received Notes (GRN)', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Inward vendor deliveries will appear here upon gate receipt',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildGRNTile(BuildContext context, GoodsReceivedNote grn, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.verified_outlined, color: Color(0xFF10B981), size: 24),
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
                      grn.grnNumber,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'PO: ${grn.poNumber}',
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
                  'Vendor: ${grn.supplierName} • Inv: ${grn.invoiceNumber}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Received: ${dateFormat.format(grn.receivedDate)} by ${grn.receivedBy}',
                  style: TextStyle(
                    fontSize: 11,
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
                  '₹${grn.totalBillAmount.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                InventoryStatusBadge.temperature(
                  isPassed: grn.temperaturePass,
                  temperature: grn.temperatureCelsius,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openRecordGRNDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Record Inward GRN'),
        content: const SizedBox(
          width: 400,
          child: Text('Inspect goods, temperature compliance and invoice against purchase orders.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
