import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_client.dart';
import 'inventory_service.dart';
import '../utils/app_image_cache_manager.dart';

class AuthService {
  static const String _tokenKey = 'access_token';
  static const String _userIdKey = 'user_id';
  static const String _roleKey = 'user_role';
  static const String _userNameKey = 'user_name';

  /// Login for a specific module with strict role validation
  static Future<bool> loginForModule(String email, String password, String moduleTitle) async {
    // 1. Immediately wipe any lingering session before logging in
    await logout();

    final cleanEmail = email.trim();
    final cleanPass = password.trim();

    try {
      final response = await ApiClient().dio.post(
        '/api/auth/admin-login',
        data: {'email': cleanEmail, 'password': cleanPass},
      );

      if (response.statusCode == 200) {
        final data = response.data;
        final rawRole = (data['role'] ?? 'CASHIER').toString().toUpperCase();
        final uName = (data['username'] ?? data['email'] ?? cleanEmail).toString();
        final displayName = (data['name'] ?? data['full_name'] ?? '').toString();

        // 2. Strict Role Access Check
        if (!isRoleAuthorizedForModule(rawRole, moduleTitle, username: uName, name: displayName)) {
          throw 'Access Denied: This account is not authorized to access $moduleTitle.';
        }

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['access_token']);
        await prefs.setString(_userIdKey, data['user_id']);
        await prefs.setString(_roleKey, rawRole);
        if (data['name'] != null) {
          await prefs.setString(_userNameKey, data['name']);
        }
        
        try {
          final assignedId = data['assigned_outlet_id']?.toString() ??
              (data['outlet'] != null ? data['outlet']['id']?.toString() : null) ??
              data['outlet_id']?.toString();

          if (assignedId != null && assignedId.isNotEmpty) {
            await InventoryService.setShopId(assignedId);
            await prefs.setString('assigned_outlet_id', assignedId);
            if (data['outlet'] != null && data['outlet']['name'] != null) {
              await prefs.setString('assigned_outlet_name', data['outlet']['name'].toString());
            }
          } else {
            // First attempt /api/restaurant/outlets (available to all staff including WAITER)
            String? resolvedOutletId;
            try {
              final outletsResp = await ApiClient().dio.get('/api/restaurant/outlets');
              if (outletsResp.statusCode == 200 && outletsResp.data is List && (outletsResp.data as List).isNotEmpty) {
                final firstOutlet = (outletsResp.data as List).first;
                resolvedOutletId = firstOutlet['id']?.toString();
                if (firstOutlet['name'] != null) {
                  await prefs.setString('assigned_outlet_name', firstOutlet['name'].toString());
                }
              }
            } catch (_) {}

            // Fallback to /api/admin/shops (available to ADMIN)
            if (resolvedOutletId == null) {
              try {
                final shopsResp = await ApiClient().dio.get('/api/admin/shops');
                if (shopsResp.statusCode == 200 && shopsResp.data != null) {
                  final List<dynamic> shops = shopsResp.data;
                  if (shops.isNotEmpty) {
                    resolvedOutletId = shops.first['id'].toString();
                  }
                }
              } catch (_) {}
            }

            if (resolvedOutletId != null && resolvedOutletId.isNotEmpty) {
              await InventoryService.setShopId(resolvedOutletId);
              await prefs.setString('assigned_outlet_id', resolvedOutletId);
            }
          }
        } catch (_) {}

        return true;
      } else {
        final localMatched = await _tryLocalOutletLogin(cleanEmail, cleanPass, moduleTitle);
        if (localMatched) return true;
        throw 'Invalid User ID or Password. Please try again.';
      }
    } on DioException catch (e) {
      final localMatched = await _tryLocalOutletLogin(cleanEmail, cleanPass, moduleTitle);
      if (localMatched) return true;

      if (e.response != null && e.response?.data != null) {
        throw e.response?.data['detail'] ??
            'Invalid User ID or Password. Please try again.';
      }
      throw 'Unable to connect to the server. Please check your network connection.';
    } catch (e) {
      if (e is String) rethrow;
      final localMatched = await _tryLocalOutletLogin(cleanEmail, cleanPass, moduleTitle);
      if (localMatched) return true;
      throw 'Invalid User ID or Password. Please try again.';
    }
  }

  /// Backward-compatible adminLogin wrapper
  static Future<bool> adminLogin(String email, String password) async {
    return loginForModule(email, password, 'All Modules');
  }

  /// Strict check: Only matching roles/stations can access this module
  static bool isRoleAuthorizedForModule(
    String role,
    String moduleTitle, {
    String? username,
    String? name,
  }) {
    final r = role.trim().toUpperCase();
    final m = moduleTitle.toLowerCase();
    final u = (username ?? '').toLowerCase();
    final n = (name ?? '').toLowerCase();

    // Universal super access for owners/super admins
    if (r == 'ADMIN' || r == 'OWNER' || r == 'SUPER_ADMIN' || r == 'SUPERADMIN') {
      return true;
    }

    final isInventoryUser = u.contains('inv') || u.contains('stock') || n.contains('inventory') || n.contains('stock');
    final isPosUser = u.contains('pos') || u.contains('cashier') || n.contains('pos') || n.contains('cashier');
    final isKitchenUser = u.contains('kitchen') || u.contains('chef') || u.contains('kds') || n.contains('kitchen') || n.contains('chef');
    final isWaiterUser = u.contains('waiter') || u.contains('captain') || n.contains('waiter') || n.contains('captain');

    if (m.contains('inventory') || m.contains('stock') || m.contains('purchase')) {
      if (isPosUser || isKitchenUser || isWaiterUser) return false;
      return r == 'INVENTORY' || r == 'STOCK' || r == 'MANAGER' || isInventoryUser;
    } else if (m.contains('pos') || m.contains('billing')) {
      if (isInventoryUser || isKitchenUser || isWaiterUser) return false;
      return r == 'CASHIER' || r == 'POS' || (r == 'MANAGER' && !isInventoryUser);
    } else if (m.contains('kitchen') || m.contains('chef') || m.contains('kds')) {
      if (isInventoryUser || isPosUser || isWaiterUser) return false;
      return r == 'CHEF' || r == 'KITCHEN' || r == 'KDS';
    } else if (m.contains('waiter') || m.contains('captain') || m.contains('server')) {
      if (isInventoryUser || isPosUser || isKitchenUser) return false;
      return r == 'WAITER' || r == 'CAPTAIN' || r == 'SERVER';
    } else if (m.contains('crm') || m.contains('report')) {
      return r == 'MANAGER';
    } else if (m.contains('admin')) {
      return r == 'ADMIN' || r == 'OWNER' || r == 'SUPER_ADMIN';
    }

    return false;
  }

  /// Verify specifically against credentials saved in Admin Panel for this outlet station
  static Future<bool> _tryLocalOutletLogin(String email, String password, String moduleTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final cleanEmail = email.trim().toLowerCase();
    final cleanPass = password.trim();

    // 1. Check local outlet station credentials (saved via Admin Panel Outlets)
    for (final key in prefs.getKeys()) {
      if (key.startsWith('outlet_cred_') && key.endsWith('_user')) {
        final savedUser = prefs.getString(key) ?? '';
        final passKey = key.replaceAll('_user', '_pass');
        final savedPass = prefs.getString(passKey) ?? '';

        if (savedUser.trim().toLowerCase() == cleanEmail && savedPass == cleanPass) {
          final withoutPrefix = key.substring('outlet_cred_'.length);
          final withoutSuffix = withoutPrefix.substring(0, withoutPrefix.length - '_user'.length);
          final lastUnderscore = withoutSuffix.lastIndexOf('_');
          final outletId = lastUnderscore != -1 ? withoutSuffix.substring(0, lastUnderscore) : '';
          final moduleKey = lastUnderscore != -1 ? withoutSuffix.substring(lastUnderscore + 1) : withoutSuffix;
          final role = _mapModuleKeyToRole(moduleKey);

          if (!isRoleAuthorizedForModule(role, moduleTitle, username: cleanEmail, name: savedUser)) {
            throw 'Access Denied: This account is for ${_friendlyModuleName(moduleKey)} and cannot access $moduleTitle. Please enter credentials created for $moduleTitle.';
          }

          final token = 'station_local_token_${DateTime.now().millisecondsSinceEpoch}';
          await prefs.setString(_tokenKey, token);
          await prefs.setString(_userIdKey, cleanEmail);
          await prefs.setString(_roleKey, role.toUpperCase());
          await prefs.setString(_userNameKey, cleanEmail.split('@').first.replaceAll('_', ' ').toUpperCase());
          if (outletId.isNotEmpty) {
            await prefs.setString('assigned_outlet_id', outletId);
            await InventoryService.setShopId(outletId);
          }
          return true;
        }
      }
    }

    // 2. Check staff users database saved from Admin Panel Users tab
    final localStaffJson = prefs.getString('local_staff_users_db');
    if (localStaffJson != null && localStaffJson.isNotEmpty) {
      try {
        final List list = jsonDecode(localStaffJson);
        for (final item in list) {
          final uName = (item['username'] ?? item['email'] ?? '').toString().trim().toLowerCase();
          final uPass = (item['password'] ?? '').toString().trim();
          if (uName == cleanEmail && uPass == cleanPass) {
            final role = (item['role'] ?? 'CASHIER').toString().toUpperCase();
            final staffName = (item['name'] ?? item['full_name'] ?? '').toString();
            if (!isRoleAuthorizedForModule(role, moduleTitle, username: cleanEmail, name: staffName)) {
              throw 'Access Denied: This account has the role "$role" and cannot access $moduleTitle. Please enter credentials created for $moduleTitle.';
            }

            final token = 'staff_local_token_${DateTime.now().millisecondsSinceEpoch}';
            await prefs.setString(_tokenKey, token);
            await prefs.setString(_userIdKey, cleanEmail);
            await prefs.setString(_roleKey, role);
            await prefs.setString(_userNameKey, (item['name'] ?? cleanEmail).toString());
            final branchId = item['outlet_id'] ?? item['branch_id'];
            if (branchId != null && branchId.toString().isNotEmpty) {
              await prefs.setString('assigned_outlet_id', branchId.toString());
              await InventoryService.setShopId(branchId.toString());
            }
            return true;
          }
        }
      } catch (e) {
        if (e is String) rethrow;
      }
    }

    // 3. Default station patterns (password: 123456)
    if (cleanPass == '123456') {
      String? detectedModuleKey;
      if (cleanEmail.startsWith('inventory_') || cleanEmail.startsWith('inv_')) {
        detectedModuleKey = 'inventory';
      } else if (cleanEmail.startsWith('pos_') || cleanEmail.startsWith('billing_')) {
        detectedModuleKey = 'pos';
      } else if (cleanEmail.startsWith('kitchen_') || cleanEmail.startsWith('chef_')) {
        detectedModuleKey = 'kitchen';
      } else if (cleanEmail.startsWith('waiter_') || cleanEmail.startsWith('captain_')) {
        detectedModuleKey = 'waiter';
      } else if (cleanEmail.startsWith('crm_')) {
        detectedModuleKey = 'crm';
      }

      if (detectedModuleKey != null) {
        final role = _mapModuleKeyToRole(detectedModuleKey);
        if (!isRoleAuthorizedForModule(role, moduleTitle)) {
          throw 'Access Denied: This account is for ${_friendlyModuleName(detectedModuleKey)} and cannot access $moduleTitle. Please enter credentials created for $moduleTitle.';
        }

        final token = 'default_station_token_${DateTime.now().millisecondsSinceEpoch}';
        await prefs.setString(_tokenKey, token);
        await prefs.setString(_userIdKey, cleanEmail);
        await prefs.setString(_roleKey, role.toUpperCase());
        await prefs.setString(_userNameKey, cleanEmail.split('@').first.replaceAll('_', ' ').toUpperCase());
        return true;
      }
    }

    return false;
  }

  static String _friendlyModuleName(String key) {
    switch (key.toLowerCase()) {
      case 'inventory':
        return 'Inventory & Purchase';
      case 'pos':
        return 'Restaurant POS';
      case 'kitchen':
        return 'Kitchen Display';
      case 'crm':
        return 'CRM & Reports';
      case 'waiter':
        return 'Waiter / Captain';
      default:
        return key.toUpperCase();
    }
  }

  static String _mapModuleKeyToRole(String key) {
    switch (key.toLowerCase()) {
      case 'inventory':
        return 'INVENTORY';
      case 'pos':
        return 'CASHIER';
      case 'kitchen':
        return 'CHEF';
      case 'crm':
        return 'MANAGER';
      case 'waiter':
        return 'WAITER';
      case 'admin':
        return 'ADMIN';
      default:
        return 'CASHIER';
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userNameKey);
    await prefs.remove('role_login_name');
    await prefs.remove('assigned_outlet_id');
    await prefs.remove('assigned_outlet_name');
    await InventoryService.clearShopId();
    AppImageCacheManager.instance.clearMemoryCache();
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_roleKey);
  }

  // ==========================================
  // REMEMBERED CREDENTIALS (PER-MODULE STRICT ISOLATION)
  // ==========================================

  static String _normalizeRoleKey(String roleName) {
    final lower = roleName.trim().toLowerCase();
    if (lower.contains('kitchen') || lower.contains('kds') || lower.contains('chef')) {
      return 'kitchen';
    }
    if (lower.contains('waiter') || lower.contains('captain') || lower.contains('server')) {
      return 'waiter';
    }
    if (lower.contains('inventory') || lower.contains('stock')) {
      return 'inventory';
    }
    if (lower.contains('admin') || lower.contains('owner') || lower.contains('super')) {
      return 'admin';
    }
    if (lower.contains('crm') || lower.contains('customer')) {
      return 'crm';
    }
    if (lower.contains('pos') || lower.contains('billing') || lower.contains('counter') || lower.contains('cashier')) {
      return 'pos';
    }
    return lower.replaceAll(RegExp(r'[^a-z0-9]'), '_');
  }

  static Future<void> saveRememberedCredentials({
    required String roleName,
    required String userId,
    required String password,
    required bool rememberMe,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final roleKey = _normalizeRoleKey(roleName);

    // Purge any legacy global keys to guarantee 100% strict per-module isolation
    await prefs.remove('saved_login_last_user');
    await prefs.remove('saved_login_last_pass');
    await prefs.remove('saved_login_last_remember');

    if (rememberMe) {
      await prefs.setString('saved_login_user_$roleKey', userId.trim());
      await prefs.setString('saved_login_pass_$roleKey', password.trim());
      await prefs.setBool('saved_login_remember_$roleKey', true);
    } else {
      await prefs.remove('saved_login_user_$roleKey');
      await prefs.remove('saved_login_pass_$roleKey');
      await prefs.setBool('saved_login_remember_$roleKey', false);
    }
  }

  static Future<Map<String, dynamic>> getRememberedCredentials(String roleName) async {
    final prefs = await SharedPreferences.getInstance();
    final roleKey = _normalizeRoleKey(roleName);

    // Purge any legacy global keys to guarantee 100% strict per-module isolation
    await prefs.remove('saved_login_last_user');
    await prefs.remove('saved_login_last_pass');
    await prefs.remove('saved_login_last_remember');

    final isRemembered = prefs.getBool('saved_login_remember_$roleKey');
    if (isRemembered == true) {
      final user = prefs.getString('saved_login_user_$roleKey') ?? '';
      final pass = prefs.getString('saved_login_pass_$roleKey') ?? '';
      if (user.isNotEmpty || pass.isNotEmpty) {
        return {
          'userId': user,
          'password': pass,
          'rememberMe': true,
        };
      }
    }

    // STRICT ISOLATION: No fallback to other roles!
    return {
      'userId': '',
      'password': '',
      'rememberMe': false,
    };
  }

  static Future<void> clearRememberedCredentials(String roleName) async {
    final prefs = await SharedPreferences.getInstance();
    final roleKey = _normalizeRoleKey(roleName);
    await prefs.remove('saved_login_user_$roleKey');
    await prefs.remove('saved_login_pass_$roleKey');
    await prefs.remove('saved_login_remember_$roleKey');
    await prefs.remove('saved_login_last_user');
    await prefs.remove('saved_login_last_pass');
    await prefs.remove('saved_login_last_remember');
  }
}
