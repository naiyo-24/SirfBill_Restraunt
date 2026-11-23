import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/theme_provider.dart';
import '../../../home/widgets/hardware_store_dialog.dart';
import '../../widgets/about/about_us_dialog.dart';

class InventorySidebarFooter extends ConsumerWidget {
  final bool? isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback onLogout;

  const InventorySidebarFooter({
    super.key,
    this.isCollapsed = false,
    this.onToggleCollapse,
    required this.onLogout,
  });

  bool get _isCollapsed => isCollapsed == true;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Dark / Light Mode Toggle
        _buildFooterItem(
          tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
          onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
          icon: Icon(
            isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            size: 20,
            color: subtitleColor,
          ),
          label: isDark ? 'Light Mode' : 'Dark Mode',
          labelColor: subtitleColor,
        ),

        // Logout
        _buildFooterItem(
          tooltip: 'Logout',
          onTap: onLogout,
          icon: const Icon(Icons.logout_rounded, size: 20, color: Colors.red),
          label: 'Logout',
          labelColor: Colors.red,
        ),

        // Buy Hardware
        _buildFooterItem(
          tooltip: 'Buy Hardware Products',
          onTap: () => HardwareStoreDialog.show(context),
          icon: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 20),
          label: 'Buy Hardware',
          labelColor: textColor,
        ),

        // About SirfBill
        _buildFooterItem(
          tooltip: 'About SirfBill',
          onTap: () => AboutUsDialog.show(context),
          icon: const Icon(Icons.info_outline_rounded, color: Color(0xFF22C55E), size: 20),
          label: 'About SirfBill',
          labelColor: textColor,
        ),

      ],
    );
  }

  Widget _buildFooterItem({
    required String tooltip,
    required VoidCallback onTap,
    required Widget icon,
    required String label,
    required Color labelColor,
  }) {
    final item = Center(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.fastOutSlowIn,
        width: _isCollapsed ? 48.0 : 236.0,
        height: 38,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: ClipRect(
              child: OverflowBox(
                minWidth: 0,
                maxWidth: 236,
                alignment: Alignment.centerLeft,
                child: SizedBox(
                  width: 236,
                  height: 38,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 46,
                        child: Center(child: icon),
                      ),
                      Expanded(
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 180),
                          opacity: _isCollapsed ? 0.0 : 1.0,
                          child: Text(
                            label,
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: labelColor,
                            ),
                            overflow: TextOverflow.clip,
                            maxLines: 1,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (_isCollapsed) {
      return Tooltip(
        message: tooltip,
        waitDuration: const Duration(milliseconds: 150),
        child: item,
      );
    }
    return item;
  }
}
