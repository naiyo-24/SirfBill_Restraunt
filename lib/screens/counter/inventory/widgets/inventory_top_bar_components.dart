import 'package:flutter/material.dart';
import '../../../../services/shop_service.dart';
import '../../widgets/about/about_us_dialog.dart';

class InventoryBranchSelector extends StatelessWidget {
  final List<Shop> shops;
  final String? currentShopId;
  final String branchName;
  final ValueChanged<Shop>? onSelectShop;

  const InventoryBranchSelector({
    super.key,
    required this.shops,
    required this.currentShopId,
    required this.branchName,
    required this.onSelectShop,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final pill = Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Icon(Icons.storefront_rounded, size: 16, color: Color(0xFF3B82F6)),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 160),
            child: Text(
              branchName.isNotEmpty ? branchName : 'Main Outlet',
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          if (shops.length > 1) ...[
            const SizedBox(width: 4),
            const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
          ],
        ],
      ),
    );

    if (shops.length <= 1 || onSelectShop == null) return pill;

    return PopupMenuButton<Shop>(
      tooltip: 'Switch Branch Outlet',
      onSelected: onSelectShop,
      itemBuilder: (ctx) => shops.map((s) {
        final isCurrent = s.id == currentShopId;
        return PopupMenuItem<Shop>(
          value: s,
          child: Row(
            children: [
              Icon(
                Icons.storefront_rounded,
                size: 18,
                color: isCurrent ? const Color(0xFF10B981) : const Color(0xFF64748B),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  s.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent ? const Color(0xFF10B981) : null,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: pill,
    );
  }
}

class InventoryDateCalendarPill extends StatelessWidget {
  final DateTime currentTime;

  const InventoryDateCalendarPill({super.key, required this.currentTime});

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    int hour = date.hour;
    final period = hour >= 12 ? 'PM' : 'AM';
    hour = hour % 12;
    if (hour == 0) hour = 12;
    return '$hour:${date.minute.toString().padLeft(2, '0')}:${date.second.toString().padLeft(2, '0')} $period';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () => showDatePicker(
        context: context,
        initialDate: currentTime,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F8F5),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: const Color(0xFF22C55E).withValues(alpha: 0.35),
            width: 1.2,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.calendar_today_rounded, color: Color(0xFF166534), size: 15),
            const SizedBox(width: 8),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _formatDate(currentTime),
                  style: const TextStyle(
                    color: Color(0xFF166534),
                    fontSize: 11.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  _formatTime(currentTime),
                  style: TextStyle(
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF1E293B),
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class InventoryProfilePill extends StatelessWidget {
  final String userName;
  final String userRole;
  final bool isDesktop;
  final VoidCallback onLogout;

  const InventoryProfilePill({
    super.key,
    required this.userName,
    required this.userRole,
    required this.isDesktop,
    required this.onLogout,
  });

  String _getDisplayName(String name) {
    final clean = name.trim();
    if (clean.isEmpty) return 'Manager';
    final lower = clean.toLowerCase();
    if (lower.contains('inventory') || lower.contains('purchase')) {
      return 'Inventory Manager';
    } else if (lower.contains('cashier')) {
      return 'POS Cashier';
    } else if (lower.contains('waiter') || lower.contains('captain')) {
      return 'Captain';
    } else if (lower.contains('kitchen')) {
      return 'Kitchen Chef';
    } else if (lower.contains('crm') || lower.contains('report')) {
      return 'Store Manager';
    }
    if (clean.length > 25) {
      return userRole.isNotEmpty ? userRole : 'Manager';
    }
    return clean;
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.trim().isNotEmpty) {
      return name.trim().substring(0, name.trim().length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'SP';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final displayName = _getDisplayName(userName);

    return PopupMenuButton<String>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (val) {
        if (val == 'about') AboutUsDialog.show(context);
        if (val == 'logout') onLogout();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'about',
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF166534)),
              SizedBox(width: 8),
              Text('About SirfBill', style: TextStyle(fontSize: 13)),
            ],
          ),
        ),
        const PopupMenuDivider(height: 1),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 18, color: Colors.red),
              SizedBox(width: 8),
              Text('Logout', style: TextStyle(fontSize: 13, color: Colors.red)),
            ],
          ),
        ),
      ],
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 32,
              height: 32,
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
                  _getInitials(displayName),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
            if (isDesktop) ...[
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 120),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    Text(
                      userRole.isNotEmpty ? userRole : 'MANAGER',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 9.5, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.keyboard_arrow_down_rounded, size: 16, color: Color(0xFF94A3B8)),
            ],
          ],
        ),
      ),
    );
  }
}
