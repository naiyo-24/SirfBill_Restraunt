import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../providers/theme_provider.dart';
import '../../../../providers/zoom_provider.dart';
import '../../widgets/about/about_us_dialog.dart';

class InventorySidebarFooter extends ConsumerWidget {
  final bool isCollapsed;
  final VoidCallback? onToggleCollapse;
  final VoidCallback onLogout;

  const InventorySidebarFooter({
    super.key,
    this.isCollapsed = false,
    this.onToggleCollapse,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Dark / Light Mode Toggle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: InkWell(
            onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Icon(
                    isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                    size: 20,
                    color: subtitleColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isDark ? 'Light Mode' : 'Dark Mode',
                      style: TextStyle(fontSize: 13, color: subtitleColor),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Logout
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          child: InkWell(
            onTap: onLogout,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: const Row(
                children: [
                  Icon(Icons.logout_rounded, size: 20, color: Colors.red),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.red,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 6),

        // About SirfBill Card
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => AboutUsDialog.show(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor.withValues(alpha: 0.8)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded, color: Color(0xFF22C55E), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'About SirfBill',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 11.5,
                            color: textColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Company & Support Info',
                          style: TextStyle(
                            fontSize: 9.5,
                            color: subtitleColor,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.chevron_right, size: 16, color: subtitleColor),
                ],
              ),
            ),
          ),
        ),

        // Screen Zoom Control
        Consumer(
          builder: (context, ref, _) {
            final zoom = ref.watch(zoomProvider);
            final pct = (zoom * 100).round();

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Container(
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
                        overflow: TextOverflow.ellipsis,
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

        const SizedBox(height: 10),
      ],
    );
  }
}
