import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_audit_models.dart';
import '../services/stock_audit_api_service.dart';
import '../widgets/inventory_header.dart';
import '../widgets/physical_count_audit_dialog.dart';
import '../widgets/stock_audit_details_dialog.dart';

class StockAuditSection extends StatefulWidget {
  const StockAuditSection({super.key});

  @override
  State<StockAuditSection> createState() => _StockAuditSectionState();
}

class _StockAuditSectionState extends State<StockAuditSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<StockAuditBatchSummary> _audits = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAudits();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAudits() async {
    setState(() => _isLoading = true);
    try {
      final data = await StockAuditApiService.getStockAudits(
        search: _searchQuery.trim().isEmpty ? null : _searchQuery.trim(),
      );
      if (mounted) {
        setState(() {
          _audits = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _audits.where((a) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          a.auditBatchId.toLowerCase().contains(q) ||
          a.auditorName.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Stock Audit & Variance Reconciliation',
          subtitle: 'Physical stocktaking logs, discrepancy investigation, and ledger variance balancing',
          searchController: _searchController,
          onSearchChanged: (v) {
            setState(() => _searchQuery = v);
          },
          searchHint: 'Search audit # or auditor...',
          onRefresh: _loadAudits,
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
        if (!_isLoading && _audits.isNotEmpty) _buildKpiSummary(isDark),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : filtered.isEmpty
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

  Widget _buildKpiSummary(bool isDark) {
    int totalAdjusted = 0;
    double totalSurplus = 0.0;
    double totalDeficit = 0.0;
    double netVariance = 0.0;

    for (final a in _audits) {
      totalAdjusted += a.itemsAdjusted;
      totalSurplus += a.totalSurplusRupees;
      totalDeficit += a.totalDeficitRupees;
      netVariance += a.netVarianceRupees;
    }

    final netColor = netVariance == 0
        ? const Color(0xFF10B981)
        : (netVariance > 0 ? const Color(0xFF0EA5E9) : const Color(0xFFEF4444));

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Row(
        children: [
          Expanded(child: _buildMetricTile('Total Audits', '${_audits.length}', const Color(0xFF64748B), isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricTile('Items Adjusted', '$totalAdjusted', const Color(0xFF8B5CF6), isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricTile('Total Surplus', '+₹${totalSurplus.toStringAsFixed(2)}', const Color(0xFF0EA5E9), isDark)),
          const SizedBox(width: 12),
          Expanded(child: _buildMetricTile('Total Shrinkage', '-₹${totalDeficit.toStringAsFixed(2)}', const Color(0xFFEF4444), isDark)),
          const SizedBox(width: 12),
          Expanded(
            child: _buildMetricTile(
              'Net Variance',
              '${netVariance >= 0 ? '+' : ''}₹${netVariance.toStringAsFixed(2)}',
              netColor,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8), fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.fact_check_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 14),
          const Text('No stock audits conducted', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'Conduct physical counts to reconcile book stock with actual shelf balances',
            style: TextStyle(fontSize: 13, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildAuditCard(BuildContext context, StockAuditBatchSummary a, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final hasDiscrepancy = a.itemsAdjusted > 0 || a.netVarianceRupees != 0;
    final statusColor = hasDiscrepancy ? Colors.amber : const Color(0xFF10B981);
    final statusLabel = hasDiscrepancy ? 'ADJUSTED (${a.itemsAdjusted})' : 'PERFECT MATCH';

    final netColor = a.netVarianceRupees == 0
        ? const Color(0xFF10B981)
        : (a.netVarianceRupees > 0 ? const Color(0xFF0EA5E9) : const Color(0xFFEF4444));

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
              color: const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.inventory, color: Color(0xFF10B981), size: 24),
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
                      a.auditBatchId,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                      ),
                      child: Text(
                        statusLabel,
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: statusColor),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Auditor: ${a.auditorName}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Text(
                  dateFormat.format(a.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 3,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (a.totalSurplusRupees > 0)
                      Text(
                        '+₹${a.totalSurplusRupees.toStringAsFixed(2)} Surplus',
                        style: const TextStyle(fontSize: 11, color: Color(0xFF0EA5E9), fontWeight: FontWeight.w600),
                      ),
                    if (a.totalDeficitRupees > 0)
                      Text(
                        '-₹${a.totalDeficitRupees.toStringAsFixed(2)} Shrinkage',
                        style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                      ),
                    Text(
                      'Net: ${a.netVarianceRupees >= 0 ? '+' : ''}₹${a.netVarianceRupees.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: netColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                OutlinedButton.icon(
                  onPressed: () => StockAuditDetailsDialog.show(
                    context,
                    batchId: a.auditBatchId,
                    summary: a,
                  ),
                  icon: const Icon(Icons.visibility_outlined, size: 14),
                  label: const Text('View Drill-Down'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF10B981),
                    side: const BorderSide(color: Color(0xFF10B981)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
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
      barrierDismissible: false,
      builder: (ctx) => PhysicalCountAuditDialog(
        onAuditSubmitted: _loadAudits,
      ),
    );
  }
}
