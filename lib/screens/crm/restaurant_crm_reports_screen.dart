import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../utils/responsive.dart';
import '../../services/auth_service.dart';
import '../../services/app_session_manager.dart';
import '../../providers/theme_provider.dart';
import '../counter/customers_screen.dart';
import '../counter/reports_screen.dart';
import 'widgets/crm_reports_sidebar.dart';
import 'widgets/crm_reports_header.dart';

class RestaurantCrmReportsScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;

  const RestaurantCrmReportsScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  ConsumerState<RestaurantCrmReportsScreen> createState() =>
      _RestaurantCrmReportsScreenState();
}

class _RestaurantCrmReportsScreenState
    extends ConsumerState<RestaurantCrmReportsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  late int _selectedIndex;
  bool _isSidebarExpanded = true;
  DateTime _currentTime = DateTime.now();
  Timer? _timer;
  String _userName = 'Sayar Paul';
  String _userRole = 'CRM Station';

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialTabIndex;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _loadProfileData();
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
      }
    }
    return false;
  }

  Future<void> _loadProfileData() async {
    try {
      final name = await AuthService.getUserName();
      final role = await AuthService.getUserRole();

      if (mounted) {
        setState(() {
          if (name != null && name.trim().isNotEmpty) {
            _userName = name.trim();
          }
          if (role != null && role.trim().isNotEmpty) {
            _userRole = role.trim();
          }
        });
      }
    } catch (_) {}
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
            Text('Exit CRM Portal', style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
        content: const Text(
          'Are you sure you want to log out of the CRM system and return to the main dashboard?',
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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

  @override
  Widget build(BuildContext context) {
    final bool isDesktop = Responsive.isDesktop(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);

    Widget buildSidebar() => CrmReportsSidebar(
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
        bottomNavigationBar: !isDesktop
            ? NavigationBar(
                selectedIndex: _selectedIndex,
                onDestinationSelected: (idx) => setState(() => _selectedIndex = idx),
                backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                indicatorColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.people_outline_rounded),
                    selectedIcon: Icon(Icons.people_rounded, color: Color(0xFF10B981)),
                    label: 'Customers',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.analytics_outlined),
                    selectedIcon: Icon(Icons.analytics_rounded, color: Color(0xFF10B981)),
                    label: 'Reports',
                  ),
                ],
              )
            : null,
        body: SafeArea(
          child: Column(
            children: [
              // 1. TOP HEADER (Spans 100% full width across the very top!)
              CrmReportsHeader(
                isDesktop: isDesktop,
                currentTime: _currentTime,
                userName: _userName,
                userRole: _userRole,
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
                        child: IndexedStack(
                          index: _selectedIndex,
                          children: const [
                            CustomersScreen(),
                            ReportsScreen(),
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
