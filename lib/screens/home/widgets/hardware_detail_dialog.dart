import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/hardware_product_model.dart';

class HardwareDetailDialog extends StatelessWidget {
  final HardwareProduct product;
  final Color accentColor;
  final IconData icon;
  final ValueChanged<HardwareProduct> onInquire;

  const HardwareDetailDialog({
    super.key,
    required this.product,
    required this.accentColor,
    required this.icon,
    required this.onInquire,
  });

  static void show(
    BuildContext context, {
    required HardwareProduct product,
    required Color accentColor,
    required IconData icon,
    required ValueChanged<HardwareProduct> onInquire,
  }) {
    showDialog(
      context: context,
      builder: (_) => HardwareDetailDialog(
        product: product,
        accentColor: accentColor,
        icon: icon,
        onInquire: onInquire,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final currency = NumberFormat('#,##0', 'en_IN');

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 560,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.86),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accentColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(fontSize: 16.5, fontWeight: FontWeight.w800, color: textColor),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${product.brand}${product.modelNumber.isNotEmpty ? " • ${product.modelNumber}" : ""} • SKU: ${product.sku}',
                          style: TextStyle(fontSize: 11.5, color: subColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: subColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Divider(height: 1, color: borderColor),

            // Scrollable Body
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (product.primaryImageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          product.primaryImageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(height: 14),
                    ],
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _chip(product.inStock ? 'In Stock' : 'Out of Stock', product.inStock ? const Color(0xFF10B981) : const Color(0xFFEF4444)),
                        _chip('${product.warrantyMonths} Months Warranty', const Color(0xFF6366F1)),
                        _chip(product.category.replaceAll('_', ' '), accentColor),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          product.effectivePrice == 0 ? 'FREE' : '₹${currency.format(product.effectivePrice)}',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: textColor),
                        ),
                        if (product.strikePrice > product.effectivePrice) ...[
                          const SizedBox(width: 8),
                          Text(
                            '₹${currency.format(product.strikePrice)}',
                            style: TextStyle(fontSize: 14, color: subColor, decoration: TextDecoration.lineThrough),
                          ),
                        ],
                        const SizedBox(width: 8),
                        Text('+ ${product.taxRate.toStringAsFixed(0)}% GST', style: TextStyle(fontSize: 11.5, color: subColor)),
                      ],
                    ),
                    if (product.description.isNotEmpty || product.shortDescription.isNotEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        product.description.isNotEmpty ? product.description : product.shortDescription,
                        style: TextStyle(fontSize: 13, color: subColor, height: 1.5),
                      ),
                    ],
                    if (product.features.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Key Features', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 8),
                      ...product.features.map((f) => Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check_circle_rounded, size: 16, color: accentColor),
                                const SizedBox(width: 8),
                                Expanded(child: Text(f, style: TextStyle(fontSize: 12.5, color: textColor))),
                              ],
                            ),
                          )),
                    ],
                    if (product.specifications.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text('Technical Specifications', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor)),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: borderColor),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: product.specifications.entries.map((e) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(border: Border(bottom: BorderSide(color: borderColor, width: 0.6))),
                              child: Row(
                                children: [
                                  Expanded(flex: 2, child: Text(e.key, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subColor))),
                                  Expanded(flex: 3, child: Text(e.value.toString(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: textColor))),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer CTA
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(border: Border(top: BorderSide(color: borderColor))),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Close'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onInquire(product);
                      },
                      icon: const Icon(Icons.shopping_cart_checkout_rounded, size: 17),
                      label: const Text('Order / Inquire Now', style: TextStyle(fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
