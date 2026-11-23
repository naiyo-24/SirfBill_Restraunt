import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../../../../services/windows_auto_updater.dart';

export 'about_policy_card.dart';

class AboutFeatureCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String desc;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color? subtitleColor;

  const AboutFeatureCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.desc,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11.5,
              color: textColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            desc,
            style: TextStyle(
              fontSize: 9.5,
              color: subtitleColor,
              height: 1.25,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class AboutContactRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isLink;
  final VoidCallback? onTap;
  final Color textColor;
  final Color? subtitleColor;

  const AboutContactRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.isLink = false,
    this.onTap,
    required this.textColor,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);
    final linkColor = isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: subtitleColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isLink ? linkColor : textColor,
                      decoration: isLink ? TextDecoration.underline : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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

/// Gradient top hero banner with logo, version pill, and dismiss button.
class AboutHeroHeader extends StatelessWidget {
  final VoidCallback onClose;

  const AboutHeroHeader({super.key, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isPhone = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isPhone ? 18 : 24,
        vertical: isPhone ? 16 : 20,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF064E3B), Color(0xFF047857), Color(0xFF0D9488)]
              : const [Color(0xFF166534), Color(0xFF15803D), Color(0xFF22C55E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/icon.png',
                height: isPhone ? 40 : 46,
                width: isPhone ? 40 : 46,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.receipt_long_rounded,
                  color: Color(0xFF10B981),
                  size: 36,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Text(
                      'SirfBill',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isPhone ? 18 : 22,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 8),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (context, snapshot) {
                        final version = snapshot.hasData ? snapshot.data!.version : '1.0.51';
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'v$version',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text(
                  'Bill Karo, Befikar Raho',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: onClose,
            tooltip: 'Close',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(maxWidth: 32, maxHeight: 32),
          ),
        ],
      ),
    );
  }
}

/// Company identity card for Naiyo24 Pvt. Ltd.
class AboutCompanyCard extends StatelessWidget {
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color? subtitleColor;

  const AboutCompanyCard({
    super.key,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Container(
            height: 50,
            width: 50,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/naiyo24_logo.jpeg',
                fit: BoxFit.cover,
                errorBuilder: (ctx, err, stack) => const Center(
                  child: Text(
                    'NAIYO24',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                      fontSize: 9,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'NAIYO24 PVT. LTD.',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Empowering businesses with modern point-of-sale and digital automation platforms.',
                  style: TextStyle(
                    fontSize: 10.5,
                    color: subtitleColor,
                    height: 1.25,
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

/// Dialog bottom footer bar with update checker and copyright.
class AboutDialogFooter extends StatelessWidget {
  final Color borderColor;
  final Color? subtitleColor;
  final VoidCallback onClose;

  const AboutDialogFooter({
    super.key,
    required this.borderColor,
    required this.subtitleColor,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final btnColor = isDark ? const Color(0xFF10B981) : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              '© 2026 NAIYO24 PVT. LTD.',
              style: TextStyle(fontSize: 10.5, color: subtitleColor),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!kIsWeb && Platform.isWindows) ...[
                TextButton.icon(
                  icon: const Icon(Icons.system_update_rounded, size: 15),
                  label: const Text('Update', style: TextStyle(fontSize: 11)),
                  style: TextButton.styleFrom(
                    foregroundColor: btnColor,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final updateInfo = await WindowsAutoUpdater.checkForUpdate();
                    if (context.mounted) {
                      if (updateInfo != null) {
                        WindowsAutoUpdater.showUpdateDialog(context, updateInfo);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('You are using the latest version of SirfBill!'),
                            backgroundColor: btnColor,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 6),
              ],
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: btnColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                onPressed: onClose,
                child: const Text('Close', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
