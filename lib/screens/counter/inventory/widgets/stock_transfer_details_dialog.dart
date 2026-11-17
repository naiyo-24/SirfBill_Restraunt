import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_transfer_models.dart';
import '../services/stock_transfer_api_service.dart';
import 'inventory_status_badge.dart';
import 'receive_stock_transfer_dialog.dart';

class StockTransferDetailsDialog extends StatefulWidget {
  final StockTransferHeader transfer;
  final VoidCallback onUpdated;

  const StockTransferDetailsDialog({
    super.key,
    required this.transfer,
    required this.onUpdated,
  });

  static Future<void> show(
    BuildContext context, {
    required StockTransferHeader transfer,
    required VoidCallback onUpdated,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => StockTransferDetailsDialog(transfer: transfer, onUpdated: onUpdated),
    );
  }

  @override
  State<StockTransferDetailsDialog> createState() => _StockTransferDetailsDialogState();
}

class _StockTransferDetailsDialogState extends State<StockTransferDetailsDialog> {
  late StockTransferHeader _t;
  bool _isActionInProgress = false;

  @override
  void initState() {
    super.initState();
    _t = widget.transfer;
  }

  Future<void> _dispatchTransfer() async {
    final vehicleCtrl = TextEditingController(text: _t.vehicleNumber);
    final driverCtrl = TextEditingController(text: _t.driverName);
    final notesCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Confirm Dispatch & Lock Stock', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('This will deduct stock from source and log TRANSFER_OUT ledger entries.', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle / Van Number')),
              const SizedBox(height: 10),
              TextField(controller: driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Dispatch Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
            child: const Text('Dispatch Goods'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionInProgress = true);
    try {
      await StockTransferApiService.dispatchTransfer(
        _t.id,
        vehicleNumber: vehicleCtrl.text.trim(),
        driverName: driverCtrl.text.trim(),
        notes: notesCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context);
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer dispatched successfully! Items are In-Transit.'), backgroundColor: Colors.blue),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  Future<void> _cancelTransfer() async {
    final reasonCtrl = TextEditingController();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Stock Transfer', style: TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Are you sure you want to cancel this transfer? Any in-transit items will be restored to source stock.', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              TextField(controller: reasonCtrl, decoration: const InputDecoration(labelText: 'Cancellation Reason *')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Close')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Confirm Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isActionInProgress = true);
    try {
      await StockTransferApiService.cancelTransfer(_t.id, reason: reasonCtrl.text.trim());
      if (!mounted) return;
      Navigator.pop(context);
      widget.onUpdated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer cancelled and ledger reversed.'), backgroundColor: Colors.orange),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isActionInProgress = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 840,
        height: 680,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(_t.transferNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          const SizedBox(width: 8),
                          InventoryStatusBadge.status(_t.status.label.toUpperCase(), color: _t.status.color),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _t.transferType.label,
                              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : const Color(0xFF475569)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Created: ${dateFormat.format(_t.createdAt)} • Initiated by ${_t.transferredBy}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoutingCard(isDark, borderColor),
                    const SizedBox(height: 14),
                    _buildLogisticsCard(isDark, borderColor),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Line Items (${_t.items.length})', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        if (_t.totalValuation > 0)
                          Text('Valuation: ₹${_t.totalValuation.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF10B981))),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildItemsTable(isDark, borderColor),
                    if (_t.notes.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8)),
                        child: Text('Notes: ${_t.notes}', style: const TextStyle(fontSize: 12)),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildRoutingCard(bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Source (Dispatch From)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_t.fromDisplayLocation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (_t.fromStation.isNotEmpty && _t.transferType == StockTransferType.interBranch)
                  Text('Station: ${_t.fromStation}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_rounded, color: Color(0xFF10B981), size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Destination (Receiving At)', style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(_t.toDisplayLocation, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                if (_t.toStation.isNotEmpty && _t.transferType == StockTransferType.interBranch)
                  Text('Station: ${_t.toStation}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsCard(bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _logisticsItem(Icons.local_shipping_outlined, 'Vehicle', _t.vehicleNumber.isNotEmpty ? _t.vehicleNumber : 'Not assigned'),
          _logisticsItem(Icons.person_pin_outlined, 'Driver', _t.driverName.isNotEmpty ? _t.driverName : 'Unassigned'),
          _logisticsItem(Icons.phone_outlined, 'Contact', _t.driverPhone.isNotEmpty ? _t.driverPhone : 'Not provided'),
        ],
      ),
    );
  }

  Widget _logisticsItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }

  Widget _buildItemsTable(bool isDark, Color borderColor) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: const Row(
              children: [
                Expanded(flex: 3, child: Text('Commodity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('Dispatched', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('Received', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('Variance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(flex: 2, child: Text('Total Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
              ],
            ),
          ),
          ..._t.items.map((it) {
            final hasLoss = it.quantityVariance > 0;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(it.ingredientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        if (it.sku.isNotEmpty) Text('SKU: ${it.sku}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                      ],
                    ),
                  ),
                  Expanded(flex: 2, child: Text('${it.quantityDispatched} ${it.unit}', style: const TextStyle(fontSize: 12))),
                  Expanded(flex: 2, child: Text(_t.status == StockTransferStatus.completed ? '${it.quantityReceived} ${it.unit}' : 'Pending', style: const TextStyle(fontSize: 12))),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLoss ? '-${it.quantityVariance} ${it.unit}' : '0.0',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: hasLoss ? Colors.red : Colors.teal),
                        ),
                        if (hasLoss && it.varianceReason.isNotEmpty) Text(it.varianceReason, style: const TextStyle(fontSize: 9.5, color: Colors.redAccent)),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text('₹${it.totalCost.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        if (_t.status == StockTransferStatus.draft || _t.status == StockTransferStatus.inTransit)
          TextButton.icon(
            onPressed: _isActionInProgress ? null : _cancelTransfer,
            icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.redAccent),
            label: const Text('Cancel Transfer', style: TextStyle(color: Colors.redAccent)),
          )
        else
          const SizedBox(),
        Row(
          children: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            if (_t.status == StockTransferStatus.draft) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isActionInProgress ? null : _dispatchTransfer,
                icon: const Icon(Icons.local_shipping_outlined, size: 16),
                label: const Text('Dispatch Goods'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
              ),
            ],
            if (_t.status == StockTransferStatus.inTransit) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: _isActionInProgress
                    ? null
                    : () {
                        Navigator.pop(context);
                        ReceiveStockTransferDialog.show(context, transfer: _t, onReceived: widget.onUpdated);
                      },
                icon: const Icon(Icons.inventory_rounded, size: 16),
                label: const Text('Receive & Reconcile'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
