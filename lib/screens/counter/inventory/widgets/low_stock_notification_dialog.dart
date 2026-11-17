import 'package:flutter/material.dart';
import '../models/inventory_models.dart';

class LowStockNotificationDialog extends StatelessWidget {
  final List<Ingredient> lowStockItems;
  final ValueChanged<Ingredient>? onOrderIngredient;
  final VoidCallback? onOrderAll;

  const LowStockNotificationDialog({
    super.key,
    required this.lowStockItems,
    this.onOrderIngredient,
    this.onOrderAll,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Ingredient> lowStockItems,
    ValueChanged<Ingredient>? onOrderIngredient,
    VoidCallback? onOrderAll,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => LowStockNotificationDialog(
        lowStockItems: lowStockItems,
        onOrderIngredient: onOrderIngredient,
        onOrderAll: onOrderAll,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final outOfStockCount = lowStockItems.where((i) => i.isOutOfStock).length;
    final lowCount = lowStockItems.length - outOfStockCount;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      child: Container(
        width: 650,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark, outOfStockCount, lowCount),
            const SizedBox(height: 16),
            Expanded(
              child: lowStockItems.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.separated(
                      itemCount: lowStockItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final item = lowStockItems[index];
                        return _buildNotificationItem(context, item, isDark);
                      },
                    ),
            ),
            if (lowStockItems.isNotEmpty) ...[
              const SizedBox(height: 16),
              _buildFooterActions(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int outOfStockCount, int lowCount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFEF4444), Color(0xFFDC2626)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Low Stock Alerts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.2,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${lowStockItems.length} ITEMS',
                        style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  outOfStockCount > 0
                      ? '$outOfStockCount out of stock • $lowCount below safety par'
                      : 'Replenish commodities before kitchen service is disrupted',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ],
            ),
          ],
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }

  Widget _buildNotificationItem(BuildContext context, Ingredient item, bool isDark) {
    final factor = item.uomConversionFactor > 0 ? item.uomConversionFactor : 1.0;
    final isOut = item.isOutOfStock;
    final accentColor = isOut ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final minParInPurchase = item.minParLevel / factor;
    final idealParInPurchase = item.idealParLevel / factor;

    // Calculate suggested reorder quantity to reach ideal par
    final stockInPurchase = item.currentStock / factor;
    final deficit = (idealParInPurchase > 0 ? (idealParInPurchase - stockInPurchase) : (minParInPurchase - stockInPurchase))
        .clamp(0.0, double.infinity);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: accentColor.withValues(alpha: 0.35),
          width: 1.1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(
                      isOut ? Icons.cancel_rounded : Icons.warning_amber_rounded,
                      size: 16,
                      color: accentColor,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (item.categoryName.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        '(${item.categoryName})',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isOut ? 'OUT OF STOCK' : 'LOW STOCK',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current On-Hand: ${item.formattedStock}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isOut ? const Color(0xFFEF4444) : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Min Par: ${minParInPurchase.toStringAsFixed(1)} ${item.purchaseUom}  •  Deficit: ~${deficit.toStringAsFixed(1)} ${item.purchaseUom}',
                      style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
              if (onOrderIngredient != null)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOrderIngredient!(item);
                  },
                  icon: const Icon(Icons.add_shopping_cart, size: 14),
                  label: const Text('Reorder', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_rounded, size: 40, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 12),
            const Text(
              'All Inventory is Healthy!',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'No ingredients are currently below safety par levels.',
              style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Orders are dispatched to verified suppliers',
          style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
        ),
        Row(
          children: [
            OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Dismiss'),
            ),
            if (onOrderAll != null) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOrderAll!();
                },
                icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
                label: const Text('Create Reorder PO'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
