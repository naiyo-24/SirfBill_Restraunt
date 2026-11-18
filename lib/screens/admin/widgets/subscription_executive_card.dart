import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../config/api_constants.dart';
import '../models/subscription_plan_models.dart';

class SubscriptionExecutiveCard extends StatelessWidget {
  final SubscriptionStatusModel status;
  final SubscriptionPlanItem currentPlan;
  final List<SubscriptionInvoiceItem> invoices;
  final bool isDark;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final VoidCallback onRenew;

  const SubscriptionExecutiveCard({
    super.key,
    required this.status,
    required this.currentPlan,
    required this.invoices,
    required this.isDark,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.onRenew,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status.isActive && status.daysRemaining > 0;
    final isTrial = status.status == 'TRIAL';

    final accent = isTrial
        ? const Color(0xFFF59E0B)
        : (isActive ? const Color(0xFF10B981) : const Color(0xFFF43F5E));

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: accent,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 800;
                final isMobile = constraints.maxWidth < 550;

                final leftInfo = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isTrial
                                    ? Icons.hourglass_top_rounded
                                    : (isActive ? Icons.verified_rounded : Icons.info_outline_rounded),
                                size: 12,
                                color: accent,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isTrial
                                    ? 'TRIAL LICENSE (${status.daysRemaining} DAYS REMAINING)'
                                    : (isActive
                                        ? 'ACTIVE RESTAURANT LICENSE (${status.daysRemaining} DAYS REMAINING)'
                                        : 'SUBSCRIPTION RENEWAL DUE • 0 DAYS REMAINING'),
                                style: TextStyle(
                                  color: accent,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (status.invoiceNumber != null || invoices.isNotEmpty)
                          InkWell(
                            onTap: () {
                              final invNum = status.invoiceNumber ?? (invoices.isNotEmpty ? invoices.first.invoiceId : null);
                              if (invNum != null) {
                                launchUrl(Uri.parse('${ApiConstants.baseUrl}/api/subscriptions/invoices/$invNum/view'), mode: LaunchMode.externalApplication);
                              }
                            },
                            borderRadius: BorderRadius.circular(6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFF3395FF).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.receipt_long_rounded, size: 11, color: Color(0xFF3395FF)),
                                  const SizedBox(width: 4),
                                  Text(
                                    status.invoiceNumber ?? (invoices.isNotEmpty ? invoices.first.invoiceId : 'INV-SUB-PRO'),
                                    style: const TextStyle(fontSize: 10.5, color: Color(0xFF3395FF), fontWeight: FontWeight.bold, fontFamily: 'monospace'),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          status.planName,
                          style: TextStyle(fontSize: isMobile ? 17 : 19, fontWeight: FontWeight.w900, color: textColor, letterSpacing: -0.3),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(color: accent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(
                            '₹${status.price.toStringAsFixed(0)} (${status.billingCycle})',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: accent),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      isActive
                          ? 'Valid until ${status.expiresAt?.toString().split(" ")[0] ?? "Next Billing Cycle"} · Full POS Billing, Live KDS, Recipe BOM & Stock Audit'
                          : 'Select any plan tier below to renew or upgrade your restaurant license with instant Razorpay checkout.',
                      style: TextStyle(fontSize: 11.5, color: subtitleColor, fontWeight: FontWeight.w500),
                    ),
                  ],
                );

                final actions = isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 15, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Current Plan Active (${status.daysRemaining}d)',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: onRenew,
                              icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF3395FF)),
                              label: Text(
                                'Renew Plan (₹${status.price.toStringAsFixed(0)})',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C2340),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: Color(0xFF3395FF), width: 1.2),
                              ),
                            ),
                          if (invoices.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () {
                                final uri = Uri.parse(invoices.first.getViewUrl(ApiConstants.baseUrl));
                                launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF10B981)),
                              label: const Text('Latest Tax Invoice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: BorderSide(color: borderColor),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                          ],
                        ],
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (isActive)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981).withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle_rounded, size: 14, color: Color(0xFF10B981)),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Current Plan Active (${status.daysRemaining}d)',
                                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: Color(0xFF10B981)),
                                  ),
                                ],
                              ),
                            )
                          else
                            ElevatedButton.icon(
                              onPressed: onRenew,
                              icon: const Icon(Icons.bolt_rounded, size: 16, color: Color(0xFF3395FF)),
                              label: Text(
                                'Renew Plan (₹${status.price.toStringAsFixed(0)})',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12.5),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0C2340),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                side: const BorderSide(color: Color(0xFF3395FF), width: 1.2),
                              ),
                            ),
                          if (invoices.isNotEmpty)
                            OutlinedButton.icon(
                              onPressed: () {
                                final uri = Uri.parse(invoices.first.getViewUrl(ApiConstants.baseUrl));
                                launchUrl(uri, mode: LaunchMode.externalApplication);
                              },
                              icon: const Icon(Icons.open_in_new_rounded, size: 13, color: Color(0xFF10B981)),
                              label: const Text('Latest Tax Invoice', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 11.5)),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: textColor,
                                side: BorderSide(color: borderColor),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                            ),
                        ],
                      );

                return isWide
                    ? Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Expanded(child: leftInfo), const SizedBox(width: 16), actions])
                    : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [leftInfo, const SizedBox(height: 12), actions]);
              },
            ),
          ),
        ],
      ),
    );
  }
}
