import 'package:flutter/material.dart';

class InventoryNotificationBell extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  final bool isDark;

  const InventoryNotificationBell({
    super.key,
    required this.count,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final hasAlerts = count > 0;
    final borderColor = hasAlerts
        ? const Color(0xFFEF4444).withValues(alpha: 0.5)
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
    final bgColor = hasAlerts
        ? const Color(0xFFEF4444).withValues(alpha: isDark ? 0.18 : 0.08)
        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC));
    final iconColor = hasAlerts
        ? const Color(0xFFEF4444)
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return Tooltip(
      message: hasAlerts
          ? '$count low stock item${count > 1 ? 's' : ''} need attention'
          : 'Low Stock Alerts (Healthy)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            height: 40,
            padding: EdgeInsets.symmetric(
              horizontal: hasAlerts ? 10 : 10,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor, width: 1.2),
              boxShadow: hasAlerts
                  ? [
                      BoxShadow(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  hasAlerts
                      ? Icons.notifications_active_rounded
                      : Icons.notifications_none_rounded,
                  size: 20,
                  color: iconColor,
                ),
                if (hasAlerts) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEF4444),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      count > 99 ? '99+' : count.toString(),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
