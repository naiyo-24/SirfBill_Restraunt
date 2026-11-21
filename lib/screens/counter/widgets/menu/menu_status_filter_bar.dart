import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';
import 'menu_category_cards.dart';

/// Ultra-responsive, theme-aware Status & Category filter bar for Menu Management
class MenuStatusFilterBar extends StatelessWidget {
  final int totalCount;
  final int availableCount;
  final int outOfStockCount;
  final List<MenuCategory> categories;
  final String selectedCategoryId;
  final bool? availabilityFilter;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<bool?> onSelectAvailability;
  final VoidCallback? onAddCategory;
  final ValueChanged<MenuCategory>? onEditCategory;
  final ValueChanged<MenuCategory>? onDeleteCategory;
  final bool isDark;
  final Color borderColor;

  const MenuStatusFilterBar({
    super.key,
    required this.totalCount,
    required this.availableCount,
    required this.outOfStockCount,
    required this.categories,
    required this.selectedCategoryId,
    required this.availabilityFilter,
    required this.onSelectCategory,
    required this.onSelectAvailability,
    this.onAddCategory,
    this.onEditCategory,
    this.onDeleteCategory,
    required this.isDark,
    required this.borderColor,
  });

  MenuCategory get _currentCategory {
    return categories.firstWhere(
      (c) => c.id == selectedCategoryId,
      orElse: () => const MenuCategory(id: 'all', name: 'All Categories', iconEmoji: '🍽️'),
    );
  }

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
              Row(
                children: [
                  Expanded(child: _buildCategoryDropdown(context, isPhone: true)),
                  if (onAddCategory != null) ...[
                    const SizedBox(width: 8),
                    _buildAddCategoryButton(isPhone: true),
                  ],
                ],
              ),
            ],
          );
        } else if (isTablet) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSegmentedStatusBar(isPhone: false),
              const SizedBox(height: 10),
              _buildTabletCategoryScroll(),
            ],
          );
        }

        // Desktop: Classic single horizontal row
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDesktopCategoryCards(),
              if (onAddCategory != null) ...[
                const SizedBox(width: 6),
                MenuAddCategoryCard(onTap: onAddCategory!),
              ],
              const SizedBox(width: 14),
              Container(height: 24, width: 1.2, color: borderColor),
              const SizedBox(width: 14),
              CommonStatusFilterPill(
                label: 'All',
                count: totalCount,
                isSelected: availabilityFilter == null,
                color: const Color(0xFF64748B),
                onTap: () => onSelectAvailability(null),
              ),
              const SizedBox(width: 8),
              CommonStatusFilterPill(
                label: 'In Stock',
                count: availableCount,
                isSelected: availabilityFilter == true,
                color: const Color(0xFF10B981),
                onTap: () => onSelectAvailability(true),
              ),
              const SizedBox(width: 8),
              CommonStatusFilterPill(
                label: 'Out of Stock',
                count: outOfStockCount,
                isSelected: availabilityFilter == false,
                color: const Color(0xFFEF4444),
                onTap: () => onSelectAvailability(false),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Full-width segmented status tab container for Stock Availability
  Widget _buildSegmentedStatusBar({required bool isPhone}) {
    final bg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9);

    final tabs = [
      _MenuStatusTabItem(
        label: 'All Items',
        count: totalCount,
        isSelected: availabilityFilter == null,
        activeColor: const Color(0xFF475569),
        onTap: () => onSelectAvailability(null),
      ),
      _MenuStatusTabItem(
        label: 'In Stock',
        count: availableCount,
        isSelected: availabilityFilter == true,
        activeColor: const Color(0xFF10B981),
        onTap: () => onSelectAvailability(true),
      ),
      _MenuStatusTabItem(
        label: 'Out of Stock',
        count: outOfStockCount,
        isSelected: availabilityFilter == false,
        activeColor: const Color(0xFFEF4444),
        onTap: () => onSelectAvailability(false),
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
                          fontSize: isPhone ? 11.5 : 12.5,
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

  /// Dropdown for Category selection on phone screens
  Widget _buildCategoryDropdown(BuildContext context, {required bool isPhone}) {
    final cur = _currentCategory;
    final isFiltered = selectedCategoryId != 'all';
    const accentColor = Color(0xFF10B981);

    return PopupMenuButton<String>(
      onSelected: onSelectCategory,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E293B) : Colors.white,
      elevation: 8,
      offset: const Offset(0, 38),
      itemBuilder: (_) => categories.map((cat) {
        final isSelected = selectedCategoryId == cat.id;
        return PopupMenuItem<String>(
          value: cat.id,
          height: 38,
          child: Row(
            children: [
              Text(cat.iconEmoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  cat.name,
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
            Text(cur.iconEmoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Category: ${cur.name}',
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

  /// Compact Add Category Button on Mobile
  Widget _buildAddCategoryButton({required bool isPhone}) {
    return SizedBox(
      height: isPhone ? 35 : 38,
      child: OutlinedButton.icon(
        onPressed: onAddCategory,
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF10B981),
          side: const BorderSide(color: Color(0xFF10B981)),
          padding: const EdgeInsets.symmetric(horizontal: 9),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        icon: const Icon(Icons.add_rounded, size: 15),
        label: const Text(
          '+ Category',
          style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  /// Tablet Compact Category Capsule Row
  Widget _buildTabletCategoryScroll() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...categories.map((c) {
            final isSelected = c.id == selectedCategoryId;
            return Padding(
              padding: const EdgeInsets.only(right: 6.0),
              child: InkWell(
                onTap: () => onSelectCategory(c.id),
                borderRadius: BorderRadius.circular(10),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6.5),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF10B981)
                        : (isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isSelected ? const Color(0xFF10B981) : borderColor,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(c.iconEmoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 5),
                      Text(
                        c.name,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          if (onAddCategory != null) ...[
            const SizedBox(width: 4),
            _buildAddCategoryButton(isPhone: false),
          ],
        ],
      ),
    );
  }

  /// Desktop Category Cards
  Widget _buildDesktopCategoryCards() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: categories.map((c) {
        return Padding(
          padding: const EdgeInsets.only(right: 10.0),
          child: MenuCategoryCard(
            category: c,
            isSelected: c.id == selectedCategoryId,
            onTap: () => onSelectCategory(c.id),
            onEdit: onEditCategory,
            onDelete: onDeleteCategory,
            isDark: isDark,
          ),
        );
      }).toList(),
    );
  }
}

class _MenuStatusTabItem {
  final String label;
  final int count;
  final bool isSelected;
  final Color activeColor;
  final VoidCallback onTap;

  const _MenuStatusTabItem({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });
}
