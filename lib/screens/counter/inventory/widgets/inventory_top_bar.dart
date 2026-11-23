import 'package:flutter/material.dart';
import '../../../../services/shop_service.dart';
import '../../../home/widgets/hardware_store_dialog.dart';
import '../models/inventory_models.dart';
import 'inventory_notification_bell.dart';
import 'inventory_top_bar_components.dart';

class InventoryTopBar extends StatelessWidget {
  final bool isDesktop;
  final DateTime currentTime;
  final String userName;
  final String userRole;
  final String branchName;
  final List<Shop> shops;
  final String? currentShopId;
  final ValueChanged<Shop>? onSelectShop;
  final InventorySection selectedSection;
  final ValueChanged<InventorySection> onSelectSection;
  final VoidCallback onMenuPressed;
  final VoidCallback onLogout;
  final VoidCallback? onRefresh;
  final VoidCallback? onBackToDashboard;
  final int lowStockCount;
  final VoidCallback? onOpenNotifications;

  const InventoryTopBar({
    super.key,
    required this.isDesktop,
    required this.currentTime,
    required this.userName,
    required this.userRole,
    this.branchName = 'Main Outlet',
    this.shops = const [],
    this.currentShopId,
    this.onSelectShop,
    required this.selectedSection,
    required this.onSelectSection,
    required this.onMenuPressed,
    required this.onLogout,
    this.onRefresh,
    this.onBackToDashboard,
    this.lowStockCount = 0,
    this.onOpenNotifications,
  });

  Widget _buildShortcutChip({
    required BuildContext context,
    required String keyLabel,
    required String title,
    required InventorySection section,
    required bool isDark,
  }) {
    final isSelected = selectedSection == section;
    final activeBg = const Color(0xFF10B981).withValues(alpha: 0.15);
    final activeBorder = const Color(0xFF10B981).withValues(alpha: 0.5);

    return InkWell(
      onTap: () => onSelectSection(section),
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: isSelected ? activeBg : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          border: isSelected ? Border.all(color: activeBorder, width: 0.8) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                keyLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? Colors.white : const Color(0xFF1E293B)),
                ),
              ),
            ),
            const SizedBox(width: 5),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final screenWidth = MediaQuery.of(context).size.width;
    final showMiddlePills = isDesktop && screenWidth >= 1260;

    return Container(
      height: isDesktop ? 70 : 64,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 16 : 8,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: headerBg,
        border: Border(
          bottom: BorderSide(color: borderColor, width: 1.2),
        ),
      ),
      child: Row(
        children: [
          // 3-Bar Hamburger Menu Toggle
          Tooltip(
            message: 'Toggle Sidebar Menu',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: onMenuPressed,
              child: Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor, width: 1.2),
                ),
                child: Center(
                  child: Icon(
                    Icons.menu_rounded,
                    size: 20,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),
          ),

          // Logo / Branding
          Flexible(
            child: Image.asset(
              isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
              height: isDesktop ? 46 : 30,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.inventory_2_rounded, color: Color(0xFF10B981), size: 24),
                  SizedBox(width: 6),
                  Text('SirfBill', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ],
              ),
            ),
          ),

          const SizedBox(width: 14),

          // Outlet / Branch Selector Dropdown Pill
          if (isDesktop)
            InventoryBranchSelector(
              shops: shops,
              currentShopId: currentShopId,
              branchName: branchName,
              onSelectShop: onSelectShop,
            ),

          if (onRefresh != null && isDesktop) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Refresh Inventory Data',
              child: InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: onRefresh,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor, width: 1.2),
                  ),
                  child: const Center(
                    child: Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF10B981)),
                  ),
                ),
              ),
            ),
          ],

          const Spacer(),

          // Middle F1-F8 Quick Shortcuts
          if (showMiddlePills) ...[
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.keyboard, size: 15, color: Color(0xFF10B981)),
                      const SizedBox(width: 6),
                      _buildShortcutChip(
                        context: context,
                        keyLabel: 'F1',
                        title: 'Dashboard',
                        section: InventorySection.dashboard,
                        isDark: isDark,
                      ),
                      _buildShortcutChip(
                        context: context,
                        keyLabel: 'F2',
                        title: 'Ingredients',
                        section: InventorySection.ingredients,
                        isDark: isDark,
                      ),
                      _buildShortcutChip(
                        context: context,
                        keyLabel: 'F3',
                        title: 'Recipe (BOM)',
                        section: InventorySection.recipeManagement,
                        isDark: isDark,
                      ),
                      _buildShortcutChip(
                        context: context,
                        keyLabel: 'F4',
                        title: 'Orders',
                        section: InventorySection.purchaseOrders,
                        isDark: isDark,
                      ),
                      _buildShortcutChip(
                        context: context,
                        keyLabel: 'F5',
                        title: 'Stock',
                        section: InventorySection.stockManagement,
                        isDark: isDark,
                      ),
                      _buildShortcutChip(
                        context: context,
                        keyLabel: 'F6',
                        title: 'GRN',
                        section: InventorySection.goodsReceived,
                        isDark: isDark,
                      ),
                      _buildShortcutChip(
                        context: context,
                        keyLabel: 'F7',
                        title: 'Wastage',
                        section: InventorySection.wastage,
                        isDark: isDark,
                      ),
                      _buildShortcutChip(
                        context: context,
                        keyLabel: 'F8',
                        title: 'Reports',
                        section: InventorySection.reports,
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],

          // Right side Bell + Calendar + Profile Pills
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (onOpenNotifications != null) ...[
                InventoryNotificationBell(
                  count: lowStockCount,
                  onTap: onOpenNotifications!,
                  isDark: isDark,
                ),
                SizedBox(width: isDesktop ? 8 : 6),
              ],
              InventoryDateCalendarPill(
                currentTime: currentTime,
                isDesktop: isDesktop,
              ),
              SizedBox(width: isDesktop ? 8 : 6),
              // Buy Hardware Pill
              Tooltip(
                message: 'Buy Certified POS Thermal Printers, Cash Drawers & KOT Displays',
                child: InkWell(
                  onTap: () => HardwareStoreDialog.show(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 38,
                    padding: EdgeInsets.symmetric(
                      horizontal: isDesktop ? 12 : 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF10B981),
                        width: 1.2,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF059669),
                          size: 17,
                        ),
                        if (isDesktop) ...[
                          const SizedBox(width: 6),
                          const Text(
                            'Buy Hardware',
                            style: TextStyle(
                              color: Color(0xFF065F46),
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(width: isDesktop ? 8 : 6),
              InventoryProfilePill(
                userName: userName,
                userRole: userRole,
                isDesktop: isDesktop,
                onLogout: onLogout,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
