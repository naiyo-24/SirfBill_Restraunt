import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import '../models/stock_transfer_models.dart';

class LowStockNotificationDialog extends StatelessWidget {
  final List<Ingredient> lowStockItems;
  final List<StockTransferHeader> incomingTransfers;
  final List<StockTransferHeader> outboundVarianceTransfers;
  final ValueChanged<Ingredient>? onOrderIngredient;
  final VoidCallback? onOrderAll;
  final ValueChanged<StockTransferHeader>? onReceiveTransfer;
  final ValueChanged<StockTransferHeader>? onInspectTransfer;

  const LowStockNotificationDialog({
    super.key,
    required this.lowStockItems,
    this.incomingTransfers = const [],
    this.outboundVarianceTransfers = const [],
    this.onOrderIngredient,
    this.onOrderAll,
    this.onReceiveTransfer,
    this.onInspectTransfer,
  });

  static Future<void> show(
    BuildContext context, {
    required List<Ingredient> lowStockItems,
    List<StockTransferHeader> incomingTransfers = const [],
    List<StockTransferHeader> outboundVarianceTransfers = const [],
    ValueChanged<Ingredient>? onOrderIngredient,
    VoidCallback? onOrderAll,
    ValueChanged<StockTransferHeader>? onReceiveTransfer,
    ValueChanged<StockTransferHeader>? onInspectTransfer,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => LowStockNotificationDialog(
        lowStockItems: lowStockItems,
        incomingTransfers: incomingTransfers,
        outboundVarianceTransfers: outboundVarianceTransfers,
        onOrderIngredient: onOrderIngredient,
        onOrderAll: onOrderAll,
        onReceiveTransfer: onReceiveTransfer,
        onInspectTransfer: onInspectTransfer,
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
        width: 680,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context, isDark, outOfStockCount, lowCount, outboundVarianceTransfers.length),
            const SizedBox(height: 16),
            Expanded(
              child: (lowStockItems.isEmpty && incomingTransfers.isEmpty && outboundVarianceTransfers.isEmpty)
                  ? _buildEmptyState(isDark)
                  : ListView(
                      children: [
                        if (outboundVarianceTransfers.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.report_problem_rounded, size: 16, color: Color(0xFFEF4444)),
                              const SizedBox(width: 6),
                              Text('Transit Loss / Shortage Discrepancies (${outboundVarianceTransfers.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final t in outboundVarianceTransfers) ...[
                            _buildVarianceTransferCard(context, t, isDark),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                        ],
                        if (incomingTransfers.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.local_shipping_rounded, size: 16, color: Color(0xFF3B82F6)),
                              const SizedBox(width: 6),
                              Text('Incoming Deliveries (${incomingTransfers.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF3B82F6))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final t in incomingTransfers) ...[
                            _buildIncomingTransferCard(context, t, isDark),
                            const SizedBox(height: 8),
                          ],
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                        ],
                        if (lowStockItems.isNotEmpty) ...[
                          Row(
                            children: [
                              const Icon(Icons.warning_amber_rounded, size: 16, color: Color(0xFFEF4444)),
                              const SizedBox(width: 6),
                              Text('Low Stock Par Alerts (${lowStockItems.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFEF4444))),
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final item in lowStockItems) ...[
                            _buildNotificationItem(context, item, isDark),
                            const SizedBox(height: 8),
                          ],
                        ],
                      ],
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

  Widget _buildIncomingTransferCard(BuildContext context, StockTransferHeader t, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.local_shipping_rounded, color: Color(0xFF10B981), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(t.transferNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('IN TRANSIT', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('From: ${t.fromOutletName} • ${t.totalItems} item(s) • Van: ${t.vehicleNumber.isNotEmpty ? t.vehicleNumber : "Delivery Van"}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onReceiveTransfer?.call(t);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Receive', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceTransferCard(BuildContext context, StockTransferHeader t, bool isDark) {
    final lossCount = t.varianceItems.length;
    final totalLossVal = t.varianceItems.fold<double>(0.0, (sum, i) => sum + (i.quantityVariance * i.unitCost));
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.report_problem_rounded, color: Color(0xFFEF4444), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(t.transferNumber, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: const Text('TRANSIT SHORTAGE', style: TextStyle(color: Color(0xFFEF4444), fontSize: 9.5, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text('To: ${t.toOutletName} • $lossCount short item(s) • Est. Loss ₹${totalLossVal.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                if (t.varianceItems.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      'Short: ${t.varianceItems.map((i) => "${i.ingredientName}: -${i.quantityVariance.toStringAsFixed(1)} ${i.unit}").join(", ")}',
                      style: const TextStyle(fontSize: 10.5, color: Color(0xFFDC2626), fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              onInspectTransfer?.call(t);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Inspect', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int outOfStockCount, int lowCount, int varianceCount) {
    final title = varianceCount > 0 ? 'Discrepancy & Stock Alerts' : 'Low Stock Alerts';
    final totalAlerts = lowStockItems.length + varianceCount;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFFEF4444), Color(0xFFDC2626)]),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: const Color(0xFFEF4444).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
          ),
          child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFFEF4444).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text('$totalAlerts ALERTS', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                varianceCount > 0
                    ? '$varianceCount transfer transit discrepancy reported by receiving branch'
                    : (outOfStockCount > 0 ? '$outOfStockCount out of stock • $lowCount below safety par' : 'Replenish commodities before kitchen service is disrupted'),
                style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.close, size: 20), visualDensity: VisualDensity.compact),
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
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                child: Text(isOut ? 'OUT OF STOCK' : 'LOW STOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: accentColor)),
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
                    Text('Current On-Hand: ${item.formattedStock}',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isOut ? const Color(0xFFEF4444) : (isDark ? Colors.white : const Color(0xFF1E293B)))),
                    const SizedBox(height: 2),
                    Text('Min Par: ${minParInPurchase.toStringAsFixed(1)} ${item.purchaseUom}  •  Deficit: ~${deficit.toStringAsFixed(1)} ${item.purchaseUom}',
                        style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
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
              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), shape: BoxShape.circle),
              child: const Icon(Icons.verified_rounded, size: 40, color: Color(0xFF10B981)),
            ),
            const SizedBox(height: 12),
            const Text('All Inventory is Healthy!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('No ingredients or transfer discrepancies currently pending attention.',
                style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterActions(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Orders are dispatched to verified suppliers', style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500)),
        Row(
          children: [
            OutlinedButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Dismiss')),
            if (onOrderAll != null) ...[
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onOrderAll!();
                },
                icon: const Icon(Icons.playlist_add_check_rounded, size: 16),
                label: const Text('Create Reorder PO'),
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10)),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
