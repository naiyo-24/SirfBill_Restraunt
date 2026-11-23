import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'about_widgets.dart';

class AboutUsDialog extends StatelessWidget {
  const AboutUsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const AboutUsDialog(),
    );
  }

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched) {
        final fallbackLaunched = await launchUrl(uri);
        if (!fallbackLaunched) {
          // ignore: use_build_context_synchronously
          _handleFallback(context, url);
        }
      }
    } catch (_) {
      // ignore: use_build_context_synchronously
      _handleFallback(context, url);
    }
  }

  void _handleFallback(BuildContext context, String url) {
    if (url.startsWith('mailto:')) {
      final email = url.replaceFirst('mailto:', '');
      Clipboard.setData(ClipboardData(text: email));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Email copied to clipboard: $email')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } else if (url.startsWith('tel:')) {
      final phone = url.replaceFirst('tel:', '');
      Clipboard.setData(ClipboardData(text: phone));
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.copy_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(child: Text('Phone copied to clipboard: $phone')),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    final screenSize = MediaQuery.of(context).size;
    final isPhone = screenSize.width < 600;
    final dialogWidth = isPhone ? screenSize.width - 24 : 540.0;
    final dialogHeight = isPhone ? (screenSize.height * 0.85).clamp(380.0, 660.0) : 660.0;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
      clipBehavior: Clip.antiAlias,
      insetPadding: EdgeInsets.symmetric(horizontal: isPhone ? 12 : 24, vertical: isPhone ? 16 : 24),
      child: SizedBox(
        width: dialogWidth,
        height: dialogHeight,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Header Hero Banner
            AboutHeroHeader(onClose: () => Navigator.pop(context)),

            // 2. Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(
                  horizontal: isPhone ? 16 : 24,
                  vertical: isPhone ? 14 : 20,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DEVELOPED & OPERATED BY',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Organization Card
                    AboutCompanyCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                      textColor: textColor,
                      subtitleColor: subtitleColor,
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'KEY SYSTEM HIGHLIGHTS',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Feature highlights grid (clean 3-card strip)
                    Row(
                      children: [
                        Expanded(
                          child: AboutFeatureCard(
                            icon: Icons.cloud_done_rounded,
                            iconColor: const Color(0xFF0284C7),
                            title: 'Cloud POS',
                            desc: 'Live sync & cloud backup',
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AboutFeatureCard(
                            icon: Icons.print_rounded,
                            iconColor: const Color(0xFF2563EB),
                            title: 'Universal Print',
                            desc: 'Thermal 58/80 & A4',
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: AboutFeatureCard(
                            icon: Icons.shield_rounded,
                            iconColor: const Color(0xFF059669),
                            title: 'GST Ready',
                            desc: 'Instant tax & HSN',
                            cardBg: cardBg,
                            borderColor: borderColor,
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'OFFICIAL CONTACT & SUPPORT',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Support channels
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Column(
                        children: [
                          AboutContactRow(
                            icon: Icons.business_rounded,
                            label: 'Organization',
                            value: 'NAIYO24 PVT. LTD.',
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 12, color: borderColor),
                          AboutContactRow(
                            icon: Icons.language_rounded,
                            label: 'Website',
                            value: 'www.naiyo24.com',
                            isLink: true,
                            onTap: () => _launchUrl(context, 'https://www.naiyo24.com'),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 12, color: borderColor),
                          AboutContactRow(
                            icon: Icons.email_rounded,
                            label: 'Support Email',
                            value: 'services.naiyo@gmail.com',
                            isLink: true,
                            onTap: () => _launchUrl(context, 'mailto:services.naiyo@gmail.com'),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                          Divider(height: 12, color: borderColor),
                          AboutContactRow(
                            icon: Icons.headset_mic_rounded,
                            label: 'Customer Support',
                            value: '+91 8100463128',
                            isLink: true,
                            onTap: () => _launchUrl(context, 'tel:+918100463128'),
                            textColor: textColor,
                            subtitleColor: subtitleColor,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    Text(
                      'LEGAL & COMPLIANCE',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: subtitleColor,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Privacy policy and Terms row
                    AboutLegalComplianceCard(
                      cardBg: cardBg,
                      borderColor: borderColor,
                    ),
                  ],
                ),
              ),
            ),

            // 3. Footer with update checker & close
            AboutDialogFooter(
              borderColor: borderColor,
              subtitleColor: subtitleColor,
              onClose: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}
