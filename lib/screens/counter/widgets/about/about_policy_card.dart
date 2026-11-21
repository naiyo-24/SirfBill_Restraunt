import 'package:flutter/material.dart';
import 'about_us_policies.dart';

/// Legal policy preview button & dialog launcher.
class AboutLegalComplianceCard extends StatelessWidget {
  final Color cardBg;
  final Color borderColor;

  const AboutLegalComplianceCard({
    super.key,
    required this.cardBg,
    required this.borderColor,
  });

  static void showPolicyDialog(BuildContext context, {required String title, required String content}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
        title: Row(
          children: [
            Icon(
              Icons.description_rounded,
              color: isDark ? const Color(0xFF34D399) : const Color(0xFF15803D),
              size: 22,
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Text(
              content,
              style: TextStyle(
                fontSize: 13,
                height: 1.6,
                color: isDark ? Colors.grey[300] : const Color(0xFF334155),
              ),
            ),
          ),
        ),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isDark ? const Color(0xFF10B981) : const Color(0xFF15803D),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentGreen = isDark ? const Color(0xFF34D399) : const Color(0xFF15803D);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showPolicyDialog(
                context,
                title: 'Privacy Policy',
                content: AboutUsPolicies.privacyPolicy,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined, size: 16, color: accentGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Privacy Policy',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(height: 20, width: 1, color: borderColor),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => showPolicyDialog(
                context,
                title: 'Terms & Conditions',
                content: AboutUsPolicies.termsAndConditions,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Icon(Icons.gavel_rounded, size: 16, color: accentGreen),
                    const SizedBox(width: 8),
                    Text(
                      'Terms & Conditions',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: accentGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
