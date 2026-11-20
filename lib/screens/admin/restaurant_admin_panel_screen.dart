import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/responsive.dart';
import '../../services/auth_service.dart';
import '../../services/app_session_manager.dart';
import '../../services/shop_service.dart';
import '../../services/inventory_service.dart';
import '../../services/admin_staff_service.dart';
import '../../providers/theme_provider.dart';
import 'models/subscription_plan_models.dart';
import 'services/subscription_api_service.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_top_header.dart';
import 'widgets/admin_dashboard_tab.dart';
import 'widgets/admin_outlets_tab.dart';
import 'widgets/admin_users_tab.dart';
import 'widgets/admin_subscription_tab.dart';
import 'widgets/admin_dialogs.dart';

class RestaurantAdminPanelScreen extends ConsumerStatefulWidget {
  const RestaurantAdminPanelScreen({super.key});

  @override
  ConsumerState<RestaurantAdminPanelScreen> createState() => _RestaurantAdminPanelScreenState();
}

class _RestaurantAdminPanelScreenState extends ConsumerState<RestaurantAdminPanelScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;
  bool _isSidebarExpanded = true;
  DateTime _currentTime = DateTime.now();
  Timer? _timer;

  List<Shop> _branches = [];
  List<RestaurantStaffUser> _staffUsers = [];
  bool _isLoading = true;
  String _searchQuery = '';
  String _userName = '';
  String? _activeShopId;
  SubscriptionStatusModel? _subscriptionStatus;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _loadAdminData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent) {
      if (event.logicalKey == LogicalKeyboardKey.f1) {
        setState(() => _selectedIndex = 0);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f2) {
        setState(() => _selectedIndex = 1);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f3) {
        setState(() => _selectedIndex = 2);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f4) {
        setState(() => _selectedIndex = 3);
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f5) {
        context.go('/counter/billing');
        return true;
      } else if (event.logicalKey == LogicalKeyboardKey.f6) {
        context.go('/dashboard');
        return true;
      }
    }
    return false;
  }

  Future<void> _loadAdminData() async {
    setState(() => _isLoading = true);
    try {
      final branchesFuture = ShopService.getShops();
      final staffFuture = AdminStaffService.getStaffUsers();
      final nameFuture = AuthService.getUserName();
      final shopIdFuture = InventoryService.getShopId();
      final subStatusFuture = SubscriptionApiService.fetchSubscriptionStatus();

      final results = await Future.wait([branchesFuture, staffFuture, nameFuture, shopIdFuture, subStatusFuture]);
      if (mounted) {
        setState(() {
          _branches = results[0] as List<Shop>;
          _staffUsers = results[1] as List<RestaurantStaffUser>;
          _userName = (results[2] as String?) ?? '';
          _activeShopId = results[3] as String?;
          _subscriptionStatus = results[4] as SubscriptionStatusModel;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 10),
            Text('Logout Admin Session'),
          ],
        ),
        content: const Text(
          'Are you sure you want to exit the Admin Panel and return to the main dashboard?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await AppSessionManager.resetSession(ref: ref);
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  void _showAddBranchDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddBranchDialog(onSaved: _loadAdminData),
    );
  }

  void _showEditBranchDialog(Shop branch) {
    showDialog(
      context: context,
      builder: (ctx) => AddBranchDialog(
        existingBranch: branch,
        onSaved: _loadAdminData,
      ),
    );
  }

  Future<void> _handleDeleteBranch(Shop branch) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Delete Outlet'),
          ],
        ),
        content: Text('Are you sure you want to delete "${branch.name}" (${branch.code})? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ShopService.deleteShop(
          branch.id,
          code: branch.code,
          name: branch.name,
        );
        _loadAdminData();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Outlet "${branch.name}" deleted successfully.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete outlet: $e'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleSelectActiveBranch(Shop branch) async {
    await InventoryService.setShopId(branch.id);
    if (mounted) {
      setState(() => _activeShopId = branch.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Active branch set to "${branch.name}". All POS & inventory operations now point to this outlet.'),
          backgroundColor: const Color(0xFF6366F1),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AddStaffUserDialog(
        branches: _branches,
        onSaved: _loadAdminData,
      ),
    );
  }

  void _showEditUserDialog(RestaurantStaffUser user) {
    showDialog(
      context: context,
      builder: (ctx) => AddStaffUserDialog(
        existingUser: user,
        branches: _branches,
        onSaved: _loadAdminData,
      ),
    );
  }

  Future<void> _handleDeleteUser(RestaurantStaffUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444)),
            SizedBox(width: 8),
            Text('Delete Staff User'),
          ],
        ),
        content: Text(
          'Are you sure you want to permanently delete user account "${user.name}" (${user.username})? This user will no longer be able to log in to POS or Admin.',
          style: const TextStyle(fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete User'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final success = await AdminStaffService.deleteStaffUser(user.id);
      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Staff user "${user.name}" deleted successfully.'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
          _loadAdminData();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete user "${user.name}".'),
              backgroundColor: const Color(0xFFEF4444),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    Widget buildSidebar() => AdminSidebar(
          isDesktop: isDesktop,
          isExpanded: _isSidebarExpanded,
          currentIndex: _selectedIndex,
          onSelectIndex: (idx) {
            setState(() => _selectedIndex = idx);
            if (!isDesktop) Navigator.pop(context);
          },
          onToggleTheme: () => ref.read(themeProvider.notifier).toggleTheme(),
          onLogout: _handleLogout,
        );

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.white,
        drawer: isDesktop ? null : Drawer(child: buildSidebar()),
        body: SafeArea(
          child: Column(
            children: [
              // 1. TOP HEADER (Spans 100% full width across the very top!)
              AdminTopHeader(
                isDesktop: isDesktop,
                currentTime: _currentTime,
                userName: _userName.isNotEmpty ? _userName : 'Admin',
                userRole: 'Administrator',
                onMenuPressed: () {
                  if (isDesktop) {
                    setState(() => _isSidebarExpanded = !_isSidebarExpanded);
                  } else {
                    _scaffoldKey.currentState?.openDrawer();
                  }
                },
                onLogout: _handleLogout,
                onSelectTab: (idx) => setState(() => _selectedIndex = idx),
              ),

              // 2. MAIN BODY (Sidebar underneath on left, Content on right)
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop) buildSidebar(),
                    Expanded(
                      child: Container(
                        color: scaffoldBg,
                        child: _isLoading
                            ? const Center(
                                child: CircularProgressIndicator(color: Color(0xFF6366F1)),
                              )
                            : IndexedStack(
                                index: _selectedIndex,
                                children: [
                                  // TAB 0: DASHBOARD
                                  AdminDashboardTab(
                                    branches: _branches,
                                    staffCount: _staffUsers.length,
                                    onAddBranch: _showAddBranchDialog,
                                    onAddUser: _showAddUserDialog,
                                    onViewAllBranches: () => setState(() => _selectedIndex = 1),
                                    onViewSubscription: () => setState(() => _selectedIndex = 3),
                                    subscriptionStatus: _subscriptionStatus,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtitleColor: subtitleColor,
                                    isDark: isDark,
                                  ),

                                  // TAB 1: OUTLETS & BRANCHES
                                  AdminOutletsTab(
                                    branches: _branches,
                                    onAddBranch: _showAddBranchDialog,
                                    onEditBranch: _showEditBranchDialog,
                                    onDeleteBranch: _handleDeleteBranch,
                                    onSelectActiveBranch: _handleSelectActiveBranch,
                                    activeShopId: _activeShopId,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtitleColor: subtitleColor,
                                    isDark: isDark,
                                  ),

                                  // TAB 2: USERS & ROLES
                                  AdminUsersTab(
                                    staffUsers: _staffUsers,
                                    searchQuery: _searchQuery,
                                    onSearchChanged: (val) => setState(() => _searchQuery = val),
                                    onAddUser: _showAddUserDialog,
                                    onEditUser: _showEditUserDialog,
                                    onDeleteUser: _handleDeleteUser,
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtitleColor: subtitleColor,
                                    isDark: isDark,
                                  ),

                                  // TAB 3: SUBSCRIPTION & MONTHLY PLANS
                                  AdminSubscriptionTab(
                                    cardBg: cardBg,
                                    borderColor: borderColor,
                                    textColor: textColor,
                                    subtitleColor: subtitleColor,
                                    isDark: isDark,
                                    initialStatus: _subscriptionStatus,
                                    onStatusChanged: (st) => setState(() => _subscriptionStatus = st),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
