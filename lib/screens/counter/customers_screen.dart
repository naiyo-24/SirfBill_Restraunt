import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/restaurant_crm_models.dart';
import '../../providers/restaurant_crm_provider.dart';
import 'widgets/crm/crm_kpi_cards.dart';
import 'widgets/crm/crm_segment_bar.dart';
import 'widgets/crm/crm_customer_card.dart';
import 'widgets/crm/crm_customer_table.dart';
import 'widgets/crm/crm_360_insights_modal.dart';
import 'widgets/crm/crm_khata_settle_dialog.dart';
import 'widgets/crm/crm_add_edit_customer_dialog.dart';
import 'widgets/reports/restaurant_executive_export_helper.dart';
import '../../models/restaurant_report_models.dart';

class CustomersScreen extends ConsumerStatefulWidget {
  const CustomersScreen({super.key});

  @override
  ConsumerState<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends ConsumerState<CustomersScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _currentPage = 1;
  static const int _pageSize = 12;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _handleExportCustomers() {
    final state = ref.read(restaurantCrmProvider);
    RestaurantExecutiveExportHelper.exportMasterWorkbookExcel(
      context: context,
      periodLabel: 'Customer Master',
      summary: SalesReportSummary.empty(),
      topDishes: const [],
      orders: const [],
      auditLogs: const [],
      customers: state.customers,
    );
  }

  void _openAddEditDialog([RestaurantCustomer? customer]) {
    final notifier = ref.read(restaurantCrmProvider.notifier);
    CrmAddEditCustomerDialog.show(
      context,
      customer: customer,
      onSave: notifier.saveCustomer,
    );
  }

  void _openKhataSettleDialog(RestaurantCustomer customer) {
    final notifier = ref.read(restaurantCrmProvider.notifier);
    CrmKhataSettleDialog.show(
      context,
      customer: customer,
      onSettle: notifier.settleKhataDues,
    );
  }

  void _openAdjustLoyaltyDialog(RestaurantCustomer customer) {
    final notifier = ref.read(restaurantCrmProvider.notifier);
    final ctrl = TextEditingController();
    final reasonCtrl = TextEditingController(text: 'Manual adjustment');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.stars_rounded, color: Color(0xFFF59E0B)),
            SizedBox(width: 8),
            Text('Adjust Loyalty Points', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Points: ${customer.loyaltyPoints} pts', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(signed: true),
              decoration: const InputDecoration(
                labelText: 'Points Delta (+ or -)',
                hintText: 'e.g. 100 or -50',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final pts = int.tryParse(ctrl.text.trim()) ?? 0;
              if (pts == 0) return;
              Navigator.pop(ctx);
              await notifier.adjustLoyaltyPoints(
                customerId: customer.id,
                points: pts,
                reason: reasonCtrl.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteCustomer(RestaurantCustomer customer) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Guest Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to permanently delete profile for "${customer.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(restaurantCrmProvider.notifier).deleteCustomer(customer.id);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showMobileInsightsSheet(RestaurantCustomer customer) {
    ref.read(restaurantCrmProvider.notifier).selectCustomer(customer);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final state = ref.watch(restaurantCrmProvider);
          return Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Crm360InsightsModal(
              customer: customer,
              insights: state.insights,
              khataLedger: state.khataLedger,
              isLoading: state.isInsightsLoading,
              onClose: () => Navigator.pop(ctx),
              onSettleKhata: () {
                Navigator.pop(ctx);
                _openKhataSettleDialog(customer);
              },
              onAdjustLoyalty: () {
                Navigator.pop(ctx);
                _openAdjustLoyaltyDialog(customer);
              },
              onEditProfile: () {
                Navigator.pop(ctx);
                _openAddEditDialog(customer);
              },
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantCrmProvider);
    final notifier = ref.read(restaurantCrmProvider.notifier);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    final filtered = state.filteredCustomers;
    final totalRecords = filtered.length;
    final totalPages = (totalRecords / _pageSize).ceil() == 0 ? 1 : (totalRecords / _pageSize).ceil();
    final startIdx = (_currentPage - 1) * _pageSize;
    final endIdx = (startIdx + _pageSize > totalRecords) ? totalRecords : startIdx + _pageSize;
    final paged = filtered.isNotEmpty ? filtered.sublist(startIdx, endIdx) : <RestaurantCustomer>[];

    final segmentCounts = {
      CustomerSegment.all: state.totalGuests,
      CustomerSegment.vip: state.vipCount,
      CustomerSegment.regular: state.regularCount,
      CustomerSegment.newGuest: state.newCount,
      CustomerSegment.atRisk: state.atRiskCount,
      CustomerSegment.hasDue: state.customers.where((c) => c.creditBalance > 0).length,
    };

    return Scaffold(
      backgroundColor: screenBg,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 650;
          final isTablet = constraints.maxWidth >= 650 && constraints.maxWidth < 1050;
          final isDesktop = constraints.maxWidth >= 1050;

          return RefreshIndicator(
            color: const Color(0xFF10B981),
            onRefresh: () => notifier.loadCustomers(),
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 20, vertical: 16),
              children: [
                // 1. KPI Summary Cards
                CrmKpiCards(
                  totalGuests: state.totalGuests,
                  vipCount: state.vipCount,
                  regularCount: state.regularCount,
                  totalKhataOutstanding: state.totalKhataOutstanding,
                  totalLoyaltyPoints: state.totalLoyaltyPoints,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),

                // 2. Segment Filter Bar + Search
                CrmSegmentBar(
                  selectedSegment: state.selectedSegment,
                  onSegmentSelected: (seg) {
                    notifier.selectSegment(seg);
                    setState(() => _currentPage = 1);
                  },
                  searchController: _searchCtrl,
                  onSearchChanged: (val) {
                    notifier.setSearchQuery(val);
                    setState(() => _currentPage = 1);
                  },
                  onAddCustomer: () => _openAddEditDialog(),
                  onRefresh: () => notifier.loadCustomers(),
                  onExport: _handleExportCustomers,
                  segmentCounts: segmentCounts,
                  isMobile: isMobile,
                ),
                const SizedBox(height: 16),

                // 3. Customer Directory Content (Desktop: Table + optional side pane; Mobile/Tablet: Card Grid)
                if (state.isLoading)
                  const SizedBox(
                    height: 300,
                    child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
                  )
                else if (isDesktop)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Main Table Area
                      Expanded(
                        child: CrmCustomerTable(
                          customers: paged,
                          selectedCustomer: state.selectedCustomer,
                          onSelectCustomer: (cust) {
                            if (state.selectedCustomer?.id == cust.id) {
                              notifier.selectCustomer(null);
                            } else {
                              notifier.selectCustomer(cust);
                            }
                          },
                          onSettleKhata: _openKhataSettleDialog,
                          onEdit: _openAddEditDialog,
                          onDelete: _confirmDeleteCustomer,
                          currentPage: _currentPage,
                          totalPages: totalPages,
                          totalRecords: totalRecords,
                          onPageChanged: (page) => setState(() => _currentPage = page),
                        ),
                      ),

                      // Optional Right 360 Insights Panel if customer is selected
                      if (state.selectedCustomer != null) ...[
                        const SizedBox(width: 16),
                        SizedBox(
                          width: 380,
                          height: 680,
                          child: Crm360InsightsModal(
                            customer: state.selectedCustomer!,
                            insights: state.insights,
                            khataLedger: state.khataLedger,
                            isLoading: state.isInsightsLoading,
                            onClose: () => notifier.selectCustomer(null),
                            onSettleKhata: () => _openKhataSettleDialog(state.selectedCustomer!),
                            onAdjustLoyalty: () => _openAdjustLoyaltyDialog(state.selectedCustomer!),
                            onEditProfile: () => _openAddEditDialog(state.selectedCustomer!),
                          ),
                        ),
                      ],
                    ],
                  )
                else
                  // Mobile & Tablet Responsive List / Grid
                  Column(
                    children: [
                      if (paged.isEmpty)
                        Container(
                          height: 200,
                          alignment: Alignment.center,
                          child: const Text('No guests match the selected filter'),
                        )
                      else if (isTablet)
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.7,
                          ),
                          itemCount: paged.length,
                          itemBuilder: (ctx, i) => CrmCustomerCard(
                            customer: paged[i],
                            onTap: () => _showMobileInsightsSheet(paged[i]),
                            onSettleKhata: () => _openKhataSettleDialog(paged[i]),
                            onEdit: () => _openAddEditDialog(paged[i]),
                            onDelete: () => _confirmDeleteCustomer(paged[i]),
                          ),
                        )
                      else
                        ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: paged.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, i) => CrmCustomerCard(
                            customer: paged[i],
                            onTap: () => _showMobileInsightsSheet(paged[i]),
                            onSettleKhata: () => _openKhataSettleDialog(paged[i]),
                            onEdit: () => _openAddEditDialog(paged[i]),
                            onDelete: () => _confirmDeleteCustomer(paged[i]),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Pagination
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left_rounded),
                            onPressed: _currentPage > 1 ? () => setState(() => _currentPage--) : null,
                          ),
                          Text(
                            'Page $_currentPage of $totalPages',
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right_rounded),
                            onPressed: _currentPage < totalPages ? () => setState(() => _currentPage++) : null,
                          ),
                        ],
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
