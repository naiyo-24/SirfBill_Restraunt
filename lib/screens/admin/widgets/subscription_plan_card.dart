import 'package:flutter/material.dart';
import '../models/subscription_plan_models.dart';

class SubscriptionPlanCard extends StatelessWidget {
  final SubscriptionPlanItem plan;
  final bool isCurrent;
  final bool isSubscribedAndActive;
  final int daysRemaining;
  final bool isDark;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final VoidCallback onSelectPlan;

  const SubscriptionPlanCard({
    super.key,
    required this.plan,
    required this.isCurrent,
    this.isSubscribedAndActive = false,
    this.daysRemaining = 0,
    required this.isDark,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.onSelectPlan,
  });

  String _getCleanTierName() {
    if (plan.durationMonths == 12 || plan.durationDays >= 360) {
      return '1 Year Pro';
    }
    if (plan.durationMonths == 6 || plan.durationDays >= 170) {
      return '6 Months Pro';
    }
    if (plan.durationMonths == 3 || plan.durationDays >= 80) {
      return '3 Months Pro';
    }
    return '1 Month Pro';
  }

  String _getRibbonText() {
    if (plan.durationMonths == 12 || plan.durationDays >= 360) {
      return 'BEST VALUE • 10% OFF';
    }
    if (plan.durationMonths == 6 || plan.durationDays >= 170) {
      return 'SAVE 5% • SEMI-ANNUAL';
    }
    if (plan.durationMonths == 3 || plan.durationDays >= 80) {
      return 'MOST POPULAR • 3 MONTHS';
    }
    return 'STANDARD • MONTHLY';
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = plan.accentColor;
    final isPlanActive =
        isCurrent && isSubscribedAndActive && daysRemaining > 0;
    final cardBorderColor = isPlanActive
        ? const Color(0xFF10B981)
        : (plan.isPopular
            ? primaryColor
            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)));

    final basePriceStr = plan.safeBasePrice.toStringAsFixed(plan.safeBasePrice % 1 == 0 ? 0 : 2);
    plan.safeGstAmount.toStringAsFixed(plan.safeGstAmount % 1 == 0 ? 0 : 2);
    final totalStr = plan.safeTotalPrice.toStringAsFixed(plan.safeTotalPrice % 1 == 0 ? 0 : 2);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: cardBorderColor,
          width: isPlanActive || plan.isPopular ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isPlanActive
                ? const Color(0xFF10B981).withValues(alpha: 0.12)
                : (plan.isPopular
                    ? primaryColor.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.04)),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Uniform top accent banner for ALL 4 cards
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 6),
            decoration: BoxDecoration(
              color: isPlanActive ? const Color(0xFF10B981) : primaryColor,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(isPlanActive ? Icons.verified_rounded : plan.icon,
                    size: 13, color: Colors.white),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    isPlanActive
                        ? 'ACTIVE LICENSE • ${daysRemaining}D LEFT'
                        : _getRibbonText(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title + Duration Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        _getCleanTierName(),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2.5),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${plan.durationDays} Days',
                        style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Big Price Display (Base Price directly from DB)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '₹$basePriceStr',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: textColor,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '/ ${plan.billingCycle.toLowerCase()}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: subtitleColor),
                    ),
                  ],
                ),
                const SizedBox(height: 4),

                // GST Excluded Mention & Total Breakdown
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'GST Excluded',
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        '+ 18% GST (Total: ₹$totalStr)',
                        style: TextStyle(fontSize: 10, color: subtitleColor, fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1),
                const SizedBox(height: 12),

                // Feature bullet points
                _buildFeatureRow(
                    'Touch POS Billing & Multi-Station KOTs', primaryColor),
                _buildFeatureRow(
                    'Automatic Recipe BOM Deductions', primaryColor),
                _buildFeatureRow(
                    'Live Kitchen Display Screen (KDS)', primaryColor),
                _buildFeatureRow(
                    'Physical Stock Audit & Loss Tracking', primaryColor),
                const SizedBox(height: 16),

                // Bottom Action Button / Active Status Container
                if (isPlanActive) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: onSelectPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      icon: const Icon(Icons.autorenew_rounded, size: 16),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          'Renew / Extend Plan (${daysRemaining}d Active)',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      onPressed: onSelectPlan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0C2340),
                        foregroundColor: Colors.white,
                        elevation: 1,
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        side: BorderSide(
                          color: isCurrent
                              ? const Color(0xFF3395FF)
                              : primaryColor,
                          width: 1.2,
                        ),
                      ),
                      icon: Icon(
                        isSubscribedAndActive
                            ? Icons.swap_horiz_rounded
                            : Icons.bolt_rounded,
                        size: 16,
                        color: const Color(0xFF3395FF),
                      ),
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          isSubscribedAndActive
                              ? 'Switch to ${plan.billingCycle} (₹$totalStr)'
                              : (isCurrent
                                  ? 'Renew Plan (₹$totalStr)'
                                  : 'Select Plan (₹$totalStr)'),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w800),
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(String text, Color accentColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                shape: BoxShape.circle),
            child: Icon(Icons.check_rounded, size: 10, color: accentColor),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : const Color(0xFF334155),
                height: 1.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
