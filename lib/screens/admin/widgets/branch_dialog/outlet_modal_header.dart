import 'package:flutter/material.dart';
import '../../../../config/api_constants.dart';
import '../../../../services/shop_service.dart';

class OutletModalHeader extends StatelessWidget {
  final Shop outlet;
  final bool isMobile;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;

  const OutletModalHeader({
    super.key,
    required this.outlet,
    required this.isMobile,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 14 : 22,
        vertical: isMobile ? 12 : 16,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: (outlet.logoUrl != null && outlet.logoUrl!.trim().isNotEmpty)
                  ? Image.network(
                      outlet.logoUrl!.startsWith('http://') || outlet.logoUrl!.startsWith('https://')
                          ? outlet.logoUrl!
                          : '${ApiConstants.baseUrl}${outlet.logoUrl!.startsWith('/') ? '' : '/'}${outlet.logoUrl}',
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.store_mall_directory_rounded,
                        color: Color(0xFF6366F1),
                        size: 22,
                      ),
                    )
                  : const Icon(Icons.store_mall_directory_rounded, color: Color(0xFF6366F1), size: 22),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        outlet.name,
                        style: TextStyle(
                          fontSize: isMobile ? 15 : 17,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        outlet.code,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${outlet.location}, ${outlet.city} • Outlet ID: ${outlet.id}',
                  style: TextStyle(fontSize: 11.5, color: subtitleColor),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close_rounded, color: subtitleColor),
            splashRadius: 20,
          ),
        ],
      ),
    );
  }
}
