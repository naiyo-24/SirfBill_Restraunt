import 'package:flutter/material.dart';
import '../models/stock_transfer_models.dart';
import '../services/stock_transfer_api_service.dart';
import 'signature_draw_box.dart';

class DispatchStockTransferDialog extends StatefulWidget {
  final StockTransferHeader transfer;
  final VoidCallback onDispatched;

  const DispatchStockTransferDialog({
    super.key,
    required this.transfer,
    required this.onDispatched,
  });

  static Future<void> show(
    BuildContext context, {
    required StockTransferHeader transfer,
    required VoidCallback onDispatched,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => DispatchStockTransferDialog(transfer: transfer, onDispatched: onDispatched),
    );
  }

  @override
  State<DispatchStockTransferDialog> createState() => _DispatchStockTransferDialogState();
}

class _DispatchStockTransferDialogState extends State<DispatchStockTransferDialog> {
  late final TextEditingController _vehicleCtrl;
  late final TextEditingController _driverCtrl;
  final TextEditingController _notesCtrl = TextEditingController();

  final SignatureDrawController _senderSignCtrl = SignatureDrawController();
  final SignatureDrawController _driverSignCtrl = SignatureDrawController();

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _vehicleCtrl = TextEditingController(text: widget.transfer.vehicleNumber);
    _driverCtrl = TextEditingController(text: widget.transfer.driverName);
  }

  @override
  void dispose() {
    _vehicleCtrl.dispose();
    _driverCtrl.dispose();
    _notesCtrl.dispose();
    _senderSignCtrl.dispose();
    _driverSignCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitDispatch() async {
    setState(() => _isSaving = true);
    try {
      final senderSig = await _senderSignCtrl.toPngBase64();
      final driverSig = await _driverSignCtrl.toPngBase64();

      await StockTransferApiService.dispatchTransfer(
        widget.transfer.id,
        vehicleNumber: _vehicleCtrl.text.trim(),
        driverName: _driverCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        senderSignature: senderSig,
        driverSignature: driverSig,
      );

      if (!mounted) return;
      Navigator.pop(context);
      widget.onDispatched();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transfer dispatched successfully! Items are In-Transit with digital sign-off.'),
          backgroundColor: Colors.blue,
        ),
      );
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isStation = widget.transfer.transferType == StockTransferType.interStation;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 600,
        height: 640,
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.local_shipping_outlined, color: Colors.blue, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(isStation ? 'Confirm Inter-Station Transfer' : 'Confirm Dispatch & Lock Stock', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text(
                        isStation ? 'Internal kitchen movement • Digital storekeeper sign-off' : 'Deducts source stock, locks manifest & authorizes transport',
                        style: const TextStyle(fontSize: 11.5, color: Colors.grey),
                      ),
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
                    if (!isStation) ...[
                      Row(
                        children: [
                          Expanded(child: TextField(controller: _vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle / Van Number', isDense: true))),
                          const SizedBox(width: 12),
                          Expanded(child: TextField(controller: _driverCtrl, decoration: const InputDecoration(labelText: 'Driver Name', isDense: true))),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ] else ...[
                      TextField(controller: _driverCtrl, decoration: const InputDecoration(labelText: 'Transferred By (Staff Name)', isDense: true)),
                      const SizedBox(height: 12),
                    ],
                    TextField(
                      controller: _notesCtrl,
                      decoration: const InputDecoration(labelText: 'Dispatch Notes', hintText: 'e.g. Dispatched in insulated crate box #4', isDense: true),
                    ),
                    const SizedBox(height: 16),
                    SignatureDrawBox(
                      title: '1. Dispatched By (Storekeeper / Sender Signature)',
                      subtitle: 'Sign using mouse or finger / touch to authorize goods exit',
                      controller: _senderSignCtrl,
                      height: 100,
                    ),
                    if (!isStation) ...[
                      const SizedBox(height: 14),
                      SignatureDrawBox(
                        title: '2. Carrier / Driver Signature',
                        subtitle: 'Driver signs acknowledging physical receipt and vehicle loading',
                        controller: _driverSignCtrl,
                        height: 100,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _submitDispatch,
                  icon: _isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline, size: 16),
                  label: Text(isStation ? 'Authorize Transfer' : 'Dispatch Goods & Sign'),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
