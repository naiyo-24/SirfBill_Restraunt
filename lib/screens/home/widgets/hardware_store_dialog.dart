import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/hardware_product_model.dart';
import '../../../services/hardware/hardware_service.dart';
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

  void _showOrderDialog(HardwareProduct item) {
    int qty = 1;
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addressCtrl = TextEditingController();
    final cityCtrl = TextEditingController();
    final pincodeCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool isSubmitting = false;

    final inFormat = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDlgState) {
            final totalPrice = item.price * qty;

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Hardware Order / Inquiry', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                          ],
                        ),
                        const Divider(),
                        Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 2),
                        Text('SKU: ${item.sku} • Price: ${inFormat.format(item.price)} each', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, size: 20),
                                  onPressed: qty > 1 ? () => setDlgState(() => qty--) : null,
                                ),
                                Text('$qty', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.add_circle_outline, size: 20),
                                  onPressed: () => setDlgState(() => qty++),
                                ),
                              ],
                            ),
                            Text('Total: ${inFormat.format(totalPrice)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        TextFormField(
                          controller: nameCtrl,
                          decoration: const InputDecoration(labelText: 'Contact / Restaurant Name *', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: phoneCtrl,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(labelText: 'Contact Phone / WhatsApp *', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          validator: (v) => v == null || v.length < 10 ? 'Enter valid 10-digit number' : null,
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: addressCtrl,
                          decoration: const InputDecoration(labelText: 'Delivery Address *', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: cityCtrl,
                                decoration: const InputDecoration(labelText: 'City *', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: pincodeCtrl,
                                keyboardType: TextInputType.number,
                                decoration: const InputDecoration(labelText: 'Pincode *', contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                                validator: (v) => v == null || v.length < 6 ? '6-digit pincode' : null,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_circle_rounded, size: 18),
                            label: isSubmitting
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Confirm Order & Open WhatsApp'),
                            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 12)),
                            onPressed: isSubmitting
                                ? null
                                : () async {
                                    if (!formKey.currentState!.validate()) return;
                                    setDlgState(() => isSubmitting = true);

                                    try {
                                      final order = await HardwareService.createOrder(
                                        productId: item.id,
                                        quantity: qty,
                                        contactName: nameCtrl.text.trim(),
                                        contactPhone: phoneCtrl.text.trim(),
                                        shippingAddress: addressCtrl.text.trim(),
                                        city: cityCtrl.text.trim(),
                                        pincode: pincodeCtrl.text.trim(),
                                      );

                                      final orderNo = order?.orderNumber ?? 'HWO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                                      final msg =
                                          'Hello SirfBill Hardware Team! I have placed Order #$orderNo for:\n• ${item.name} (${item.sku})\n• Quantity: $qty\n• Total: ${inFormat.format(totalPrice)}\n• Delivery to: ${nameCtrl.text}, ${addressCtrl.text}, ${cityCtrl.text} - ${pincodeCtrl.text}\n• Phone: ${phoneCtrl.text}';

                                      if (ctx.mounted) Navigator.pop(ctx);
                                      await _openWhatsApp(msg);
                                    } catch (_) {
                                      final msg =
                                          'Hello SirfBill Hardware Team! I want to purchase:\n• ${item.name} (${item.sku})\n• Quantity: $qty\n• Name: ${nameCtrl.text}\n• Phone: ${phoneCtrl.text}\n• Address: ${addressCtrl.text}, ${cityCtrl.text} - ${pincodeCtrl.text}';
                                      if (ctx.mounted) Navigator.pop(ctx);
                                      await _openWhatsApp(msg);
                                    }
                                  },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
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
                        Row(
                          children: [
                            Text('SirfBill Certified POS Hardware', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: textColor)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: const Color(0xFF10B981).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(4)),
                              child: const Text('100% Plug & Play', style: TextStyle(color: Color(0xFF10B981), fontSize: 10, fontWeight: FontWeight.bold)),
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
                      ? const Center(child: Text('No hardware products available in this category'))
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(20)),
                border: Border(top: BorderSide(color: borderColor)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.headset_mic_rounded, color: Color(0xFF10B981), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Need urgent hardware consultation or custom bulk quote? Call $supportPhoneDisplay', style: TextStyle(fontSize: 11, color: subtitleColor)),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.phone, size: 14),
                    label: const Text('Call Support'),
                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF10B981), side: const BorderSide(color: Color(0xFF10B981))),
                    onPressed: () => _launchCall(supportPhone),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.chat_bubble_outline_rounded, size: 14),
                    label: const Text('WhatsApp Desk'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                    onPressed: () => _openWhatsApp('Hello SirfBill Hardware Desk, I need assistance choosing POS equipment for my restaurant.'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
