import 'package:flutter/material.dart';

/// Filter chip bar for browsing hardware categories (All, Printers, Terminals, etc.)
class AdminHardwareCategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String> onSelectCategory;
  final bool isDark;

  const AdminHardwareCategoryFilterBar({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.onSelectCategory,
    required this.isDark,
  });

  String _formatName(String raw) {
    if (raw == 'ALL') return 'All Hardware';
    switch (raw.toUpperCase()) {
      case 'PRINTER':
        return 'Printers';
      case 'POS_TERMINAL':
        return 'POS Terminals';
      case 'HANDHELD_PDA':
        return 'Handhelds';
      case 'KDS_DISPLAY':
        return 'Kitchen KDS';
      case 'CASH_DRAWER':
        return 'Cash Drawers';
      case 'SCANNER':
        return 'Scanners';
      case 'PAPER_ROLLS':
        return 'Paper Rolls';
      default:
        return raw.replaceAll('_', ' ');
    }
  }

  IconData _icon(String raw) {
    switch (raw.toUpperCase()) {
      case 'ALL':
        return Icons.grid_view_rounded;
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((cat) {
          final isSelected = selectedCategory.toUpperCase() == cat.toUpperCase();
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => onSelectCategory(cat),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF1E293B) : Colors.white),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF10B981).withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _icon(cat),
                      size: 15,
                      color: isSelected ? Colors.white : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatName(cat),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected ? Colors.white : (isDark ? Colors.white : const Color(0xFF1E293B)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
