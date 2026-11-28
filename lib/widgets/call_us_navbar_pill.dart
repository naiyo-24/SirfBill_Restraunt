import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Reusable top-navbar pill displaying the SirfBill support phone number
/// (`Call Us : +91 6289171798`) that opens the phone dialer when tapped.
class CallUsNavbarPill extends StatelessWidget {
  final bool compact;
  final double height;

  const CallUsNavbarPill({
    super.key,
    this.compact = false,
    this.height = 38,
  });

  static const String displayText = 'Call Us : +91 6289171798';
  static const String telUri = 'tel:+916289171798';

  Future<void> _launchDialer() async {
    await launchUrl(
      Uri.parse(telUri),
      mode: LaunchMode.externalApplication,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF0F172A)
        : const Color(0xFFF0F9FF);
    final borderColor = isDark
        ? const Color(0xFF0284C7).withValues(alpha: 0.5)
        : const Color(0xFF0EA5E9).withValues(alpha: 0.35);
    final fgColor = isDark
        ? const Color(0xFF38BDF8)
        : const Color(0xFF0369A1);

    return Tooltip(
      message: displayText,
      child: InkWell(
        onTap: _launchDialer,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 11),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: borderColor, width: 1.1),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.call_rounded, size: 15, color: fgColor),
              if (!compact) ...[
                const SizedBox(width: 6),
                Text(
                  displayText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: fgColor,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
