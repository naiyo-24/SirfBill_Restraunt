import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/shop_service.dart';
import '../../../../utils/responsive.dart';
import 'models/inventory_models.dart';
import 'services/inventory_api_service.dart';
import 'sections/categories_section.dart';
import 'sections/grn_section.dart';
import 'sections/ingredients_section.dart';
import 'sections/inventory_dashboard_section.dart';
import 'sections/inventory_reports_section.dart';
import 'sections/purchase_orders_section.dart';
import 'sections/recipe_management_section.dart';
import 'sections/stock_audit_section.dart';
import 'sections/stock_consumption_section.dart';
import 'sections/stock_management_section.dart';
import 'sections/stock_transfers_section.dart';
import 'sections/suppliers_section.dart';
import 'sections/wastage_section.dart';
import 'widgets/inventory_sidebar.dart';
import 'widgets/inventory_top_bar.dart';

class RestaurantInventoryScreen extends StatefulWidget {
  final InventorySection initialSection;
  final bool isStandalone;

  const RestaurantInventoryScreen({
    super.key,
    this.initialSection = InventorySection.dashboard,
    this.isStandalone = false,
  });

  @override
  State<RestaurantInventoryScreen> createState() => _RestaurantInventoryScreenState();
}

class _RestaurantInventoryScreenState extends State<RestaurantInventoryScreen> {
  late InventorySection _currentSection;
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  String _userName = 'Store Manager';
  String _userRole = 'Inventory & Purchase';
  String _branchName = 'Main Outlet';
  List<Shop> _shops = [];
  String? _currentShopId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _refreshKeyCounter = 0;

  final Map<InventorySection, int> _badgeCounts = {};

  @override
  void initState() {
    super.initState();
    _currentSection = widget.initialSection;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() => _currentTime = DateTime.now());
      }
    });
    _loadUserInfo();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final name = await AuthService.getUserName();
      final role = await AuthService.getUserRole();
      final shops = await ShopService.getShops();
      final prefs = await SharedPreferences.getInstance();
      final savedId = prefs.getString('assigned_outlet_id') ?? prefs.getString('selected_shop_id');
      final savedName = prefs.getString('assigned_outlet_name');

      String branchName = savedName ?? 'Karim\'s - Original From Jama Masjid Delhi 6';
      if (shops.isNotEmpty) {
        final match = shops.firstWhere(
          (s) => s.id == savedId,
          orElse: () => shops.first,
        );
        branchName = match.name;
      }

      int lowStockCount = 0;
      try {
        final items = await InventoryApiService.getIngredients();
        lowStockCount = items.where((i) => i.isLowStock || i.isOutOfStock).length;
      } catch (_) {}

      if (mounted) {
        setState(() {
          if (name != null && name.trim().isNotEmpty) {
            _userName = name.trim();
          }
          if (role != null && role.trim().isNotEmpty) {
            _userRole = role.trim();
          }
          _shops = shops;
          _currentShopId = savedId ?? (shops.isNotEmpty ? shops.first.id : null);
          _branchName = branchName;
          _badgeCounts.clear();
          if (lowStockCount > 0) {
            _badgeCounts[InventorySection.ingredients] = lowStockCount;
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _selectShop(Shop shop) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_shop_id', shop.id);
    await prefs.setString('assigned_outlet_name', shop.name);
    await InventoryService.setShopId(shop.id);
    if (mounted) {
      setState(() {
        _currentShopId = shop.id;
        _branchName = shop.name;
      });
    }
  }

  void _onSectionSelected(InventorySection section) {
    setState(() {
      _currentSection = section;
    });
    if (!Responsive.isDesktop(context) && _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  void _toggleSidebar() {
    if (!Responsive.isDesktop(context)) {
      if (_scaffoldKey.currentState?.isDrawerOpen == true) {
        Navigator.pop(context);
      } else {
        _scaffoldKey.currentState?.openDrawer();
      }
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
            SizedBox(width: 8),
            Text('Sign Out of Inventory', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of the culinary inventory module and return to the dashboard?',
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
      await AuthService.logout();
      if (mounted) {
        context.go('/dashboard');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    Widget buildSidebar() => InventorySidebar(
          selectedSection: _currentSection,
          onSectionSelected: _onSectionSelected,
          onLogout: _handleLogout,
          badgeCounts: _badgeCounts,
          isStandalone: widget.isStandalone,
          onBackToDashboard: () => context.go('/dashboard'),
        );

    return PopScope(
      canPop: false,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        drawer: isDesktop ? null : Drawer(child: buildSidebar()),
        body: SafeArea(
          child: Column(
            children: [
              // Top Bar Header
              InventoryTopBar(
                isDesktop: isDesktop,
                currentTime: _currentTime,
                userName: _userName,
                userRole: _userRole,
                branchName: _branchName,
                shops: _shops,
                currentShopId: _currentShopId,
                onSelectShop: _selectShop,
                selectedSection: _currentSection,
                onSelectSection: _onSectionSelected,
                onMenuPressed: _toggleSidebar,
                onLogout: _handleLogout,
                onRefresh: () {
                  setState(() {
                    _refreshKeyCounter++;
                  });
                  _loadUserInfo();
                },
                onBackToDashboard: () => context.go('/dashboard'),
              ),

              // Sidebar + Section Content
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop) buildSidebar(),
                    Expanded(
                      child: Container(
                        color: contentBg,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: KeyedSubtree(
                            key: ValueKey('${_currentSection}_$_refreshKeyCounter'),
                            child: _buildActiveSection(),
                          ),
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

  Widget _buildActiveSection() {
    switch (_currentSection) {
      case InventorySection.dashboard:
        return InventoryDashboardSection(onNavigateSection: _onSectionSelected);
      case InventorySection.ingredients:
        return const IngredientsSection();
      case InventorySection.categories:
        return const CategoriesSection();
      case InventorySection.suppliers:
        return const SuppliersSection();
      case InventorySection.purchaseOrders:
        return const PurchaseOrdersSection();
      case InventorySection.goodsReceived:
        return const GrnSection();
      case InventorySection.stockManagement:
        return const StockManagementSection();
      case InventorySection.stockTransfers:
        return const StockTransfersSection();
      case InventorySection.recipeManagement:
        return const RecipeManagementSection();
      case InventorySection.stockConsumption:
        return const StockConsumptionSection();
      case InventorySection.wastage:
        return const WastageSection();
      case InventorySection.stockAudit:
        return const StockAuditSection();
      case InventorySection.reports:
        return const InventoryReportsSection();
    }
  }
}
