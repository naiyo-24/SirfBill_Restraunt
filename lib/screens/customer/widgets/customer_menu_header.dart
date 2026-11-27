import 'package:flutter/material.dart';
import 'dish_network_image.dart';

class CustomerMenuHeader extends StatelessWidget implements PreferredSizeWidget {
  final String outletName;
  final String outletAddress;
  final String outletLogo;
  final String tableCode;
  final String section;

  const CustomerMenuHeader({
    super.key,
    required this.outletName,
    required this.outletAddress,
    required this.outletLogo,
    required this.tableCode,
    required this.section,
  });

  @override
  Size get preferredSize => Size.fromHeight(outletAddress.isNotEmpty ? 92 : 76);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF064E3B)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        boxShadow: [
          BoxShadow(color: Color(0x260F172A), blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (Navigator.of(context).canPop()) ...[
                IconButton(
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 22),
                  onPressed: () => Navigator.of(context).pop(),
                  tooltip: 'Back to POS',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                const SizedBox(width: 8),
              ],
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: outletLogo.isNotEmpty
                      ? buildDishNetworkImage(
                          imageUrl: outletLogo,
                          width: 44,
                          height: 44,
                          placeholderBuilder: () => const Icon(
                            Icons.restaurant_rounded,
                            color: Color(0xFF064E3B),
                            size: 22,
                          ),
                        )
                      : const Icon(
                          Icons.restaurant_rounded,
                          color: Color(0xFF064E3B),
                          size: 22,
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      outletName,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (outletAddress.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        outletAddress,
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFFCBD5E1)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 3),
                    const Row(
                      children: [
                        Icon(Icons.verified_rounded, size: 12, color: Color(0xFF34D399)),
                        SizedBox(width: 4),
                        Text(
                          'Digital Table Menu • Contactless Dining',
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Color(0xFF34D399)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF34D399).withValues(alpha: 0.5)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.table_restaurant_rounded, size: 14, color: Color(0xFF34D399)),
                    const SizedBox(width: 5),
                    Text(
                      '$tableCode • $section',
                      style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
