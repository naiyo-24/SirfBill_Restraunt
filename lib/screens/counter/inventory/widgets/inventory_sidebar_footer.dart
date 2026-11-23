import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../providers/zoom_provider.dart';
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
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
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

        // Screen Zoom Control (Desktop & Web only - hidden on phone screens)
        if (MediaQuery.sizeOf(context).width >= 650)
          AnimatedCrossFade(
          duration: const Duration(milliseconds: 200),
          crossFadeState: _isCollapsed ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: const SizedBox(height: 6),
          secondChild: Consumer(
            builder: (context, ref, _) {
              final zoom = ref.watch(zoomProvider);
              final pct = (zoom * 100).round();

              return Center(
                child: Container(
                  width: 236.0,
                  margin: const EdgeInsets.fromLTRB(10, 4, 10, 8),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: borderColor),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.zoom_in_rounded, size: 16, color: Color(0xFF3B82F6)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Zoom $pct%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                          overflow: TextOverflow.clip,
                          maxLines: 1,
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.remove_rounded, size: 14),
                        tooltip: 'Zoom Out (Ctrl -)',
                        onPressed: () => ref.read(zoomProvider.notifier).zoomOut(),
                      ),
                      InkWell(
                        onTap: () => ref.read(zoomProvider.notifier).resetZoom(),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          child: Text(
                            '100%',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: pct == 100 ? const Color(0xFF10B981) : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                      IconButton(
                        constraints: const BoxConstraints(maxWidth: 24, maxHeight: 24),
                        padding: EdgeInsets.zero,
                        icon: const Icon(Icons.add_rounded, size: 14),
                        tooltip: 'Zoom In (Ctrl +)',
                        onPressed: () => ref.read(zoomProvider.notifier).zoomIn(),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
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
