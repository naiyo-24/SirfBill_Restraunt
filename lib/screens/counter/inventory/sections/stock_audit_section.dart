import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_ops_models.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_status_badge.dart';

class StockAuditSection extends StatefulWidget {
  const StockAuditSection({super.key});

  @override
  State<StockAuditSection> createState() => _StockAuditSectionState();
}

class _StockAuditSectionState extends State<StockAuditSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  final List<StockAuditSession> _audits = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _audits.where((a) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          a.auditNumber.toLowerCase().contains(q) ||
          a.zone.toLowerCase().contains(q) ||
          a.auditorName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Stock Audit & Variance Reconciliation',
          subtitle: 'Physical stocktaking logs, discrepancy investigation, and ledger variance balancing',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search audit # or auditor...',
          trailing: ElevatedButton.icon(
            onPressed: () => _openStartAuditDialog(context),
            icon: const Icon(Icons.playlist_add_check, size: 16),
            label: const Text('Start Physical Count'),
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
                    final a = filtered[index];
                    return _buildAuditCard(context, a, isDark);
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
          Icon(Icons.fact_check_outlined, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No stock audits conducted', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('Conduct physical counts to reconcile book stock with actual shelf balances',
              style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context, StockAuditSession a, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy');

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
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory, color: Color(0xFF8B5CF6), size: 24),
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
                      a.auditNumber,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InventoryStatusBadge.status(
                      a.status.name.toUpperCase(),
                      color: a.status == AuditStatus.completed ? Colors.teal : Colors.amber,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Zone: ${a.zone} • Auditor: ${a.auditorName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  dateFormat.format(a.auditDate),
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
                  '${a.totalItemsCounted} items audited',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Variance: ₹${a.totalDiscrepancyValue.toStringAsFixed(0)}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: a.totalDiscrepancyValue == 0 ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _openStartAuditDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Start Physical Count'),
        content: const SizedBox(
          width: 400,
          child: Text('Select storage zone (e.g. Dry Pantry, Walk-in Chiller) to start cycle audit.'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close')),
        ],
      ),
    );
  }
}
