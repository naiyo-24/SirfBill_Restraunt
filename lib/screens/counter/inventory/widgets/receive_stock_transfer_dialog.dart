import 'package:flutter/material.dart';
import '../models/stock_transfer_models.dart';
import '../services/stock_transfer_api_service.dart';
import 'signature_draw_box.dart';

class _ReceiveItemRow {
  final StockTransferItem item;
  final TextEditingController receivedCtrl;
  final TextEditingController reasonCtrl;
  String inputUom = 'RECIPE';

  _ReceiveItemRow({required this.item})
      : receivedCtrl = TextEditingController(
          text: (item.quantityDispatched > 0 ? item.quantityDispatched : item.quantityRequested)
              .toStringAsFixed((item.quantityDispatched > 0 ? item.quantityDispatched : item.quantityRequested) % 1 == 0 ? 0 : 1),
        ),
        reasonCtrl = TextEditingController();

  double get expectedQty => item.quantityDispatched > 0 ? item.quantityDispatched : item.quantityRequested;
  double get quantityReceived => double.tryParse(receivedCtrl.text.trim()) ?? 0.0;
  double get variance => expectedQty - quantityReceived;
}

class ReceiveStockTransferDialog extends StatefulWidget {
  final StockTransferHeader transfer;
  final VoidCallback onReceived;

  const ReceiveStockTransferDialog({
    super.key,
    required this.transfer,
    required this.onReceived,
  });

  static Future<void> show(
    BuildContext context, {
    required StockTransferHeader transfer,
    required VoidCallback onReceived,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReceiveStockTransferDialog(transfer: transfer, onReceived: onReceived),
    );
  }

  @override
  State<ReceiveStockTransferDialog> createState() => _ReceiveStockTransferDialogState();
}

class _ReceiveStockTransferDialogState extends State<ReceiveStockTransferDialog> {
  late List<_ReceiveItemRow> _rows;
  final TextEditingController _notesCtrl = TextEditingController();
  final SignatureDrawController _receiverSignCtrl = SignatureDrawController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _rows = widget.transfer.items.map((it) => _ReceiveItemRow(item: it)).toList();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _receiverSignCtrl.dispose();
    for (final r in _rows) {
      r.receivedCtrl.dispose();
      r.reasonCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _submitReceipt() async {
    for (final r in _rows) {
      if (r.variance > 0 && r.reasonCtrl.text.trim().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please specify a variance reason for ${r.item.ingredientName} (Shortage: ${r.variance.toStringAsFixed(1)} ${r.item.unit})'), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final itemsPayload = _rows.map((r) => {
        'item_id': r.item.id,
        'quantity_received': r.quantityReceived,
        'input_uom': r.inputUom,
        'variance_reason': r.variance > 0 ? r.reasonCtrl.text.trim() : '',
      }).toList();

      final receiverSig = await _receiverSignCtrl.toPngBase64();
      await StockTransferApiService.receiveTransfer(
        widget.transfer.id,
        items: itemsPayload,
        notes: _notesCtrl.text.trim(),
        receiverSignature: receiverSig,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onReceived();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock Transfer received and reconciled in ledger!'), backgroundColor: Color(0xFF10B981)),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 760,
        height: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.inventory_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Receive & Reconcile ${widget.transfer.transferNumber}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
                      Text('${widget.transfer.fromDisplayLocation} ➔ ${widget.transfer.toDisplayLocation}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Commodity', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Dispatched', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Received Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                          Expanded(flex: 2, child: Text('Variance (Shrinkage)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._rows.map((r) => _buildItemRow(r, isDark, borderColor)),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Receiving Notes / Temperature Verification', hintText: 'e.g. Verified temperature at arrival: 3.5°C'),
                    ),
                    const SizedBox(height: 14),
                    SignatureDrawBox(
                      title: 'Received & Verified By (Chef / Manager Signature)',
                      subtitle: 'Sign using mouse or finger / touch to verify stock arrival',
                      controller: _receiverSignCtrl,
                      height: 100,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _isSaving ? null : _submitReceipt,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Receipt & Blend WAC'),
                ),
              ],
            ),
          ],
        ),
      ),
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

  Widget _buildItemRow(_ReceiveItemRow r, bool isDark, Color borderColor) {
    final hasVariance = r.variance > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasVariance ? Colors.red.withValues(alpha: 0.5) : borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.item.ingredientName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    Text('SKU: ${r.item.sku.isNotEmpty ? r.item.sku : 'N/A'}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(_formatQty(r.expectedQty, r.item.unit), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              ),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: r.receivedCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                    ),
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: Text(
                  hasVariance ? '-${r.variance.toStringAsFixed(1)} ${r.item.unit} (Loss)' : '0.0 (Matched)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: hasVariance ? Colors.red : Colors.teal),
                ),
              ),
            ],
          ),
          if (hasVariance) ...[
            const SizedBox(height: 8),
            TextField(
              controller: r.reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Mandatory Transit Variance Reason *',
                hintText: 'e.g. Transit spillage from tub lid opening / trim loss',
                isDense: true,
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}
