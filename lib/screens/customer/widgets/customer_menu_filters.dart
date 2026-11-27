import 'dart:async';
import 'package:flutter/material.dart';

class CustomerMenuFilters extends StatefulWidget {
  final List<String> categories;
  final String selectedCategory;
  final bool vegOnly;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onVegChanged;
  final ValueChanged<String> onCategorySelected;

  const CustomerMenuFilters({
    super.key,
    required this.categories,
    required this.selectedCategory,
    required this.vegOnly,
    required this.onSearchChanged,
    required this.onVegChanged,
    required this.onCategorySelected,
  });

  @override
  State<CustomerMenuFilters> createState() => _CustomerMenuFiltersState();
}

class _CustomerMenuFiltersState extends State<CustomerMenuFilters> {
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
          child: Row(
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    onChanged: (val) {
                      _debounce?.cancel();
                      _debounce = Timer(const Duration(milliseconds: 300), () {
                        if (mounted) widget.onSearchChanged(val.trim());
                      });
                    },
                    decoration: const InputDecoration(
                      hintText: 'Search biryani, kebabs, desserts...',
                      hintStyle: TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                      prefixIcon: Icon(Icons.search_rounded, size: 20, color: Color(0xFF059669)),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => widget.onVegChanged(!widget.vegOnly),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  height: 46,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: widget.vegOnly ? const Color(0xFFECFDF5) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: widget.vegOnly ? const Color(0xFF10B981) : const Color(0xFFE2E8F0),
                      width: widget.vegOnly ? 1.5 : 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFF16A34A), width: 1.5),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Center(
                          child: CircleAvatar(radius: 3.5, backgroundColor: Color(0xFF16A34A)),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Veg',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: widget.vegOnly ? const Color(0xFF059669) : const Color(0xFF475569),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 14),
            itemCount: widget.categories.length,
            itemBuilder: (context, idx) {
              final c = widget.categories[idx];
              final isSel = c == widget.selectedCategory;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GestureDetector(
                  onTap: () => widget.onCategorySelected(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                    decoration: BoxDecoration(
                      gradient: isSel
                          ? const LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF065F46)])
                          : null,
                      color: isSel ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSel ? Colors.transparent : const Color(0xFFE2E8F0),
                      ),
                      boxShadow: isSel
                          ? [
                              BoxShadow(
                                color: const Color(0xFF065F46).withValues(alpha: 0.25),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: Text(
                        c,
                        style: TextStyle(
                          color: isSel ? Colors.white : const Color(0xFF475569),
                          fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
