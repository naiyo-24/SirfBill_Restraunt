import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../services/auth_service.dart';
import '../../services/windows_auto_updater.dart';
import '../../services/app_session_manager.dart';
import 'widgets/role_login_feature_panel.dart';
import 'widgets/role_login_form_card.dart';
import '../home/widgets/hardware_store_dialog.dart';

class RoleLoginScreen extends ConsumerStatefulWidget {
  final String roleName;
  final Color themeColor;
  final String nextRoute;

  const RoleLoginScreen({
    super.key,
    required this.roleName,
    required this.themeColor,
    required this.nextRoute,
  });

  @override
  ConsumerState<RoleLoginScreen> createState() => _RoleLoginScreenState();
}

class _RoleLoginScreenState extends ConsumerState<RoleLoginScreen> {
  bool _isLoading = false;
  bool _isCheckingUpdate = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        WindowsAutoUpdater.checkAndShowUpdateIfAvailable(context);
      }
    });
  }

  Future<void> _manualCheckUpdate() async {
    setState(() => _isCheckingUpdate = true);
    try {
      await WindowsAutoUpdater.checkAndShowUpdateIfAvailable(
        context,
        showFeedbackWhenLatest: true,
      );
    } finally {
      if (mounted) setState(() => _isCheckingUpdate = false);
    }
  }

  Future<void> _login(String rawEmail, String rawPass) async {
    setState(() => _isLoading = true);

    try {
      final success = await AuthService.loginForModule(rawEmail, rawPass, widget.roleName);
      if (success && mounted) {
        AppSessionManager.invalidateProviders(ref: ref);
        context.go(widget.nextRoute);
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Login Failed', style: TextStyle(color: Colors.red)),
              ],
            ),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  'OK',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWeb = size.width > 900;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final shaderColor = isDark ? const Color(0xFF0F172A) : Colors.white;

    return Stack(
      children: [
        Positioned.fill(child: Container(color: scaffoldBg)),
        Positioned.fill(
          child: ShaderMask(
            shaderCallback: (rect) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [shaderColor, shaderColor.withValues(alpha: 0.2)],
              stops: const [0.4, 1.0],
            ).createShader(rect),
            blendMode: BlendMode.dstOut,
            child: Image.asset(
              'assets/back.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  Container(color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
            ),
          ),
        ),
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  scaffoldBg.withValues(alpha: 0.95),
                  scaffoldBg.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
        ),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: Column(
            children: [
              _buildTopBar(isWeb),
              Expanded(child: isWeb ? _buildWebLayout() : _buildMobileLayout()),
              if (isWeb) _buildWebFooter(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTopBar(bool isWeb) {
    return Container(
      color: widget.themeColor,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 4,
        bottom: 8,
        left: isWeb ? 24 : 12,
        right: isWeb ? 24 : 12,
      ),
      child: Row(
        children: [
          if (isWeb)
            TextButton.icon(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/dashboard');
                }
              },
              icon: const Icon(Icons.arrow_back, color: Colors.white, size: 18),
              label: const Text('Back', style: TextStyle(color: Colors.white)),
            )
          else
            IconButton(
              onPressed: () {
                if (Navigator.canPop(context)) {
                  Navigator.pop(context);
                } else {
                  context.go('/dashboard');
                }
              },
              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
              tooltip: 'Back',
            ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${widget.roleName} Login',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: isWeb ? 16 : 15),
              overflow: TextOverflow.ellipsis,
              textAlign: isWeb ? TextAlign.center : TextAlign.start,
            ),
          ),
          TextButton.icon(
            onPressed: () => HardwareStoreDialog.show(context),
            icon: const Icon(Icons.storefront_rounded, color: Colors.white, size: 16),
            label: Text(
              isWeb ? 'Buy Hardware' : 'Store',
              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
            ),
            style: TextButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
          if (!kIsWeb) ...[
            const SizedBox(width: 8),
            TextButton.icon(
              onPressed: _isCheckingUpdate ? null : _manualCheckUpdate,
              icon: _isCheckingUpdate
                  ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.system_update_alt_rounded, color: Colors.white, size: 16),
              label: Text(
                _isCheckingUpdate ? 'Checking...' : 'Check Updates',
                style: const TextStyle(color: Colors.white, fontSize: 13),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildWebLayout() {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 64.0, vertical: 16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  flex: 1,
                  child: RoleLoginFeaturePanel(
                    roleName: widget.roleName,
                    themeColor: widget.themeColor,
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: RoleLoginFormCard(
                        roleName: widget.roleName,
                        themeColor: widget.themeColor,
                        isLoading: _isLoading,
                        onLogin: _login,
                        onCheckUpdate: _manualCheckUpdate,
                        isCheckingUpdate: _isCheckingUpdate,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactHeight = constraints.maxHeight < 580 || isKeyboardOpen;

        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: SingleChildScrollView(
              physics: isCompactHeight ? const ClampingScrollPhysics() : const NeverScrollableScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: isCompactHeight ? 6.0 : 16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isCompactHeight) ...[
                    Image.asset(isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png', height: 46, fit: BoxFit.contain),
                    const SizedBox(height: 14),
                  ],
                  RoleLoginFormCard(
                    roleName: widget.roleName,
                    themeColor: widget.themeColor,
                    isLoading: _isLoading,
                    isMobile: true,
                    isCompactHeight: isCompactHeight,
                    onLogin: _login,
                    onCheckUpdate: _manualCheckUpdate,
                    isCheckingUpdate: _isCheckingUpdate,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWebFooter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            '© 2026 Sirfbill Restaurant • Naiyo24',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
          InkWell(
            onTap: () => HardwareStoreDialog.show(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.storefront_rounded, size: 14, color: Color(0xFF10B981)),
                SizedBox(width: 4),
                Text(
                  'Need Hardware? Buy Thermal Printers & KOT Displays',
                  style: TextStyle(
                    color: Color(0xFF10B981),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ],
            ),
          ),
          const Text(
            'Smart Restaurant POS & Operations',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
