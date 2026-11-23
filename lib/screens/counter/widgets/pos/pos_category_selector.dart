import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

class PosCategorySelector extends StatefulWidget {
  final String activeCategoryId;
  final ValueChanged<String> onSelectCategory;
  final List<MenuCategory>? categories;

  const PosCategorySelector({
    super.key,
    required this.activeCategoryId,
    required this.onSelectCategory,
    this.categories,
  });

  @override
  State<PosCategorySelector> createState() => _PosCategorySelectorState();
}

class _PosCategorySelectorState extends State<PosCategorySelector> {
  final ScrollController _scrollController = ScrollController();

  static const List<MenuCategory> _emptyList = [
    MenuCategory(id: 'all', name: 'All Items', iconEmoji: '🍱'),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final list = (widget.categories != null && widget.categories!.isNotEmpty) ? widget.categories! : _emptyList;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 700;

    return Container(
      height: isMobile ? 46 : 56,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: list.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = list[index];
          final isSelected = cat.id == widget.activeCategoryId;

          return InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => widget.onSelectCategory(cat.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 14 : 16,
                vertical: isMobile ? 6 : 8,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFF10B981)
                    : (isDark ? const Color(0xFF1E293B) : Colors.white),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF10B981)
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: const Color(0xFF10B981).withValues(alpha: 0.28),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 1),
                        ),
                      ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(cat.iconEmoji, style: TextStyle(fontSize: isMobile ? 16 : 18)),
                  const SizedBox(width: 6),
                  Text(
                    cat.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: isMobile ? 12.5 : 13.5,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white : const Color(0xFF334155)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
