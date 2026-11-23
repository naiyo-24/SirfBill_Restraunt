import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../services/inventory_api_service.dart';

class AuditRowItem {
  final Ingredient ingredient;
  final TextEditingController countController;
  String inputUom; // 'PURCHASE' or 'RECIPE'

  AuditRowItem({
    required this.ingredient,
    required this.countController,
    this.inputUom = 'PURCHASE',
  });

  double? get physicalCount => double.tryParse(countController.text.trim());

  /// Returns variance in Recipe UOM (standard base)
  double? get varianceRecipeUom {
    final count = physicalCount;
    if (count == null) return null;

    final multiplier = (ingredient.recipeUom == 'G' || ingredient.recipeUom == 'ML') ? 1000.0 : 1.0;
    final countInRecipeUom = inputUom == 'PURCHASE' ? count * multiplier : count;
    return countInRecipeUom - ingredient.currentStock;
  }
}

class PhysicalCountAuditDialog extends StatefulWidget {
  final VoidCallback onAuditSubmitted;

  const PhysicalCountAuditDialog({
    super.key,
    required this.onAuditSubmitted,
  });

  @override
  State<PhysicalCountAuditDialog> createState() => _PhysicalCountAuditDialogState();
}

class _PhysicalCountAuditDialogState extends State<PhysicalCountAuditDialog> {
  final TextEditingController _notesCtrl = TextEditingController(text: 'Physical Cycle Count Audit');
  final TextEditingController _searchCtrl = TextEditingController();
  final DateTime _auditStartedAt = DateTime.now().toUtc();

  bool _isLoading = true;
  bool _isSubmitting = false;
  List<AuditRowItem> _rows = [];
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadIngredients();
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    _searchCtrl.dispose();
    for (final r in _rows) {
      r.countController.dispose();
    }
    super.dispose();
  }

  Future<void> _loadIngredients() async {
    setState(() => _isLoading = true);
    try {
      final ingredients = await InventoryApiService.getIngredients();
      if (mounted) {
        setState(() {
          _rows = ingredients.map((ing) {
            return AuditRowItem(
              ingredient: ing,
              countController: TextEditingController(),
              inputUom: 'PURCHASE',
            );
          }).toList();
        });
      }
    } catch (_) {
      if (mounted) setState(() => _rows = []);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAuditBatch() async {
    final enteredItems = _rows.where((r) => r.physicalCount != null).toList();
    if (enteredItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a physical count for at least one item')),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final outletId = await InventoryApiService.getResolvedOutletId();
      final itemsPayload = enteredItems.map((r) {
        return {
          'ingredient_id': r.ingredient.id,
          'physical_count': r.physicalCount!,
          'input_uom': r.inputUom,
          'expected_stock': r.ingredient.currentStock,
        };
      }).toList();

      final result = await InventoryApiService.submitStockAudit(
        outletId: outletId,
        notes: _notesCtrl.text.trim(),
        items: itemsPayload,
        auditStartedAt: _auditStartedAt,
      );

      if (!mounted) return;
      if (result != null) {
        Navigator.pop(context);
        widget.onAuditSubmitted();
        _showAuditSummaryModal(result, enteredItems.length);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit audit batch. Check backend.'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showAuditSummaryModal(Map<String, dynamic> res, int count) {
    double parseVal(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final batchId = res['audit_batch_id']?.toString() ?? 'BATCH-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    final itemsAdjusted = res['items_adjusted'] ?? count;
    final netVariance = parseVal(res['net_variance_rupees']);
    final surplus = parseVal(res['total_surplus_rupees']);
    final deficit = parseVal(res['total_deficit_rupees']);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
            SizedBox(width: 8),
            Text('Audit Batch Recorded', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Audit Batch ID: $batchId', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const Divider(height: 20),
              _summaryRow('Items Counted:', '$count ingredients'),
              _summaryRow('Ledger Adjustments:', '$itemsAdjusted entries posted'),
              _summaryRow('Total Surplus:', '₹${surplus.toStringAsFixed(2)}', valueColor: Colors.teal),
              _summaryRow('Total Deficit:', '₹${deficit.toStringAsFixed(2)}', valueColor: Colors.red),
              const Divider(height: 20),
              _summaryRow(
                'Net Variance Impact:',
                '₹${netVariance.toStringAsFixed(2)}',
                isBold: true,
                valueColor: netVariance >= 0 ? Colors.teal : Colors.red,
              ),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, fontWeight: isBold ? FontWeight.bold : FontWeight.normal)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final filtered = _rows.where((r) {
      final q = _searchQuery.toLowerCase();
      return q.isEmpty ||
          r.ingredient.name.toLowerCase().contains(q) ||
          r.ingredient.code.toLowerCase().contains(q) ||
          r.ingredient.storageLocation.toLowerCase().contains(q);
    }).toList();

    final enteredCount = _rows.where((r) => r.physicalCount != null).length;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 860,
        height: 640,
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.playlist_add_check_rounded, color: Color(0xFF10B981), size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Bulk Physical Stock Audit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                      Text('Count shelf items and reconcile against live ledger balances', style: TextStyle(fontSize: 12, color: Colors.grey)),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Top Bar Controls: Notes + Search + Count Indicator
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextField(
                    controller: _notesCtrl,
                    decoration: InputDecoration(
                      labelText: 'Audit Batch Notes',
                      prefixIcon: const Icon(Icons.edit_note, size: 20),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: _searchCtrl,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      hintText: 'Search items...',
                      prefixIcon: const Icon(Icons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: enteredCount > 0 ? const Color(0xFF10B981).withValues(alpha: 0.12) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$enteredCount / ${_rows.length} Counted',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: enteredCount > 0 ? const Color(0xFF10B981) : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Expanded(flex: 3, child: Text('Commodity / Storage', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Book Balance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Physical Count', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Entry Unit', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                  Expanded(flex: 2, child: Text('Calculated Variance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // Ingredients List
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : filtered.isEmpty
                      ? const Center(child: Text('No commodities found matching filter'))
                      : ListView.separated(
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
                          itemBuilder: (ctx, index) {
                            final row = filtered[index];
                            return _buildAuditItemRow(row, isDark);
                          },
                        ),
            ),

            const SizedBox(height: 16),

            // Actions Bottom Bar
            Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _submitAuditBatch,
                  icon: _isSubmitting
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.send_rounded, size: 15),
                  label: Text(_isSubmitting ? 'Posting...' : 'Submit Batch ($enteredCount items)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAuditItemRow(AuditRowItem row, bool isDark) {
    final variance = row.varianceRecipeUom;
    final ing = row.ingredient;

    Color varianceColor = Colors.grey;
    String varianceText = '—';
    if (variance != null) {
      if (variance > 0) {
        varianceColor = Colors.teal;
        varianceText = '+${(variance / ((ing.recipeUom == 'G' || ing.recipeUom == 'ML') ? 1000 : 1)).toStringAsFixed(2)} ${ing.purchaseUom}';
      } else if (variance < 0) {
        varianceColor = Colors.red;
        varianceText = '${(variance / ((ing.recipeUom == 'G' || ing.recipeUom == 'ML') ? 1000 : 1)).toStringAsFixed(2)} ${ing.purchaseUom}';
      } else {
        varianceColor = Colors.green;
        varianceText = '0.00 (Balanced)';
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // Name & Storage
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ing.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('${ing.code} • ${ing.storageLocation}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),

          // Book Balance
          Expanded(
            flex: 2,
            child: Text(ing.formattedStock, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
          ),

          // Physical Count TextField
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: row.countController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Enter count',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(6)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                ),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Entry Unit Toggle
          Expanded(
            flex: 2,
            child: DropdownButton<String>(
              value: row.inputUom,
              isDense: true,
              underline: const SizedBox(),
              items: [
                DropdownMenuItem(value: 'PURCHASE', child: Text(ing.purchaseUom, style: const TextStyle(fontSize: 12))),
                DropdownMenuItem(value: 'RECIPE', child: Text(ing.recipeUom, style: const TextStyle(fontSize: 12))),
              ],
              onChanged: (val) {
                if (val != null) setState(() => row.inputUom = val);
              },
            ),
          ),

          // Variance Result
          Expanded(
            flex: 2,
            child: Text(
              varianceText,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: varianceColor),
            ),
          ),
        ],
      ),
    );
  }
}
