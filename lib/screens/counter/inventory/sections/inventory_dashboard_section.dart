import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
// ignore: unnecessary_import
import '../models/inventory_ops_models.dart';
import '../services/inventory_api_service.dart';
import '../widgets/dashboard_alert_cards.dart';
import '../widgets/inventory_header.dart';
import '../widgets/inventory_kpi_card.dart';

class InventoryDashboardSection extends StatefulWidget {
  final ValueChanged<InventorySection>? onNavigateSection;

  const InventoryDashboardSection({super.key, this.onNavigateSection});

  @override
  State<InventoryDashboardSection> createState() => _InventoryDashboardSectionState();
}

class _InventoryDashboardSectionState extends State<InventoryDashboardSection> {
  bool _isLoading = true;
  List<Ingredient> _ingredients = [];
  List<IngredientCategory> _categories = [];
  List<PurchaseOrder> _purchaseOrders = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        InventoryApiService.getIngredients(),
        InventoryApiService.getCategories(),
        InventoryApiService.getPurchaseOrders(),
      ]);

      if (mounted) {
        setState(() {
          _ingredients = results[0] as List<Ingredient>;
          _categories = results[1] as List<IngredientCategory>;
          _purchaseOrders = results[2] as List<PurchaseOrder>;
        });
      }
    } catch (_) {
      // Graceful fallback
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStockItems =
        _ingredients.where((i) => i.isLowStock || i.isOutOfStock).toList();
    final pendingPOs = _purchaseOrders
        .where((po) => po.status == POStatus.sent || po.status == POStatus.partiallyReceived)
        .toList();

    return Column(
      children: [
        InventoryHeader(
          title: 'Stock Overview & Alerts',
          subtitle: 'Live kitchen commodities balance, procurement pipeline & food costs',
          trailing: ElevatedButton.icon(
            onPressed: () => widget.onNavigateSection?.call(InventorySection.purchaseOrders),
            icon: const Icon(Icons.add_shopping_cart, size: 16),
            label: const Text('New Purchase Order'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    _buildKpiGrid(context, lowStockItems.length),
                    const SizedBox(height: 24),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 6,
                          child: DashboardLowStockCard(
                            items: lowStockItems,
                            onViewAll: () => widget.onNavigateSection?.call(InventorySection.ingredients),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          flex: 5,
                          child: DashboardPendingOrdersCard(
                            orders: pendingPOs,
                            onManage: () => widget.onNavigateSection?.call(InventorySection.purchaseOrders),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    const DashboardRecentActivityCard(),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildKpiGrid(BuildContext context, int lowStockCount) {
    double totalValue = 0.0;
    for (final ing in _ingredients) {
      totalValue += (ing.currentStock * ing.costPerPurchaseUnit);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 900 ? 4 : 2;
        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.1,
          children: [
            InventoryKpiCard(
              title: 'Total Stock Value',
              value: '₹${totalValue.toStringAsFixed(0)}',
              subtitle: '${_ingredients.length} raw ingredients',
              icon: Icons.account_balance_wallet_outlined,
              accentColor: const Color(0xFF10B981),
              trendText: 'Live balance',
              isPositiveTrend: true,
              onTap: () => widget.onNavigateSection?.call(InventorySection.reports),
            ),
            InventoryKpiCard(
              title: 'Low Stock Alerts',
              value: '$lowStockCount Items',
              subtitle: 'Below safety par level',
              icon: Icons.warning_amber_rounded,
              accentColor: lowStockCount > 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
              trendText: lowStockCount > 0 ? 'Needs restock' : 'Healthy',
              isPositiveTrend: lowStockCount == 0,
              onTap: () => widget.onNavigateSection?.call(InventorySection.ingredients),
            ),
            InventoryKpiCard(
              title: 'Storage Zones',
              value: '${_categories.length} Categories',
              subtitle: 'Active pantry & chillers',
              icon: Icons.kitchen_rounded,
              accentColor: const Color(0xFF3B82F6),
              trendText: 'Isolated',
              isPositiveTrend: true,
              onTap: () => widget.onNavigateSection?.call(InventorySection.categories),
            ),
            InventoryKpiCard(
              title: 'Purchase Orders',
              value: '${_purchaseOrders.length} Invoices',
              subtitle: 'Direct vendor purchases',
              icon: Icons.receipt_long_rounded,
              accentColor: const Color(0xFF8B5CF6),
              trendText: 'Sync',
              isPositiveTrend: true,
              onTap: () => widget.onNavigateSection?.call(InventorySection.purchaseOrders),
            ),
          ],
        );
      },
    );
  }
}
