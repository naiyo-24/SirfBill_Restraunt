import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/stock_consumption_models.dart';
import '../services/stock_consumption_api_service.dart';
import '../widgets/inventory_header.dart';

class StockConsumptionSection extends StatefulWidget {
  final String? outletId;
  const StockConsumptionSection({super.key, this.outletId});

  @override
  State<StockConsumptionSection> createState() => _StockConsumptionSectionState();
}

class _StockConsumptionSectionState extends State<StockConsumptionSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _reasonFilter; // null = all, ORDER_CONSUMPTION, REVERSAL, WASTAGE
  bool _isDetailedLedgerView = false;
  StockConsumptionStreamData? _streamData;
  bool _isLoading = true;

  StockConsumptionStreamData get _safeData =>
      _streamData ??
      const StockConsumptionStreamData(
        isActive: true,
        totalRecords: 0,
        totalConsumptionInr: 0.0,
        totalReversalsInr: 0.0,
        totalWastageInr: 0.0,
        events: [],
        ledgerStream: [],
      );

  @override
  void initState() {
    super.initState();
    _loadStream();
  }

  @override
  void didUpdateWidget(covariant StockConsumptionSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outletId != widget.outletId) {
      _loadStream();
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStream() async {
    setState(() => _isLoading = true);
    try {
      final data = await StockConsumptionApiService.fetchConsumptionStream(
        outletId: widget.outletId,
        reason: _reasonFilter,
        search: _searchQuery,
      );
      if (mounted) {
        setState(() {
          _streamData = data;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredEvents = _safeData.events.where((e) {
      final q = _searchQuery.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          e.orderId.toLowerCase().contains(q) ||
          e.dishName.toLowerCase().contains(q);
      final matchReason = _reasonFilter == null || e.reason == _reasonFilter;
      return matchQuery && matchReason;
    }).toList();

    final filteredLedger = _safeData.ledgerStream.where((item) {
      final q = _searchQuery.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          item.orderNumber.toLowerCase().contains(q) ||
          item.dishName.toLowerCase().contains(q) ||
          item.ingredientName.toLowerCase().contains(q);
      final matchReason = _reasonFilter == null || item.reason == _reasonFilter;
      return matchQuery && matchReason;
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Stock Consumption Engine',
          subtitle: 'Automatic ingredient deduction stream triggered when POS orders are KOT dispatched or settled',
          searchController: _searchController,
          onSearchChanged: (v) {
            _searchQuery = v;
            setState(() {});
          },
          searchHint: 'Search order ID, dish, or commodity...',
          onRefresh: _loadStream,
          trailing: _buildEngineStatusBadge(),
        ),
        _buildMetricSummaryBanner(isDark),
        _buildFilterAndToggleBar(isDark),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (_isDetailedLedgerView
                  ? (filteredLedger.isEmpty ? _buildEmptyState(isDark) : _buildLedgerStreamList(filteredLedger, isDark))
                  : (filteredEvents.isEmpty ? _buildEmptyState(isDark) : _buildEventsList(filteredEvents, isDark))),
        ),
      ],
    );
  }

  Widget _buildEngineStatusBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 16, color: Color(0xFF10B981)),
          SizedBox(width: 6),
          Text(
            'Auto-Deduction: ACTIVE',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricSummaryBanner(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryCell('Consumed Stock', '₹${_safeData.totalConsumptionInr.toStringAsFixed(2)}', const Color(0xFF10B981), isDark),
          _buildDivider(isDark),
          _buildSummaryCell('Returned to Shelf', '₹${_safeData.totalReversalsInr.toStringAsFixed(2)}', const Color(0xFF3B82F6), isDark),
          _buildDivider(isDark),
          _buildSummaryCell('Prep Wastage', '₹${_safeData.totalWastageInr.toStringAsFixed(2)}', const Color(0xFFEF4444), isDark),
          _buildDivider(isDark),
          _buildSummaryCell('Ledger Mutations', '${_safeData.totalRecords} deductions', isDark ? Colors.white : const Color(0xFF0F172A), isDark),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(height: 32, width: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
  }

  Widget _buildSummaryCell(String label, String value, Color color, bool isDark) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _buildFilterAndToggleBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildFilterChip('All Events', null),
              const SizedBox(width: 6),
              _buildFilterChip('KOT Consumptions', 'ORDER_CONSUMPTION'),
              const SizedBox(width: 6),
              _buildFilterChip('Voids (Restocked)', 'REVERSAL'),
              const SizedBox(width: 6),
              _buildFilterChip('Wastage', 'WASTAGE'),
            ],
          ),
          Row(
            children: [
              Text('Detailed Audit View', style: TextStyle(fontSize: 11.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              const SizedBox(width: 6),
              Switch(
                value: _isDetailedLedgerView,
                activeThumbColor: const Color(0xFF10B981),
                onChanged: (v) => setState(() => _isDetailedLedgerView = v),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, String? reason) {
    final isSelected = _reasonFilter == reason;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) {
        setState(() => _reasonFilter = reason);
        _loadStream();
      },
      selectedColor: const Color(0xFF10B981).withValues(alpha: 0.2),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.soup_kitchen_outlined, size: 52, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          const Text('No recipe consumptions recorded yet', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'When orders are fired in POS or KDS, raw ingredient deductions will stream here in real time.',
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<StockConsumptionGroup> events, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final c = events[index];
        final isReversal = c.reason == 'REVERSAL';
        final isWastage = c.reason == 'WASTAGE';
        final accentColor = isReversal ? const Color(0xFF3B82F6) : (isWastage ? const Color(0xFFEF4444) : const Color(0xFF10B981));
        final reasonBadge = isReversal ? 'RESTOCKED' : (isWastage ? 'WASTAGE' : 'CONSUMED');

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: ExpansionTile(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            tilePadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)),
              child: Icon(isReversal ? Icons.replay_rounded : Icons.soup_kitchen_rounded, color: accentColor, size: 22),
            ),
            title: Row(
              children: [
                Text(
                  c.dishName,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                  child: Text(c.orderId, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Color(0xFF3B82F6))),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                  child: Text(reasonBadge, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: accentColor)),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 6.0),
              child: Row(
                children: [
                  Text(
                    '${c.portionsPrepared} portions prepared • Cost: ₹${c.totalBatchCost.toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    dateFormat.format(c.timestamp),
                    style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
                  ),
                ],
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${c.deductions.length} commodity lines', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                const SizedBox(height: 2),
                Text(isReversal ? 'Restored to shelf' : 'Deducted from stock', style: TextStyle(fontSize: 11, color: accentColor, fontWeight: FontWeight.bold)),
              ],
            ),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AUTOMATED DEDUCTION TRACE (DUAL-UOM NORMALIZED)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 8),
                    ...c.deductions.map((d) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 14, color: accentColor),
                              const SizedBox(width: 8),
                              Text(d, style: TextStyle(fontSize: 12.5, color: isDark ? Colors.white70 : Colors.black87)),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLedgerStreamList(List<StockConsumptionItem> items, bool isDark) {
    final dateFormat = DateFormat('dd MMM, hh:mm a');

    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        final isReversal = item.reason == 'REVERSAL';
        final isWastage = item.reason == 'WASTAGE';
        final accentColor = isReversal ? const Color(0xFF3B82F6) : (isWastage ? const Color(0xFFEF4444) : const Color(0xFF10B981));

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
                child: Icon(isReversal ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: accentColor, size: 18),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.ingredientName, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    const SizedBox(height: 2),
                    Text('${item.dishName} • Order: ${item.orderNumber}', style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ],
                ),
              ),
              Expanded(
                flex: 2,
                child: Text(
                  '${item.signedQuantity > 0 ? "+" : ""}${item.signedQuantity.toStringAsFixed(1)} ${item.unit}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: accentColor),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('₹${item.totalCost.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text('WAC: ₹${item.unitCost.toStringAsFixed(2)}/${item.unit}', style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Text(dateFormat.format(item.timestamp), style: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
            ],
          ),
        );
      },
    );
  }
}
