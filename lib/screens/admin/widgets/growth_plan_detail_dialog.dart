import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class GrowthPlanDetailDialog extends StatelessWidget {
  final String category;
  final Map<String, dynamic> plan;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;

  const GrowthPlanDetailDialog({
    super.key,
    required this.category,
    required this.plan,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
  });

  static void show(
    BuildContext context, {
    required String category,
    required Map<String, dynamic> plan,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
  }) {
    showDialog(
      context: context,
      builder: (_) => GrowthPlanDetailDialog(
        category: category,
        plan: plan,
        cardBg: cardBg,
        borderColor: borderColor,
        textColor: textColor,
        subtitleColor: subtitleColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final accent = Color(plan['color'] as int);
    final title = plan['title'].toString();
    final price = plan['price'].toString();
    final gst = (plan['gst'] ?? '').toString();
    final priceLabel = gst.isNotEmpty ? '$price $gst' : price;
    final tag = plan['tag'].toString();
    final features = (plan['features'] as List).cast<String>();
    final details = (plan['details'] ?? '').toString();

    return Dialog(
      backgroundColor: cardBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$category • $tag',
                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: accent),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: subtitleColor, size: 20),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(title, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: textColor)),
            const SizedBox(height: 4),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(price, style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: accent)),
                if (gst.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  Text(gst, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subtitleColor)),
                ],
              ],
            ),
            if (details.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(details, style: TextStyle(fontSize: 13, color: subtitleColor, height: 1.45)),
            ],
            const SizedBox(height: 16),
            Divider(height: 1, color: borderColor),
            const SizedBox(height: 14),
            Text('What’s Included', style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: textColor)),
            const SizedBox(height: 10),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded, size: 17, color: accent),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: TextStyle(fontSize: 13, color: textColor))),
                    ],
                  ),
                )),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      Navigator.pop(context);
                      final msg = Uri.encodeComponent(
                        'Hello SirfBill Team, I want to book $category - $title ($priceLabel) for my restaurant.',
                      );
                      await launchUrl(
                        Uri.parse('https://wa.me/916289171798?text=$msg'),
                        mode: LaunchMode.externalApplication,
                      );
                    },
                    icon: const Icon(Icons.chat_rounded, size: 17),
                    label: const Text('Book via WhatsApp', style: TextStyle(fontWeight: FontWeight.w800)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
