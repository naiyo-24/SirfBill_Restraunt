import 'package:flutter/material.dart';
import '../../../../config/api_constants.dart';
import '../models/inventory_models.dart';
import 'inventory_status_badge.dart';

/// Reusable responsive card for an ingredient in the catalog
class IngredientCatalogCard extends StatelessWidget {
  final Ingredient item;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const IngredientCatalogCard({
    super.key,
    required this.item,
    required this.isDark,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final healthPercent = (item.stockHealthPercent / 100.0).clamp(0.0, 1.0);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxWidth < 750;
                final isMobile = constraints.maxWidth < 500;

                if (isMobile) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildThumbnail(item, isDark),
                          const SizedBox(width: 12),
                          Expanded(child: _buildItemDetails(item, isDark)),
                          _buildPriceColumn(item, isDark),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _buildStockProgress(item, healthPercent, isDark),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            tooltip: 'Edit Ingredient',
                            onPressed: onEdit,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                            tooltip: 'Delete Ingredient',
                            onPressed: onDelete,
                          ),
                        ],
                      ),
                    ],
                  );
                }

                if (isCompact) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          _buildThumbnail(item, isDark),
                          const SizedBox(width: 14),
                          Expanded(child: _buildItemDetails(item, isDark)),
                          const SizedBox(width: 12),
                          _buildPriceColumn(item, isDark),
                          const SizedBox(width: 8),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Edit',
                                onPressed: onEdit,
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                                tooltip: 'Delete',
                                onPressed: onDelete,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _buildStockProgress(item, healthPercent, isDark),
                    ],
                  );
                }

                // Desktop Row
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildThumbnail(item, isDark),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildItemDetails(item, isDark)),
                    const SizedBox(width: 16),
                    Expanded(flex: 3, child: _buildStockProgress(item, healthPercent, isDark)),
                    const SizedBox(width: 20),
                    _buildPriceColumn(item, isDark),
                    const SizedBox(width: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Ingredient',
                          onPressed: onEdit,
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent),
                          tooltip: 'Delete Ingredient',
                          onPressed: onDelete,
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildItemDetails(Ingredient item, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                item.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                item.code,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          '${item.categoryName.isNotEmpty ? item.categoryName : 'General'} • ${item.storageLocation}',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          'Supplier: ${item.primarySupplierName.isNotEmpty ? item.primarySupplierName : 'Direct Kitchen'}',
          style: TextStyle(
            fontSize: 11,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildStockProgress(Ingredient item, double healthPercent, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Stock: ${item.formattedStock}',
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            InventoryStatusBadge.stockLevel(
              currentStock: item.currentStock,
              minPar: item.minParLevel,
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: healthPercent,
            minHeight: 5,
            backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(
              item.isOutOfStock
                  ? const Color(0xFFEF4444)
                  : (item.isLowStock ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          'Par: ${(item.minParLevel / 1000).toStringAsFixed(1)} kg min / ${(item.idealParLevel / 1000).toStringAsFixed(1)} kg max',
          style: TextStyle(
            fontSize: 10,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPriceColumn(Ingredient item, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${item.costPerPurchaseUnit.toStringAsFixed(0)} / ${item.purchaseUom}',
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          '≈ ₹${(item.costPerRecipeUnit * 100).toStringAsFixed(2)} / 100${item.recipeUom.toLowerCase()}',
          style: TextStyle(
            fontSize: 10.5,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    );
  }

  Widget _buildThumbnail(Ingredient item, bool isDark) {
    final imgUrl = item.imageUrl?.trim() ?? '';
    if (imgUrl.isNotEmpty) {
      final base = ApiConstants.baseUrl.replaceAll(RegExp(r'/+$'), '');
      final String fullUrl;
      if (imgUrl.startsWith('http://') || imgUrl.startsWith('https://')) {
        fullUrl = imgUrl.startsWith(base)
            ? imgUrl
            : '$base/api/restaurant/inventory/proxy-image?url=${Uri.encodeComponent(imgUrl)}';
      } else {
        fullUrl = '$base${imgUrl.startsWith('/') ? '' : '/'}$imgUrl';
      }
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          fullUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildFallbackIcon(isDark),
        ),
      );
    }
    return _buildFallbackIcon(isDark);
  }

  Widget _buildFallbackIcon(bool isDark) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.grain, color: Color(0xFF10B981), size: 22),
    );
  }
}
