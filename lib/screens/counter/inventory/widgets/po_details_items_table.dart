import 'package:flutter/material.dart';
import '../models/inventory_ops_models.dart';

class PoDetailsItemsTable extends StatelessWidget {
  final List<PurchaseOrderItem> items;
  final bool isDark;

  const PoDetailsItemsTable({
    super.key,
    required this.items,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 460),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)),
                  child: const Row(
                    children: [
                      SizedBox(width: 140, child: Text('Ingredient Item', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                      SizedBox(width: 90, child: Text('Ordered Qty', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      SizedBox(width: 80, child: Text('Unit Price', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                      SizedBox(width: 60, child: Text('GST %', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      SizedBox(width: 90, child: Text('Line Total', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
                    ],
                  ),
                ),
                ...items.map((it) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 140,
                        child: Text(it.ingredientName, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ),
                      SizedBox(
                        width: 90,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('${it.orderedQty.toStringAsFixed(1)} ${it.uom}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
                            if (it.receivedQty > 0)
                              Text(
                                'Rec: ${it.receivedQty.toStringAsFixed(1)} ${it.uom}',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: it.receivedQty >= it.orderedQty ? const Color(0xFF10B981) : Colors.orange,
                                ),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),
                      SizedBox(width: 80, child: Text('₹${it.unitPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.right)),
                      SizedBox(width: 60, child: Text('${it.taxRate.toStringAsFixed(0)}%', style: const TextStyle(fontSize: 12, color: Color(0xFFF59E0B), fontWeight: FontWeight.w600), textAlign: TextAlign.center)),
                      SizedBox(width: 90, child: Text('₹${it.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)), textAlign: TextAlign.right)),
                    ],
                  ),
                )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
