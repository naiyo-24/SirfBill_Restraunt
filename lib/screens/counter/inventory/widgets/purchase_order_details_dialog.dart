import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_ops_models.dart';
import '../services/procurement_api_service.dart';
import '../utils/purchase_order_pdf_helper.dart';
import 'inventory_status_badge.dart';
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

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 800,
        constraints: BoxConstraints(maxWidth: 820, maxHeight: MediaQuery.of(context).size.height * 0.90),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(16)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.receipt_long, color: Color(0xFF3B82F6), size: 22),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_currentPo.poNumber, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                        const SizedBox(height: 2),
                        Text('Vendor: ${_currentPo.supplierName}', style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                      ],
                    ),
                  ],
                ),
                Row(
                  children: [
                    InventoryStatusBadge.status(_currentPo.status.label, color: _currentPo.status.color),
                    const SizedBox(width: 8),
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
                          _buildMetaCards(isDark),
                          const SizedBox(height: 16),
                          _buildItemsTable(isDark),
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
            _buildActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaCards(bool isDark) {
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: highlight ? const Color(0xFF10B981) : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(icon, size: 14, color: highlight ? const Color(0xFF10B981) : Colors.grey), const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey))]),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: highlight ? const Color(0xFF10B981) : null)),
        ],
      ),
    );
  }

  Widget _buildItemsTable(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(9)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Ingredient Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                Expanded(flex: 2, child: Text('Ordered Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Unit Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text('GST %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('Line Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              ],
            ),
          ),
          ..._currentPo.items.map((it) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(flex: 3, child: Text(it.ingredientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('${it.orderedQty.toStringAsFixed(1)} ${it.uom}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                      if (it.receivedQty > 0)
                        Text(
                          'Rec: ${it.receivedQty.toStringAsFixed(1)} ${it.uom}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: it.receivedQty >= it.orderedQty ? const Color(0xFF10B981) : Colors.orange,
                          ),
                          textAlign: TextAlign.center,
                        ),
                    ],
                  ),
                ),
                Expanded(flex: 2, child: Text('₹${it.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                Expanded(flex: 2, child: Text('${it.taxRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                Expanded(flex: 2, child: Text('₹${it.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)), textAlign: TextAlign.right)),
              ],
            ),
          )),
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

  Widget _buildPrintSplitButton() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF475569),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: _printOrDownloadPo,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 11, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Print / Download', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 18, color: Colors.white24),
          PopupMenuButton<String>(
            tooltip: 'More Print Options',
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
            onSelected: (val) {
              if (val == 'pdf') _printOrDownloadPo();
              if (val == 'html') _openHtmlPrintView();
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text('Print / Save PDF (A4)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'html',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser_rounded, size: 16, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('Open Backend HTML Bill', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Left side: Cancel PO (isolated to prevent misclicks)
        if (_currentPo.status == POStatus.draft)
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _deletePO,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            label: const Text('Delete Draft', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else if (_currentPo.status == POStatus.sent)
          OutlinedButton.icon(
            onPressed: _isProcessing ? null : _cancelPO,
            icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.orange),
            label: const Text('Cancel PO', style: TextStyle(color: Colors.orange)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else
          const SizedBox.shrink(),

        // Right side: Operational actions, Dismissal, and Primary Call-To-Action
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: _openEmailDialog,
              icon: const Icon(Icons.email_outlined, size: 15, color: Color(0xFF3B82F6)),
              label: const Text('Email PO', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            _buildPrintSplitButton(),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(_currentPo),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 13)),
            ),
            if (_currentPo.status == POStatus.draft) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _issuePO,
                icon: const Icon(Icons.send, size: 15),
                label: const Text('Send to Vendor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ] else if (_currentPo.status == POStatus.sent || _currentPo.status == POStatus.partiallyReceived) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () async {
                  final res = await showDialog(
                    context: context,
                    builder: (ctx) => RecordGrnDialog(initialPo: _currentPo),
                  );
                  if (res != null) {
                    _fetchFullDetails();
                  }
                },
                icon: const Icon(Icons.inventory_2_rounded, size: 15),
                label: const Text('Receive Goods (GRN)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
