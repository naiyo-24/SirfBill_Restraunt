import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';

class AdjustStockDialog extends StatefulWidget {
  final Ingredient? initialIngredient;
  final List<Ingredient> ingredients;
  final VoidCallback onAdjusted;
  final String? initialReason;
  final String? customTitle;

  const AdjustStockDialog({
    super.key,
    this.initialIngredient,
    required this.ingredients,
    required this.onAdjusted,
    this.initialReason,
    this.customTitle,
  });

  @override
  State<AdjustStockDialog> createState() => _AdjustStockDialogState();
}

class _AdjustStockDialogState extends State<AdjustStockDialog> {
  late Ingredient _selectedIngredient;
  final TextEditingController _qtyCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  String _inputUom = 'PURCHASE'; // 'PURCHASE' or 'RECIPE'
  bool _isDeduction = true; // true: negative (-), false: positive (+)
  late String _reason;
  bool _isSaving = false;

  final Map<String, String> _reasons = {
    'MANUAL_CORRECTION': 'Manual Correction',
    'WASTAGE': 'Kitchen Wastage',
    'SPOILAGE': 'Spoiled / Expired Goods',
    'PHYSICAL_COUNT_ADJUSTMENT': 'Physical Count Adjustment',
  };

  @override
  void initState() {
    super.initState();
    _selectedIngredient = widget.initialIngredient ?? widget.ingredients.first;
    _reason = widget.initialReason ?? 'MANUAL_CORRECTION';
    if (_reason == 'WASTAGE' || _reason == 'SPOILAGE') {
      _isDeduction = true;
    }
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  double _getCalculatedSignedQty() {
    final rawQty = double.tryParse(_qtyCtrl.text.trim()) ?? 0.0;
    final absQty = rawQty.abs();
    return _isDeduction ? -absQty : absQty;
  }

  String _getPreviewText() {
    final signedQty = _getCalculatedSignedQty();
    if (signedQty == 0) return 'Enter quantity to preview balance change';

    final sign = signedQty < 0 ? '-' : '+';
    final absVal = signedQty.abs();

    if (_inputUom == 'PURCHASE') {
      final recipeEquiv = absVal * (_selectedIngredient.recipeUom == 'G' || _selectedIngredient.recipeUom == 'ML' ? 1000 : 1);
      return '$sign$absVal ${_selectedIngredient.purchaseUom} ($sign${recipeEquiv.toStringAsFixed(0)} ${_selectedIngredient.recipeUom})';
    } else {
      final purchaseEquiv = absVal / (_selectedIngredient.recipeUom == 'G' || _selectedIngredient.recipeUom == 'ML' ? 1000 : 1);
      return '$sign$absVal ${_selectedIngredient.recipeUom} ($sign${purchaseEquiv.toStringAsFixed(3)} ${_selectedIngredient.purchaseUom})';
    }
  }

  Future<void> _submitAdjustment() async {
    final signedQty = _getCalculatedSignedQty();
    if (signedQty == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid non-zero adjustment quantity')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final success = await InventoryApiService.recordStockAdjustment(
        ingredientId: _selectedIngredient.id,
        signedQuantity: signedQty,
        inputUom: _inputUom,
        reason: _reason,
        notes: _notesCtrl.text.trim(),
      );

      if (!mounted) return;
      if (success) {
        Navigator.pop(context);
        widget.onAdjusted();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Stock adjustment recorded successfully in event ledger'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to record adjustment. Please check server.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.tune_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 10),
          Text(widget.customTitle ?? 'Adjust Stock Balance', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        ],
      ),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ingredient Selector
              if (widget.initialIngredient == null) ...[
                const Text('Select Commodity / Ingredient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                DropdownButtonFormField<Ingredient>(
                  initialValue: _selectedIngredient,
                  isExpanded: true,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  items: widget.ingredients.map((ing) {
                    return DropdownMenuItem(value: ing, child: Text('${ing.name} (${ing.code})'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedIngredient = val);
                  },
                ),
                const SizedBox(height: 14),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_selectedIngredient.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          Text('Code: ${_selectedIngredient.code}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Live Stock', style: TextStyle(fontSize: 11, color: Colors.grey)),
                          Text(_selectedIngredient.formattedStock, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Dual-UOM Selection Mode
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Entry Unit (UOM)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            _buildChoiceChip(
                              label: 'Purchase (${_selectedIngredient.purchaseUom})',
                              isSelected: _inputUom == 'PURCHASE',
                              onSelected: () => setState(() => _inputUom = 'PURCHASE'),
                            ),
                            const SizedBox(width: 8),
                            _buildChoiceChip(
                              label: 'Recipe (${_selectedIngredient.recipeUom})',
                              isSelected: _inputUom == 'RECIPE',
                              onSelected: () => setState(() => _inputUom = 'RECIPE'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Sign Selector (Deduction vs Addition)
              const Text('Adjustment Direction', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Row(
                children: [
                  _buildDirectionButton(
                    label: 'Deduct / Waste (-)',
                    icon: Icons.remove_circle_outline,
                    isSelected: _isDeduction,
                    color: Colors.red,
                    onTap: () => setState(() => _isDeduction = true),
                  ),
                  const SizedBox(width: 10),
                  _buildDirectionButton(
                    label: 'Add / Surpluses (+)',
                    icon: Icons.add_circle_outline,
                    isSelected: !_isDeduction,
                    color: const Color(0xFF10B981),
                    onTap: () => setState(() => _isDeduction = false),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Quantity Field
              TextField(
                controller: _qtyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  labelText: 'Quantity to ${_isDeduction ? 'Deduct' : 'Add'} (${_inputUom == 'PURCHASE' ? _selectedIngredient.purchaseUom : _selectedIngredient.recipeUom}) *',
                  hintText: 'e.g. 2.5',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 6),

              // Live Preview Feedback
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: (_isDeduction ? Colors.red : const Color(0xFF10B981)).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Effect: ${_getPreviewText()}',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _isDeduction ? Colors.red.shade700 : const Color(0xFF059669),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Reason Dropdown
              const Text('Reason', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                initialValue: _reason,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                items: _reasons.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _reason = val);
                },
              ),
              const SizedBox(height: 14),

              // Notes Field
              TextField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes / Remarks (Optional)',
                  hintText: 'e.g. Dropped tray during prep or cycle count',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submitAdjustment,
          style: ElevatedButton.styleFrom(
            backgroundColor: _isDeduction ? Colors.red.shade600 : const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSaving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : Text(_isDeduction ? 'Record Deduction' : 'Record Addition'),
        ),
      ],
    );
  }

  Widget _buildChoiceChip({required String label, required bool isSelected, required VoidCallback onSelected}) {
    return InkWell(
      onTap: onSelected,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF10B981) : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: isSelected ? const Color(0xFF10B981) : Colors.grey.shade400),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? Colors.white : null,
          ),
        ),
      ),
    );
  }

  Widget _buildDirectionButton({
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? color : Colors.grey.shade400, width: isSelected ? 1.5 : 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: isSelected ? color : Colors.grey),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
