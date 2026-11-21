import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';

/// Reusable Category Card for Desktop Menu Header
class MenuCategoryCard extends StatelessWidget {
  final MenuCategory category;
  final bool isSelected;
  final VoidCallback onTap;
  final ValueChanged<MenuCategory>? onEdit;
  final ValueChanged<MenuCategory>? onDelete;
  final bool isDark;

  const MenuCategoryCard({
    super.key,
    required this.category,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isAll = category.id == 'all';

    return Container(
      width: 96,
      height: 80,
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFF10B981)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF10B981)
              : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFF10B981).withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                )
              ]
            : null,
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: onTap,
              child: SizedBox.expand(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(category.iconEmoji, style: const TextStyle(fontSize: 22)),
                      const SizedBox(height: 5),
                      Text(
                        category.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF1E293B)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (!isAll && (onEdit != null || onDelete != null))
            Positioned(
              top: 4,
              right: 4,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (onEdit != null)
                    Tooltip(
                      message: 'Edit Category',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => onEdit?.call(category),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.edit_outlined,
                            size: 12,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFF3B82F6),
                          ),
                        ),
                      ),
                    ),
                  if (onDelete != null)
                    Tooltip(
                      message: 'Delete Category',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(4),
                        onTap: () => onDelete?.call(category),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: Icon(
                            Icons.close_rounded,
                            size: 12,
                            color: isSelected
                                ? Colors.white.withValues(alpha: 0.9)
                                : const Color(0xFFEF4444),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Reusable Add Category Button Card for Desktop Menu Header
class MenuAddCategoryCard extends StatelessWidget {
  final VoidCallback onTap;

  const MenuAddCategoryCard({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      height: 80,
      decoration: BoxDecoration(
        color: const Color(0xFF10B981).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF10B981),
          width: 1.2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_circle_outline_rounded, size: 22, color: Color(0xFF10B981)),
              SizedBox(height: 5),
              Text(
                '+ Category',
                maxLines: 1,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF10B981),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
