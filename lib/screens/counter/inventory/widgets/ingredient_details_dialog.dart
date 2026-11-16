import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../config/api_constants.dart';
import '../models/inventory_models.dart';
import 'inventory_status_badge.dart';

class IngredientDetailsDialog extends StatelessWidget {
  final Ingredient item;
  final VoidCallback? onEdit;
  final VoidCallback? onCreatePo;

  const IngredientDetailsDialog({
    super.key,
    required this.item,
    this.onEdit,
    this.onCreatePo,
  });

  String _resolveFullUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return '';
    final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return trimmed;
    }
    final clean = trimmed.startsWith('/') ? trimmed : '/$trimmed';
    return '$base$clean';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    final factor = item.uomConversionFactor > 0 ? item.uomConversionFactor : 1.0;
    final isDual = item.purchaseUom.toUpperCase() != item.recipeUom.toUpperCase();
    final stockInPurchase = item.currentStock / factor;
    final minParInPurchase = item.minParLevel / factor;
    final idealParInPurchase = item.idealParLevel / factor;
    final remainingSpace = (idealParInPurchase - stockInPurchase).clamp(0.0, double.infinity);
    final healthPercent = (item.stockHealthPercent / 100.0).clamp(0.0, 1.0);
    final totalInventoryValue = item.currentStock * item.costPerRecipeUnit;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 700,
        constraints: BoxConstraints(maxWidth: 740, maxHeight: MediaQuery.of(context).size.height * 0.88),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Header with Image & Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildImagePreview(isDark),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              item.name,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              item.code,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.categoryName.isNotEmpty ? item.categoryName : 'General',
                              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6)),
                            ),
                          ),
                          InventoryStatusBadge.stockLevel(
                            currentStock: item.currentStock,
                            minPar: item.minParLevel,
                          ),
                          if (item.isPerishable)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('Perishable', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Storage: ${item.storageLocation} • Last Restocked: ${dateFormat.format(item.lastRestockedAt)}',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // 2. Metrics KPI Grid
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'CURRENT STOCK',
                    value: '${stockInPurchase.toStringAsFixed(1)} ${item.purchaseUom}',
                    subtext: isDual ? '(${item.currentStock.toStringAsFixed(0)} ${item.recipeUom})' : null,
                    color: item.isOutOfStock ? Colors.red : const Color(0xFF10B981),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'IDEAL PAR (MAX CAP)',
                    value: '${idealParInPurchase.toStringAsFixed(1)} ${item.purchaseUom}',
                    subtext: 'Free Space: ${remainingSpace.toStringAsFixed(1)} ${item.purchaseUom}',
                    color: const Color(0xFF3B82F6),
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'MIN PAR (ALERT)',
                    value: '${minParInPurchase.toStringAsFixed(1)} ${item.purchaseUom}',
                    subtext: isDual ? '(${item.minParLevel.toStringAsFixed(0)} ${item.recipeUom})' : null,
                    color: Colors.orange,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildMetricTile(
                    label: 'LANDED COST',
                    value: '₹${item.costPerPurchaseUnit.toStringAsFixed(2)} / ${item.purchaseUom}',
                    subtext: '≈ ₹${(item.costPerRecipeUnit * 100).toStringAsFixed(2)} / 100${item.recipeUom.toLowerCase()}',
                    color: const Color(0xFF8B5CF6),
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 3. Storage Health & Dual UOM Specifications
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Storage Level Health (${(healthPercent * 100).toStringAsFixed(0)}% of Max Capacity)',
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        remainingSpace > 0 ? '${remainingSpace.toStringAsFixed(1)} ${item.purchaseUom} space remaining' : 'At Full Capacity',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: remainingSpace > 0 ? const Color(0xFF10B981) : Colors.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: healthPercent,
                      minHeight: 8,
                      backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        item.isOutOfStock
                            ? Colors.red
                            : (item.isLowStock ? Colors.orange : const Color(0xFF10B981)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DUAL UOM CONVERSION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('1 ${item.purchaseUom} = ${factor.toStringAsFixed(0)} ${item.recipeUom}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('PRIMARY SUPPLIER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text(item.primarySupplierName.isNotEmpty ? item.primarySupplierName : 'Direct Kitchen', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('TOTAL ON-HAND VALUE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
                            const SizedBox(height: 2),
                            Text('₹${totalInventoryValue.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF10B981))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // 4. Action Footer
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (onCreatePo != null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onCreatePo!();
                    },
                    icon: const Icon(Icons.add_shopping_cart, size: 15),
                    label: const Text('Create Purchase Order', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  )
                else
                  const SizedBox.shrink(),
                Row(
                  children: [
                    if (onEdit != null) ...[
                      OutlinedButton.icon(
                        onPressed: () {
                          Navigator.of(context).pop();
                          onEdit!();
                        },
                        icon: const Icon(Icons.edit_outlined, size: 15),
                        label: const Text('Edit Ingredient', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(width: 10),
                    ],
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF475569),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview(bool isDark) {
    if (item.imageUrl != null && item.imageUrl!.isNotEmpty) {
      final fullUrl = _resolveFullUrl(item.imageUrl!);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          fullUrl,
          width: 64,
          height: 64,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
        ),
      );
    }
    return _buildPlaceholder(isDark);
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: const Icon(Icons.kitchen_rounded, color: Color(0xFF10B981), size: 28),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    String? subtext,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), overflow: TextOverflow.ellipsis),
          if (subtext != null) ...[
            const SizedBox(height: 2),
            Text(subtext, style: const TextStyle(fontSize: 10, color: Colors.grey), overflow: TextOverflow.ellipsis),
          ],
        ],
      ),
    );
  }
}
