import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';
import 'order_filter_dropdowns.dart';

/// Ultra-responsive, theme-aware Status, Order Type & Date filter bar
/// engineered specifically for Phone, Tablet, and Desktop POS screens.
class OrderStatusFilterBar extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int holdCount;
  final int completedCount;
  final OrderStatus? statusFilter;
  final OrderType? typeFilter;
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final ValueChanged<OrderStatus?> onSelectStatus;
  final ValueChanged<OrderType?> onSelectType;
  final ValueChanged<DateRangePreset> onSelectDatePreset;
  final ValueChanged<DateTimeRange?> onSelectCustomRange;
  final bool isDark;
  final Color borderColor;

  const OrderStatusFilterBar({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.holdCount,
    required this.completedCount,
    required this.statusFilter,
    required this.typeFilter,
    required this.datePreset,
    this.customRange,
    required this.onSelectStatus,
    required this.onSelectType,
    required this.onSelectDatePreset,
    required this.onSelectCustomRange,
    required this.isDark,
    required this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isPhone = width < 650;
        final isTablet = width >= 650 && width < 1024;

        if (isPhone) {
          return _buildPhoneLayout(context);
        } else if (isTablet) {
          return _buildTabletLayout(context);
        } else {
          return _buildDesktopLayout(context);
        }
      },
    );
  }

  /// Mobile layout: 2 clean tiers with zero clipping
  /// Tier 1: Full-width 4-stage segmented status bar
  /// Tier 2: Dual dropdown selector (Order Type & Date Filter)
  Widget _buildPhoneLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSegmentedStatusBar(isPhone: true),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OrderTypeFilterDropdown(
                typeFilter: typeFilter,
                onSelectType: onSelectType,
                isDark: isDark,
                borderColor: borderColor,
                isPhone: true,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OrderDateFilterDropdown(
                datePreset: datePreset,
                customRange: customRange,
                onSelectPreset: onSelectDatePreset,
                onSelectCustomRange: onSelectCustomRange,
                isDark: isDark,
                borderColor: borderColor,
                isPhone: true,
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Tablet layout: 2 spacious tiers
  /// Tier 1: Segmented status bar
  /// Tier 2: Order Type segmented container + Date Dropdown
  Widget _buildTabletLayout(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildSegmentedStatusBar(isPhone: false),
        const SizedBox(height: 10),
        Row(
          children: [
            _buildOrderTypeSegmentedContainer(),
            const SizedBox(width: 12),
            Container(height: 24, width: 1.2, color: borderColor),
            const SizedBox(width: 12),
            OrderDateFilterDropdown(
              datePreset: datePreset,
              customRange: customRange,
              onSelectPreset: onSelectDatePreset,
              onSelectCustomRange: onSelectCustomRange,
              isDark: isDark,
              borderColor: borderColor,
              isPhone: false,
            ),
          ],
        ),
      ],
    );
  }

  /// Desktop layout: Classic full single horizontal row
  Widget _buildDesktopLayout(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildOrderTypeSegmentedContainer(),
          const SizedBox(width: 14),
          Container(height: 24, width: 1.2, color: borderColor),
          const SizedBox(width: 14),
          CommonStatusFilterPill(
            label: 'All',
            count: totalCount,
            isSelected: statusFilter == null,
            color: const Color(0xFF64748B),
            onTap: () => onSelectStatus(null),
          ),
          const SizedBox(width: 8),
          CommonStatusFilterPill(
            label: 'Active / In Prep',
            count: activeCount,
            isSelected: statusFilter == OrderStatus.active,
            color: const Color(0xFF3B82F6),
            onTap: () => onSelectStatus(OrderStatus.active),
          ),
          const SizedBox(width: 8),
          CommonStatusFilterPill(
            label: 'Held',
            count: holdCount,
            isSelected: statusFilter == OrderStatus.hold,
            color: const Color(0xFFF59E0B),
            onTap: () => onSelectStatus(OrderStatus.hold),
          ),
          const SizedBox(width: 8),
          CommonStatusFilterPill(
            label: 'Completed',
            count: completedCount,
            isSelected: statusFilter == OrderStatus.completed,
            color: const Color(0xFF10B981),
            onTap: () => onSelectStatus(OrderStatus.completed),
          ),
          const SizedBox(width: 14),
          Container(height: 24, width: 1.2, color: borderColor),
          const SizedBox(width: 14),
          CommonDateFilterBar(
            selectedPreset: datePreset,
            customRange: customRange,
            onSelectPreset: onSelectDatePreset,
            onSelectCustomRange: onSelectCustomRange,
          ),
        ],
      ),
    );
  }

  /// Full-width segmented status tab container
  Widget _buildSegmentedStatusBar({required bool isPhone}) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final tabs = [
      _StatusTabItem(
        label: isPhone ? 'All' : 'All Orders',
        count: totalCount,
        isSelected: statusFilter == null,
        activeColor: const Color(0xFF475569),
        onTap: () => onSelectStatus(null),
      ),
      _StatusTabItem(
        label: isPhone ? 'Active' : 'Active / Prep',
        count: activeCount,
        isSelected: statusFilter == OrderStatus.active,
        activeColor: const Color(0xFF2563EB),
        onTap: () => onSelectStatus(OrderStatus.active),
      ),
      _StatusTabItem(
        label: 'Held',
        count: holdCount,
        isSelected: statusFilter == OrderStatus.hold,
        activeColor: const Color(0xFFD97706),
        onTap: () => onSelectStatus(OrderStatus.hold),
      ),
      _StatusTabItem(
        label: isPhone ? 'Done' : 'Completed',
        count: completedCount,
        isSelected: statusFilter == OrderStatus.completed,
        activeColor: const Color(0xFF059669),
        onTap: () => onSelectStatus(OrderStatus.completed),
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(3.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: tabs.map((tab) {
          final isSelected = tab.isSelected;
          final color = tab.activeColor;

          return Expanded(
            child: InkWell(
              onTap: tab.onTap,
              borderRadius: BorderRadius.circular(9),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeInOut,
                padding: EdgeInsets.symmetric(vertical: isPhone ? 7 : 8),
                decoration: BoxDecoration(
                  color: isSelected ? color : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: color.withValues(alpha: 0.35),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tab.label,
                      style: TextStyle(
                        fontSize: isPhone ? 11.5 : 12.5,
                        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Colors.white24
                            : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${tab.count}',
                        style: TextStyle(
                          fontSize: isPhone ? 10 : 10.5,
                          fontWeight: FontWeight.w900,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155)),
                        ),
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

  /// Segmented container for Order Types (Dine-In, Takeaway, Delivery)
  Widget _buildOrderTypeSegmentedContainer() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CommonFilterTypePill(
            label: 'All Types',
            icon: Icons.tune_rounded,
            isSelected: typeFilter == null,
            onTap: () => onSelectType(null),
          ),
          const SizedBox(width: 4),
          CommonFilterTypePill(
            label: 'Dine-In',
            icon: Icons.table_restaurant_rounded,
            isSelected: typeFilter == OrderType.dineIn,
            onTap: () => onSelectType(OrderType.dineIn),
          ),
          const SizedBox(width: 4),
          CommonFilterTypePill(
            label: 'Takeaway',
            icon: Icons.shopping_bag_rounded,
            isSelected: typeFilter == OrderType.takeaway,
            onTap: () => onSelectType(OrderType.takeaway),
          ),
          const SizedBox(width: 4),
          CommonFilterTypePill(
            label: 'Delivery',
            icon: Icons.moped_rounded,
            isSelected: typeFilter == OrderType.delivery,
            onTap: () => onSelectType(OrderType.delivery),
          ),
        ],
      ),
    );
  }
}

class _StatusTabItem {
  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _StatusTabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });
}
