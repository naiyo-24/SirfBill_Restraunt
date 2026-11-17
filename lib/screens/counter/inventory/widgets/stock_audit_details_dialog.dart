import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_audit_models.dart';
import '../services/stock_audit_api_service.dart';

class StockAuditDetailsDialog extends StatefulWidget {
  final String batchId;
  final StockAuditBatchSummary? initialSummary;

  const StockAuditDetailsDialog({
    super.key,
    required this.batchId,
    this.initialSummary,
  });

  static Future<void> show(
    BuildContext context, {
    required String batchId,
    StockAuditBatchSummary? summary,
  }) {
    return showDialog(
      context: context,
      builder: (_) => StockAuditDetailsDialog(batchId: batchId, initialSummary: summary),
    );
  }

  @override
  State<StockAuditDetailsDialog> createState() => _StockAuditDetailsDialogState();
}

class _StockAuditDetailsDialogState extends State<StockAuditDetailsDialog> {
  StockAuditBatchDetail? _detail;
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadDetail();
  }

  Future<void> _loadDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await StockAuditApiService.getStockAuditDetail(widget.batchId);
      if (mounted) {
        setState(() {
          _detail = res;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Container(
        width: 860,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark),
            const SizedBox(height: 16),
            if (_isLoading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(child: Center(child: Text('Failed to load audit detail: $_error', style: const TextStyle(color: Colors.red))))
            else if (_detail == null)
              const Expanded(child: Center(child: Text('Audit batch not found.')))
            else ...[
              _buildKpiCards(isDark),
              const SizedBox(height: 16),
              _buildFilterChips(isDark),
              const SizedBox(height: 12),
              Expanded(child: _buildItemsTable(isDark)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final dateStr = widget.initialSummary != null
        ? dateFormat.format(widget.initialSummary!.createdAt)
        : (_detail != null ? dateFormat.format(_detail!.auditDate) : '');

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.playlist_add_check_circle_outlined, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.batchId,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  'Audit Session • $dateStr',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _buildKpiCards(bool isDark) {
    final d = _detail!;
    final netColor = d.netVarianceRupees == 0
        ? const Color(0xFF10B981)
        : (d.netVarianceRupees > 0 ? const Color(0xFF0EA5E9) : const Color(0xFFEF4444));

    return Row(
      children: [
        Expanded(child: _buildKpiTile('Items Audited', '${d.totalItemsAudited}', const Color(0xFF64748B), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildKpiTile('Items Adjusted', '${d.itemsAdjusted}', const Color(0xFF8B5CF6), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildKpiTile('Total Surplus', '+₹${d.totalSurplusRupees.toStringAsFixed(2)}', const Color(0xFF0EA5E9), isDark)),
        const SizedBox(width: 10),
        Expanded(child: _buildKpiTile('Total Deficit', '-₹${d.totalDeficitRupees.toStringAsFixed(2)}', const Color(0xFFEF4444), isDark)),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiTile(
            'Net Variance',
            '${d.netVarianceRupees >= 0 ? '+' : ''}₹${d.netVarianceRupees.toStringAsFixed(2)}',
            netColor,
            isDark,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiTile(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
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

  Widget _buildFilterChips(bool isDark) {
    final statuses = ['ALL', 'MATCHED', 'SURPLUS', 'DEFICIT'];

    return Row(
      children: statuses.map((st) {
        final isSelected = _filterStatus == st;
        return Padding(
          padding: const EdgeInsets.only(right: 8),
          child: ChoiceChip(
            label: Text(st, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
            selected: isSelected,
            onSelected: (selected) {
              if (selected) setState(() => _filterStatus = st);
            },
            selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
            backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildItemsTable(bool isDark) {
    final d = _detail!;
    final filtered = d.results.where((item) {
      if (_filterStatus == 'ALL') return true;
      return item.status.name.toUpperCase() == _filterStatus;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Text(
          'No items found matching $_filterStatus.',
          style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: ListView.separated(
          itemCount: filtered.length,
          separatorBuilder: (_, __) => Divider(
            height: 1,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          itemBuilder: (context, idx) {
            final item = filtered[idx];
            final signStr = item.variance > 0 ? '+' : '';

            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.ingredientName,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        if (item.notes != null && item.notes!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              item.notes!,
                              style: TextStyle(
                                fontSize: 11,
                                color: item.notes!.contains('Shift drift')
                                    ? Colors.amber.shade700
                                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Book: ${item.previousStock} ${item.recipeUom}', style: const TextStyle(fontSize: 12)),
                        Text(
                          'Count: ${item.physicalCount} ${item.recipeUom}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? const Color(0xFF38BDF8) : const Color(0xFF0284C7),
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
                          '$signStr${item.variance} ${item.recipeUom}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: item.status.color,
                          ),
                        ),
                        Text(
                          '$signStr₹${item.varianceRupees.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: item.status.color,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: item.status.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: item.status.color.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      item.status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: item.status.color,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
