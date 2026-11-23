import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/hardware_product_model.dart';
import '../../../services/auth_service.dart';
import '../../../services/hardware/hardware_service.dart';
import 'hardware_order_inquiry_dialog.dart';
import 'hardware_store_product_card.dart';

class HardwareStoreDialog extends StatefulWidget {
  const HardwareStoreDialog({super.key});

  static Future<void> show(BuildContext context) async {
    final token = await AuthService.getToken();
    final isLoggedIn = token != null && token.trim().isNotEmpty;

    if (!context.mounted) return;

    if (!isLoggedIn) {
      await showLoginRequiredDialog(context);
      return;
    }

    return showDialog(
      context: context,
      builder: (ctx) => const HardwareStoreDialog(),
    );
  }

  static Future<void> showLoginRequiredDialog(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    bool isAlreadyOnLogin = false;
    try {
      final loc = GoRouterState.of(context).uri.toString();
      isAlreadyOnLogin = loc.contains('role_login');
    } catch (_) {}

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: const Color(0xFFF59E0B).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.lock_outline_rounded, color: Color(0xFFF59E0B), size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(child: Text('Login Required', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textColor))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Please log in to your restaurant account first before purchasing certified hardware.',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textColor, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Hardware orders and warranties must be linked directly to your restaurant outlet in the database.',
              style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.3),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () {
                Navigator.pop(ctx);
                _openWhatsAppDirect(
                  'Hello SirfBill Hardware Team! I want to purchase restaurant hardware (Printers/POS/Cash Drawers). Please assist me.',
                );
              },
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.chat_outlined, size: 16, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Don\'t have an account? Chat with Sales',
                        style: TextStyle(fontSize: 12, color: Color(0xFF10B981), fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: TextStyle(color: subtitleColor)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10B981),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              if (!isAlreadyOnLogin) {
                context.push('/role_login?roleName=Admin&nextRoute=/admin', extra: {
                  'roleName': 'Admin',
                  'themeColor': const Color(0xFF6366F1),
                  'nextRoute': '/admin',
                });
              }
            },
            child: Text(isAlreadyOnLogin ? 'Log In Below' : 'Go to Login'),
          ),
        ],
      ),
    );
  }

  static Future<void> _openWhatsAppDirect(String message) async {
    final encoded = Uri.encodeComponent(message);
    final nativeUri = Uri.parse('whatsapp://send?phone=918100463128&text=$encoded');
    final webUri = Uri.parse('https://wa.me/918100463128?text=$encoded');
    try {
      if (await launchUrl(nativeUri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    try {
      if (await launchUrl(webUri, mode: LaunchMode.externalApplication)) return;
    } catch (_) {}
    try {
      await launchUrl(webUri);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

  @override
  State<HardwareStoreDialog> createState() => _HardwareStoreDialogState();
}

class _HardwareStoreDialogState extends State<HardwareStoreDialog> {
  int _selectedCategoryIndex = 0;
  List<HardwareCategoryInfo> _categories = [];
  List<HardwareProduct> _products = [];
  bool _isLoading = true;

  static const String supportPhone = '+918100463128';
  static const String supportPhoneDisplay = '+91 8100463128';

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() => _isLoading = true);
    final cats = await HardwareService.fetchCategories();
    final prods = await HardwareService.fetchProducts();
    if (mounted) {
      final List<HardwareCategoryInfo> sanitized = [];
      final hasAll = cats.any((c) => c.key.toUpperCase() == 'ALL');
      if (!hasAll) {
        sanitized.add(HardwareCategoryInfo(
          key: 'ALL',
          name: 'All Hardware',
          deviceCount: prods.length,
          icon: 'storefront',
          description: 'All certified restaurant POS hardware & accessories',
        ));
      }
      sanitized.addAll(cats);

      setState(() {
        _categories = sanitized;
        _products = prods;
        _isLoading = false;
        _selectedCategoryIndex = 0;
      });
    }
  }

  Future<void> _openWhatsApp(String message) => HardwareStoreDialog._openWhatsAppDirect(message);

  Future<void> _launchCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(uri);
      } catch (e) {
        debugPrint('Could not launch call: $e');
      }
    }
  }

  Future<void> _showOrderDialog(HardwareProduct item) async {
    final token = await AuthService.getToken();
    if (token == null || token.trim().isEmpty) {
      if (mounted) {
        Navigator.pop(context);
        HardwareStoreDialog.showLoginRequiredDialog(context);
      }
      return;
    }
    if (!mounted) return;
    HardwareOrderInquiryDialog.show(
      context,
      item: item,
      onOpenWhatsApp: _openWhatsApp,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final dialogBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final selectedCategoryKey = _categories.isNotEmpty && _selectedCategoryIndex < _categories.length
        ? _categories[_selectedCategoryIndex].key
        : 'ALL';

    final filteredProducts = selectedCategoryKey.toUpperCase() == 'ALL'
        ? _products
        : _products.where((p) => p.category.toUpperCase() == selectedCategoryKey.toUpperCase()).toList();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 960, maxHeight: 720),
        child: Column(
          children: [
            // 1. Dialog Header with SirfBill Official Brand Logo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.storefront_rounded, color: Color(0xFF10B981), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              'SirfBill Certified POS Hardware',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: textColor),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '100% Plug & Play',
                                style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('12-month brand warranty • Free remote setup • Direct warehouse delivery across India', style: TextStyle(fontSize: 11, color: subtitleColor)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: subtitleColor),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // 2. Category Filter Pills
            if (_categories.isNotEmpty)
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(color: cardBg, border: Border(bottom: BorderSide(color: borderColor))),
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategoryIndex == index;
                    return Center(
                      child: ChoiceChip(
                        label: Text(cat.name),
                        selected: isSelected,
                        onSelected: (_) => setState(() => _selectedCategoryIndex = index),
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                        labelStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                        ),
                        side: BorderSide(color: isSelected ? const Color(0xFF10B981) : borderColor),
                      ),
                    );
                  },
                ),
              ),

            // 3. Products Grid View
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                  : filteredProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inventory_2_outlined, size: 48, color: subtitleColor),
                              const SizedBox(height: 12),
                              Text(
                                'No hardware products found in backend catalog',
                                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: textColor),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Products are loaded directly from the backend server database.',
                                style: TextStyle(fontSize: 12, color: subtitleColor),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _loadCatalog,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Refresh from Backend'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFF10B981),
                                  side: const BorderSide(color: Color(0xFF10B981)),
                                ),
                              ),
                            ],
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final isWide = constraints.maxWidth > 700;
                            return GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: isWide ? 2 : 1,
                                crossAxisSpacing: 14,
                                mainAxisSpacing: 14,
                                mainAxisExtent: 275,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                return HardwareStoreProductCard(
                                  product: filteredProducts[index],
                                  isDark: isDark,
                                  cardBg: cardBg,
                                  textColor: textColor,
                                  subtitleColor: subtitleColor,
                                  borderColor: borderColor,
                                  onInquire: _showOrderDialog,
                                );
                              },
                            );
                          },
                        ),
            ),

            // 4. Contact & Order Action Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: LayoutBuilder(
                builder: (context, footerBox) {
                  final isCompact = footerBox.maxWidth < 620;
                  final textPart = Row(
                    children: [
                      const Icon(Icons.headset_mic_rounded, color: Color(0xFF10B981), size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Need hardware advice or bulk quote? Call $supportPhoneDisplay',
                          style: TextStyle(fontSize: 11, color: subtitleColor),
                        ),
                      ),
                    ],
                  );

                  final buttonsPart = Row(
                    mainAxisSize: isCompact ? MainAxisSize.max : MainAxisSize.min,
                    children: [
                      isCompact
                          ? Expanded(child: _buildCallBtn())
                          : _buildCallBtn(),
                      const SizedBox(width: 8),
                      isCompact
                          ? Expanded(child: _buildWhatsAppBtn())
                          : _buildWhatsAppBtn(),
                    ],
                  );

                  if (isCompact) {
                    return Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        textPart,
                        const SizedBox(height: 8),
                        buttonsPart,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: textPart),
                      const SizedBox(width: 12),
                      buttonsPart,
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCallBtn() {
    return OutlinedButton.icon(
      icon: const Icon(Icons.phone, size: 14),
      label: const Text('Call Support', style: TextStyle(fontSize: 12)),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF10B981),
        side: const BorderSide(color: Color(0xFF10B981)),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: () => _launchCall(supportPhone),
    );
  }

  Widget _buildWhatsAppBtn() {
    return ElevatedButton.icon(
      icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
      label: const Text('WhatsApp Desk', style: TextStyle(fontSize: 12)),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF25D366),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      ),
      onPressed: () => _openWhatsApp('Hello SirfBill Hardware Desk, I need assistance choosing POS equipment for my restaurant.'),
    );
  }
}
