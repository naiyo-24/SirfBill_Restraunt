import 'package:flutter/material.dart';

class InventoryKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color accentColor;
  final String? trendText;
  final bool? isPositiveTrend;
  final VoidCallback? onTap;

  const InventoryKpiCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.accentColor,
    this.trendText,
    this.isPositiveTrend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(icon, size: 18, color: accentColor),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                value,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  if (trendText != null && isPositiveTrend != null) ...[
                    Icon(
                      isPositiveTrend! ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      size: 13,
                      color: isPositiveTrend! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                    const SizedBox(width: 3),
                    Text(
                      trendText!,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isPositiveTrend! ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                    const SizedBox(width: 6),
                  ],
                  if (subtitle != null)
                    Expanded(
                      child: Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
