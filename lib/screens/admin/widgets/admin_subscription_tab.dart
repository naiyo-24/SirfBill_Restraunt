import 'package:flutter/material.dart';
import '../models/subscription_plan_models.dart';
import '../services/subscription_api_service.dart';
import 'subscription_branch_selector.dart';
import 'subscription_checkout_dialog.dart';
import 'subscription_plan_card.dart';
import 'subscription_executive_card.dart';
import 'subscription_invoice_history_table.dart';

class AdminSubscriptionTab extends StatefulWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;
  final SubscriptionStatusModel? initialStatus;
  final String? initialOutletId;
  final List<dynamic>? initialBranches;
  final ValueChanged<SubscriptionStatusModel>? onStatusChanged;

  const AdminSubscriptionTab({
    super.key,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
    this.initialStatus,
    this.initialOutletId,
    this.initialBranches,
    this.onStatusChanged,
  });

  @override
  State<AdminSubscriptionTab> createState() => _AdminSubscriptionTabState();
}

class _AdminSubscriptionTabState extends State<AdminSubscriptionTab> {
  bool _isLoading = true;
  SubscriptionStatusModel? _status;
  List<SubscriptionPlanItem> _plans = [];
  List<SubscriptionInvoiceItem> _invoices = [];
  List<Map<String, dynamic>> _branches = [];
  String? _selectedOutletId;
  String? _selectedBranchName;

  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _selectedOutletId = widget.initialOutletId;
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData({String? targetOutletId}) async {
    setState(() => _isLoading = true);
    try {
      final reqOutletId = targetOutletId ?? _selectedOutletId ?? widget.initialOutletId;
      final branches = await SubscriptionApiService.fetchBranchSubscriptions(outletId: reqOutletId);

      List<Map<String, dynamic>> resolvedBranches = List.from(branches);
      if (resolvedBranches.isEmpty && widget.initialBranches != null && widget.initialBranches!.isNotEmpty) {
        for (final b in widget.initialBranches!) {
          if (b is Map<String, dynamic>) {
            resolvedBranches.add(b);
          } else if (b != null) {
            try {
              resolvedBranches.add({
                'outlet_id': (b as dynamic).id?.toString(),
                'outlet_name': (b as dynamic).name?.toString(),
                'outlet_code': (b as dynamic).code?.toString(),
                'is_active': (b as dynamic).isSubscribed ?? false,
                'status': (b as dynamic).subscriptionStatus ?? 'UNPAID',
                'days_remaining': (b as dynamic).subscriptionDaysRemaining ?? 0,
              });
            } catch (_) {}
          }
        }
      }

      if (targetOutletId != null) {
        _selectedOutletId = targetOutletId;
      } else if (_selectedOutletId == null && resolvedBranches.isNotEmpty) {
        _selectedOutletId = resolvedBranches.first['outlet_id']?.toString();
      }

      final activeBranch = resolvedBranches.firstWhere(
        (b) => b['outlet_id']?.toString() == _selectedOutletId,
        orElse: () => resolvedBranches.isNotEmpty ? resolvedBranches.first : <String, dynamic>{},
      );
      _selectedBranchName = activeBranch['outlet_name']?.toString();

      final statusFuture = SubscriptionApiService.fetchSubscriptionStatus(outletId: _selectedOutletId);
      final plansFuture = SubscriptionApiService.fetchPlans();
      final invoicesFuture = SubscriptionApiService.fetchInvoiceHistory(outletId: _selectedOutletId);
      final results = await Future.wait([statusFuture, plansFuture, invoicesFuture]);

      if (mounted) {
        final fetchedPlans = results[1] as List<SubscriptionPlanItem>;
        setState(() {
          _branches = resolvedBranches;
          _status = results[0] as SubscriptionStatusModel;
          _plans = fetchedPlans.isNotEmpty ? List.from(fetchedPlans) : List.from(kMonthlySubscriptionPlans);
          _invoices = results[2] as List<SubscriptionInvoiceItem>;
          _isLoading = false;
        });
        widget.onStatusChanged?.call(_status!);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _status ??= SubscriptionStatusModel.defaultActive();
          _plans = List.from(kMonthlySubscriptionPlans);
          _invoices = [];
          _isLoading = false;
        });
      }
    }
  }

  void _openCheckoutDialog(SubscriptionPlanItem plan) {
    SubscriptionCheckoutDialog.show(
      context,
      plan: plan,
      currentStatus: _status,
      outletId: _selectedOutletId,
      branchName: _selectedBranchName,
      cardBg: widget.cardBg,
      borderColor: widget.borderColor,
      textColor: widget.textColor,
      subtitleColor: widget.subtitleColor,
      isDark: widget.isDark,
      onSuccess: (newStatus) {
        setState(() => _status = newStatus);
        widget.onStatusChanged?.call(newStatus);
        _loadSubscriptionData(targetOutletId: _selectedOutletId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _status == null) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)));
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final status = _status ?? SubscriptionStatusModel.defaultActive();
    final currentPlan = _plans.firstWhere(
      (p) => p.planCode == status.planCode,
      orElse: () => _plans.isNotEmpty ? _plans.first : kMonthlySubscriptionPlans.first,
    );

    return RefreshIndicator(
      onRefresh: _loadSubscriptionData,
      child: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 14 : 22,
          vertical: isMobile ? 14 : 20,
        ),
        children: [
          if (_branches.length > 1)
            SubscriptionBranchSelector(
              branches: _branches,
              selectedOutletId: _selectedOutletId,
              onBranchSelected: (newId) {
                _loadSubscriptionData(targetOutletId: newId);
              },
              cardBg: widget.cardBg,
              borderColor: widget.borderColor,
              textColor: widget.textColor,
              subtitleColor: widget.subtitleColor,
              isDark: widget.isDark,
            ),
          SubscriptionExecutiveCard(
            status: status,
            currentPlan: currentPlan,
            invoices: _invoices,
            isDark: widget.isDark,
            textColor: widget.textColor,
            subtitleColor: widget.subtitleColor,
            borderColor: widget.borderColor,
            onRenew: () => _openCheckoutDialog(currentPlan),
          ),
          const SizedBox(height: 22),
          _buildPlanCatalogHeader(isMobile),
          const SizedBox(height: 14),
          _buildPlanCardsLayout(),
          const SizedBox(height: 24),
          _buildIncludedCapabilitiesSection(isMobile),
          const SizedBox(height: 24),
          SubscriptionInvoiceHistoryTable(
            invoices: _invoices,
            isDark: widget.isDark,
            borderColor: widget.borderColor,
            textColor: widget.textColor,
            subtitleColor: widget.subtitleColor,
            branchName: _selectedBranchName,
          ),
          const SizedBox(height: 20),
          _buildBillingSupportCard(isMobile),
        ],
      ),
    );
  }

  Widget _buildPlanCatalogHeader(bool isMobile) {
    final titleColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Subscription Tier',
          style: TextStyle(fontSize: isMobile ? 15.5 : 16.5, fontWeight: FontWeight.w900, color: widget.textColor, letterSpacing: -0.3),
        ),
        const SizedBox(height: 2),
        Text(
          'Select any tier to activate or renew. All plans include full POS, inventory, recipe costing & live KDS.',
          style: TextStyle(fontSize: isMobile ? 11 : 12, color: widget.subtitleColor),
        ),
      ],
    );

    final taxBadge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shield_outlined, size: 13, color: Color(0xFF10B981)),
          SizedBox(width: 5),
          Text('18% GST Compliant • Official Invoice', style: TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleColumn,
          const SizedBox(height: 8),
          taxBadge,
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [titleColumn, taxBadge],
    );
  }

  Widget _buildCardWidget(SubscriptionPlanItem p, bool isSubActive, int daysLeft) {
    final status = _status;
    final isCurr = (status?.planCode == p.planCode) || (status?.price == p.price && status?.isActive == true);
    return SubscriptionPlanCard(
      plan: p,
      isCurrent: isCurr,
      isSubscribedAndActive: isSubActive,
      daysRemaining: daysLeft,
      isDark: widget.isDark,
      cardBg: widget.cardBg,
      borderColor: widget.borderColor,
      textColor: widget.textColor,
      subtitleColor: widget.subtitleColor,
      onSelectPlan: () => _openCheckoutDialog(p),
    );
  }

  Widget _buildPlanCardsLayout() {
    final status = _status;
    final isSubActive = status != null && status.isActive && status.daysRemaining > 0;
    final daysLeft = status?.daysRemaining ?? 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isDesktop = width >= 980;
        final isTablet = width >= 560 && width < 980;

        if (isDesktop) {
          // Desktop: 4 columns side by side
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: _plans.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: idx < _plans.length - 1 ? 14 : 0),
                  child: _buildCardWidget(p, isSubActive, daysLeft),
                ),
              );
            }).toList(),
          );
        } else if (isTablet) {
          // Tablet: 2 cards per row dynamically chunked
          final rows = <Widget>[];
          for (int i = 0; i < _plans.length; i += 2) {
            final p1 = _plans[i];
            final p2 = (i + 1 < _plans.length) ? _plans[i + 1] : null;
            rows.add(
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: _buildCardWidget(p1, isSubActive, daysLeft)),
                  const SizedBox(width: 14),
                  Expanded(
                    child: p2 != null
                        ? _buildCardWidget(p2, isSubActive, daysLeft)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            );
            if (i + 2 < _plans.length) {
              rows.add(const SizedBox(height: 14));
            }
          }
          return Column(children: rows);
        } else {
          // Mobile (< 560px): 1 card per row, 100% full width
          return Column(
            children: _plans.asMap().entries.map((entry) {
              final idx = entry.key;
              final p = entry.value;
              return Padding(
                padding: EdgeInsets.only(bottom: idx < _plans.length - 1 ? 14 : 0),
                child: _buildCardWidget(p, isSubActive, daysLeft),
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildIncludedCapabilitiesSection(bool isMobile) {
    final modules = [
      (Icons.point_of_sale_rounded, 'Touch POS & KOT Printing', 'Fast multi-station counter billing'),
      (Icons.inventory_2_rounded, 'Recipe BOM & Inventory', 'Automatic stock consumption deductions'),
      (Icons.soup_kitchen_rounded, 'Kitchen Display (KDS)', 'Real-time chef screen & order tracking'),
      (Icons.analytics_rounded, 'Stock Audit & Costing', 'Physical count reconciliation & variance'),
    ];

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 20, vertical: 14),
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.verified_rounded, color: Color(0xFF10B981), size: 16),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Included System Capabilities',
                        style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: widget.textColor),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(4)),
                child: const Text('All Modules Enabled', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, modConstraints) {
              final isNarrow = modConstraints.maxWidth < 600;
              if (isNarrow) {
                return Column(
                  children: modules.map((m) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: Icon(m.$1, size: 15, color: const Color(0xFF10B981)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(m.$2, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: widget.textColor)),
                                Text(m.$3, style: TextStyle(fontSize: 10, color: widget.subtitleColor)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }
              return Wrap(
                spacing: 16,
                runSpacing: 10,
                children: modules.map((m) {
                  return Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                        child: Icon(m.$1, size: 15, color: const Color(0xFF10B981)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(m.$2, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5, color: widget.textColor)),
                          Text(m.$3, style: TextStyle(fontSize: 10, color: widget.subtitleColor)),
                        ],
                      ),
                    ],
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBillingSupportCard(bool isMobile) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 14 : 18, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.headset_mic_rounded, color: Color(0xFF10B981), size: 18),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Need Custom Enterprise Billing or Multi-Outlet Setup?',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            icon: const Icon(Icons.mail_outline_rounded, size: 14),
            label: const Text('Contact Desk', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }
}
