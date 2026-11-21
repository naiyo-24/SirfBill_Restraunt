import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_date_picker_modal.dart';
import '../../../../widgets/common_filter_pills.dart';

/// Reusable Dropdown for Order Fulfillment Type (Dine-In, Takeaway, Delivery)
class OrderTypeFilterDropdown extends StatelessWidget {
  final OrderType? typeFilter;
  final ValueChanged<OrderType?> onSelectType;
  final bool isDark;
  final Color borderColor;
  final bool isPhone;

  const OrderTypeFilterDropdown({
    super.key,
    required this.typeFilter,
    required this.onSelectType,
    required this.isDark,
    required this.borderColor,
    this.isPhone = false,
  });

  static String getOrderTypeLabel(OrderType? type) {
    switch (type) {
      case OrderType.dineIn:
        return 'Dine-In';
      case OrderType.takeaway:
        return 'Takeaway';
      case OrderType.delivery:
        return 'Delivery';
      case null:
        return 'All Types';
    }
  }

  static IconData getOrderTypeIcon(OrderType? type) {
    switch (type) {
      case OrderType.dineIn:
        return Icons.table_restaurant_rounded;
      case OrderType.takeaway:
        return Icons.shopping_bag_rounded;
      case OrderType.delivery:
        return Icons.moped_rounded;
      case null:
        return Icons.tune_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasFilter = typeFilter != null;
    const accentColor = Color(0xFF2563EB);

    return PopupMenuButton<OrderType?>(
      onSelected: onSelectType,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      offset: const Offset(0, 38),
      itemBuilder: (_) => [
        _buildPopupItem(value: null, label: 'All Types', icon: Icons.tune_rounded, isSelected: typeFilter == null, accentColor: accentColor),
        _buildPopupItem(value: OrderType.dineIn, label: 'Dine-In', icon: Icons.table_restaurant_rounded, isSelected: typeFilter == OrderType.dineIn, accentColor: accentColor),
        _buildPopupItem(value: OrderType.takeaway, label: 'Takeaway', icon: Icons.shopping_bag_rounded, isSelected: typeFilter == OrderType.takeaway, accentColor: accentColor),
        _buildPopupItem(value: OrderType.delivery, label: 'Delivery', icon: Icons.moped_rounded, isSelected: typeFilter == OrderType.delivery, accentColor: accentColor),
      ],
      child: Container(
        height: isPhone ? 35 : 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: hasFilter
              ? accentColor.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasFilter ? accentColor : borderColor,
            width: hasFilter ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              getOrderTypeIcon(typeFilter),
              size: 14,
              color: hasFilter ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                getOrderTypeLabel(typeFilter),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: hasFilter ? FontWeight.w800 : FontWeight.w600,
                  color: hasFilter ? accentColor : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: hasFilter ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<T> _buildPopupItem<T>({
    required T value,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
  }) {
    return PopupMenuItem<T>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: isSelected ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? accentColor : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check_rounded, size: 15, color: accentColor),
        ],
      ),
    );
  }
}

/// Reusable Dropdown for Order Date Range (Today, Week, Month, Custom)
class OrderDateFilterDropdown extends StatelessWidget {
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final ValueChanged<DateRangePreset> onSelectPreset;
  final ValueChanged<DateTimeRange?> onSelectCustomRange;
  final bool isDark;
  final Color borderColor;
  final bool isPhone;

  const OrderDateFilterDropdown({
    super.key,
    required this.datePreset,
    this.customRange,
    required this.onSelectPreset,
    required this.onSelectCustomRange,
    required this.isDark,
    required this.borderColor,
    this.isPhone = false,
  });

  static String getDatePresetLabel(DateRangePreset preset, DateTimeRange? customRange) {
    switch (preset) {
      case DateRangePreset.all:
        return 'All Time';
      case DateRangePreset.today:
        return 'Today';
      case DateRangePreset.thisWeek:
        return 'This Week';
      case DateRangePreset.thisMonth:
        return 'This Month';
      case DateRangePreset.thisYear:
        return 'This Year';
      case DateRangePreset.custom:
        if (customRange != null) {
          final s = customRange.start;
          final e = customRange.end;
          return '${s.day}/${s.month} - ${e.day}/${e.month}';
        }
        return 'Custom Range';
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNotToday = datePreset != DateRangePreset.today;
    const accentColor = Color(0xFF10B981);

    return PopupMenuButton<DateRangePreset>(
      onSelected: (preset) {
        if (preset == DateRangePreset.custom) {
          final now = DateTime.now();
          final initial = customRange ?? DateTimeRange(start: now.subtract(const Duration(days: 7)), end: now);
          CommonDatePickerModal.show(
            context: context,
            initialRange: initial,
            onApply: onSelectCustomRange,
            onSelectPreset: onSelectPreset,
          );
        } else {
          onSelectPreset(preset);
        }
      },
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      offset: const Offset(0, 38),
      itemBuilder: (_) => [
        _buildPopupItem(value: DateRangePreset.today, label: 'Today', icon: Icons.today_rounded, isSelected: datePreset == DateRangePreset.today, accentColor: accentColor),
        _buildPopupItem(value: DateRangePreset.thisWeek, label: 'This Week', icon: Icons.view_week_rounded, isSelected: datePreset == DateRangePreset.thisWeek, accentColor: accentColor),
        _buildPopupItem(value: DateRangePreset.thisMonth, label: 'This Month', icon: Icons.calendar_month_rounded, isSelected: datePreset == DateRangePreset.thisMonth, accentColor: accentColor),
        _buildPopupItem(value: DateRangePreset.thisYear, label: 'This Year', icon: Icons.event_note_rounded, isSelected: datePreset == DateRangePreset.thisYear, accentColor: accentColor),
        _buildPopupItem(value: DateRangePreset.all, label: 'All Time', icon: Icons.history_rounded, isSelected: datePreset == DateRangePreset.all, accentColor: accentColor),
        const PopupMenuDivider(),
        _buildPopupItem(value: DateRangePreset.custom, label: 'Custom Range...', icon: Icons.date_range_rounded, isSelected: datePreset == DateRangePreset.custom, accentColor: accentColor),
      ],
      child: Container(
        height: isPhone ? 35 : 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isNotToday
              ? accentColor.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isNotToday ? accentColor : borderColor,
            width: isNotToday ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.calendar_today_rounded,
              size: 13,
              color: isNotToday ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                getDatePresetLabel(datePreset, customRange),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isNotToday ? FontWeight.w800 : FontWeight.w600,
                  color: isNotToday ? accentColor : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isNotToday ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<T> _buildPopupItem<T>({
    required T value,
    required String label,
    required IconData icon,
    required bool isSelected,
    required Color accentColor,
  }) {
    return PopupMenuItem<T>(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(
            icon,
            size: 15,
            color: isSelected ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? accentColor : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
              ),
            ),
          ),
          if (isSelected) Icon(Icons.check_rounded, size: 15, color: accentColor),
        ],
      ),
    );
  }
}
