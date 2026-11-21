import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../models/restaurant_pos_models.dart';
import 'manage_categories_dialog.dart';
import 'menu_status_filter_bar.dart';

class MenuFilterHeader extends StatefulWidget {
  final int totalCount;
  final int availableCount;
  final int outOfStockCount;
  final List<MenuCategory> categories;
  final String selectedCategoryId;
  final bool? availabilityFilter;
  final ValueChanged<String> onSelectCategory;
  final ValueChanged<bool?> onSelectAvailability;
  final ValueChanged<String> onSearch;
  final VoidCallback onAddDish;
  final VoidCallback? onBulkUpload;
  final VoidCallback? onAddCategory;
  final ValueChanged<MenuCategory>? onEditCategory;
  final ValueChanged<MenuCategory>? onDeleteCategory;
  final VoidCallback? onRefresh;

  const MenuFilterHeader({
    super.key,
    required this.totalCount,
    required this.availableCount,
    required this.outOfStockCount,
    required this.categories,
    required this.selectedCategoryId,
    required this.availabilityFilter,
    required this.onSelectCategory,
    required this.onSelectAvailability,
    required this.onSearch,
    required this.onAddDish,
    this.onBulkUpload,
    this.onAddCategory,
    this.onEditCategory,
    this.onDeleteCategory,
    this.onRefresh,
  });

  @override
  State<MenuFilterHeader> createState() => _MenuFilterHeaderState();
}

class _MenuFilterHeaderState extends State<MenuFilterHeader> {
  Timer? _searchDebounce;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      widget.onSearch(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final isPhone = MediaQuery.of(context).size.width < 650;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 12 : 16,
        vertical: isPhone ? 10 : 12,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        border: Border(bottom: BorderSide(color: borderColor)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Title, Search, and Add Dish CTA
          LayoutBuilder(
            builder: (context, constraints) {
              final isPhoneView = constraints.maxWidth < 650;
              final isCompact = constraints.maxWidth < 850;

              Widget buildSearchWidget({bool fullWidth = false}) {
                return SizedBox(
                  width: fullWidth ? double.infinity : (isCompact ? 130 : 200),
                  height: 36,
                  child: TextField(
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 12),
                    decoration: InputDecoration(
                      isDense: true,
                      prefixIcon: const Icon(Icons.search_rounded, size: 16, color: Color(0xFF94A3B8)),
                      hintText: 'Search dishes...',
                      hintStyle: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8)),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      contentPadding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide.none),
                    ),
                  ),
                );
              }

              final refreshButton = IconButton(
                onPressed: widget.onRefresh,
                tooltip: 'Refresh Menu from Backend',
                constraints: const BoxConstraints(maxWidth: 34, maxHeight: 34),
                icon: const Icon(Icons.refresh_rounded, size: 18, color: Color(0xFF10B981)),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  padding: const EdgeInsets.all(7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              );

              final categoriesButton = OutlinedButton.icon(
                onPressed: () => _showManageCategoriesModal(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFF2563EB)),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(0, 34),
                ),
                icon: const Icon(Icons.tune_rounded, size: 15),
                label: Text(
                  isPhoneView ? 'Categories' : (isCompact ? 'Categories' : 'Manage Categories'),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              );

              final bulkUploadButton = OutlinedButton.icon(
                onPressed: widget.onBulkUpload,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: const BorderSide(color: Color(0xFF10B981)),
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  minimumSize: const Size(0, 34),
                ),
                icon: const Icon(Icons.table_view_rounded, size: 15),
                label: Text(
                  isPhoneView ? 'Bulk' : (isCompact ? 'Bulk' : 'Bulk Upload'),
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                ),
              );

              final addDishButton = ElevatedButton.icon(
                onPressed: widget.onAddDish,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                  minimumSize: const Size(0, 34),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text(
                  isPhoneView ? 'Add' : (isCompact ? 'Add' : 'Add Food Item'),
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              );

              if (isPhoneView) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF10B981), size: 20),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'Menu & Catalog',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (widget.onRefresh != null) ...[
                          refreshButton,
                          const SizedBox(width: 6),
                        ],
                        categoriesButton,
                        const SizedBox(width: 6),
                        addDishButton,
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: buildSearchWidget(fullWidth: true)),
                        if (widget.onBulkUpload != null) ...[
                          const SizedBox(width: 8),
                          bulkUploadButton,
                        ],
                      ],
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  const Icon(Icons.restaurant_menu_rounded, color: Color(0xFF10B981), size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Menu & Catalog Management',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  buildSearchWidget(fullWidth: false),
                  const SizedBox(width: 8),
                  if (widget.onRefresh != null) ...[
                    refreshButton,
                    const SizedBox(width: 8),
                  ],
                  categoriesButton,
                  const SizedBox(width: 8),
                  if (widget.onBulkUpload != null) ...[
                    bulkUploadButton,
                    const SizedBox(width: 8),
                  ],
                  addDishButton,
                ],
              );
            },
          ),
          const SizedBox(height: 10),

          // Bottom Filter Row: Responsive Category & Stock Status Matrix
          MenuStatusFilterBar(
            totalCount: widget.totalCount,
            availableCount: widget.availableCount,
            outOfStockCount: widget.outOfStockCount,
            categories: widget.categories,
            selectedCategoryId: widget.selectedCategoryId,
            availabilityFilter: widget.availabilityFilter,
            onSelectCategory: widget.onSelectCategory,
            onSelectAvailability: widget.onSelectAvailability,
            onAddCategory: widget.onAddCategory,
            onEditCategory: widget.onEditCategory,
            onDeleteCategory: widget.onDeleteCategory,
            isDark: isDark,
            borderColor: borderColor,
          ),
        ],
      ),
    );
  }

  void _showManageCategoriesModal(BuildContext context) {
    ManageCategoriesDialog.show(
      context: context,
      categories: widget.categories,
      onAddCategory: widget.onAddCategory,
      onEditCategory: widget.onEditCategory,
      onDeleteCategory: widget.onDeleteCategory,
    );
  }
}
