import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/hardware_product_model.dart';
import '../../../services/hardware/hardware_service.dart';
import '../../home/widgets/hardware_order_inquiry_dialog.dart';
import '../../home/widgets/hardware_store_product_card.dart';
import 'admin_hardware_category_filter_bar.dart';
import 'admin_hardware_hero_banner.dart';

/// Modular, premium Admin Panel tab for the Certified POS Hardware Store.
class AdminHardwareStoreTab extends StatefulWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;

  const AdminHardwareStoreTab({
    super.key,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  State<AdminHardwareStoreTab> createState() => _AdminHardwareStoreTabState();
}

class _AdminHardwareStoreTabState extends State<AdminHardwareStoreTab> {
  List<HardwareProduct> _allProducts = [];
  String _selectedCategory = 'ALL';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadHardware();
  }

  Future<void> _loadHardware() async {
    try {
      final items = await HardwareService.fetchProducts();
      if (mounted) {
        setState(() {
          _allProducts = items;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<String> _extractCategories() {
    final set = <String>{'ALL'};
    for (final p in _allProducts) {
      if (p.category.isNotEmpty) set.add(p.category.toUpperCase());
    }
    return set.toList();
  }

  List<HardwareProduct> get _filteredProducts {
    if (_selectedCategory == 'ALL') return _allProducts;
    return _allProducts
        .where((p) => p.category.toUpperCase() == _selectedCategory.toUpperCase())
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final categories = _extractCategories();
    final products = _filteredProducts;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Executive Hero Banner Component
          AdminHardwareHeroBanner(totalCount: _allProducts.length),
          const SizedBox(height: 22),

          // 2. Interactive Category Filter Bar Component
          if (!_loading && categories.length > 1) ...[
            AdminHardwareCategoryFilterBar(
              categories: categories,
              selectedCategory: _selectedCategory,
              onSelectCategory: (cat) => setState(() => _selectedCategory = cat),
              isDark: widget.isDark,
            ),
            const SizedBox(height: 18),
          ],

          // 3. Grid View or States
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 48),
              child: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
            )
          else if (products.isEmpty)
            _buildEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final cols = constraints.maxWidth > 1050 ? 3 : (constraints.maxWidth > 650 ? 2 : 1);
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: cols,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    mainAxisExtent: 428,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, idx) => HardwareStoreProductCard(
                    product: products[idx],
                    isDark: widget.isDark,
                    cardBg: widget.cardBg,
                    textColor: widget.textColor,
                    subtitleColor: widget.subtitleColor,
                    borderColor: widget.borderColor,
                    onInquire: (item) => HardwareOrderInquiryDialog.show(
                      context,
                      item: item,
                      onOpenWhatsApp: (msg) async {
                        await launchUrl(
                          Uri.parse('https://wa.me/918100463128?text=${Uri.encodeComponent(msg)}'),
                          mode: LaunchMode.externalApplication,
                        );
                      },
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: widget.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: widget.borderColor),
      ),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 36, color: widget.subtitleColor),
          const SizedBox(height: 10),
          Text(
            'No hardware products found in this category.',
            style: TextStyle(fontWeight: FontWeight.bold, color: widget.textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Select "All Hardware" or check other categories.',
            style: TextStyle(fontSize: 12, color: widget.subtitleColor),
          ),
        ],
      ),
    );
  }
}
