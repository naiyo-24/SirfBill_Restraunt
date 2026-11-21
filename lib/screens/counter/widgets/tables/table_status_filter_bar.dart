import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';

/// Ultra-responsive, theme-aware Status & Floor filter bar for Tables
class TableStatusFilterBar extends StatelessWidget {
  final List<String>? floors;
  final int totalCount;
  final int availableCount;
  final int occupiedCount;
  final int reservedCount;
  final String selectedFloor;
  final TableStatus? statusFilter;
  final ValueChanged<String> onSelectFloor;
  final ValueChanged<TableStatus?> onSelectStatus;
  final bool isDark;
  final Color borderColor;

  const TableStatusFilterBar({
    super.key,
    this.floors,
    required this.totalCount,
    required this.availableCount,
    required this.occupiedCount,
    required this.reservedCount,
    required this.selectedFloor,
    required this.statusFilter,
    required this.onSelectFloor,
    required this.onSelectStatus,
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
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSegmentedStatusBar(isPhone: true),
              const SizedBox(height: 8),
              _buildFloorDropdown(context, isPhone: true),
            ],
          );
        } else if (isTablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSegmentedStatusBar(isPhone: false),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildFloorSegmentedContainer(),
                ],
              ),
            ],
          );
        }

        // Desktop: Classic single horizontal row
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFloorSegmentedContainer(),
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
                label: 'Available',
                count: availableCount,
                isSelected: statusFilter == TableStatus.available,
                color: const Color(0xFF10B981),
                onTap: () => onSelectStatus(TableStatus.available),
              ),
              const SizedBox(width: 8),
              CommonStatusFilterPill(
                label: 'Occupied',
                count: occupiedCount,
                isSelected: statusFilter == TableStatus.occupied,
                color: const Color(0xFFEF4444),
                onTap: () => onSelectStatus(TableStatus.occupied),
              ),
              const SizedBox(width: 8),
              CommonStatusFilterPill(
                label: 'Reserved',
                count: reservedCount,
                isSelected: statusFilter == TableStatus.reserved,
                color: const Color(0xFFF59E0B),
                onTap: () => onSelectStatus(TableStatus.reserved),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Full-width segmented status tab container for Table Status
  Widget _buildSegmentedStatusBar({required bool isPhone}) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final tabs = [
      _TableStatusTabItem(
        label: 'All',
        count: totalCount,
        isSelected: statusFilter == null,
        activeColor: const Color(0xFF475569),
        onTap: () => onSelectStatus(null),
      ),
      _TableStatusTabItem(
        label: 'Available',
        count: availableCount,
        isSelected: statusFilter == TableStatus.available,
        activeColor: const Color(0xFF10B981),
        onTap: () => onSelectStatus(TableStatus.available),
      ),
      _TableStatusTabItem(
        label: 'Occupied',
        count: occupiedCount,
        isSelected: statusFilter == TableStatus.occupied,
        activeColor: const Color(0xFFEF4444),
        onTap: () => onSelectStatus(TableStatus.occupied),
      ),
      _TableStatusTabItem(
        label: 'Reserved',
        count: reservedCount,
        isSelected: statusFilter == TableStatus.reserved,
        activeColor: const Color(0xFFF59E0B),
        onTap: () => onSelectStatus(TableStatus.reserved),
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
                    Flexible(
                      child: Text(
                        tab.label,
                        style: TextStyle(
                          fontSize: isPhone ? 11 : 12.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF475569)),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                          fontSize: isPhone ? 9.5 : 10.5,
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

  /// Segmented container for Floors (Ground Floor, 1st Floor, etc.)
  Widget _buildFloorSegmentedContainer() {
    final floorList = (floors != null && floors!.isNotEmpty) ? floors! : ['All Floors'];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: floorList
            .map((floor) => Padding(
                  padding: const EdgeInsets.only(right: 4),
                  child: CommonFilterTypePill(
                    label: floor,
                    icon: Icons.apartment_rounded,
                    isSelected: selectedFloor == floor,
                    onTap: () => onSelectFloor(floor),
                  ),
                ))
            .toList(),
      ),
    );
  }

  /// Dropdown for Floor selection on phone screens
  Widget _buildFloorDropdown(BuildContext context, {required bool isPhone}) {
    final floorList = (floors != null && floors!.isNotEmpty) ? floors! : ['All Floors'];
    final isFiltered = selectedFloor != 'All Floors';
    const accentColor = Color(0xFF10B981);

    return PopupMenuButton<String>(
      onSelected: onSelectFloor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      offset: const Offset(0, 38),
      itemBuilder: (_) => floorList.map((floor) {
        final isSelected = selectedFloor == floor;
        return PopupMenuItem<String>(
          value: floor,
          height: 38,
          child: Row(
            children: [
              Icon(
                Icons.apartment_rounded,
                size: 15,
                color: isSelected ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  floor,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? accentColor : (isDark ? const Color(0xFFF1F5F9) : const Color(0xFF0F172A)),
                  ),
                ),
              ),
              if (isSelected) const Icon(Icons.check_rounded, size: 15, color: accentColor),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: isPhone ? 35 : 38,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isFiltered
              ? accentColor.withValues(alpha: isDark ? 0.2 : 0.1)
              : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isFiltered ? accentColor : borderColor,
            width: isFiltered ? 1.3 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.apartment_rounded,
              size: 14,
              color: isFiltered ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Floor: $selectedFloor',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isFiltered ? FontWeight.w800 : FontWeight.w600,
                  color: isFiltered ? accentColor : (isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155)),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Icon(
              Icons.arrow_drop_down_rounded,
              size: 16,
              color: isFiltered ? accentColor : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            ),
          ],
        ),
      ),
    );
  }
}

class _TableStatusTabItem {
  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _TableStatusTabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });
}
