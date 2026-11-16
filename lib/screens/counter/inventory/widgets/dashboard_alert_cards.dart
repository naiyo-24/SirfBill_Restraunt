import 'package:flutter/material.dart';
import '../models/inventory_models.dart';
import 'inventory_status_badge.dart';

class DashboardLowStockCard extends StatelessWidget {
  final List<Ingredient> items;
  final VoidCallback onViewAll;

  const DashboardLowStockCard({
    super.key,
    required this.items,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.warning_amber_rounded,
                      size: 18,
                      color: Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Critical Par Re-orders',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onViewAll,
                child: const Text('View All', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...items.map((item) {
            final percent = (item.currentStock / item.minParLevel).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                      InventoryStatusBadge.stockLevel(
                        currentStock: item.currentStock,
                        minPar: item.minParLevel,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 6,
                            backgroundColor:
                                isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(item.currentStock / 1000).toStringAsFixed(1)} / ${(item.minParLevel / 1000).toStringAsFixed(1)} kg',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DashboardPendingOrdersCard extends StatelessWidget {
  final List<PurchaseOrder> orders;
  final VoidCallback onManage;

  const DashboardPendingOrdersCard({
    super.key,
    required this.orders,
    required this.onManage,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.local_shipping_outlined,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Active Deliveries (POs)',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: onManage,
                child: const Text('Manage', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...orders.map((po) {
            return Container(
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          po.poNumber,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF10B981),
                          ),
                        ),
                        Text(
                          po.supplierName,
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${po.totalAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      InventoryStatusBadge.custom(
                        label: po.status.label,
                        color: po.status.color,
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class DashboardRecentActivityCard extends StatelessWidget {
  const DashboardRecentActivityCard({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(18),
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
          Text(
            'Live Inventory Activity',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 12),
          _buildItem(
            icon: Icons.point_of_sale_rounded,
            color: Colors.blue,
            title: 'Auto-depleted ingredients for POS Order #ORD-1092 (Butter Chicken x 2)',
            subtitle: '24 mins ago • Stock Consumption Engine',
            isDark: isDark,
          ),
          _buildItem(
            icon: Icons.fact_check_rounded,
            color: const Color(0xFF10B981),
            title: 'GRN-2026-089 approved by Chef Vikram (10 Bags Basmati Rice accepted)',
            subtitle: '3 days ago • Goods Received Note',
            isDark: isDark,
          ),
          _buildItem(
            icon: Icons.delete_outline,
            color: Colors.redAccent,
            title: 'Wastage recorded: 1,200g Chicken Breast (Freezer burn)',
            subtitle: '1 day ago • Reported by Junior Sous Chef',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
