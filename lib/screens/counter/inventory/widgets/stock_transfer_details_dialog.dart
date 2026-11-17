import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_transfer_models.dart';
import '../services/inventory_api_service.dart';
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
  String _currentOutletId = '';

  @override
  void initState() {
    super.initState();
    _t = widget.transfer;
    _resolveCurrentOutlet();
  }

  Future<void> _resolveCurrentOutlet() async {
    final outlet = await InventoryApiService.getResolvedOutletId();
    if (mounted) setState(() => _currentOutletId = outlet);
  }

  Future<void> _dispatchTransfer() async {
    final isStation = _t.transferType == StockTransferType.interStation;
    final vehicleCtrl = TextEditingController(text: _t.vehicleNumber);
    final driverCtrl = TextEditingController(text: _t.driverName);
    final notesCtrl = TextEditingController();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(isStation ? 'Confirm Inter-Station Transfer' : 'Confirm Dispatch & Lock Stock', style: const TextStyle(fontWeight: FontWeight.bold)),
        content: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(isStation ? 'This will transfer stock to destination station.' : 'This will deduct stock from source and log TRANSFER_OUT ledger entries.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 12),
              if (!isStation) ...[
                TextField(controller: vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle / Van Number')),
                const SizedBox(height: 10),
              ],
              TextField(controller: driverCtrl, decoration: InputDecoration(labelText: isStation ? 'Transferred By (Staff Name)' : 'Driver Name')),
              const SizedBox(height: 10),
              TextField(controller: notesCtrl, decoration: const InputDecoration(labelText: 'Dispatch Notes')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white), child: Text(isStation ? 'Transfer Stock' : 'Dispatch Goods')),
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
          ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white), child: const Text('Confirm Cancel')),
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
                IconButton(
                  tooltip: 'Digital Bill / Print Challan',
                  onPressed: () => StockTransferApiService.openTransferBillView(_t.id),
                  icon: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981)),
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
    final isStation = _t.transferType == StockTransferType.interStation;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: isStation
            ? [
                _logisticsItem(Icons.person_pin_outlined, 'Transferred By', _t.driverName.isNotEmpty ? _t.driverName : (_t.transferredBy.isNotEmpty ? _t.transferredBy : 'Staff')),
                _logisticsItem(Icons.phone_outlined, 'Contact Phone', _t.driverPhone.isNotEmpty ? _t.driverPhone : 'Not provided'),
              ]
            : [
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

  String _formatQty(double qty, String unit) {
    final u = unit.trim().toUpperCase();
    if ((u == 'G' || u == 'GM') && qty >= 1000) {
      final kg = qty / 1000;
      final kgStr = kg % 1 == 0 ? kg.toStringAsFixed(0) : kg.toStringAsFixed(2);
      final gmStr = qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(1);
      return '$kgStr KG ($gmStr GM)';
    }
    if (u == 'ML' && qty >= 1000) {
      final ltr = qty / 1000;
      final ltrStr = ltr % 1 == 0 ? ltr.toStringAsFixed(0) : ltr.toStringAsFixed(2);
      final mlStr = qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(1);
      return '$ltrStr LTR ($mlStr ML)';
    }
    final qStr = qty % 1 == 0 ? qty.toStringAsFixed(0) : qty.toStringAsFixed(2);
    return '$qStr $unit';
  }

  Widget _buildItemsTable(bool isDark, Color borderColor) {
    return Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
            child: Row(
              children: [
                const Expanded(flex: 3, child: Text('Commodity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                Expanded(
                  flex: 2,
                  child: Text(
                    _t.status == StockTransferStatus.draft ? 'Requested' : 'Dispatched',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                const Expanded(flex: 2, child: Text('Received', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const Expanded(flex: 2, child: Text('Variance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
                const Expanded(flex: 2, child: Text('Total Cost', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11))),
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
                  Expanded(
                    flex: 2,
                    child: Text(
                      _t.status == StockTransferStatus.draft
                          ? _formatQty(it.quantityRequested, it.unit)
                          : _formatQty(it.quantityDispatched, it.unit),
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      _t.status == StockTransferStatus.completed
                          ? _formatQty(it.quantityReceived, it.unit)
                          : 'Pending',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          hasLoss ? '-${_formatQty(it.quantityVariance, it.unit)}' : '0.0',
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
    final isDestination = _currentOutletId.isEmpty || _t.toOutletId == _currentOutletId;
    final isSource = _currentOutletId.isEmpty || _t.fromOutletId == _currentOutletId;

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
            OutlinedButton.icon(
              onPressed: () => StockTransferApiService.openTransferBillView(_t.id),
              icon: const Icon(Icons.receipt_long_rounded, size: 16),
              label: const Text('Digital Bill'),
              style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF10B981), side: const BorderSide(color: Color(0xFF10B981)), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8)),
            ),
            const SizedBox(width: 8),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
            if (_t.status == StockTransferStatus.draft) ...[
              const SizedBox(width: 10),
              if (isSource)
                ElevatedButton.icon(
                  onPressed: _isActionInProgress ? null : _dispatchTransfer,
                  icon: const Icon(Icons.local_shipping_outlined, size: 16),
                  label: const Text('Dispatch Goods'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Awaiting Dispatch', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Colors.grey)),
                ),
            ],
            if (_t.status == StockTransferStatus.inTransit) ...[
              const SizedBox(width: 10),
              if (isDestination)
                ElevatedButton.icon(
                  onPressed: _isActionInProgress ? null : () { Navigator.pop(context); ReceiveStockTransferDialog.show(context, transfer: _t, onReceived: widget.onUpdated); },
                  icon: const Icon(Icons.inventory_rounded, size: 16),
                  label: const Text('Receive & Reconcile'),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.blue.withValues(alpha: 0.3))),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.local_shipping_rounded, size: 16, color: Colors.blue),
                      const SizedBox(width: 6),
                      Text('En Route to ${_t.toOutletName.isNotEmpty ? _t.toOutletName : "Destination"}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.blue)),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ],
    );
  }
}
