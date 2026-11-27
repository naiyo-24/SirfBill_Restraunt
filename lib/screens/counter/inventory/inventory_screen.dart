import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/inventory_service.dart';
import '../../../../services/shop_service.dart';
import '../../../../utils/responsive.dart';
import 'models/inventory_models.dart';
import 'models/stock_transfer_models.dart';
import 'services/inventory_api_service.dart';
import 'services/stock_transfer_api_service.dart';
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
import 'widgets/create_purchase_order_dialog.dart';
import 'widgets/inventory_sidebar.dart';
import 'widgets/inventory_top_bar.dart';
import 'widgets/low_stock_notification_dialog.dart';
import 'widgets/receive_stock_transfer_dialog.dart';
import 'widgets/stock_transfer_details_dialog.dart';
import '../../../widgets/exit_confirmation_dialog.dart';

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
  List<Ingredient>? _lowStockItems = [];
  List<StockTransferHeader>? _incomingTransfers = [];
  List<StockTransferHeader>? _outboundVarianceTransfers = [];
  bool _isSidebarCollapsed = false;
  List<Ingredient> get _safeLowStock => _lowStockItems ?? const [];
  List<StockTransferHeader> get _safeIncoming => _incomingTransfers ?? const [];
  List<StockTransferHeader> get _safeVariances => _outboundVarianceTransfers ?? const [];

  @override
  void initState() {
    super.initState();
    _isSidebarCollapsed = false;
    _currentSection = widget.initialSection;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
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
      final role = (await AuthService.getUserRole() ?? '').trim().toUpperCase();
      final allShops = await ShopService.getShops(allBranches: true);
      final prefs = await SharedPreferences.getInstance();
      final assignedOutletId = prefs.getString('assigned_outlet_id');
      final savedId = (assignedOutletId != null && assignedOutletId.isNotEmpty) ? assignedOutletId : prefs.getString('selected_shop_id');
      final savedName = prefs.getString('assigned_outlet_name');

      final isAdmin = role == 'ADMIN' || role == 'OWNER' || role == 'SUPER_ADMIN';
      final isRestricted = !isAdmin && (assignedOutletId != null && assignedOutletId.isNotEmpty);

      List<Shop> shops = allShops;
      if (isRestricted) {
        final assigned = allShops.where((s) => s.id == assignedOutletId).toList();
        if (assigned.isNotEmpty) shops = assigned;
      }

      String branchName = savedName ?? 'Karim\'s - Original From Jama Masjid Delhi 6';
      if (shops.isNotEmpty) {
        final match = shops.firstWhere((s) => s.id == savedId, orElse: () => shops.first);
        branchName = match.name;
      }

      final resolvedOutlet = (savedId != null && savedId.isNotEmpty)
          ? savedId
          : (shops.isNotEmpty ? shops.first.id : '');
      if (resolvedOutlet.isNotEmpty) {
        await prefs.setString('selected_shop_id', resolvedOutlet);
        await InventoryService.setShopId(resolvedOutlet);
      }

      int lowStockCount = 0;
      List<Ingredient> lowItems = [];
      try {
        final items = await InventoryApiService.getIngredients(outletId: resolvedOutlet);
        lowItems = items.where((i) => i.isLowStock || i.isOutOfStock).toList();
        lowStockCount = lowItems.length;
      } catch (_) {}

      List<StockTransferHeader> incoming = [];
      try {
        final transfers = await StockTransferApiService.getTransfers(outletId: resolvedOutlet, status: 'IN_TRANSIT');
        incoming = transfers.where((t) => t.toOutletId == resolvedOutlet).toList();
      } catch (_) {}

      List<StockTransferHeader> outboundVariances = [];
      try {
        final completed = await StockTransferApiService.getTransfers(outletId: resolvedOutlet, status: 'COMPLETED');
        outboundVariances = completed.where((t) => t.fromOutletId == resolvedOutlet && t.hasVariance).toList();
      } catch (_) {}

      if (mounted) {
        setState(() {
          if (name != null && name.trim().isNotEmpty) _userName = name.trim();
          if (role.isNotEmpty) _userRole = role;
          _shops = shops;
          _currentShopId = resolvedOutlet.isNotEmpty ? resolvedOutlet : null;
          _branchName = branchName;
          _lowStockItems = lowItems;
          _incomingTransfers = incoming;
          _outboundVarianceTransfers = outboundVariances;
          _badgeCounts.clear();
          if (lowStockCount > 0) _badgeCounts[InventorySection.ingredients] = lowStockCount;
          final transferBadge = incoming.length + outboundVariances.length;
          if (transferBadge > 0) _badgeCounts[InventorySection.stockTransfers] = transferBadge;
        });
      }
    } catch (_) {}
  }

  void _handleIngredientsLoaded(List<Ingredient> items) {
    final lowItems = items.where((i) => i.isLowStock || i.isOutOfStock).toList();
    if (mounted) {
      setState(() {
        _lowStockItems = lowItems;
        _badgeCounts[InventorySection.ingredients] = lowItems.length;
      });
    }
  }

  void _openLowStockNotifications() {
    LowStockNotificationDialog.show(
      context,
      lowStockItems: _safeLowStock,
      incomingTransfers: _safeIncoming,
      outboundVarianceTransfers: _safeVariances,
      onOrderIngredient: (ing) => CreatePurchaseOrderDialog.show(context, initialIngredient: ing).then((_) => _loadUserInfo()),
      onOrderAll: () => CreatePurchaseOrderDialog.show(context, initialIngredients: _safeLowStock).then((_) => _loadUserInfo()),
      onReceiveTransfer: (t) => ReceiveStockTransferDialog.show(context, transfer: t, onReceived: _loadUserInfo),
      onInspectTransfer: (t) => StockTransferDetailsDialog.show(context, transfer: t, onUpdated: _loadUserInfo),
    );
  }

  Future<void> _selectShop(Shop shop) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_shop_id', shop.id);
    await prefs.setString('assigned_outlet_id', shop.id);
    await prefs.setString('assigned_outlet_name', shop.name);
    await InventoryService.setShopId(shop.id);
    if (mounted) {
      setState(() {
        _currentShopId = shop.id;
        _branchName = shop.name;
      });
      _loadUserInfo();
    }
  }

  void _onSectionSelected(InventorySection section) {
    setState(() {
      _currentSection = section;
      if (Responsive.isDesktop(context)) {
        _isSidebarCollapsed = true;
      }
    });
    if (!Responsive.isDesktop(context) && _scaffoldKey.currentState?.isDrawerOpen == true) {
      Navigator.pop(context);
    }
  }

  void _toggleSidebar() {
    if (Responsive.isDesktop(context)) {
      setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
    } else {
      if (_scaffoldKey.currentState?.isDrawerOpen == true) {
        Navigator.pop(context);
      } else {
        _scaffoldKey.currentState?.openDrawer();
      }
    }
  }

  Future<void> _handleExit({bool isLogout = false}) async {
    final confirmed = await ExitConfirmationDialog.show(
      context: context,
      title: isLogout ? 'Sign Out of Inventory?' : 'Exit Inventory?',
      message: isLogout
          ? 'Are you sure you want to log out of culinary inventory and return to dashboard?'
          : 'Are you sure you want to return to the main dashboard?',
      confirmText: isLogout ? 'Logout' : 'Exit',
    );
    if (confirmed == true && mounted) {
      await AuthService.logout();
      if (mounted) context.go('/dashboard');
    }
  }

  void _handleLogout() => _handleExit(isLogout: true);

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final contentBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    Widget buildSidebar({bool isDrawer = false}) => InventorySidebar(
          selectedSection: _currentSection,
          onSectionSelected: _onSectionSelected,
          isCollapsed: isDrawer ? false : (_isSidebarCollapsed == true),
          onToggleCollapse: _toggleSidebar,
          onLogout: _handleLogout,
          badgeCounts: _badgeCounts,
          isStandalone: widget.isStandalone,
          onBackToDashboard: _handleExit,
          isDesktop: isDesktop && !isDrawer,
        );

    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f1): () => _onSectionSelected(InventorySection.dashboard),
        const SingleActivator(LogicalKeyboardKey.f2): () => _onSectionSelected(InventorySection.ingredients),
        const SingleActivator(LogicalKeyboardKey.f3): () => _onSectionSelected(InventorySection.recipeManagement),
        const SingleActivator(LogicalKeyboardKey.f4): () => _onSectionSelected(InventorySection.purchaseOrders),
        const SingleActivator(LogicalKeyboardKey.f5): () => _onSectionSelected(InventorySection.stockManagement),
        const SingleActivator(LogicalKeyboardKey.f6): () => _onSectionSelected(InventorySection.goodsReceived),
        const SingleActivator(LogicalKeyboardKey.f7): () => _onSectionSelected(InventorySection.wastage),
        const SingleActivator(LogicalKeyboardKey.f8): () => _onSectionSelected(InventorySection.reports),
      },
      child: Focus(
        autofocus: true,
        child: PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
          _scaffoldKey.currentState?.closeDrawer();
          return;
        }
        if (_currentSection != widget.initialSection) {
          setState(() => _currentSection = widget.initialSection);
          return;
        }
        _handleExit();
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        drawer: isDesktop
            ? null
            : Drawer(
                width: 256,
                child: buildSidebar(isDrawer: true),
              ),
        body: SafeArea(
          child: Column(
            children: [
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
                  setState(() => _refreshKeyCounter++);
                  _loadUserInfo();
                },
                onBackToDashboard: _handleExit,
                lowStockCount: _safeLowStock.length + _safeIncoming.length + _safeVariances.length,
                onOpenNotifications: _openLowStockNotifications,
              ),
              Expanded(
                child: Row(
                  children: [
                    if (isDesktop) buildSidebar(),
                    Expanded(
                      child: Container(
                        color: contentBg,
                        child: Column(
                          children: [
                            if (_safeIncoming.isNotEmpty) _buildIncomingTransferAlertBanner(isDark, _safeIncoming.first),
                            if (_safeVariances.isNotEmpty) _buildVarianceAlertBanner(isDark, _safeVariances.first),
                            if (_safeLowStock.isNotEmpty) _buildLowStockAlertBanner(isDark),
                            Expanded(
                              child: AnimatedSwitcher(
                                duration: const Duration(milliseconds: 180),
                                child: KeyedSubtree(
                                  key: ValueKey('${_currentSection}_$_refreshKeyCounter'),
                                  child: _buildActiveSection(),
                                ),
                              ),
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
    ),
    ),
    );
  }

  Widget _buildLowStockAlertBanner(bool isDark) {
    final count = _safeLowStock.length;
    final itemNames = _safeLowStock.map((e) => e.name).take(3).join(', ');
    final suffix = count > 3 ? ' +${count - 3} more' : '';

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF7F1D1D).withValues(alpha: 0.35) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFEF4444), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.notifications_active_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Critical Par Alert: $count item${count > 1 ? 's' : ''} ($itemNames$suffix) below minimum threshold.',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: _openLowStockNotifications,
            icon: const Icon(Icons.shopping_cart_checkout, size: 14),
            label: const Text('Review & Reorder'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVarianceAlertBanner(bool isDark, StockTransferHeader t) {
    final lossCount = t.varianceItems.length;
    final totalLossVal = t.varianceItems.fold<double>(0.0, (sum, i) => sum + (i.quantityVariance * i.unitCost));
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF7C2D12).withValues(alpha: 0.35) : const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.6), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFFF59E0B), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.report_problem_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Discrepancy Alert: Transfer ${t.transferNumber} received at ${t.toOutletName} with $lossCount short item(s) (Shortage Value: ₹${totalLossVal.toStringAsFixed(2)}).',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? const Color(0xFFFDE68A) : const Color(0xFFB45309)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => StockTransferDetailsDialog.show(context, transfer: t, onUpdated: _loadUserInfo),
            icon: const Icon(Icons.receipt_long_rounded, size: 14),
            label: const Text('View Challan & Variance'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD97706),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncomingTransferAlertBanner(bool isDark, StockTransferHeader t) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A8A).withValues(alpha: 0.35) : const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: const Color(0xFF3B82F6), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.local_shipping_rounded, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Incoming Delivery: Transfer ${t.transferNumber} from ${t.fromOutletName} is In-Transit (${t.vehicleNumber.isNotEmpty ? t.vehicleNumber : "Delivery Van"}) • ${t.totalItems} commodity line(s).',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isDark ? const Color(0xFF93C5FD) : const Color(0xFF1E40AF)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            onPressed: () => ReceiveStockTransferDialog.show(context, transfer: t, onReceived: _loadUserInfo),
            icon: const Icon(Icons.check_circle_outline_rounded, size: 14),
            label: const Text('Receive & Reconcile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveSection() {
    switch (_currentSection) {
      case InventorySection.dashboard: return InventoryDashboardSection(onNavigateSection: _onSectionSelected);
      case InventorySection.ingredients: return IngredientsSection(onIngredientsLoaded: _handleIngredientsLoaded);
      case InventorySection.categories: return const CategoriesSection();
      case InventorySection.suppliers: return const SuppliersSection();
      case InventorySection.purchaseOrders: return const PurchaseOrdersSection();
      case InventorySection.goodsReceived: return const GrnSection();
      case InventorySection.stockManagement: return const StockManagementSection();
      case InventorySection.stockTransfers: return const StockTransfersSection();
      case InventorySection.recipeManagement: return const RecipeManagementSection();
      case InventorySection.stockConsumption: return StockConsumptionSection(outletId: _currentShopId);
      case InventorySection.wastage: return const WastageSection();
      case InventorySection.stockAudit: return const StockAuditSection();
      case InventorySection.reports: return InventoryReportsSection(outletId: _currentShopId);
    }
  }
}
