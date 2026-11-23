import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/windows_auto_updater.dart';
import '../../widgets/app_video_loader.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. On Windows desktop, check for updates first before navigating
    if (!kIsWeb && Platform.isWindows) {
      try {
        final updateInfo = await WindowsAutoUpdater.checkForUpdate();
        if (updateInfo != null && mounted) {
          // Show the update popup immediately on top of the splash screen
          await WindowsAutoUpdater.showUpdateDialog(context, updateInfo);
        }
      } catch (e) {
        debugPrint('[SplashScreen] Auto update check failed: $e');
      }
    }

    // 2. Minimum splash delay for smooth video loader animation experience
    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;

    // 3. Navigate forward based on login status and role
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('access_token');
      final isLoggedIn = token != null && token.isNotEmpty;

      if (isLoggedIn && mounted) {
        final role = (prefs.getString('user_role') ?? '').trim().toUpperCase();
        final loginModule = (prefs.getString('role_login_name') ?? '').trim().toUpperCase();
        final stationKey = (prefs.getString('station_module_key') ?? '').trim().toLowerCase();
        final isCrm = role == 'CRM' || role == 'REPORTS' || stationKey == 'crm' || loginModule.contains('CRM') || loginModule.contains('REPORT');

        if (role == 'ADMIN' || role == 'OWNER' || role == 'SUPER_ADMIN') {
          context.go('/admin');
          return;
        } else if (role == 'KITCHEN' || role == 'CHEF' || role == 'KDS' || loginModule.contains('KITCHEN')) {
          context.go('/kitchen');
          return;
        } else if (role == 'WAITER' || role == 'CAPTAIN' || role == 'SERVER' || loginModule.contains('WAITER')) {
          context.go('/waiter');
          return;
        } else if (role == 'INVENTORY' || role == 'STOCK' || loginModule.contains('INVENTORY')) {
          context.go('/inventory');
          return;
        } else if (isCrm) {
          context.go('/crm');
          return;
        }
        context.go('/counter/billing');
        return;
      }
    } catch (e) {
      debugPrint('[SplashScreen] Navigation check error: $e');
    }

    if (mounted) {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            // Responsive sizing for the animated splash video
            final isLandscapeCompact = h < 450;
            final isSmallMobile = w < 480;
            final isTablet = w >= 600 && w < 1024;
            final isDesktop = w >= 1024;

            final double videoSize;

            if (isLandscapeCompact) {
              videoSize = (h * 0.72).clamp(180.0, 260.0);
            } else if (isSmallMobile) {
              videoSize = (w * 0.82).clamp(220.0, 320.0);
            } else if (isTablet) {
              videoSize = (w * 0.45).clamp(280.0, 380.0);
            } else if (isDesktop) {
              // Desktop .exe and Web
              videoSize = (h * 0.52).clamp(320.0, 440.0);
            } else {
              videoSize = 300.0;
            }

            return Center(
              child: SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: AppVideoLoader(
                      size: videoSize,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
