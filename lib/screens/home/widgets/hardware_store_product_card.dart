import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/hardware_product_model.dart';
import 'hardware_detail_dialog.dart';

/// Card widget presenting a single certified hardware product with pricing, specs & order action.
class HardwareStoreProductCard extends StatelessWidget {
  final HardwareProduct product;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final ValueChanged<HardwareProduct> onInquire;

  const HardwareStoreProductCard({
    super.key,
    required this.product,
    required this.isDark,
    required this.cardBg,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.onInquire,
  });

  IconData _resolveIcon(String category) {
    switch (category.toUpperCase()) {
      case 'PRINTER':
        return Icons.print_rounded;
      case 'POS_TERMINAL':
        return Icons.point_of_sale_rounded;
      case 'HANDHELD_PDA':
        return Icons.phone_android_rounded;
      case 'KDS_DISPLAY':
        return Icons.soup_kitchen_rounded;
      case 'CASH_DRAWER':
        return Icons.archive_rounded;
      case 'SCANNER':
        return Icons.qr_code_scanner_rounded;
      case 'PAPER_ROLLS':
        return Icons.receipt_long_rounded;
      default:
        return Icons.storefront_rounded;
    }
  }

  Color _resolveColor(String category) {
    switch (category.toUpperCase()) {
      case 'PRINTER':
        return const Color(0xFF10B981);
      case 'POS_TERMINAL':
        return const Color(0xFF3B82F6);
      case 'HANDHELD_PDA':
        return const Color(0xFFF59E0B);
      case 'KDS_DISPLAY':
        return const Color(0xFFF97316);
      case 'CASH_DRAWER':
        return const Color(0xFF8B5CF6);
      case 'SCANNER':
        return const Color(0xFFEC4899);
      default:
        return const Color(0xFF065F46);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final accentColor = _resolveColor(product.category);
    final icon = _resolveIcon(product.category);

    final displaySpecs = product.features.isNotEmpty
        ? product.features.take(4).toList()
        : [
            '100% Plug & Play with SirfBill POS',
            'Commercial Heavy-Duty Restaurant Grade',
            'Full 12-Month Official Replacement Warranty',
            'Express Dispatch within 24 Hours',
          ];

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => HardwareDetailDialog.show(
        context,
        product: product,
        accentColor: accentColor,
        icon: icon,
        onInquire: onInquire,
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            product.name,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (product.isPopular || product.isFeatured)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accentColor.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              product.isPopular ? 'BESTSELLER' : 'FLAGSHIP',
                              style: TextStyle(
                                color: accentColor,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      product.shortDescription.isNotEmpty
                          ? product.shortDescription
                          : '${product.brand} • ${product.modelNumber.isNotEmpty ? product.modelNumber : product.categoryDisplay}',
                      style: TextStyle(fontSize: 11, color: subtitleColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Price and MRP Row
          Row(
            children: [
              Text(
                inFormat.format(product.price),
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF10B981)),
              ),
              const SizedBox(width: 6),
              if (product.mrp > product.price) ...[
                Text(
                  inFormat.format(product.mrp),
                  style: TextStyle(
                    fontSize: 11,
                    color: subtitleColor,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(
                    '${product.discountPercentage}% OFF',
                    style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w800, color: Colors.orange),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          const SizedBox(height: 8),

          // Product Specs List
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: displaySpecs.map((spec) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, size: 13, color: accentColor),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        spec,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.verified_user_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Text(
                    '${product.warrantyMonths}M Warranty',
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () => onInquire(product),
                icon: const Icon(Icons.shopping_bag_outlined, size: 14),
                label: const Text('Order Now'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
}

