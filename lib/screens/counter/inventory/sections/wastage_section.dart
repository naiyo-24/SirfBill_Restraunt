import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/wastage_models.dart';
import '../services/wastage_api_service.dart';
import '../widgets/inventory_header.dart';
import '../widgets/log_wastage_dialog.dart';

class WastageSection extends StatefulWidget {
  const WastageSection({super.key});

  @override
  State<WastageSection> createState() => _WastageSectionState();
}

class _WastageSectionState extends State<WastageSection> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _reasonFilter; // null = all, SPOILAGE, BURNT_RUINED, EXPIRY, CUSTOMER_RETURN, PREP_TRIM
  List<WastageItemRecord>? _logs = [];
  WastageSummaryData? _summary;
  bool _isLoading = true;

  List<WastageItemRecord> get _safeLogs => _logs ?? const [];
  WastageSummaryData get _safeSummary =>
      _summary ??
      const WastageSummaryData(
        isActive: true,
        timeframeDays: 30,
        totalWasteIncidents: 0,
        totalFinancialLossInr: 0.0,
        lossByReasonInr: {},
        topWastedIngredients: [],
      );

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final logsFuture = WastageApiService.getWastageLogs();
      final summaryFuture = WastageApiService.getWastageSummary();

      final results = await Future.wait([logsFuture, summaryFuture]);
      if (mounted) {
        setState(() {
          _logs = results[0] as List<WastageItemRecord>;
          _summary = results[1] as WastageSummaryData?;
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

    final filtered = _safeLogs.where((w) {
      final q = _searchQuery.toLowerCase().trim();
      final matchQuery = q.isEmpty ||
          w.ingredientName.toLowerCase().contains(q) ||
          w.reportedBy.toLowerCase().contains(q) ||
          w.notes.toLowerCase().contains(q);
      final matchReason = _reasonFilter == null || w.wasteReason.toUpperCase().contains(_reasonFilter!);
      return matchQuery && matchReason;
    }).toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Wastage & Spoilage Tracking',
          subtitle: 'Decouple food loss from COGS with raw material spoilage, recipe BOM prep discards & void audits',
          searchController: _searchController,
          onSearchChanged: (v) => setState(() => _searchQuery = v),
          searchHint: 'Search wasted ingredient, reporter, or note...',
          onRefresh: _loadData,
          trailing: ElevatedButton.icon(
            onPressed: () => LogWastageDialog.show(context, onLogged: _loadData),
            icon: const Icon(Icons.delete_sweep_rounded, size: 16),
            label: const Text('Log Kitchen Wastage'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        _buildMetricSummaryBanner(isDark),
        if (_safeSummary.topWastedIngredients.isNotEmpty) _buildTopLeakageRadar(isDark),
        _buildFilterBar(isDark),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : (filtered.isEmpty
                  ? _buildEmptyState(isDark)
                  : ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        return _buildWastageCard(context, filtered[index], isDark);
                      },
                    )),
        ),
      ],
    );
  }

  Widget _buildMetricSummaryBanner(bool isDark) {
    final s = _safeSummary;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildSummaryCell('Financial Loss (30d)', '₹${s.totalFinancialLossInr.toStringAsFixed(2)}', const Color(0xFFEF4444), isDark),
            _buildDivider(isDark),
            _buildSummaryCell('Wastage Incidents', '${s.totalWasteIncidents} logged', const Color(0xFFEA580C), isDark),
            _buildDivider(isDark),
            _buildSummaryCell('Primary Loss Reason', s.lossByReasonInr.isNotEmpty ? s.lossByReasonInr.keys.first : 'None', const Color(0xFF7C3AED), isDark),
            _buildDivider(isDark),
            _buildSummaryCell('Leakage Scope', '${_safeLogs.length} ledger records', isDark ? Colors.white : const Color(0xFF0F172A), isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Container(height: 32, width: 1, margin: const EdgeInsets.symmetric(horizontal: 12), color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));
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

  Widget _buildTopLeakageRadar(bool isDark) {
    final top = _safeSummary.topWastedIngredients.take(4).toList();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.radar_rounded, size: 18, color: Color(0xFFEF4444)),
          const SizedBox(width: 8),
          const Text('Top Leakage Commodities: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: Color(0xFFEF4444))),
          const SizedBox(width: 8),
          Expanded(
            child: Wrap(
              spacing: 8,
              runSpacing: 4,
              children: top.map((t) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    '${t.ingredientName}: -${t.totalQuantityWasted.toStringAsFixed(0)} ${t.unit} (₹${t.totalLossInr.toStringAsFixed(0)})',
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(bottom: BorderSide(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: Row(
          children: [
            _buildFilterChip('All Loss (${_safeLogs.length})', null),
            const SizedBox(width: 6),
            _buildFilterChip('Spoilage', 'SPOILAGE'),
            const SizedBox(width: 6),
            _buildFilterChip('Burnt / Ruined', 'BURNT'),
            const SizedBox(width: 6),
            _buildFilterChip('Expired', 'EXPIR'),
            const SizedBox(width: 6),
            _buildFilterChip('Customer Return', 'RETURN'),
            const SizedBox(width: 6),
            _buildFilterChip('Prep Trim', 'TRIM'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String? reasonCode) {
    final isSelected = _reasonFilter == reasonCode;
    return ChoiceChip(
      label: Text(label, style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
      selected: isSelected,
      onSelected: (_) => setState(() => _reasonFilter = reasonCode),
      selectedColor: const Color(0xFFEF4444).withValues(alpha: 0.2),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.verified_rounded, size: 52, color: Colors.green.shade400),
          const SizedBox(height: 12),
          const Text('Zero Wastage Logged', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            'No raw material spoilage, burnt prep pots, or void returns recorded.',
            style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => LogWastageDialog.show(context, onLogged: _loadData),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Log First Kitchen Wastage'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _buildWastageCard(BuildContext context, WastageItemRecord w, bool isDark) {
    final dateFormat = DateFormat('dd MMM yyyy, hh:mm a');
    final reasonMeta = WastageReasonType.fromCode(w.wasteReason);
    final accentColor = reasonMeta.color;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
            child: Icon(reasonMeta.icon, color: accentColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      w.ingredientName,
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: accentColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                      child: Text(reasonMeta.label, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: accentColor)),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Reported by: ${w.reportedBy} • Source: ${w.sourceType.replaceAll('_', ' ').toUpperCase()}',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                if (w.notes.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(w.notes, style: TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Colors.grey.shade600), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 2),
                Text(dateFormat.format(w.reportedAt), style: TextStyle(fontSize: 10, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-${w.quantity.toStringAsFixed(1)} ${w.unit}',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: accentColor),
                ),
                const SizedBox(height: 2),
                Text(
                  '₹${w.cost.toStringAsFixed(2)} Loss',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFFEF4444)),
                ),
                const SizedBox(height: 2),
                Text('WAC: ₹${w.unitCost.toStringAsFixed(2)}/${w.unit}', style: TextStyle(fontSize: 10.5, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
