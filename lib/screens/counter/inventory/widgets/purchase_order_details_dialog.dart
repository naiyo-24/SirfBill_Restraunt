import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_ops_models.dart';
import '../services/procurement_api_service.dart';
import '../utils/purchase_order_pdf_helper.dart';
import 'inventory_status_badge.dart';
import 'po_details_actions.dart';
import 'po_details_items_table.dart';
import 'po_email_dispatch_dialog.dart';
import 'record_grn_dialog.dart';

class PurchaseOrderDetailsDialog extends StatefulWidget {
  final PurchaseOrder po;

  const PurchaseOrderDetailsDialog({super.key, required this.po});

  @override
  State<PurchaseOrderDetailsDialog> createState() => _PurchaseOrderDetailsDialogState();
}

class _PurchaseOrderDetailsDialogState extends State<PurchaseOrderDetailsDialog> {
  late PurchaseOrder _currentPo;
  bool _isLoading = true;
  bool _isProcessing = false;
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');

  @override
  void initState() {
    super.initState();
    _currentPo = widget.po;
    _fetchFullDetails();
  }

  Future<void> _fetchFullDetails() async {
    final full = await ProcurementApiService.getPurchaseOrderById(_currentPo.id);
    if (full != null && mounted) {
      setState(() {
        _currentPo = full;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _issuePO() async {
    setState(() => _isProcessing = true);
    try {
      final updated = await ProcurementApiService.issuePurchaseOrder(_currentPo.id);
      if (updated != null && mounted) {
        setState(() => _currentPo = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PO sent to vendor!'), backgroundColor: Color(0xFF10B981)),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _cancelPO() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Purchase Order?'),
        content: Text('Are you sure you want to cancel ${_currentPo.poNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Cancel PO'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isProcessing = true);
    try {
      final updated = await ProcurementApiService.cancelPurchaseOrder(_currentPo.id);
      if (updated != null && mounted) {
        setState(() => _currentPo = updated);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PO has been cancelled.'), backgroundColor: Colors.orange),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _deletePO() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Purchase Order?'),
        content: Text('Are you sure you want to delete ${_currentPo.poNumber}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Yes, Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final ok = await ProcurementApiService.deletePurchaseOrder(_currentPo.id);
    if (ok && mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase Order deleted'), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 40,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: 800,
        constraints: BoxConstraints(maxWidth: 820, maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: EdgeInsets.all(isMobile ? 14 : 24),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.receipt_long, color: Color(0xFF3B82F6), size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _currentPo.poNumber,
                              style: TextStyle(
                                fontSize: isMobile ? 16 : 18,
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Vendor: ${_currentPo.supplierName}',
                              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    InventoryStatusBadge.status(_currentPo.status.label, color: _currentPo.status.color),
                    const SizedBox(width: 4),
                    IconButton(onPressed: () => Navigator.of(context).pop(_currentPo), icon: const Icon(Icons.close, size: 20)),
                  ],
                ),
              ],
            ),
            const Divider(height: 20),
            Flexible(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildMetaCards(isDark, isMobile),
                          const SizedBox(height: 16),
                          PoDetailsItemsTable(items: _currentPo.items, isDark: isDark),
                          if (_currentPo.notes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                              child: Text('Notes: ${_currentPo.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),
            PoDetailsActions(
              po: _currentPo,
              isProcessing: _isProcessing,
              isMobile: isMobile,
              onDelete: _deletePO,
              onCancel: _cancelPO,
              onEmail: _openEmailDialog,
              onIssue: _issuePO,
              onReceive: () async {
                final res = await showDialog(
                  context: context,
                  builder: (ctx) => RecordGrnDialog(initialPo: _currentPo),
                );
                if (res != null) {
                  _fetchFullDetails();
                }
              },
              onPrintPdf: _printOrDownloadPo,
              onOpenHtml: _openHtmlPrintView,
              onClose: () => Navigator.of(context).pop(_currentPo),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCards(bool isDark, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildInfoCard('Order Date', _dateFormat.format(_currentPo.orderDate), Icons.event_note, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoCard('Expected Delivery', _dateFormat.format(_currentPo.expectedDeliveryDate), Icons.local_shipping_outlined, isDark)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildInfoCard('GST Total', '₹${_currentPo.taxAmount.toStringAsFixed(2)}', Icons.account_balance_outlined, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildInfoCard('Total Amount', '₹${_currentPo.totalAmount.toStringAsFixed(2)}', Icons.payments_outlined, isDark, highlight: true)),
            ],
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(child: _buildInfoCard('Order Date', _dateFormat.format(_currentPo.orderDate), Icons.event_note, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoCard('Expected Delivery', _dateFormat.format(_currentPo.expectedDeliveryDate), Icons.local_shipping_outlined, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoCard('GST Total', '₹${_currentPo.taxAmount.toStringAsFixed(2)}', Icons.account_balance_outlined, isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildInfoCard('Total Amount', '₹${_currentPo.totalAmount.toStringAsFixed(2)}', Icons.payments_outlined, isDark, highlight: true)),
      ],
    );
  }

  Widget _buildInfoCard(String label, String value, IconData icon, bool isDark, {bool highlight = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: highlight ? const Color(0xFF10B981) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: highlight ? const Color(0xFF10B981) : Colors.grey),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 10.5, color: Colors.grey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: highlight ? const Color(0xFF10B981) : (isDark ? Colors.white : const Color(0xFF0F172A)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEmailDialog() async {
    final sent = await showDialog<bool>(
      context: context,
      builder: (ctx) => PoEmailDispatchDialog(po: _currentPo),
    );
    if (sent == true) {
      _fetchFullDetails();
    }
  }

  Future<void> _printOrDownloadPo() async {
    try {
      await PurchaseOrderPdfHelper.printOrDownloadPo(context, _currentPo);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate PDF: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _openHtmlPrintView() async {
    try {
      await PurchaseOrderPdfHelper.openBackendPrintView(_currentPo.id, autoprint: true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open HTML bill view: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }
}
