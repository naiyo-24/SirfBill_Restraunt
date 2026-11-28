import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../models/hardware_product_model.dart';
import 'hardware_detail_dialog.dart';

/// Luxury hardware product card with a soft product photo frame, clear pricing,
/// official warranty pill, and a tactile Order Now button with tap feedback.
class HardwareStoreProductCard extends StatefulWidget {
  final HardwareProduct product;
  final bool isDark;
  final Color cardBg;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final void Function(HardwareProduct product) onInquire;

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

  @override
  State<HardwareStoreProductCard> createState() => _HardwareStoreProductCardState();
}

class _HardwareStoreProductCardState extends State<HardwareStoreProductCard> {
  bool _hovered = false;

  Color _accentColor(String category) {
    switch (category.toUpperCase()) {
      case 'PRINTER':
        return const Color(0xFF10B981);
      case 'POS_TERMINAL':
        return const Color(0xFF2563EB);
      case 'HANDHELD_PDA':
        return const Color(0xFFF59E0B);
      case 'KDS_DISPLAY':
        return const Color(0xFFEA580C);
      case 'CASH_DRAWER':
        return const Color(0xFF7C3AED);
      case 'SCANNER':
        return const Color(0xFFDB2777);
      case 'PAPER_ROLLS':
        return const Color(0xFF059669);
      default:
        return const Color(0xFF10B981);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category.toUpperCase()) {
      case 'PRINTER':
        return Icons.print_rounded;
      case 'POS_TERMINAL':
        return Icons.point_of_sale_rounded;
      case 'HANDHELD_PDA':
        return Icons.tablet_android_rounded;
      case 'KDS_DISPLAY':
        return Icons.tv_rounded;
      case 'CASH_DRAWER':
        return Icons.all_inbox_rounded;
      case 'SCANNER':
        return Icons.qr_code_scanner_rounded;
      case 'PAPER_ROLLS':
        return Icons.receipt_long_rounded;
      default:
        return Icons.devices_other_rounded;
    }
  }

  String _getImageUrl() {
    if (widget.product.primaryImageUrl.isNotEmpty) {
      return widget.product.primaryImageUrl;
    }
    if (widget.product.images.isNotEmpty) {
      return widget.product.images.first;
    }
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final accent = _accentColor(product.category);
    final icon = _categoryIcon(product.category);
    final inFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final imageUrl = _getImageUrl();

    final List<String> displaySpecs = product.features.isNotEmpty
        ? product.features.take(2).toList()
        : [
            '${product.warrantyMonths} Months Official Warranty',
            product.brand,
          ];

    final isSpecial = product.isPopular || product.isFeatured;
    final cardBorder = _hovered
        ? accent
        : (isSpecial ? accent.withValues(alpha: 0.5) : widget.borderColor);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        transform: Matrix4.translationValues(0, _hovered ? -5 : 0, 0),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder, width: _hovered || isSpecial ? 1.8 : 1.0),
          boxShadow: [
            BoxShadow(
              color: (_hovered ? accent : Colors.black).withValues(alpha: _hovered ? 0.18 : 0.04),
              blurRadius: _hovered ? 22 : 12,
              offset: Offset(0, _hovered ? 9 : 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => HardwareDetailDialog.show(
              context,
              product: product,
              accentColor: accent,
              icon: icon,
              onInquire: widget.onInquire,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Color Ribbon Strip
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(color: accent),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 13, color: Colors.white),
                          const SizedBox(width: 6),
                          Text(
                            product.categoryDisplay.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.6,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      if (isSpecial)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            product.isPopular ? '★ BESTSELLER' : '★ FLAGSHIP',
                            style: const TextStyle(
                              fontSize: 8.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Enhanced Image Display with Soft Inner Frame
                Container(
                  height: 148,
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: widget.isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: widget.isDark
                            ? const Color(0xFF334155).withValues(alpha: 0.6)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Center(
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => _buildFallbackIcon(accent, icon),
                            )
                          : _buildFallbackIcon(accent, icon),
                    ),
                  ),
                ),

                Divider(height: 1, color: widget.borderColor),

                // Card Content
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          product.name,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: widget.textColor,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          product.shortDescription.isNotEmpty
                              ? product.shortDescription
                              : '${product.brand} • ${product.modelNumber.isNotEmpty ? product.modelNumber : product.sku}',
                          style: TextStyle(fontSize: 11, color: widget.subtitleColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),

                        // Price & Discount Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            Text(
                              product.effectivePrice == 0 ? 'FREE' : inFormat.format(product.effectivePrice),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF10B981),
                                letterSpacing: -0.5,
                              ),
                            ),
                            if (product.strikePrice > product.effectivePrice) ...[
                              const SizedBox(width: 6),
                              Text(
                                inFormat.format(product.strikePrice),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.subtitleColor,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${product.discountPercentage}% OFF',
                                  style: const TextStyle(
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFFD97706),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),

                        const SizedBox(height: 6),
                        const Divider(height: 1),
                        const SizedBox(height: 6),

                        // Specs Checklist
                        ...displaySpecs.map((spec) => Padding(
                              padding: const EdgeInsets.only(bottom: 3),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.check_circle_rounded, size: 12, color: accent),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      spec,
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.w500,
                                        color: widget.isDark ? Colors.white70 : const Color(0xFF334155),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            )),

                        const Spacer(),

                        // Warranty & In-Stock indicator
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
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '● IN STOCK',
                                style: TextStyle(
                                  fontSize: 8.5,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF059669),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Polished Order Now CTA Button
                        SizedBox(
                          width: double.infinity,
                          height: 38,
                          child: ElevatedButton(
                            onPressed: () => widget.onInquire(product),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_bag_outlined, size: 15),
                                SizedBox(width: 6),
                                Text(
                                  'Order via WhatsApp',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFallbackIcon(Color accent, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 40, color: accent),
    );
  }
}
