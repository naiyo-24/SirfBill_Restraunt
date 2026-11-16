import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/inventory_models.dart';
import 'inventory_sidebar_footer.dart';

class InventorySidebar extends StatelessWidget {
  final InventorySection selectedSection;
  final ValueChanged<InventorySection> onSectionSelected;
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback onLogout;
  final Map<InventorySection, int>? badgeCounts;
  final bool isStandalone;
  final VoidCallback? onBackToDashboard;

  const InventorySidebar({
    super.key,
    required this.selectedSection,
    required this.onSectionSelected,
    this.isCollapsed = false,
    this.onToggleCollapse,
    required this.onLogout,
    this.badgeCounts,
    this.isStandalone = false,
    this.onBackToDashboard,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final sidebarBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    final groups = <String, List<InventorySection>>{};
    for (final section in InventorySection.values) {
      groups.putIfAbsent(section.group, () => []).add(section);
    }

    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(context, isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              children: groups.entries.map((entry) {
                return _buildGroup(context, entry.key, entry.value, isDark);
              }).toList(),
            ),
          ),
          Divider(color: borderColor, height: 1, thickness: 1),
          InventorySidebarFooter(
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      alignment: Alignment.centerLeft,
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withValues(alpha: 0.25),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.inventory_2_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'INVENTORY',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        letterSpacing: 0.6,
                        color: textColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Restaurant Culinary BOM',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          InkWell(
            onTap: () {
              if (onBackToDashboard != null) {
                onBackToDashboard!();
              } else {
                context.go('/dashboard');
              }
            },
            borderRadius: BorderRadius.circular(8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                    : const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                      : const Color(0xFFBFDBFE),
                  width: 1,
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.arrow_back_rounded,
                    size: 13,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Main Dashboard',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroup(
    BuildContext context,
    String groupTitle,
    List<InventorySection> items,
    bool isDark,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 4),
          child: Text(
            groupTitle.toUpperCase(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
        ),
        ...items.map((sec) => _buildItem(context, sec, isDark)),
      ],
    );
  }

  Widget _buildItem(BuildContext context, InventorySection sec, bool isDark) {
    final isSelected = sec == selectedSection;
    final badge = badgeCounts?[sec] ?? 0;

    final selectedBg = const Color(0xFF10B981).withValues(alpha: 0.12);
    final selectedBorder = const Color(0xFF10B981).withValues(alpha: 0.3);
    final unselectedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    const selectedText = Color(0xFF10B981);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: isSelected ? selectedBg : Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: isSelected
              ? BorderSide(color: selectedBorder, width: 1)
              : BorderSide.none,
        ),
        child: ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
          leading: Icon(
            sec.icon,
            color: isSelected ? selectedText : unselectedText,
            size: 19,
          ),
          minLeadingWidth: 24,
          title: Text(
            sec.title,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? selectedText : (isDark ? Colors.white : const Color(0xFF1E293B)),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: badge > 0
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                )
              : null,
          onTap: () => onSectionSelected(sec),
        ),
      ),
    );
  }
}
