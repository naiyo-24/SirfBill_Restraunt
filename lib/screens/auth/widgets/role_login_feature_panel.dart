import 'package:flutter/material.dart';

class RoleLoginFeaturePanel extends StatelessWidget {
  final String roleName;
  final Color themeColor;

  const RoleLoginFeaturePanel({
    super.key,
    required this.roleName,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Image.asset(
          isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
          height: 80,
          cacheHeight: 250,
        ),
        const SizedBox(height: 24),
        Text(
          'Welcome to',
          style: TextStyle(fontSize: 24, color: subtitleColor),
        ),
        Text(
          '$roleName Module',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.w900,
            color: themeColor,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          _getDescription(),
          style: TextStyle(
            fontSize: 16,
            color: subtitleColor,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),
        ..._buildFeatureItems(context),
      ],
    );
  }

  String _getDescription() {
    if (roleName == 'Restaurant POS' || roleName == 'Billing Counter') {
      return 'Lightning-fast restaurant billing, dine-in tables,\ntakeaway orders and split payment processing.';
    } else if (roleName == 'Kitchen Display') {
      return 'Manage digital KOTs, live kitchen tickets\nand real-time preparation status effortlessly.';
    } else if (roleName == 'Inventory & Purchase') {
      return 'Track ingredients, recipe consumption, suppliers\nand live stock movements accurately.';
    } else if (roleName.contains('Waiter')) {
      return 'Table-side order taking, floor management\nand instant kitchen order ticket (KOT) firing.';
    } else {
      return 'Guest profiles, loyalty rewards, repeat visits\nand real-time sales performance analytics.';
    }
  }

  List<Widget> _buildFeatureItems(BuildContext context) {
    if (roleName == 'Restaurant POS' || roleName == 'Billing Counter') {
      return [
        _buildItem(context, Icons.table_restaurant_rounded, 'Table & Dine-in Management', 'Assign tables and manage guest orders'),
        _buildItem(context, Icons.receipt_long_rounded, 'Fast POS & KOT Printing', 'One-click order punch and thermal receipts'),
        _buildItem(context, Icons.payments_rounded, 'Flexible Payments', 'Cash, UPI, Cards and Split bill settlement'),
      ];
    } else if (roleName == 'Kitchen Display') {
      return [
        _buildItem(context, Icons.soup_kitchen_rounded, 'Live Kitchen Order Tickets', 'Color-coded tickets with preparation timer'),
        _buildItem(context, Icons.checklist_rounded, 'Course & Item Progress', 'Mark items preparing, ready or served'),
        _buildItem(context, Icons.notifications_active_rounded, 'Instant Order Sync', 'Real-time updates between waiter and kitchen'),
      ];
    } else if (roleName == 'Inventory & Purchase') {
      return [
        _buildItem(context, Icons.inventory_2_rounded, 'Ingredient & Recipe BOM', 'Automatic stock deduction per dish prepared'),
        _buildItem(context, Icons.local_shipping_rounded, 'Suppliers & Purchase Bills', 'Track raw materials and vendor balances'),
        _buildItem(context, Icons.warning_amber_rounded, 'Low Stock & Wastage', 'Real-time shortage alerts and wastage logs'),
      ];
    } else if (roleName.contains('Waiter')) {
      return [
        _buildItem(context, Icons.table_restaurant_rounded, 'Floor & Table Status', 'Select live tables with real-time occupancy timers'),
        _buildItem(context, Icons.touch_app_rounded, 'Instant Menu Ordering', 'Quick-tap dishes, modifiers and item instructions'),
        _buildItem(context, Icons.soup_kitchen_rounded, 'Automated KOT & POS Sync', 'Orders route directly to kitchen & cashier counters'),
      ];
    } else {
      return [
        _buildItem(context, Icons.people_alt_rounded, 'Customer & Guest Profiles', 'Order history, favorites and dining notes'),
        _buildItem(context, Icons.loyalty_rounded, 'Loyalty & Rewards', 'Point ledgers, reward points and coupons'),
        _buildItem(context, Icons.insights_rounded, 'Sales & Shift Analytics', 'Daily sales, best-selling dishes and reports'),
      ];
    }
  }

  Widget _buildItem(BuildContext context, IconData icon, String title, String subtitle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: themeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: themeColor, size: 24),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 12, color: subtitleColor),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
