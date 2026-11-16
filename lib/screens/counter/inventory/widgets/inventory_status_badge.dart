import 'package:flutter/material.dart';

/// Reusable Badge for stock levels, statuses, and tags
class InventoryStatusBadge extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const InventoryStatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory InventoryStatusBadge.stockLevel({
    required double currentStock,
    required double minPar,
  }) {
    if (currentStock <= 0) {
      return const InventoryStatusBadge(
        label: 'Out of Stock',
        backgroundColor: Color(0xFFFEE2E2),
        textColor: Color(0xFFDC2626),
        icon: Icons.cancel_outlined,
      );
    } else if (currentStock <= minPar) {
      return const InventoryStatusBadge(
        label: 'Low Stock',
        backgroundColor: Color(0xFFFEF3C7),
        textColor: Color(0xFFD97706),
        icon: Icons.warning_amber_rounded,
      );
    } else {
      return const InventoryStatusBadge(
        label: 'Healthy Stock',
        backgroundColor: Color(0xFFD1FAE5),
        textColor: Color(0xFF059669),
        icon: Icons.check_circle_outline,
      );
    }
  }

  factory InventoryStatusBadge.custom({
    required String label,
    required Color color,
    IconData? icon,
  }) {
    return InventoryStatusBadge(
      label: label,
      backgroundColor: color.withValues(alpha: 0.12),
      textColor: color,
      icon: icon,
    );
  }

  factory InventoryStatusBadge.status(
    String label, {
    required Color color,
    IconData? icon,
  }) {
    return InventoryStatusBadge.custom(
      label: label,
      color: color,
      icon: icon,
    );
  }

  factory InventoryStatusBadge.temperature({
    required bool isPassed,
    double? temperature,
  }) {
    final color = isPassed ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final tempStr = temperature != null ? '${temperature.toStringAsFixed(1)}°C ' : '';
    return InventoryStatusBadge(
      label: '$tempStr(${isPassed ? 'PASS' : 'FAIL'})',
      backgroundColor: color.withValues(alpha: 0.12),
      textColor: color,
      icon: isPassed ? Icons.thermostat_outlined : Icons.warning_amber_rounded,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: textColor.withValues(alpha: 0.2),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
