import 'package:flutter/material.dart';
import '../../admin/models/subscription_plan_models.dart';
import '../../admin/services/subscription_api_service.dart';
import '../../admin/widgets/subscription_checkout_dialog.dart';

class BranchSubscriptionExpiredDialog extends StatelessWidget {
  final String? outletId;
  final String? outletName;
  final String message;
  final VoidCallback? onRenewed;

  const BranchSubscriptionExpiredDialog({
    super.key,
    this.outletId,
    this.outletName,
    required this.message,
    this.onRenewed,
  });

  static Future<void> show(
    BuildContext context, {
    String? outletId,
    String? outletName,
    required String message,
    VoidCallback? onRenewed,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BranchSubscriptionExpiredDialog(
        outletId: outletId,
        outletName: outletName,
        message: message,
        onRenewed: onRenewed,
      ),
    );
  }

  void _openCheckout(BuildContext context) async {
    final plans = await SubscriptionApiService.fetchPlans();
    final plan = plans.isNotEmpty ? plans.first : kMonthlySubscriptionPlans.first;

    if (!context.mounted) return;
    SubscriptionCheckoutDialog.show(
      context,
      plan: plan,
      outletId: outletId,
      branchName: outletName,
      cardBg: Colors.white,
      borderColor: const Color(0xFFE2E8F0),
      textColor: const Color(0xFF0F172A),
      subtitleColor: const Color(0xFF64748B),
      isDark: Theme.of(context).brightness == Brightness.dark,
      onSuccess: (_) {
        Navigator.pop(context);
        onRenewed?.call();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Branch "${outletName ?? 'Outlet'}" license renewed successfully! You can now log in.',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final branchLabel = (outletName != null && outletName!.trim().isNotEmpty) ? outletName!.trim() : 'Restaurant Branch';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          width: double.infinity,
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.15),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Red Accent Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: isDark ? 0.15 : 0.08),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  border: Border(bottom: BorderSide(color: const Color(0xFFEF4444).withValues(alpha: 0.2))),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lock_clock_rounded, color: Color(0xFFEF4444), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Branch License Inactive',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'EXPIRED',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'Subscription renewal is required for this outlet',
                            style: TextStyle(fontSize: 11.5, color: subtitleColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Content Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Outlet Name Highlight Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.storefront_rounded, color: subtitleColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Target Outlet',
                                  style: TextStyle(fontSize: 10, color: subtitleColor, fontWeight: FontWeight.w600),
                                ),
                                Text(
                                  branchLabel,
                                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: textColor),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Operational billing, KOT printing, and staff station logins for this branch are temporarily suspended until the license is renewed.',
                      style: TextStyle(fontSize: 12, color: subtitleColor, height: 1.4),
                    ),
                    const SizedBox(height: 16),

                    // Feature highlights
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withValues(alpha: isDark ? 0.08 : 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.workspace_premium_rounded, color: Color(0xFF10B981), size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SirfBill Restaurant Pro • ₹299 / Month (18% GST Incl.)',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.bold,
                                color: isDark ? const Color(0xFF34D399) : const Color(0xFF059669),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Actions
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _openCheckout(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          elevation: 1,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.bolt_rounded, size: 18),
                        label: const Text(
                          'Renew Branch License Now (₹299/mo)',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 40,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: subtitleColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Back to Login', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
