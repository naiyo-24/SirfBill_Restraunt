import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/inventory_models.dart';
import '../models/po_line_item_input.dart';
import '../services/inventory_api_service.dart';
import '../services/procurement_api_service.dart';
import 'po_line_items_table.dart';
import 'po_summary_section.dart';

class CreatePurchaseOrderDialog extends StatefulWidget {
  final Ingredient? initialIngredient;
  final List<Ingredient>? initialIngredients;

  const CreatePurchaseOrderDialog({
    super.key,
    this.initialIngredient,
    this.initialIngredients,
  });

  static Future<PurchaseOrder?> show(
    BuildContext context, {
    Ingredient? initialIngredient,
    List<Ingredient>? initialIngredients,
  }) {
    return showDialog<PurchaseOrder>(
      context: context,
      barrierDismissible: false,
      builder: (_) => CreatePurchaseOrderDialog(
        initialIngredient: initialIngredient,
        initialIngredients: initialIngredients,
      ),
    );
  }

  @override
  State<CreatePurchaseOrderDialog> createState() => _CreatePurchaseOrderDialogState();
}

class _CreatePurchaseOrderDialogState extends State<CreatePurchaseOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _notesController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  List<Supplier> _suppliers = [];
  List<Ingredient> _ingredients = [];
  String? _selectedSupplierId;
  DateTime _expectedDeliveryDate = DateTime.now().add(const Duration(days: 2));
  bool _sendImmediately = true;
  bool _isLoading = true;
  bool _isSaving = false;
  final List<PoLineItemInput> _items = [];

  @override
  void initState() {
    super.initState();
    _loadPrerequisites();
  }

  @override
  void dispose() {
    _notesController.dispose();
    for (final item in _items) {
      item.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPrerequisites() async {
    try {
      final results = await Future.wait([
        InventoryApiService.getSuppliers(),
        InventoryApiService.getIngredients(),
      ]);
      if (mounted) {
        setState(() {
          _suppliers = results[0] as List<Supplier>;
          _ingredients = results[1] as List<Ingredient>;

          final prefillList = widget.initialIngredients ??
              (widget.initialIngredient != null ? [widget.initialIngredient!] : <Ingredient>[]);

          if (prefillList.isNotEmpty) {
            for (final ing in prefillList) {
              final item = PoLineItemInput();
              item.ingredientId = ing.id;
              item.ingredientName = ing.name;
              item.unit = ing.purchaseUom.isNotEmpty ? ing.purchaseUom : 'KG';
              item.priceController.text = ing.costPerPurchaseUnit > 0
                  ? (ing.costPerPurchaseUnit == ing.costPerPurchaseUnit.roundToDouble()
                      ? ing.costPerPurchaseUnit.toInt().toString()
                      : ing.costPerPurchaseUnit.toStringAsFixed(2))
                  : '100';

              final factor = ing.uomConversionFactor > 0 ? ing.uomConversionFactor : 1.0;
              final deficit = (ing.idealParLevel > ing.currentStock)
                  ? ((ing.idealParLevel - ing.currentStock) / factor)
                  : 1.0;
              final reorderQty = deficit <= 0 ? 1.0 : deficit;
              item.qtyController.text = reorderQty == reorderQty.roundToDouble()
                  ? reorderQty.toInt().toString()
                  : reorderQty.toStringAsFixed(1);
              _items.add(item);
            }
            final first = prefillList.first;
            if (first.primarySupplierId.isNotEmpty && _suppliers.any((s) => s.id == first.primarySupplierId)) {
              _selectedSupplierId = first.primarySupplierId;
            } else if (_suppliers.isNotEmpty) {
              _selectedSupplierId = _suppliers.first.id;
            }
          } else {
            String? prefSup;
            if (_ingredients.isNotEmpty) {
              final first = _ingredients.first;
              if (first.primarySupplierId.isNotEmpty && _suppliers.any((s) => s.id == first.primarySupplierId)) {
                prefSup = first.primarySupplierId;
              }
            }
            _selectedSupplierId = prefSup ?? (_suppliers.isNotEmpty ? _suppliers.first.id : null);
            _addItem();
          }
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _addItem() {
    final item = PoLineItemInput();
    if (_ingredients.isNotEmpty) {
      final first = _ingredients.first;
      item.ingredientId = first.id;
      item.ingredientName = first.name;
      item.unit = first.purchaseUom.isNotEmpty ? first.purchaseUom : 'KG';
      item.priceController.text = first.costPerPurchaseUnit > 0
          ? (first.costPerPurchaseUnit == first.costPerPurchaseUnit.roundToDouble()
              ? first.costPerPurchaseUnit.toInt().toString()
              : first.costPerPurchaseUnit.toStringAsFixed(2))
          : '100';

      if (_items.isEmpty && first.primarySupplierId.isNotEmpty && _suppliers.any((s) => s.id == first.primarySupplierId)) {
        _selectedSupplierId = first.primarySupplierId;
      }
    }
    setState(() => _items.add(item));
  }

  void _removeItem(int index) {
    if (_items.length <= 1) return;
    final item = _items.removeAt(index);
    item.dispose();
    setState(() {});
  }

  void _onIngredientSelected(PoLineItemInput lineItem, String? ingId) {
    if (ingId == null) return;
    final match = _ingredients.where((i) => i.id == ingId).toList();
    if (match.isNotEmpty) {
      final ing = match.first;
      setState(() {
        lineItem.ingredientId = ing.id;
        lineItem.ingredientName = ing.name;
        lineItem.unit = ing.purchaseUom.isNotEmpty ? ing.purchaseUom : 'KG';
        lineItem.priceController.text = ing.costPerPurchaseUnit > 0
            ? (ing.costPerPurchaseUnit == ing.costPerPurchaseUnit.roundToDouble()
                ? ing.costPerPurchaseUnit.toInt().toString()
                : ing.costPerPurchaseUnit.toStringAsFixed(2))
            : '100';

        // Suggest primary supplier only if no supplier has been chosen yet
        if (_selectedSupplierId == null && ing.primarySupplierId.isNotEmpty && _suppliers.any((s) => s.id == ing.primarySupplierId)) {
          _selectedSupplierId = ing.primarySupplierId;
        }
      });
    }
  }

  double get _subtotal => _items.fold(0.0, (sum, it) => sum + it.subtotal);

  Future<void> _submitPO() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a supplier / vendor'), backgroundColor: Colors.red));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one line item'), backgroundColor: Colors.red));
      return;
    }

    // Prevent ordering in excess of max capacity (ideal par level)
    for (final it in _items) {
      final matching = _ingredients.where((i) => i.id == it.ingredientId).toList();
      if (matching.isNotEmpty) {
        final ing = matching.first;
        if (ing.idealParLevel > 0) {
          final factor = ing.uomConversionFactor > 0 ? ing.uomConversionFactor : 1.0;
          final isPurchase = it.unit.toUpperCase() == ing.purchaseUom.toUpperCase();
          final stockInUnit = isPurchase ? (ing.currentStock / factor) : ing.currentStock;
          final idealParInUnit = isPurchase ? (ing.idealParLevel / factor) : ing.idealParLevel;
          final availSpace = (idealParInUnit - stockInUnit).clamp(0.0, double.infinity);

          if (it.quantity > availSpace) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Order quantity (${it.quantity.toStringAsFixed(1)} ${it.unit}) for "${ing.name}" exceeds max capacity! Available space is ${availSpace.toStringAsFixed(1)} ${it.unit} (Ideal Par: ${idealParInUnit.toStringAsFixed(1)} ${it.unit}).',
                ),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 4),
              ),
            );
            return;
          }
        }
      }
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'supplier_id': _selectedSupplierId,
        'order_date': _dateFormat.format(DateTime.now()),
        'expected_delivery_date': _dateFormat.format(_expectedDeliveryDate),
        'notes': _notesController.text.trim(),
        'items': _items.map((it) => {
          'ingredient_id': it.ingredientId,
          'quantity_ordered': it.quantity,
          'unit': it.unit.toUpperCase(),
          'unit_price': it.unitPrice,
          'tax_rate': 0.0,
        }).toList(),
      };

      PurchaseOrder? createdPo = await ProcurementApiService.createPurchaseOrder(payload);
      if (createdPo != null && _sendImmediately) {
        createdPo = await ProcurementApiService.issuePurchaseOrder(createdPo.id);
      }

      if (mounted) {
        Navigator.of(context).pop(createdPo);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_sendImmediately
                ? 'PO ${createdPo?.poNumber ?? ''} created & dispatched to vendor!'
                : 'PO ${createdPo?.poNumber ?? ''} saved as Draft!'),
            backgroundColor: const Color(0xFF10B981),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        width: 880,
        constraints: BoxConstraints(maxWidth: 880, maxHeight: MediaQuery.of(context).size.height * 0.92),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.45 : 0.12),
              blurRadius: 28,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        padding: const EdgeInsets.all(26),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 18),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSupplierAndDateRow(isDark),
                            const SizedBox(height: 20),
                            PoLineItemsTable(
                              items: _items,
                              ingredients: _ingredients,
                              onAddItem: _addItem,
                              onRemoveItem: _removeItem,
                              onIngredientSelected: _onIngredientSelected,
                              onItemChanged: () => setState(() {}),
                              isDark: isDark,
                            ),
                            const SizedBox(height: 20),
                            PoSummarySection(
                              notesController: _notesController,
                              sendImmediately: _sendImmediately,
                              onSendImmediatelyChanged: (v) => setState(() => _sendImmediately = v),
                              itemsCount: _items.length,
                              subtotal: _subtotal,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildActions(isDark),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF10B981), Color(0xFF059669)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Create Purchase Order (PO)',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'PO-REQUISITION',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Procure commodities & replenish kitchen storage inventory',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        InkWell(
          onTap: () => Navigator.of(context).pop(),
          borderRadius: BorderRadius.circular(50),
          child: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.close_rounded, size: 18, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildSupplierAndDateRow(bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TARGET SUPPLIER / VENDOR', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _suppliers.any((s) => s.id == _selectedSupplierId) ? _selectedSupplierId : null,
                isExpanded: true,
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A), fontWeight: FontWeight.w600),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF10B981)),
                  filled: true,
                  fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                items: _suppliers.map((s) => DropdownMenuItem(value: s.id, child: Text('${s.name} ${s.phone.isNotEmpty ? "(${s.phone})" : ""}', overflow: TextOverflow.ellipsis))).toList(),
                onChanged: (v) => setState(() => _selectedSupplierId = v),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          flex: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('EXPECTED DELIVERY DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569))),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(context: context, initialDate: _expectedDeliveryDate, firstDate: DateTime.now(), lastDate: DateTime.now().add(const Duration(days: 90)));
                  if (picked != null) setState(() => _expectedDeliveryDate = picked);
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(10), border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
                  child: Row(
                    children: [
                      const Icon(Icons.event_available_rounded, size: 18, color: Color(0xFF10B981)),
                      const SizedBox(width: 10),
                      Text(_displayFormat.format(_expectedDeliveryDate), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      const Spacer(),
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 14),
        ElevatedButton.icon(
          onPressed: _isSaving ? null : _submitPO,
          icon: _isSaving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Icon(_sendImmediately ? Icons.send_rounded : Icons.save_rounded, size: 16),
          label: Text(_sendImmediately ? 'Create & Dispatch PO' : 'Save as Draft', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, elevation: 3, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
        ),
      ],
    );
  }
}
