import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import 'inventory_sidebar_footer.dart';

class InventorySidebar extends StatelessWidget {
  final InventorySection selectedSection;
  final ValueChanged<InventorySection> onSectionSelected;
  final bool? isCollapsed;
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

  bool get _isCollapsed => isCollapsed == true;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final sidebarBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);

    final groups = <String, List<InventorySection>>{};
    for (final section in InventorySection.values) {
      groups.putIfAbsent(section.group, () => []).add(section);
    }
    final entries = groups.entries.toList();
    final targetWidth = _isCollapsed ? 68.0 : 256.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 260),
      curve: Curves.fastOutSlowIn,
      clipBehavior: Clip.hardEdge,
      width: targetWidth,
      decoration: BoxDecoration(
        color: sidebarBg,
        border: Border(
          right: BorderSide(color: borderColor, width: 1),
        ),
      ),
      child: Column(
        children: [
          _buildUnifiedHeader(context, isDark),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                for (int i = 0; i < entries.length; i++)
                  _buildGroup(context, entries[i].key, entries[i].value, isDark, i == 0),
              ],
            ),
          ),
          Divider(color: borderColor, height: 1, thickness: 1),
          InventorySidebarFooter(
            isCollapsed: _isCollapsed,
            onToggleCollapse: onToggleCollapse,
            onLogout: onLogout,
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedHeader(BuildContext context, bool isDark) {
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
      ),
      child: Center(
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          curve: Curves.fastOutSlowIn,
          width: _isCollapsed ? 44.0 : 232.0,
          child: Row(
            children: [
              Container(
                width: 44,
                height: 40,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(color: const Color(0xFF10B981).withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
                  ],
                ),
                child: const Center(child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20)),
              ),
              if (!_isCollapsed) ...[
                const SizedBox(width: 10),
                Expanded(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 180),
                    opacity: _isCollapsed ? 0.0 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'INVENTORY',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.6, color: textColor),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                        ),
                        Text(
                          'Restaurant Culinary BOM',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, color: subtitleColor),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGroup(BuildContext context, String groupTitle, List<InventorySection> items, bool isDark, bool isFirst) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst)
          Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.fastOutSlowIn,
              width: _isCollapsed ? 44.0 : 232.0,
              padding: EdgeInsets.symmetric(vertical: _isCollapsed ? 6 : 8),
              child: _isCollapsed
                  ? Divider(
                      height: 1,
                      thickness: 0.8,
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    )
                  : Text(
                      groupTitle.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                      ),
                    ),
            ),
          )
        else if (!_isCollapsed)
          Center(
            child: SizedBox(
              width: 232.0,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
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
            ),
          ),
        ...items.map((sec) => _buildUnifiedItem(context, sec, isDark)),
      ],
    );
  }

  Widget _buildUnifiedItem(BuildContext context, InventorySection sec, bool isDark) {
    final isSelected = sec == selectedSection;
    final badge = badgeCounts?[sec] ?? 0;

    final selectedBg = const Color(0xFF10B981).withValues(alpha: 0.12);
    final selectedBorder = const Color(0xFF10B981).withValues(alpha: 0.35);
    final unselectedText = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    const selectedText = Color(0xFF10B981);

    final itemWidget = Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.fastOutSlowIn,
        width: _isCollapsed ? 48.0 : 236.0,
        height: 40,
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          color: isSelected ? selectedBg : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: isSelected
              ? Border.all(color: selectedBorder, width: 1.2)
              : Border.all(color: Colors.transparent, width: 1.2),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: () => onSectionSelected(sec),
            child: ClipRect(
              child: OverflowBox(
                minWidth: 0,
                maxWidth: 236,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 236,
                  height: 40,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              sec.icon,
                              color: isSelected ? selectedText : unselectedText,
                              size: 19,
                            ),
                            if (badge > 0 && _isCollapsed)
                              Positioned(
                                top: 5,
                                right: 8,
                                child: Container(
                                  width: 7,
                                  height: 7,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFEF4444),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isCollapsed ? 0.0 : 1.0,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    sec.title,
                                    style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? selectedText : (isDark ? Colors.white : const Color(0xFF1E293B)),
                                    ),
                                    overflow: TextOverflow.clip,
                                    maxLines: 1,
                                  ),
                                ),
                                if (badge > 0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      '$badge',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (_isCollapsed) {
      return Tooltip(
        message: sec.title,
        waitDuration: const Duration(milliseconds: 150),
        child: itemWidget,
      );
    }
    return itemWidget;
  }
}
