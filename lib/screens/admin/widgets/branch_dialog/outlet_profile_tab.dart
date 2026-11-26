import 'package:flutter/material.dart';
import '../../../../services/shop_service.dart';
import '../../models/subscription_plan_models.dart';
import '../../services/subscription_api_service.dart';
import '../subscription_checkout_dialog.dart';

class OutletProfileTab extends StatelessWidget {
  final Shop outlet;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final Color cardBg;
  final VoidCallback? onRenewSuccess;

  const OutletProfileTab({
    super.key,
    required this.outlet,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.cardBg,
    this.onRenewSuccess,
  });

  void _openBranchCheckout(BuildContext context) async {
    final plans = await SubscriptionApiService.fetchPlans();
    final defaultPlan = plans.isNotEmpty ? plans.first : kMonthlySubscriptionPlans.first;

    if (!context.mounted) return;
    SubscriptionCheckoutDialog.show(
      context,
      plan: defaultPlan,
      outletId: outlet.id,
      branchName: outlet.name,
      cardBg: cardBg,
      borderColor: borderColor,
      textColor: textColor,
      subtitleColor: subtitleColor,
      isDark: false,
      onSuccess: (_) {
        onRenewSuccess?.call();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSubActive = outlet.isSubscribed;
    final subStatus = outlet.subscriptionStatus;
    final daysLeft = outlet.subscriptionDaysRemaining;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Branch License & Subscription Card
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isSubActive ? const Color(0xFF10B981).withValues(alpha: 0.08) : const Color(0xFFEF4444).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSubActive ? const Color(0xFF10B981).withValues(alpha: 0.35) : const Color(0xFFEF4444).withValues(alpha: 0.35),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSubActive ? Icons.verified_user_rounded : Icons.warning_amber_rounded,
                          color: isSubActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Branch License Status',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isSubActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isSubActive ? 'ACTIVE ($daysLeft Days)' : (subStatus == 'PENDING_PAYMENT' ? 'PAYMENT REQUIRED' : 'EXPIRED'),
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  isSubActive
                      ? 'This branch has an independent license active for $daysLeft more day(s).'
                      : 'This branch license is inactive. Renew to allow billing and POS operations.',
                  style: TextStyle(fontSize: 11.5, color: subtitleColor),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 38,
                  child: ElevatedButton.icon(
                    onPressed: () => _openBranchCheckout(context),
                    icon: Icon(
                      isSubActive ? Icons.autorenew_rounded : Icons.bolt_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                    label: Text(
                      isSubActive ? 'Extend / Renew Branch Plan (+30 Days)' : 'Activate Branch License (₹299/mo)',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isSubActive ? const Color(0xFF6366F1) : const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                  ),
                ),
              ],
            ),
          ),

          _buildDetailTile('Branch Name', outlet.name),
          _buildDetailTile('Branch Code', outlet.code),
          _buildDetailTile('Physical Address', outlet.location),
          _buildDetailTile('City & Region', outlet.city),
          _buildDetailTile('Contact Phone', outlet.contact),
          _buildDetailTile('Operational Status', outlet.status.toUpperCase()),
          _buildDetailTile(
            'Primary Branch Flag',
            outlet.isPrimary ? 'YES (HQ Outlet)' : 'NO',
          ),
          if (outlet.bankAccountName != null && outlet.bankAccountName!.isNotEmpty)
            _buildDetailTile('Account Holder Name', outlet.bankAccountName!),
          if (outlet.bankName != null && outlet.bankName!.isNotEmpty)
            _buildDetailTile('Bank Name', outlet.bankName!),
          if (outlet.bankAccount != null && outlet.bankAccount!.isNotEmpty)
            _buildDetailTile('Bank Account Number', outlet.bankAccount!),
          if (outlet.bankIfsc != null && outlet.bankIfsc!.isNotEmpty)
            _buildDetailTile('Bank IFSC Code', outlet.bankIfsc!),
          if (outlet.bankBranch != null && outlet.bankBranch!.isNotEmpty)
            _buildDetailTile('Bank Branch', outlet.bankBranch!),
          if (outlet.upiId != null && outlet.upiId!.isNotEmpty)
            _buildDetailTile('UPI ID / VPA', outlet.upiId!),
        ],
      ),
    );
  }

  Widget _buildDetailTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: subtitleColor,
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              maxLines: 2,
            ),
          ),
        ],
      ),
    );
  }
}
