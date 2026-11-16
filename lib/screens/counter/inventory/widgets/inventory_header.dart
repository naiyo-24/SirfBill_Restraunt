import 'package:flutter/material.dart';

class InventoryHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget? trailing;
  final TextEditingController? searchController;
  final ValueChanged<String>? onSearchChanged;
  final String searchHint;
  final List<Widget>? actions;

  const InventoryHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.searchController,
    this.onSearchChanged,
    this.searchHint = 'Search...',
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          if (searchController != null || (actions != null && actions!.isNotEmpty)) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (searchController != null)
                  SizedBox(
                    width: 280,
                    height: 40,
                    child: TextField(
                      controller: searchController,
                      onChanged: onSearchChanged,
                      style: const TextStyle(fontSize: 13),
                      decoration: InputDecoration(
                        hintText: searchHint,
                        hintStyle: TextStyle(
                          fontSize: 13,
                          color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                        ),
                        prefixIcon: const Icon(Icons.search, size: 18),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        filled: true,
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5),
                        ),
                      ),
                    ),
                  ),
                if (actions != null) ...actions!,
              ],
            ),
          ],
        ],
      ),
    );
  }
}
