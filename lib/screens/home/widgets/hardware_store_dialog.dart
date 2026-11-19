import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/hardware_item_model.dart';
import 'hardware_store_product_card.dart';

class HardwareStoreDialog extends StatefulWidget {
  const HardwareStoreDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const HardwareStoreDialog(),
    );
  }

  @override
  State<HardwareStoreDialog> createState() => _HardwareStoreDialogState();
}

class _HardwareStoreDialogState extends State<HardwareStoreDialog> {
  int _selectedCategoryIndex = 0;

  static const String supportPhone = '+918100463128';
  static const String supportPhoneDisplay = '+91 8100463128';

  Future<void> _openWhatsApp(String message) async {
    final encoded = Uri.encodeComponent(message);
    final nativeUri = Uri.parse('whatsapp://send?phone=918100463128&text=$encoded');
    final webUri = Uri.parse('https://wa.me/918100463128?text=$encoded');

    try {
      final launchedNative = await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      if (launchedNative) return;
    } catch (_) {}

    try {
      final launchedWeb = await launchUrl(webUri, mode: LaunchMode.externalApplication);
      if (launchedWeb) return;
    } catch (_) {}

    try {
      await launchUrl(webUri);
    } catch (e) {
      debugPrint('Could not launch WhatsApp: $e');
    }
  }

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

  void _inquireProduct(HardwareProductItem item) {
    _openWhatsApp(
      'Hello SirfBill Team, I want to inquire about purchasing: ${item.title} (${item.category}) for my restaurant.',
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

    const categories = ['All Products', 'Printers', 'POS Terminals', 'Handhelds', 'Cash Drawers', 'Scanners', 'Kitchen KDS'];

    final filteredProducts = _selectedCategoryIndex == 0
        ? kCertifiedHardwareProducts
        : kCertifiedHardwareProducts.where((p) => p.category == categories[_selectedCategoryIndex]).toList();

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
                    width: 44,
                    height: 44,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.asset(
                        'assets/icon.png',
                        fit: BoxFit.contain,
                      ),
                    ),
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
                            Image.asset(
                              isDark ? 'assets/LOGO_DM.png' : 'assets/LOGO.png',
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'HARDWARE STORE',
                                style: TextStyle(
                                  color: Color(0xFF10B981),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          'Tested & pre-configured hardware guaranteed to work out-of-the-box with SirfBill',
                          style: TextStyle(fontSize: 11.5, color: subtitleColor),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            // 2. Category Filter Tabs
            Container(
              height: 48,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: cardBg,
                border: Border(bottom: BorderSide(color: borderColor)),
              ),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedCategoryIndex == index;
                  return Center(
                    child: ChoiceChip(
                      label: Text(categories[index]),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _selectedCategoryIndex = index),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF334155)),
                      ),
                      selectedColor: const Color(0xFF10B981),
                      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      side: BorderSide(color: isSelected ? const Color(0xFF10B981) : borderColor),
                    ),
                  );
                },
              ),
            ),

            // 3. Products List / Grid View (Adaptive to mobile & desktop)
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 700;
                  if (!isWide) {
                    return ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      itemCount: filteredProducts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 14),
                      itemBuilder: (context, index) {
                        final item = filteredProducts[index];
                        return HardwareStoreProductCard(
                          item: item,
                          isDark: isDark,
                          cardBg: cardBg,
                          textColor: textColor,
                          subtitleColor: subtitleColor,
                          borderColor: borderColor,
                          onInquire: _inquireProduct,
                        );
                      },
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      mainAxisExtent: 265,
                    ),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final item = filteredProducts[index];
                      return HardwareStoreProductCard(
                        item: item,
                        isDark: isDark,
                        cardBg: cardBg,
                        textColor: textColor,
                        subtitleColor: subtitleColor,
                        borderColor: borderColor,
                        onInquire: _inquireProduct,
                      );
                    },
                  );
                },
              ),
            ),

            // 4. Contact & Order Action Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: LayoutBuilder(
                builder: (context, footerConstraints) {
                  final isCompact = footerConstraints.maxWidth < 620;
                  if (isCompact) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_outlined, size: 16, color: Color(0xFF10B981)),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '1 Year Warranty • Free Setup • Express Delivery',
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: subtitleColor),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _launchCall(supportPhone),
                                icon: const Icon(Icons.phone_rounded, size: 14),
                                label: const Text('Call Support', style: TextStyle(fontSize: 11)),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: textColor,
                                  side: BorderSide(color: borderColor),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _openWhatsApp(
                                  'Hello SirfBill Hardware Team, I would like to order POS Hardware for my restaurant.',
                                ),
                                icon: const Icon(Icons.chat_rounded, size: 15),
                                label: const Text('WhatsApp Order', style: TextStyle(fontSize: 11)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Icon(Icons.verified_outlined, size: 18, color: Color(0xFF10B981)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                '1 Year Warranty • Free Setup Assistance • Express Pan-India Delivery',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: subtitleColor),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OutlinedButton.icon(
                        onPressed: () => _launchCall(supportPhone),
                        icon: const Icon(Icons.phone_rounded, size: 15),
                        label: const Text('Call $supportPhoneDisplay'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: textColor,
                          side: BorderSide(color: borderColor),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: () => _openWhatsApp(
                          'Hello SirfBill Hardware Team, I would like to order POS Hardware for my restaurant.',
                        ),
                        icon: const Icon(Icons.chat_rounded, size: 16),
                        label: const Text('Order on WhatsApp'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          elevation: 0,
                        ),
                      ),
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
}
