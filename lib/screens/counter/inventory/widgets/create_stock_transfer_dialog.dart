import 'package:flutter/material.dart';
import '../../../../services/shop_service.dart';
import '../models/inventory_models.dart';
import '../models/stock_transfer_models.dart';
import '../services/inventory_api_service.dart';
import '../services/stock_transfer_api_service.dart';

class _TransferItemRow {
  Ingredient? ingredient;
  final TextEditingController qtyCtrl = TextEditingController();
  String inputUom = 'PURCHASE';

  double get quantity => double.tryParse(qtyCtrl.text.trim()) ?? 0.0;
}

class CreateStockTransferDialog extends StatefulWidget {
  final VoidCallback onCreated;

  const CreateStockTransferDialog({super.key, required this.onCreated});

  static Future<void> show(BuildContext context, {required VoidCallback onCreated}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreateStockTransferDialog(onCreated: onCreated),
    );
  }

  @override
  State<CreateStockTransferDialog> createState() => _CreateStockTransferDialogState();
}

class _CreateStockTransferDialogState extends State<CreateStockTransferDialog> {
  StockTransferType _transferType = StockTransferType.interBranch;
  List<Shop> _shops = [];
  List<Ingredient> _ingredients = [];

  String? _fromOutletId;
  String? _toOutletId;
  final _fromStationCtrl = TextEditingController(text: 'Central Cold Store');
  final _toStationCtrl = TextEditingController(text: 'Prep Kitchen Chiller');
  final _vehicleCtrl = TextEditingController();
  final _driverNameCtrl = TextEditingController();
  final _driverPhoneCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final List<_TransferItemRow> _items = [_TransferItemRow()];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadPrerequisites();
  }

  @override
  void dispose() {
    _fromStationCtrl.dispose();
    _toStationCtrl.dispose();
    _vehicleCtrl.dispose();
    _driverNameCtrl.dispose();
    _driverPhoneCtrl.dispose();
    _notesCtrl.dispose();
    for (final it in _items) {
      it.qtyCtrl.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPrerequisites() async {
    setState(() => _isLoading = true);
    try {
      final shops = await ShopService.getShops(allBranches: true);
      final currentOutlet = await InventoryApiService.getResolvedOutletId();
      final ingredients = await InventoryApiService.getIngredients(outletId: currentOutlet);

      if (mounted) {
        final fromId = currentOutlet.isNotEmpty && shops.any((s) => s.id == currentOutlet)
            ? currentOutlet
            : (shops.isNotEmpty ? shops.first.id : null);
        final otherShops = shops.where((s) => s.id != fromId).toList();
        final toId = otherShops.isNotEmpty ? otherShops.first.id : fromId;

        setState(() {
          _shops = shops;
          _ingredients = ingredients;
          _fromOutletId = fromId;
          _toOutletId = toId;
        });
      }
    } catch (e, st) {
      debugPrint('[CreateStockTransferDialog] Prerequisites error: $e\n$st');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem() => setState(() => _items.add(_TransferItemRow()));

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items[index].qtyCtrl.dispose();
        _items.removeAt(index);
      });
    }
  }

  Future<void> _submit() async {
    final validRows = _items.where((it) => it.ingredient != null && it.quantity > 0).toList();
    if (validRows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one commodity and enter quantity'), backgroundColor: Colors.orange),
      );
      return;
    }

    if (_transferType == StockTransferType.interBranch && _fromOutletId == _toOutletId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inter-Branch transfers require different source and destination outlets'), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      await StockTransferApiService.createTransfer({
        'transfer_type': _transferType == StockTransferType.interBranch ? 'INTER_BRANCH' : 'INTER_STATION',
        'from_outlet_id': _fromOutletId,
        'to_outlet_id': _transferType == StockTransferType.interBranch ? _toOutletId : _fromOutletId,
        'from_station': _fromStationCtrl.text.trim(),
        'to_station': _toStationCtrl.text.trim(),
        'vehicle_number': _transferType == StockTransferType.interStation ? '' : _vehicleCtrl.text.trim(),
        'driver_name': _driverNameCtrl.text.trim(),
        'driver_phone': _driverPhoneCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'items': validRows.map((it) => {
          'ingredient_id': it.ingredient!.id,
          'quantity': it.quantity,
          'input_uom': it.inputUom,
        }).toList(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      widget.onCreated();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stock Transfer created in Draft state!'), backgroundColor: Color(0xFF10B981)),
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
        width: 820,
        height: 670,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.swap_horiz_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Initiate Stock Transfer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Requisition food commodities across outlets or kitchen stations', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 14),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModeSelector(),
                          const SizedBox(height: 14),
                          _buildRoutingSection(isDark, borderColor),
                          const SizedBox(height: 14),
                          _buildLogisticsSection(isDark, borderColor),
                          const SizedBox(height: 14),
                          _buildItemsSection(isDark, borderColor),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _notesCtrl,
                            decoration: const InputDecoration(labelText: 'Handling Notes', hintText: 'e.g. Maintain cold chain at 2°C - 4°C'),
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
                  onPressed: _isSaving ? null : _submit,
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
                  child: _isSaving
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Create Transfer (Draft)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSelector() {
    return Row(
      children: [
        _modeCard(StockTransferType.interBranch, 'Inter-Branch Transfer', 'Commissary ➔ Outlet Branch (Stock & Cost Blended)', Icons.storefront_outlined),
        const SizedBox(width: 10),
        _modeCard(StockTransferType.interStation, 'Inter-Station Transfer', 'Chiller ➔ Prep / Kitchen Station (Internal Movement)', Icons.kitchen_outlined),
      ],
    );
  }

  Widget _modeCard(StockTransferType type, String title, String subtitle, IconData icon) {
    final sel = _transferType == type;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _transferType = type),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: sel ? const Color(0xFF10B981).withValues(alpha: 0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? const Color(0xFF10B981) : Colors.grey.shade400, width: sel ? 1.5 : 1),
          ),
          child: Row(
            children: [
              Icon(icon, color: sel ? const Color(0xFF10B981) : Colors.grey, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: sel ? const Color(0xFF10B981) : null)),
                    Text(subtitle, style: const TextStyle(fontSize: 10.5, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoutingSection(bool isDark, Color borderColor) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Routing & Stations', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 10),
          if (_transferType == StockTransferType.interBranch) ...[
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('from_branch_${_shops.length}_$_fromOutletId'),
                    initialValue: _shops.any((s) => s.id == _fromOutletId) ? _fromOutletId : null,
                    decoration: const InputDecoration(labelText: 'From Branch *'),
                    isExpanded: true,
                    items: _shops
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _fromOutletId = val),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('to_branch_${_shops.length}_$_toOutletId'),
                    initialValue: _shops.any((s) => s.id == _toOutletId) ? _toOutletId : null,
                    decoration: const InputDecoration(labelText: 'To Branch *'),
                    isExpanded: true,
                    items: _shops
                        .map((s) => DropdownMenuItem(
                              value: s.id,
                              child: Text(s.name, overflow: TextOverflow.ellipsis),
                            ))
                        .toList(),
                    onChanged: (val) => setState(() => _toOutletId = val),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(child: TextField(controller: _fromStationCtrl, decoration: const InputDecoration(labelText: 'From Storage / Station'))),
              const SizedBox(width: 12),
              Expanded(child: TextField(controller: _toStationCtrl, decoration: const InputDecoration(labelText: 'To Kitchen Station'))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogisticsSection(bool isDark, Color borderColor) {
    final isStation = _transferType == StockTransferType.interStation;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: borderColor)),
      child: isStation
          ? Row(
              children: [
                Expanded(child: TextField(controller: _driverNameCtrl, decoration: const InputDecoration(labelText: 'Transferred By (Name)', hintText: 'e.g. Ramesh Chef / Staff Name'))),
                const SizedBox(width: 12),
                Expanded(child: TextField(controller: _driverPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Contact Phone', hintText: '+91 98301 23456'))),
              ],
            )
          : Row(
              children: [
                Expanded(child: TextField(controller: _vehicleCtrl, decoration: const InputDecoration(labelText: 'Vehicle / Van Number', hintText: 'WB-02-AK-9821'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _driverNameCtrl, decoration: const InputDecoration(labelText: 'Driver Name', hintText: 'Ramesh Kumar'))),
                const SizedBox(width: 10),
                Expanded(child: TextField(controller: _driverPhoneCtrl, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Driver Phone', hintText: '+91 98301 23456'))),
              ],
            ),
    );
  }

  Widget _buildItemsSection(bool isDark, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Transfer Commodities (Dual-UOM)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            TextButton.icon(
              onPressed: _addItem,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add Line Item'),
              style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ..._items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : Colors.white, borderRadius: BorderRadius.circular(8), border: Border.all(color: borderColor)),
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: DropdownButtonFormField<Ingredient>(
                    initialValue: item.ingredient,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Select Commodity *', isDense: true),
                    items: _ingredients.map((ing) => DropdownMenuItem(value: ing, child: Text('${ing.name} (${ing.formattedStock})'))).toList(),
                    onChanged: (val) => setState(() => item.ingredient = val),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: item.qtyCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Qty (${item.inputUom == 'PURCHASE' ? item.ingredient?.purchaseUom ?? 'UOM' : item.ingredient?.recipeUom ?? 'UOM'})',
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: DropdownButton<String>(
                    value: item.inputUom,
                    isDense: true,
                    underline: const SizedBox(),
                    items: [
                      DropdownMenuItem(value: 'PURCHASE', child: Text(item.ingredient?.purchaseUom ?? 'Purchase')),
                      DropdownMenuItem(value: 'RECIPE', child: Text(item.ingredient?.recipeUom ?? 'Recipe')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => item.inputUom = val);
                    },
                  ),
                ),
                IconButton(
                  onPressed: () => _removeItem(index),
                  icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
