import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'table_status_filter_bar.dart';

class TableFilterHeader extends StatelessWidget {
  final List<String>? floors;
  final int totalCount;
  final int availableCount;
  final int occupiedCount;
  final int reservedCount;
  final String selectedFloor;
  final TableStatus? statusFilter;
  final ValueChanged<String> onSelectFloor;
  final ValueChanged<TableStatus?> onSelectStatus;
  final ValueChanged<String> onSearch;
  final VoidCallback onAddTable;
  final VoidCallback? onRefresh;

  const TableFilterHeader({
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
    required this.onSearch,
    required this.onAddTable,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final isPhone = MediaQuery.of(context).size.width < 650;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 16,
        vertical: isPhone ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Search, and "+ Add Table" Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isPhoneView = constraints.maxWidth < 580;
              final isCompact = constraints.maxWidth < 750;

              Widget buildSearchWidget({bool fullWidth = false}) {
                return SizedBox(
                  width: fullWidth ? double.infinity : (isCompact ? 140 : 200),
                  height: 36,
                  child: TextField(
                    onChanged: onSearch,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                      hintText: 'Search tables...',
                      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                );
              }

              final refreshButton = IconButton(
                onPressed: onRefresh,
                tooltip: 'Refresh Tables & Floors',
                constraints: const BoxConstraints(maxWidth: 34, maxHeight: 34),
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF10B981)),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );

              final addButton = ElevatedButton.icon(
                onPressed: onAddTable,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  minimumSize: const Size(0, 34),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  isPhoneView ? 'Add' : (isCompact ? 'Add' : 'Add Table'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );

              final backButton = OutlinedButton.icon(
                onPressed: () => Navigator.of(context).canPop()
                    ? Navigator.of(context).pop()
                    : context.go('/counter/billing'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  side: BorderSide(color: borderColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(0, 34),
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 15, color: Color(0xFF10B981)),
                label: Text(
                  isPhoneView ? 'POS' : 'Back to POS',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
                ),
              );

              if (isPhoneView) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        backButton,
                        const SizedBox(width: 8),
                        const Icon(Icons.table_restaurant_rounded, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Tables & Floors',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (onRefresh != null) ...[
                          refreshButton,
                          const SizedBox(width: 6),
                        ],
                        addButton,
                      ],
                    ),
                    const SizedBox(height: 8),
                    buildSearchWidget(fullWidth: true),
                  ],
                );
              }

              return Row(
                children: [
                  backButton,
                  const SizedBox(width: 12),
                  const Icon(Icons.table_restaurant_rounded, color: Color(0xFF10B981), size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Table & Floor Management',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  buildSearchWidget(fullWidth: false),
                  if (onRefresh != null) ...[
                    const SizedBox(width: 8),
                    refreshButton,
                  ],
                  const SizedBox(width: 8),
                  addButton,
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Bottom Filter Row: Responsive Floor & Status Matrix
          TableStatusFilterBar(
            floors: floors,
            totalCount: totalCount,
            availableCount: availableCount,
            occupiedCount: occupiedCount,
            reservedCount: reservedCount,
            selectedFloor: selectedFloor,
            statusFilter: statusFilter,
            onSelectFloor: onSelectFloor,
            onSelectStatus: onSelectStatus,
            isDark: isDark,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }
}
