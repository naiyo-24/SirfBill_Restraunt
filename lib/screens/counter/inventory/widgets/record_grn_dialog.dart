import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sirfbill_restaurant/screens/counter/inventory/widgets/vendor_invoice_attachment_box.dart';
import '../models/inventory_models.dart';
import '../models/grn_models.dart';
import '../services/inventory_api_service.dart';
import '../services/procurement_api_service.dart';
import 'grn_receiving_table.dart';

class RecordGrnDialog extends StatefulWidget {
  final PurchaseOrder? initialPo;

  const RecordGrnDialog({super.key, this.initialPo});

  @override
  State<RecordGrnDialog> createState() => _RecordGrnDialogState();
}

class _RecordGrnDialogState extends State<RecordGrnDialog> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _invoiceNoController = TextEditingController();
  final TextEditingController _remarksController = TextEditingController();
  final DateFormat _dateFormat = DateFormat('yyyy-MM-dd');
  final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  List<PurchaseOrder> _availablePos = [];
  String? _selectedPoId;
  String? _selectedSupplierId;
  DateTime _invoiceDate = DateTime.now();
  String _nextGrnNumber = '';
  String? _invoiceDocumentUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  final List<GrnItemInput> _items = [];

  @override
  void initState() {
    super.initState();
    _loadPrerequisites();
  }

  @override
  void dispose() {
    _invoiceNoController.dispose();
    _remarksController.dispose();
    for (final it in _items) {
      it.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPrerequisites() async {
    try {
      final results = await Future.wait([
        ProcurementApiService.getPurchaseOrders(),
        InventoryApiService.getSuppliers(),
        ProcurementApiService.getNextGrnNumber(),
      ]);
      if (mounted) {
        final allPos = results[0] as List<PurchaseOrder>;
        setState(() {
          _availablePos = allPos.where((p) => p.status == POStatus.sent || p.status == POStatus.partiallyReceived).toList();
          _nextGrnNumber = results[2] as String;
          _isLoading = false;
        });
        if (widget.initialPo != null) {
          await _hydrateAndSelectPo(widget.initialPo!);
        } else if (_availablePos.isNotEmpty) {
          _onPoSelected(_availablePos.first.id);
        }
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _hydrateAndSelectPo(PurchaseOrder initPo) async {
    PurchaseOrder poToUse = initPo;
    if (poToUse.items.isEmpty) {
      final full = await ProcurementApiService.getPurchaseOrderById(poToUse.id);
      if (full != null) poToUse = full;
    }
    if (mounted) {
      setState(() {
        if (!_availablePos.any((p) => p.id == poToUse.id)) _availablePos = [poToUse, ..._availablePos];
        _onPoSelected(poToUse.id);
      });
    }
  }

  void _onPoSelected(String? poId) {
    _selectedPoId = poId;
    if (poId == null || poId.isEmpty) return;
    final match = _availablePos.where((p) => p.id == poId);
    if (match.isNotEmpty) {
      final po = match.first;
      _selectedSupplierId = po.supplierId;
      for (final it in _items) { it.dispose(); }
      _items.clear();
      for (final poItem in po.items) {
        final remaining = poItem.orderedQty - poItem.receivedQty;
        _items.add(GrnItemInput(
          ingredientId: poItem.ingredientId,
          ingredientName: poItem.ingredientName,
          poItemId: poItem.id.isNotEmpty ? poItem.id : null,
          orderedQty: remaining > 0 ? remaining : poItem.orderedQty,
          unit: poItem.uom,
          initialUnitPrice: poItem.unitPrice,
        ));
      }
    }
    setState(() {});
  }

  double get _subtotal => _items.fold(0.0, (sum, it) => sum + it.subtotal);
  double get _taxAmount => _items.fold(0.0, (sum, it) => sum + it.taxAmount);
  double get _totalAmount => _subtotal + _taxAmount;

  Future<void> _submitGRN() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSupplierId == null || _selectedSupplierId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select supplier / vendor'), backgroundColor: Colors.red));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No goods to receive'), backgroundColor: Colors.red));
      return;
    }

    setState(() => _isSaving = true);
    try {
      final payload = {
        'po_id': _selectedPoId,
        'supplier_id': _selectedSupplierId,
        'supplier_invoice_no': _invoiceNoController.text.trim(),
        'invoice_date': _dateFormat.format(_invoiceDate),
        'invoice_document_url': _invoiceDocumentUrl,
        'remarks': _remarksController.text.trim(),
        'items': _items.map((it) => {
          'ingredient_id': it.ingredientId,
          'po_item_id': it.poItemId,
          'quantity_received': it.quantityReceived,
          'quantity_rejected': it.quantityRejected,
          'rejection_reason': it.rejectionReasonController.text.trim().isNotEmpty ? it.rejectionReasonController.text.trim() : null,
          'unit': it.unit.toUpperCase(),
          'unit_price': it.unitPrice,
          'actual_unit_price': it.unitPrice,
          'tax_rate': it.taxRate,
          'batch_number': it.batchController.text.trim().isNotEmpty ? it.batchController.text.trim() : null,
        }).toList(),
      };

      final created = await ProcurementApiService.createGRN(payload);
      if (mounted) {
        Navigator.of(context).pop(created);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('GRN ${created?.grnNumber ?? ""} recorded & stock updated!'), backgroundColor: const Color(0xFF10B981)));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 650;

    return Dialog(
      insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 40, vertical: isMobile ? 12 : 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 880,
        constraints: BoxConstraints(maxWidth: 880, maxHeight: MediaQuery.of(context).size.height * 0.92),
        padding: EdgeInsets.all(isMobile ? 14 : 26),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
            : Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark, isMobile),
                    SizedBox(height: isMobile ? 12 : 18),
                    Flexible(
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildPoAndInvoiceRow(isDark, isMobile),
                            const SizedBox(height: 14),
                            GrnReceivingTable(
                              items: _items,
                              isDark: isDark,
                              onItemChanged: () => setState(() {}),
                            ),
                            const SizedBox(height: 14),
                            _buildSummaryRow(isDark, isMobile),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: isMobile ? 14 : 20),
                    _buildActions(isMobile),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, bool isMobile) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      'Record Inward Goods (GRN)',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 19,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isMobile) ...[
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                      child: Text(_nextGrnNumber.isNotEmpty ? 'NEXT: $_nextGrnNumber' : 'GATE RECEIPT', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF3B82F6))),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 2),
              Text(
                'Verify delivered goods against vendor invoice & restock inventory',
                style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close_rounded, size: 20)),
      ],
    );
  }

  Widget _buildPoAndInvoiceRow(bool isDark, bool isMobile) {
    final poCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('MATCHING PURCHASE ORDER (PO)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          // ignore: deprecated_member_use
          value: _selectedPoId,
          isExpanded: true,
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.receipt_long, size: 18),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text('-- Direct Inward / No PO --')),
            ..._availablePos.map((p) => DropdownMenuItem(
              value: p.id,
              child: Text('${p.poNumber} (${p.supplierName})', overflow: TextOverflow.ellipsis),
            )),
          ],
          onChanged: _onPoSelected,
        ),
      ],
    );

    final invCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('VENDOR INVOICE / BILL # *', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextFormField(
          controller: _invoiceNoController,
          decoration: InputDecoration(
            hintText: 'e.g. INV-2026-9041',
            prefixIcon: const Icon(Icons.tag_rounded, size: 18),
            filled: true,
            fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
        ),
      ],
    );

    final dateCol = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('INVOICE DATE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        InkWell(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _invoiceDate,
              firstDate: DateTime.now().subtract(const Duration(days: 30)),
              lastDate: DateTime.now(),
            );
            if (picked != null) setState(() => _invoiceDate = picked);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 13),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.event, size: 18, color: Color(0xFF3B82F6)),
                const SizedBox(width: 8),
                Expanded(child: Text(_displayFormat.format(_invoiceDate), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis)),
                const Icon(Icons.arrow_drop_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isMobile) ...[
          poCol,
          const SizedBox(height: 10),
          invCol,
          const SizedBox(height: 10),
          dateCol,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 4, child: poCol),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: invCol),
              const SizedBox(width: 14),
              Expanded(flex: 3, child: dateCol),
            ],
          ),
        const SizedBox(height: 12),
        VendorInvoiceAttachmentBox(
          initialUrl: _invoiceDocumentUrl,
          isDark: isDark,
          onAttachmentChanged: (url) => setState(() => _invoiceDocumentUrl = url),
        ),
      ],
    );
  }

  Widget _buildSummaryRow(bool isDark, bool isMobile) {
    final remarksBox = TextFormField(
      controller: _remarksController,
      maxLines: 2,
      style: const TextStyle(fontSize: 12),
      decoration: InputDecoration(
        labelText: 'Receiving Remarks / Cold-Chain Inspection Notes',
        hintText: 'e.g. Received chilled poultry at 3.2°C, passed physical QA.',
        filled: true,
        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding: const EdgeInsets.all(12),
      ),
    );

    final summaryCard = Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          _summaryLine('Base Inward Cost:', '₹${_subtotal.toStringAsFixed(2)}'),
          const SizedBox(height: 5),
          _summaryLine('Vendor Invoice GST:', '₹${_taxAmount.toStringAsFixed(2)}', color: const Color(0xFFF59E0B)),
          const Divider(height: 14),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Flexible(child: Text('FINAL BILL PAYABLE:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis)),
            FittedBox(fit: BoxFit.scaleDown, child: Text('₹${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: Color(0xFF10B981)))),
          ]),
        ],
      ),
    );

    if (isMobile) {
      return Column(children: [remarksBox, const SizedBox(height: 12), summaryCard]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(flex: 6, child: remarksBox),
        const SizedBox(width: 16),
        Expanded(flex: 4, child: summaryCard),
      ],
    );
  }

  Widget _summaryLine(String label, String value, {Color? color}) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      Text(value, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _buildActions(bool isMobile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        OutlinedButton(
          onPressed: () => Navigator.of(context).pop(),
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: isMobile ? 10 : 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: ElevatedButton.icon(
            onPressed: _isSaving ? null : _submitGRN,
            icon: _isSaving
                ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check_circle_rounded, size: 16),
            label: Text(
              isMobile ? 'Verify & Receive' : 'Verify & Receive Inward Stock',
              style: TextStyle(fontSize: isMobile ? 12 : 13, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: isMobile ? 10 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }
}
