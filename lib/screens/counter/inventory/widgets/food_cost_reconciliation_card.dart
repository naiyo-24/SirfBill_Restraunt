import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../models/food_cost_models.dart';
import '../services/food_cost_api_service.dart';
import 'food_cost_breakdown_table.dart';

class FoodCostReconciliationCard extends StatefulWidget {
  final String? outletId;

  const FoodCostReconciliationCard({
    super.key,
    this.outletId,
  });

  @override
  State<FoodCostReconciliationCard> createState() => _FoodCostReconciliationCardState();
}

class _FoodCostReconciliationCardState extends State<FoodCostReconciliationCard> {
  int _selectedDays = 30;
  bool _isLoading = true;
  FoodCostReconciliationReport _report = FoodCostReconciliationReport.empty();
  String _searchQuery = '';
  CancelToken? _cancelToken;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  @override
  void didUpdateWidget(covariant FoodCostReconciliationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.outletId != widget.outletId) {
      _loadReport();
    }
  }

  @override
  void dispose() {
    _cancelToken?.cancel();
    super.dispose();
  }

  Future<void> _loadReport() async {
    _cancelToken?.cancel();
    _cancelToken = CancelToken();

    setState(() => _isLoading = true);
    try {
      final res = await FoodCostApiService.getFoodCostReconciliation(
        outletId: widget.outletId,
        days: _selectedDays,
        cancelToken: _cancelToken,
      );
      if (mounted) {
        setState(() {
          _report = res;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final summary = _report.summary;

    final filteredBreakdown = _report.breakdown.where((item) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return item.ingredientName.toLowerCase().contains(q) ||
          item.category.toLowerCase().contains(q) ||
          item.healthStatus.toLowerCase().contains(q);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(context, isDark),
          const SizedBox(height: 16),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF10B981)),
              ),
            )
          else ...[
            _buildKpiMetrics(context, isDark, summary),
            const SizedBox(height: 16),
            _buildBenchmarkBar(context, isDark, summary),
            const SizedBox(height: 20),
            _buildBreakdownHeader(context, isDark),
            const SizedBox(height: 12),
            FoodCostBreakdownTable(items: filteredBreakdown, isDark: isDark),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Actual vs. Theoretical Food Cost Reconciliation',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Theoretical cost is computed by POS Recipe BOM consumption. Variances are attributed to Recorded Wastage and Unrecorded Prep Loss/Spillage in kitchen operations.',
                style: TextStyle(
                  fontSize: 12,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        _buildTimeframeSelector(isDark),
      ],
    );
  }

  Widget _buildTimeframeSelector(bool isDark) {
    const timeframes = [7, 30, 90];
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: timeframes.map((days) {
          final isSelected = _selectedDays == days;
          return InkWell(
            onTap: () {
              if (_selectedDays != days) {
                setState(() => _selectedDays = days);
                _loadReport();
              }
            },
            borderRadius: BorderRadius.circular(6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? const Color(0xFF1E293B) : Colors.white)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        )
                      ]
                    : null,
              ),
              child: Text(
                '$days Days',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, bool isDark, FoodCostSummaryData summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        final cardWidth = isWide ? (constraints.maxWidth - 48) / 4 : (constraints.maxWidth - 16) / 2;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildMetricTile(
              title: 'Theoretical Cost (BOM)',
              value: '₹${summary.theoreticalCostInr.toStringAsFixed(2)}',
              subtitle: '${summary.theoreticalCostPct.toStringAsFixed(1)}% of ₹${summary.totalSalesInr.toStringAsFixed(0)} sales',
              accentColor: const Color(0xFF3B82F6),
              icon: Icons.receipt_long_outlined,
              isDark: isDark,
              width: cardWidth,
            ),
            _buildMetricTile(
              title: 'Recorded Wastage',
              value: '₹${summary.recordedWasteInr.toStringAsFixed(2)}',
              subtitle: 'Burnt batches, trim & drops',
              accentColor: const Color(0xFFF59E0B),
              icon: Icons.delete_sweep_outlined,
              isDark: isDark,
              width: cardWidth,
            ),
            _buildMetricTile(
              title: 'Physical Audit Shrinkage',
              value: '₹${summary.auditShrinkageInr.toStringAsFixed(2)}',
              subtitle: 'Shelf variance discrepancy',
              accentColor: const Color(0xFF8B5CF6),
              icon: Icons.fact_check_outlined,
              isDark: isDark,
              width: cardWidth,
            ),
            _buildMetricTile(
              title: 'Actual Food Cost (COGS)',
              value: '₹${summary.actualCogsInr.toStringAsFixed(2)}',
              subtitle: '${summary.actualCostPct.toStringAsFixed(1)}% (Gap: +₹${summary.varianceLossInr.toStringAsFixed(0)})',
              accentColor: summary.actualCostPct <= summary.targetBenchmarkPct
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
              icon: Icons.account_balance_wallet_outlined,
              isDark: isDark,
              width: cardWidth,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String title,
    required String value,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
    required bool isDark,
    required double width,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              Icon(icon, size: 16, color: accentColor),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: accentColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenchmarkBar(BuildContext context, bool isDark, FoodCostSummaryData summary) {
    final cogsPct = summary.actualCostPct;
    final benchmark = summary.targetBenchmarkPct;
    final isWithinBudget = cogsPct <= benchmark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A).withValues(alpha: 0.5) : const Color(0xFFF1F5F9).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isWithinBudget ? Icons.check_circle_outline : Icons.warning_amber_rounded,
            size: 18,
            color: isWithinBudget ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Actual Food Cost: ${cogsPct.toStringAsFixed(1)}% of Gross Sales (Target Benchmark: ${benchmark.toStringAsFixed(1)}%)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      isWithinBudget ? 'HEALTHY MARGIN' : 'OVER BUDGET',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: isWithinBudget ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (cogsPct / 50.0).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isWithinBudget ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBreakdownHeader(BuildContext context, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Commodity Food Cost & Variance Breakdown',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        SizedBox(
          width: 220,
          height: 34,
          child: TextField(
            onChanged: (val) => setState(() => _searchQuery = val),
            style: TextStyle(fontSize: 12, color: isDark ? Colors.white : const Color(0xFF0F172A)),
            decoration: InputDecoration(
              hintText: 'Filter commodities...',
              hintStyle: TextStyle(fontSize: 11, color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8)),
              prefixIcon: const Icon(Icons.search, size: 14),
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(6),
                borderSide: BorderSide(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
