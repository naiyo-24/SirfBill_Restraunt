import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import '../../../../services/shop_service.dart';

/// 1. Outlet / Branch selector pill with popup menu.
class PosBranchSelector extends StatelessWidget {
  final List<Shop> shops;
  final String? currentShopId;
  final String branchName;
  final ValueChanged<Shop> onSelectShop;
  final bool isMobile;

  const PosBranchSelector({
    super.key,
    required this.shops,
    required this.currentShopId,
    required this.branchName,
    required this.onSelectShop,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final content = Container(
      height: isMobile ? 38 : 54,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
        border: Border.all(color: borderColor, width: isMobile ? 1.2 : 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 4 : 7),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(isMobile ? 6 : 10),
            ),
            child: Icon(Icons.storefront_rounded, size: isMobile ? 16 : 19, color: const Color(0xFF3B82F6)),
          ),
          SizedBox(width: isMobile ? 5 : 10),
          Flexible(
            child: Text(
              branchName,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: isMobile ? 12 : 14.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          if (shops.length > 1) ...[
            const SizedBox(width: 3),
            Icon(Icons.keyboard_arrow_down_rounded, size: isMobile ? 15 : 20, color: const Color(0xFF94A3B8)),
          ],
        ],
      ),
    );

    if (shops.length <= 1) return content;

    return PopupMenuButton<Shop>(
      tooltip: 'Select Outlet / Branch',
      onSelected: onSelectShop,
      itemBuilder: (ctx) => shops.map((shop) {
        final isCurrent = shop.id == currentShopId;
        return PopupMenuItem<Shop>(
          value: shop,
          child: Row(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 22,
                color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  shop.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? const Color(0xFF10B981) : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (isCurrent)
                const Icon(Icons.check, size: 20, color: Color(0xFF10B981)),
            ],
          ),
        );
      }).toList(),
      child: content,
    );
  }
}

/// 2. Touch Screen Search Bar with large touch target.
class PosSearchBox extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final bool isMobile;

  const PosSearchBox({
    super.key,
    required this.onChanged,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      width: isMobile ? double.infinity : 340,
      height: isMobile ? 42 : 54,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            width: isMobile ? 1.2 : 1.4,
          ),
        ),
        child: Row(
          children: [
            Icon(Icons.search_rounded, size: isMobile ? 19 : 22, color: const Color(0xFF94A3B8)),
            SizedBox(width: isMobile ? 8 : 12),
            Expanded(
              child: TextField(
                onChanged: onChanged,
                style: TextStyle(fontSize: isMobile ? 13 : 14.5, fontWeight: FontWeight.w500),
                decoration: InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: isMobile ? 'Search food name or code (e.g. PBM)...' : 'Search food name or code (e.g. PBM)...',
                  hintStyle: TextStyle(color: const Color(0xFF94A3B8), fontSize: isMobile ? 12.5 : 14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 3. Segmented Order Mode Selector (Dine-in, Takeaway, Delivery).
class PosOrderTypeSelector extends StatelessWidget {
  final OrderType selectedType;
  final ValueChanged<OrderType> onSelectType;
  final bool isMobile;

  const PosOrderTypeSelector({
    super.key,
    required this.selectedType,
    required this.onSelectType,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: isMobile ? 38 : 54,
      padding: EdgeInsets.all(isMobile ? 3 : 5),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          PosOrderTypePill(
            label: isMobile ? 'Dine-In' : 'Dine-in',
            icon: Icons.table_restaurant_rounded,
            isSelected: selectedType == OrderType.dineIn,
            onTap: () => onSelectType(OrderType.dineIn),
            activeColor: const Color(0xFF3B82F6),
            isMobile: isMobile,
          ),
          SizedBox(width: isMobile ? 3 : 5),
          PosOrderTypePill(
            label: 'Takeaway',
            icon: Icons.shopping_bag_rounded,
            isSelected: selectedType == OrderType.takeaway,
            onTap: () => onSelectType(OrderType.takeaway),
            activeColor: const Color(0xFF10B981),
            isMobile: isMobile,
          ),
          SizedBox(width: isMobile ? 3 : 5),
          PosOrderTypePill(
            label: 'Delivery',
            icon: Icons.moped_rounded,
            isSelected: selectedType == OrderType.delivery,
            onTap: () => onSelectType(OrderType.delivery),
            activeColor: const Color(0xFFF59E0B),
            isMobile: isMobile,
          ),
        ],
      ),
    );
  }
}

/// 4. Individual order type pill.
class PosOrderTypePill extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final Color activeColor;
  final bool isMobile;

  const PosOrderTypePill({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    required this.activeColor,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 6 : 18,
          vertical: isMobile ? 4 : 10,
        ),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: activeColor.withValues(alpha: 0.38),
                    blurRadius: isMobile ? 6 : 10,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: isMobile ? 13 : 19,
              color: isSelected ? Colors.white : const Color(0xFF64748B),
            ),
            SizedBox(width: isMobile ? 3 : 7),
            Text(
              label,
              style: TextStyle(
                fontSize: isMobile ? 11 : 14.5,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 5. Admin Panel shortcut pill for administrators.
class PosAdminButton extends StatelessWidget {
  final VoidCallback onTap;

  const PosAdminButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Tooltip(
      message: 'Open Admin Panel',
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withValues(alpha: isDark ? 0.2 : 0.1),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFF6366F1).withValues(alpha: 0.4), width: 1.4),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.admin_panel_settings_rounded, size: 20, color: Color(0xFF6366F1)),
              SizedBox(width: 8),
              Text(
                'Admin Panel',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6366F1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 6. Cashier Profile badge with circular avatar and role label.
class PosCashierProfilePill extends StatelessWidget {
  final String cashierName;
  final String initials;
  final bool isAdmin;
  final bool isMobile;

  const PosCashierProfilePill({
    super.key,
    required this.cashierName,
    required this.initials,
    required this.isAdmin,
    this.isMobile = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      height: 54,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 13.5,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          if (!isMobile) ...[
            const SizedBox(width: 10),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    cashierName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    isAdmin ? 'Super Admin' : 'Counter POS',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF94A3B8),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

