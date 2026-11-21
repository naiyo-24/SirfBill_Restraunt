import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../widgets/common_filter_pills.dart';
import 'order_status_filter_bar.dart';

class OrderFilterHeader extends StatelessWidget {
  final int totalCount;
  final int activeCount;
  final int completedCount;
  final int holdCount;
  final OrderStatus? statusFilter;
  final OrderType? typeFilter;
  final DateRangePreset datePreset;
  final DateTimeRange? customRange;
  final ValueChanged<OrderStatus?> onSelectStatus;
  final ValueChanged<OrderType?> onSelectType;
  final ValueChanged<DateRangePreset> onSelectDatePreset;
  final ValueChanged<DateTimeRange?> onSelectCustomRange;
  final ValueChanged<String> onSearch;
  final VoidCallback onNewOrder;
  final VoidCallback? onRefresh;
  final VoidCallback? onExport;
  final bool isLoading;

  const OrderFilterHeader({
    super.key,
    required this.totalCount,
    required this.activeCount,
    required this.completedCount,
    required this.holdCount,
    required this.statusFilter,
    required this.typeFilter,
    required this.datePreset,
    this.customRange,
    required this.onSelectStatus,
    required this.onSelectType,
    required this.onSelectDatePreset,
    required this.onSelectCustomRange,
    required this.onSearch,
    required this.onNewOrder,
    this.onRefresh,
    this.onExport,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final isPhone = MediaQuery.of(context).size.width < 650;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 20,
        vertical: isPhone ? 10 : 16,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor, width: 1.2)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : const Color(0xFF0F172A).withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title Badge, Search, Refresh, and "+ New Order" Button
          LayoutBuilder(
            builder: (context, constraints) {
              final isPhone = constraints.maxWidth < 650;
              final isCompact = constraints.maxWidth < 850;

              Widget buildSearchWidget({bool fullWidth = false}) {
                return SizedBox(
                  width: fullWidth ? double.infinity : (isCompact ? 160 : 250),
                  height: isPhone ? 38 : 44,
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor, width: 1.2),
                    ),
                    child: Row(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 10),
                          child: Icon(Icons.search_rounded, size: 18, color: Color(0xFF94A3B8)),
                        ),
                        Expanded(
                          child: TextField(
                            onChanged: onSearch,
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500),
                            decoration: const InputDecoration(
                              isDense: true,
                              border: InputBorder.none,
                              hintText: 'Search order #, table...',
                              hintStyle: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              Widget buildRefreshButton() {
                return Tooltip(
                  message: 'Refresh Orders',
                  child: InkWell(
                    onTap: isLoading ? null : onRefresh,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      width: isPhone ? 38 : 44,
                      height: isPhone ? 38 : 44,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor, width: 1.2),
                      ),
                      child: Center(
                        child: isLoading
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF10B981)),
                              )
                            : Icon(Icons.refresh_rounded, size: isPhone ? 18 : 22, color: const Color(0xFF10B981)),
                      ),
                    ),
                  ),
                );
              }

              Widget buildExportButton() {
                return Tooltip(
                  message: 'Export Orders (Excel / PDF)',
                  child: InkWell(
                    onTap: onExport,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: isPhone ? 38 : 44,
                      padding: EdgeInsets.symmetric(horizontal: isPhone ? 10 : 14),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4), width: 1.2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.file_download_outlined, size: isPhone ? 18 : 20, color: const Color(0xFF10B981)),
                          if (!isPhone) ...[
                            const SizedBox(width: 6),
                            const Text(
                              'Export Data',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                );
              }

              Widget buildNewOrderButton() {
                return SizedBox(
                  height: isPhone ? 38 : 44,
                  child: ElevatedButton.icon(
                    onPressed: onNewOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    icon: Icon(Icons.add_rounded, size: isPhone ? 16 : 18),
                    label: Text(
                      isPhone ? 'POS' : (isCompact ? 'POS' : 'New Order'),
                      style: TextStyle(fontSize: isPhone ? 12 : 13.5, fontWeight: FontWeight.bold),
                    ),
                  ),
                );
              }

              if (isPhone) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(7),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Live Orders',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'Kitchen status & bills',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        if (onRefresh != null) ...[
                          buildRefreshButton(),
                          const SizedBox(width: 6),
                        ],
                        if (onExport != null) ...[
                          buildExportButton(),
                          const SizedBox(width: 6),
                        ],
                        buildNewOrderButton(),
                      ],
                    ),
                    const SizedBox(height: 10),
                    buildSearchWidget(fullWidth: true),
                  ],
                );
              }

              return Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Live Orders & History',
                          style: TextStyle(
                            fontSize: isCompact ? 16 : 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Track real-time kitchen status, print bills & manage guest orders',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  buildSearchWidget(fullWidth: false),
                  if (onRefresh != null) ...[
                    const SizedBox(width: 10),
                    buildRefreshButton(),
                  ],
                  if (onExport != null) ...[
                    const SizedBox(width: 10),
                    buildExportButton(),
                  ],
                  const SizedBox(width: 10),
                  buildNewOrderButton(),
                ],
              );
            },
          ),
          const SizedBox(height: 12),

          // Bottom Responsive Filter Bar (Adaptive Phone, Tablet & Desktop)
          OrderStatusFilterBar(
            totalCount: totalCount,
            activeCount: activeCount,
            holdCount: holdCount,
            completedCount: completedCount,
            statusFilter: statusFilter,
            typeFilter: typeFilter,
            datePreset: datePreset,
            customRange: customRange,
            onSelectStatus: onSelectStatus,
            onSelectType: onSelectType,
            onSelectDatePreset: onSelectDatePreset,
            onSelectCustomRange: onSelectCustomRange,
            isDark: isDark,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }
}
