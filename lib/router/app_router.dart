import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/splash/splash_screen.dart';
import '../screens/home/dashboard_screen.dart';
import '../screens/auth/role_login_screen.dart';
import '../screens/counter/counter_dashboard.dart';
import '../screens/counter/billing_screen.dart';
import '../screens/counter/customers_screen.dart';
// import '../screens/counter/accounts_screen.dart';
import '../screens/counter/bill_customization_screen.dart';
import '../screens/counter/table_management_screen.dart';
import '../screens/counter/order_management_screen.dart';
import '../screens/counter/kitchen_display_screen.dart';
import '../screens/counter/menu_management_screen.dart';
import '../screens/counter/reports_screen.dart';
import '../screens/counter/inventory/inventory_screen.dart';
import '../screens/admin/restaurant_admin_panel_screen.dart';
import '../screens/waiter/waiter_order_screen.dart';

import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);

final goRouter = GoRouter(
  navigatorKey: rootNavigatorKey,
  initialLocation: '/splash',
  redirect: (BuildContext context, GoRouterState state) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final isLoggedIn = token != null && token.isNotEmpty;
    
    final loc = state.matchedLocation;
    final isPublicRoute = loc == '/role_login' || loc == '/splash' || loc == '/dashboard';

    final fullUri = state.uri.path;
    if (fullUri.contains('/counter/inventory') || loc.contains('/counter/inventory')) {
      return '/inventory';
    }

    // If not logged in and not on a public route, redirect to dashboard
    if (!isLoggedIn && !isPublicRoute) {
      return '/dashboard';
    }

    // Auto-forward from splash based on role or active station module
    if (loc == '/splash') {
      if (isLoggedIn) {
        final role = (prefs.getString('user_role') ?? '').trim().toUpperCase();
        final loginModule = (prefs.getString('role_login_name') ?? '').trim().toUpperCase();
        final stationKey = (prefs.getString('station_module_key') ?? '').trim().toLowerCase();
        final userName = (prefs.getString('user_name') ?? '').trim().toLowerCase();
        final userId = (prefs.getString('user_id') ?? '').trim().toLowerCase();

        final isCrm = role == 'CRM' ||
            role == 'REPORTS' ||
            stationKey == 'crm' ||
            loginModule.contains('CRM') ||
            loginModule.contains('REPORT') ||
            userName.contains('crm') ||
            userId.contains('crm');

        if (role == 'ADMIN' || role == 'OWNER' || role == 'SUPER_ADMIN') {
          return '/admin';
        } else if (role == 'KITCHEN' || role == 'CHEF' || role == 'KDS' || loginModule.contains('KITCHEN')) {
          return '/kitchen';
        } else if (role == 'WAITER' || role == 'CAPTAIN' || role == 'SERVER' || loginModule.contains('WAITER')) {
          return '/waiter';
        } else if (role == 'INVENTORY' || role == 'STOCK' || loginModule.contains('INVENTORY')) {
          return '/inventory';
        } else if (isCrm) {
          return '/counter/customers';
        }
        return '/counter/billing';
      }
      return '/dashboard';
    }

    // Direct CRM users to CRM screen if they land on POS Billing
    if (loc == '/counter/billing' && isLoggedIn) {
      final role = (prefs.getString('user_role') ?? '').trim().toUpperCase();
      final loginModule = (prefs.getString('role_login_name') ?? '').trim().toUpperCase();
      final stationKey = (prefs.getString('station_module_key') ?? '').trim().toLowerCase();
      final userName = (prefs.getString('user_name') ?? '').trim().toLowerCase();
      final userId = (prefs.getString('user_id') ?? '').trim().toLowerCase();

      final isCrm = role == 'CRM' ||
          role == 'REPORTS' ||
          stationKey == 'crm' ||
          loginModule.contains('CRM') ||
          loginModule.contains('REPORT') ||
          userName.contains('crm') ||
          userId.contains('crm');

      if (isCrm) {
        return '/counter/customers';
      }
    }

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardScreen(),
    ),
    GoRoute(
      path: '/admin',
      builder: (context, state) => const RestaurantAdminPanelScreen(),
    ),
    GoRoute(
      path: '/kitchen',
      builder: (context, state) => const KitchenDisplayScreen(isStandalone: true),
    ),
    GoRoute(
      path: '/waiter',
      builder: (context, state) => const WaiterOrderScreen(),
    ),
    GoRoute(
      path: '/inventory',
      builder: (context, state) => const RestaurantInventoryScreen(isStandalone: true),
    ),
    GoRoute(
      path: '/counter/inventory',
      redirect: (context, state) => '/inventory',
    ),
    GoRoute(
      path: '/role_login',
      builder: (context, state) {
        final Map<String, dynamic> extra = state.extra is Map<String, dynamic>
            ? state.extra as Map<String, dynamic>
            : {};
        final q = state.uri.queryParameters;
        final roleName = (extra['roleName'] as String?) ?? q['roleName'] ?? 'Restaurant POS';

        final Color themeColor = extra['themeColor'] is Color
            ? extra['themeColor'] as Color
            : (roleName.contains('Inventory')
                ? const Color(0xFF3B82F6)
                : (roleName.contains('Kitchen')
                    ? const Color(0xFFF97316)
                    : (roleName.contains('Waiter')
                        ? const Color(0xFFF59E0B)
                        : (roleName.contains('CRM')
                            ? const Color(0xFF8B5CF6)
                            : (roleName.contains('Admin')
                                ? const Color(0xFF6366F1)
                                : const Color(0xFF10B981))))));

        String nextRoute = (extra['nextRoute'] as String?) ?? q['nextRoute'] ?? '';
        if (nextRoute.isEmpty) {
          if (roleName.contains('Inventory')) {
            nextRoute = '/inventory';
          } else if (roleName.contains('Kitchen')) {
            nextRoute = '/kitchen';
          } else if (roleName.contains('Waiter')) {
            nextRoute = '/waiter';
          } else if (roleName.contains('Admin')) {
            nextRoute = '/admin';
          } else if (roleName.contains('CRM')) {
            nextRoute = '/counter/customers';
          } else {
            nextRoute = '/counter/billing';
          }
        }

        return RoleLoginScreen(
          roleName: roleName,
          themeColor: themeColor,
          nextRoute: nextRoute,
        );
      },
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) {
        return CounterDashboard(navigationShell: navigationShell);
      },
      branches: [
        // 0: POS Billing
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/billing',
              builder: (context, state) => const BillingScreen(),
            ),
          ],
        ),
        // 1: Tables
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/tables',
              builder: (context, state) => const TableManagementScreen(),
            ),
          ],
        ),
        // 2: Orders
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/orders',
              builder: (context, state) => const OrderManagementScreen(),
            ),
          ],
        ),
        // 3: Kitchen (KOT)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/kitchen',
              builder: (context, state) => const KitchenDisplayScreen(),
            ),
          ],
        ),
        // 4: Menu Management
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/menu',
              builder: (context, state) => const MenuManagementScreen(),
            ),
          ],
        ),
        // 5: Customers (CRM)
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/customers',
              builder: (context, state) => const CustomersScreen(),
            ),
          ],
        ),
        // 6: Reports
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/reports',
              builder: (context, state) => const ReportsScreen(),
            ),
          ],
        ),
        // 7: Expenses (Commented out)
        // StatefulShellBranch(
        //   routes: [
        //     GoRoute(
        //       path: '/counter/expenses',
        //       builder: (context, state) => const AccountsScreen(),
        //     ),
        //   ],
        // ),
        // 8: Settings
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/counter/settings',
              builder: (context, state) => const BillCustomizationScreen(),
            ),
          ],
        ),
      ],
    ),

  ],
);
