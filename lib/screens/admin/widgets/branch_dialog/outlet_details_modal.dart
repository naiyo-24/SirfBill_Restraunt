import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/shop_service.dart';
import '../../../../services/admin_staff_service.dart';
import 'outlet_edit_credential_dialog.dart';
import 'outlet_modal_header.dart';
import 'outlet_profile_tab.dart';
import 'outlet_station_card.dart';

class OutletDetailsModal extends StatefulWidget {
  final Shop outlet;
  final VoidCallback onCredentialsUpdated;

  const OutletDetailsModal({
    super.key,
    required this.outlet,
    required this.onCredentialsUpdated,
  });

  static void show(BuildContext context, Shop outlet, {required VoidCallback onUpdated}) {
    showDialog(
      context: context,
      builder: (ctx) => OutletDetailsModal(
        outlet: outlet,
        onCredentialsUpdated: onUpdated,
      ),
    );
  }

  @override
  State<OutletDetailsModal> createState() => _OutletDetailsModalState();
}

class _OutletDetailsModalState extends State<OutletDetailsModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<RestaurantStaffUser> _outletUsers = [];
  Map<String, String> _customPasswords = {};
  Map<String, String> _customUsernames = {};
  bool _isSavingCredentials = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadOutletCredentials();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _cleanCode(String code) {
    return code.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '').toLowerCase();
  }

  Future<void> _loadOutletCredentials() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final outletPrefix = 'outlet_cred_${widget.outlet.id}_';

      final keys = ['pos', 'kitchen', 'inventory', 'crm', 'waiter'];
      final savedPasswords = <String, String>{};
      final savedUsernames = <String, String>{};
      for (final k in keys) {
        final p = prefs.getString('$outletPrefix${k}_pass');
        if (p != null && p.isNotEmpty) savedPasswords[k] = p;
        final u = prefs.getString('$outletPrefix${k}_user');
        if (u != null && u.isNotEmpty) savedUsernames[k] = u;
      }

      final allStaff = await AdminStaffService.getStaffUsers();
      final branchCode = _cleanCode(widget.outlet.code);
      final outletName = widget.outlet.name.trim().toLowerCase();
      final outletId = widget.outlet.id.trim().toLowerCase();

      final matched = allStaff.where((u) {
        final un = u.username.toLowerCase();
        final uBranch = (u.branchId ?? '').toLowerCase();
        final uBranchName = (u.branchName ?? '').toLowerCase();
        return (outletId.isNotEmpty && uBranch == outletId) ||
            (outletName.isNotEmpty && uBranchName == outletName) ||
            (branchCode.isNotEmpty && un.contains(branchCode));
      }).toList();

      for (final u in matched) {
        final un = u.username.toLowerCase();
        if ((un.contains('pos') || un.contains('cashier')) && !savedUsernames.containsKey('pos')) {
          savedUsernames['pos'] = u.username;
        } else if ((un.contains('kds') || un.contains('kitchen') || un.contains('chef')) && !savedUsernames.containsKey('kitchen')) {
          savedUsernames['kitchen'] = u.username;
        } else if ((un.contains('inv') || un.contains('stock') || un.contains('inventory')) && !savedUsernames.containsKey('inventory')) {
          savedUsernames['inventory'] = u.username;
        } else if ((un.contains('crm') || un.contains('report')) && !savedUsernames.containsKey('crm')) {
          savedUsernames['crm'] = u.username;
        } else if ((un.contains('waiter') || un.contains('captain')) && !savedUsernames.containsKey('waiter')) {
          savedUsernames['waiter'] = u.username;
        }
      }

      _customPasswords = savedPasswords;
      _customUsernames = savedUsernames;
      _outletUsers = matched;
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditCredentialSheet(String moduleTitle, String moduleKey, String defaultUsername, String defaultPassword, String role) {
    OutletEditCredentialDialog.show(
      context,
      moduleTitle: moduleTitle,
      initialUsername: _customUsernames[moduleKey] ?? defaultUsername,
      initialPassword: _customPasswords[moduleKey] ?? defaultPassword,
      onSave: (newUsername, newPassword) async {
        setState(() => _isSavingCredentials = true);
        try {
          final prefs = await SharedPreferences.getInstance();
          final outletPrefix = 'outlet_cred_${widget.outlet.id}_';
          if (moduleKey.isNotEmpty) {
            await prefs.setString('$outletPrefix${moduleKey}_pass', newPassword);
            await prefs.setString('$outletPrefix${moduleKey}_user', newUsername);
            _customPasswords[moduleKey] = newPassword;
            _customUsernames[moduleKey] = newUsername;
          }

          await AdminStaffService.createStaffUser(
            username: newUsername,
            password: newPassword,
            name: '${widget.outlet.name} $moduleTitle',
            role: role,
            branchId: widget.outlet.id,
          );

          await _loadOutletCredentials();
          widget.onCredentialsUpdated();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('$moduleTitle login credentials updated successfully!'),
                backgroundColor: const Color(0xFF10B981),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update credentials: $e'),
                backgroundColor: const Color(0xFFEF4444),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } finally {
          if (mounted) setState(() => _isSavingCredentials = false);
        }
      },
    );
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard!'),
        backgroundColor: const Color(0xFF6366F1),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F172A) : Colors.white;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final cleanCode = _cleanCode(widget.outlet.code);

    final modules = [
      {
        'key': 'pos',
        'title': 'Restaurant POS',
        'subtitle': 'Billing Counter, KOTs, Dine-in & Payments',
        'icon': Icons.restaurant_menu_rounded,
        'color': const Color(0xFF10B981),
        'userId': _customUsernames['pos'] ?? '${cleanCode}_pos',
        'pass': _customPasswords['pos'] ?? '${cleanCode}_pos@123',
        'role': 'cashier',
      },
      {
        'key': 'kitchen',
        'title': 'Kitchen Display',
        'subtitle': 'Live Chef Station & Order Routing',
        'icon': Icons.soup_kitchen_rounded,
        'color': const Color(0xFFF97316),
        'userId': _customUsernames['kitchen'] ?? '${cleanCode}_kds',
        'pass': _customPasswords['kitchen'] ?? '${cleanCode}_kds@123',
        'role': 'kitchen',
      },
      {
        'key': 'inventory',
        'title': 'Inventory & Purchase',
        'subtitle': 'Branch Stock, Recipes, Ingredients & POs',
        'icon': Icons.inventory_2_rounded,
        'color': const Color(0xFF3B82F6),
        'userId': _customUsernames['inventory'] ?? '${cleanCode}_inv',
        'pass': _customPasswords['inventory'] ?? '${cleanCode}_inv@123',
        'role': 'manager',
      },
      {
        'key': 'crm',
        'title': 'CRM & Reports',
        'subtitle': 'Customer Loyalty, Daily Revenue & Branch Audits',
        'icon': Icons.groups_rounded,
        'color': const Color(0xFF8B5CF6),
        'userId': _customUsernames['crm'] ?? '${cleanCode}_crm',
        'pass': _customPasswords['crm'] ?? '${cleanCode}_crm@123',
        'role': 'manager',
      },
      {
        'key': 'waiter',
        'title': 'Waiter / Captain',
        'subtitle': 'Table Order Taking & Automated KOT Dispatch',
        'icon': Icons.room_service_rounded,
        'color': const Color(0xFFF59E0B),
        'userId': _customUsernames['waiter'] ?? '${cleanCode}_waiter',
        'pass': _customPasswords['waiter'] ?? '${cleanCode}_waiter@123',
        'role': 'waiter',
      },
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;

    return Dialog(
      backgroundColor: bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 18,
        vertical: isMobile ? 16 : 24,
      ),
      child: Container(
        width: isMobile ? double.infinity : 780,
        height: isMobile ? MediaQuery.of(context).size.height * 0.88 : 640,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            // Modal Header
            OutletModalHeader(
              outlet: widget.outlet,
              isMobile: isMobile,
              borderColor: borderColor,
              textColor: textColor,
              subtitleColor: subtitleColor,
            ),

            // Tab Bar
            Container(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
              child: TabBar(
                controller: _tabController,
                isScrollable: isMobile,
                tabAlignment: isMobile ? TabAlignment.start : TabAlignment.fill,
                labelColor: const Color(0xFF6366F1),
                unselectedLabelColor: subtitleColor,
                indicatorColor: const Color(0xFF6366F1),
                indicatorWeight: 3,
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.key_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Station Logins & Passwords', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.tune_rounded, size: 16),
                        SizedBox(width: 6),
                        Text('Branch Profile & Settings', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  // TAB 1: MODULE PASSWORDS & LOGINS
                  (_isLoading || _isSavingCredentials)
                      ? const Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)))
                      : ListView.separated(
                          padding: const EdgeInsets.all(20),
                          itemCount: modules.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, idx) {
                            final m = modules[idx];
                            final color = m['color'] as Color;
                            final defaultId = m['userId'] as String;
                            final role = m['role'] as String;
                            final moduleKey = m['key'] as String;

                            final matchingStaff = _outletUsers.firstWhere(
                              (u) {
                                final un = u.username.toLowerCase();
                                if (moduleKey == 'pos') {
                                  return un.contains('pos') || un.contains('cashier');
                                } else if (moduleKey == 'kitchen') {
                                  return un.contains('kds') || un.contains('kitchen') || un.contains('chef');
                                } else if (moduleKey == 'inventory') {
                                  return un.contains('inv') || un.contains('stock') || un.contains('inventory');
                                } else if (moduleKey == 'crm') {
                                  return un.contains('crm') || un.contains('report') || un.contains('loyalty');
                                } else if (moduleKey == 'waiter') {
                                  return un.contains('waiter') || un.contains('captain');
                                }
                                return false;
                              },
                              orElse: () => RestaurantStaffUser(
                                id: '',
                                username: defaultId,
                                name: '',
                                role: role,
                              ),
                            );

                            final activeUser = (matchingStaff.username.isNotEmpty && matchingStaff.id.isNotEmpty)
                                ? matchingStaff.username
                                : defaultId;
                            final activePass = (matchingStaff.password != null && matchingStaff.password!.isNotEmpty)
                                ? matchingStaff.password!
                                : (m['pass'] as String);

                            return OutletStationCard(
                              title: m['title'] as String,
                              subtitle: m['subtitle'] as String,
                              icon: m['icon'] as IconData,
                              color: color,
                              activeUser: activeUser,
                              activePass: activePass,
                              cardBg: cardBg,
                              borderColor: borderColor,
                              textColor: textColor,
                              subtitleColor: subtitleColor,
                              isDark: isDark,
                              isMobile: isMobile,
                              onCopy: _copyToClipboard,
                              onEdit: () => _openEditCredentialSheet(
                                m['title'] as String,
                                moduleKey,
                                activeUser,
                                activePass,
                                role,
                              ),
                            );
                          },
                        ),

                  // TAB 2: BRANCH PROFILE OVERVIEW
                  OutletProfileTab(
                    outlet: widget.outlet,
                    textColor: textColor,
                    subtitleColor: subtitleColor,
                    borderColor: borderColor,
                    cardBg: cardBg,
                    onRenewSuccess: widget.onCredentialsUpdated,
                  ),
                ],
              ),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 22,
                vertical: isMobile ? 10 : 14,
              ),
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Staff can use these credentials to log in to POS, Kitchen, and Inventory.',
                      style: TextStyle(fontSize: 11.5, color: subtitleColor),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF6366F1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Done'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
