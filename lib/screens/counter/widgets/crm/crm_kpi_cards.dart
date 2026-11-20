import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CrmKpiCards extends StatelessWidget {
  final int totalGuests;
  final int vipCount;
  final int regularCount;
  final double totalKhataOutstanding;
  final int totalLoyaltyPoints;
  final bool isMobile;

  const CrmKpiCards({
    super.key,
    required this.totalGuests,
    required this.vipCount,
    required this.regularCount,
    required this.totalKhataOutstanding,
    required this.totalLoyaltyPoints,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      _buildCard(
        context: context,
        title: 'Total Guests',
        value: totalGuests.toString(),
        subtitle: '$regularCount Regular diners',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF3B82F6),
        isDark: isDark,
      ),
      _buildCard(
        context: context,
        title: 'VIP Members',
        value: vipCount.toString(),
        subtitle: '≥10 visits or ₹5,000+ spent',
        icon: Icons.stars_rounded,
        color: const Color(0xFFF59E0B),
        isDark: isDark,
      ),
      _buildCard(
        context: context,
        title: 'Khata Outstanding',
        value: NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(totalKhataOutstanding),
        subtitle: 'Store credit receivables',
        icon: Icons.account_balance_wallet_rounded,
        color: const Color(0xFFEF4444),
        isDark: isDark,
      ),
      _buildCard(
        context: context,
        title: 'Loyalty Points',
        value: totalLoyaltyPoints.toString(),
        subtitle: 'Active member rewards',
        icon: Icons.card_giftcard_rounded,
        color: const Color(0xFF10B981),
        isDark: isDark,
      ),
    ];

    if (isMobile) {
      return SizedBox(
        height: 104,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: cards.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (ctx, i) => SizedBox(width: 210, child: cards[i]),
        ),
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final isTablet = constraints.maxWidth < 900;
        if (isTablet) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 2.4,
            children: cards,
          );
        }
        return Row(
          children: cards
              .map((c) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: c,
                    ),
                  ))
              .toList(),
        );
      },
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
