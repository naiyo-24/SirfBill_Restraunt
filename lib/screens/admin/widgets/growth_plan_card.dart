import 'package:flutter/material.dart';

/// Professional, uniform pricing card matching the official SirfBill Subscriptions tab design.
class GrowthPlanCard extends StatefulWidget {
  final Map<String, dynamic> plan;
  final String category;
  final int index;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;
  final VoidCallback onTap;

  const GrowthPlanCard({
    super.key,
    required this.plan,
    required this.category,
    required this.index,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  State<GrowthPlanCard> createState() => _GrowthPlanCardState();
}

class _GrowthPlanCardState extends State<GrowthPlanCard> {
  bool _hovered = false;

  IconData _ribbonIcon() {
    final isInfluencer = widget.category.toLowerCase().contains('influencer');
    if (isInfluencer) {
      const icons = [
        Icons.verified_user_rounded,
        Icons.star_rounded,
        Icons.campaign_rounded,
        Icons.workspace_premium_rounded,
      ];
      return icons[widget.index % icons.length];
    }
    const webIcons = [
      Icons.check_circle_rounded,
      Icons.star_rounded,
      Icons.brush_rounded,
      Icons.corporate_fare_rounded,
    ];
    return webIcons[widget.index % webIcons.length];
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.plan;
    final accent = Color(p['color'] as int);
    final gst = (p['gst'] ?? '').toString();
    final tag = p['tag'].toString();
    final priceText = p['price'].toString();
    final originalPrice = (p['original_price'] ?? '').toString();
    final isFree = priceText == 'FREE';
    final discountPct = p['discount_pct'] as int?;
    final isPopular = tag == 'POPULAR' || tag == 'BEST VALUE';
    final features = (p['features'] as List).cast<String>();

    String ribbonLabel;
    if (isFree) {
      ribbonLabel = 'LIMITED TIME • 100% FREE';
    } else if (discountPct != null && discountPct > 0) {
      ribbonLabel = '$tag • $discountPct% OFF';
    } else {
      ribbonLabel = tag;
    }

    final cardBorderColor = isPopular
        ? accent
        : (_hovered ? accent.withValues(alpha: 0.6) : (widget.isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)));

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: cardBorderColor,
            width: isPopular || _hovered ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isPopular
                  ? accent.withValues(alpha: _hovered ? 0.22 : 0.12)
                  : Colors.black.withValues(alpha: _hovered ? 0.10 : 0.04),
              blurRadius: _hovered ? 20 : 14,
              offset: Offset(0, _hovered ? 8 : 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Accent Ribbon (Consistent across all cards like Subscriptions)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 12),
              decoration: BoxDecoration(
                color: accent,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(_ribbonIcon(), size: 13, color: Colors.white),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      ribbonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.6,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + Category Tag Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            p['title'].toString(),
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: widget.textColor,
                              letterSpacing: -0.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: accent,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Price Row
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        if (isFree) ...[
                          const Text(
                            'FREE',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF10B981),
                              letterSpacing: -0.5,
                            ),
                          ),
                        ] else ...[
                          Text(
                            priceText,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w900,
                              color: widget.textColor,
                              letterSpacing: -0.8,
                            ),
                          ),
                        ],
                        if (originalPrice.isNotEmpty) ...[
                          const SizedBox(width: 7),
                          Text(
                            originalPrice,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: widget.subtitleColor,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                        if (gst.isNotEmpty) ...[
                          const SizedBox(width: 5),
                          Text(
                            gst,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: widget.subtitleColor,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Feature List
                    ...features.map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Icon(Icons.check_circle_rounded, size: 14, color: accent),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.textColor.withValues(alpha: 0.85),
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(),

                    // Action Button (Identical to Subscriptions card style)
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: widget.onTap,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: isPopular
                              ? accent
                              : (widget.isDark ? const Color(0xFF334155) : const Color(0xFF0F172A)),
                          foregroundColor: Colors.white,
                          elevation: isPopular ? 2 : 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.touch_app_rounded, size: 15),
                        label: Text(
                          isPopular ? 'Select Plan (Recommended)' : 'Select Plan',
                          style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
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
    );
  }
}
