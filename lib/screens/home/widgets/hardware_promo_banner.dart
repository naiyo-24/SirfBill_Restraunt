import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'hardware_store_dialog.dart';

class HardwarePromoBanner extends StatelessWidget {
  final bool isDark;
  final bool isMobile;
  final bool isCompactHeight;

  const HardwarePromoBanner({
    super.key,
    required this.isDark,
    required this.isMobile,
    this.isCompactHeight = false,
  });

  Future<void> _openWhatsApp() async {
    final message = Uri.encodeComponent(
      'Hello SirfBill Hardware Team, I am interested in purchasing restaurant hardware (Printers/POS/Cash Drawers). Please share catalog and pricing.',
    );
    final nativeUri = Uri.parse('whatsapp://send?phone=918100463128&text=$message');
    final webUri = Uri.parse('https://wa.me/918100463128?text=$message');

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
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return LayoutBuilder(
      builder: (context, constraints) {
        final useMobileLayout = isMobile || constraints.maxWidth < 820;

        return Container(
          constraints: const BoxConstraints(maxWidth: 1560),
          margin: EdgeInsets.symmetric(horizontal: useMobileLayout ? 8 : 12),
          padding: EdgeInsets.symmetric(
            horizontal: useMobileLayout ? 14 : 20,
            vertical: useMobileLayout ? 10 : (isCompactHeight ? 10 : 14),
          ),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: useMobileLayout
              ? _buildMobileLayout(context, textColor, subtitleColor, borderColor)
              : _buildDesktopLayout(context, textColor, subtitleColor, borderColor),
        );
      },
    );
  }

  Widget _buildDesktopLayout(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF10B981).withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.print_rounded, color: Color(0xFF10B981), size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  Text(
                    'Need Restaurant POS Hardware?',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: const Text(
                      'PRE-CONFIGURED FOR SIRFBILL',
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                'Buy 80mm Thermal KOT Printers, Dual-Screen Touch POS Terminals, Cash Drawers & Waiter Handhelds with 1 Year Warranty & Free Setup.',
                style: TextStyle(fontSize: 12, color: subtitleColor),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _openWhatsApp,
          icon: const Icon(Icons.chat_rounded, size: 14),
          label: const Text('WhatsApp Inquiry'),
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF10B981),
            side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
        const SizedBox(width: 10),
        ElevatedButton.icon(
          onPressed: () => HardwareStoreDialog.show(context),
          icon: const Icon(Icons.shopping_bag_outlined, size: 16),
          label: const Text('Buy Hardware'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    Color textColor,
    Color subtitleColor,
    Color borderColor,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.print_rounded, color: Color(0xFF10B981), size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Need Restaurant Hardware?',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    'Printers, Touch Terminals & Cash Drawers',
                    style: TextStyle(fontSize: 10.5, color: subtitleColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _openWhatsApp,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF10B981),
                  side: BorderSide(color: const Color(0xFF10B981).withValues(alpha: 0.5)),
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('WhatsApp', style: TextStyle(fontSize: 11.5)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton(
                onPressed: () => HardwareStoreDialog.show(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: const Text('Buy Hardware', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
