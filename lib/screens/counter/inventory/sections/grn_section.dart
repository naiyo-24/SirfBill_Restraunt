import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/grn_models.dart';
import '../services/procurement_api_service.dart';
import '../widgets/inventory_header.dart';
import '../widgets/record_grn_dialog.dart';
import '../widgets/grn_details_dialog.dart';

class GrnSection extends StatefulWidget {
  const GrnSection({super.key});

  @override
  State<GrnSection> createState() => _GrnSectionState();
}

class _GrnSectionState extends State<GrnSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isLoading = true;
  List<GrnRecord> _grns = [];

  @override
  void initState() {
    super.initState();
    _loadGrns();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadGrns() async {
    setState(() => _isLoading = true);
    try {
      final list = await ProcurementApiService.getGRNList();
      if (mounted) setState(() => _grns = list);
    } catch (_) {
      if (mounted) setState(() => _grns = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _grns.where((grn) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          grn.grnNumber.toLowerCase().contains(q) ||
          grn.supplierInvoiceNo.toLowerCase().contains(q) ||
          grn.supplierName.toLowerCase().contains(q) ||
          grn.poNumber.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Goods Received Notes (GRN)',
          subtitle: 'Verify inward supplier consignments, vendor invoice GST, and restock kitchen inventory',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search GRN #, Invoice #, PO #, Supplier...',
          onRefresh: _loadGrns,
          isRefreshing: _isLoading,
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
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : filtered.isEmpty
                  ? _buildEmptyState()
                  : RefreshIndicator(
                      onRefresh: _loadGrns,
                      color: const Color(0xFF10B981),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(24),
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final grn = filtered[index];
                          return _buildGRNTile(context, grn, isDark);
                        },
                      ),
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
          const Text('No Goods Received Notes (GRN)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 6),
          const Text(
            'Inward supplier deliveries, physical bills & invoice taxes are recorded here',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _openRecordGRNDialog(context),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Record First GRN Receipt'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGRNTile(BuildContext context, GrnRecord grn, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

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
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _openGrnDetails(context, grn),
          child: Padding(
            padding: const EdgeInsets.all(18),
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
                          if (grn.invoiceDocumentUrl != null && grn.invoiceDocumentUrl!.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.attach_file_rounded, size: 10, color: Color(0xFF3B82F6)),
                                  SizedBox(width: 2),
                                  Text(
                                    'Bill Attached',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Vendor: ${grn.supplierName} • Vendor Bill: ${grn.supplierInvoiceNo}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Received at Dock: ${dateFormat.format(grn.receivedDate)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                      ),
                      if (grn.remarks.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Notes: ${grn.remarks}',
                          style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey),
                        ),
                      ],
                    ],
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${grn.totalAmount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '${grn.items.length} items verified',
                              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _openGrnDetails(BuildContext context, GrnRecord grn) {
    showDialog(
      context: context,
      builder: (ctx) => GrnDetailsDialog(grn: grn),
    );
  }

  Future<void> _openRecordGRNDialog(BuildContext context) async {
    final result = await showDialog<GrnRecord>(
      context: context,
      builder: (ctx) => const RecordGrnDialog(),
    );
    if (result != null) {
      _loadGrns();
    }
  }
}
