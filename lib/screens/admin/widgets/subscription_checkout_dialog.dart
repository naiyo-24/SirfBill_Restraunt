import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/subscription_plan_models.dart';
import '../services/subscription_api_service.dart';
import '../services/razorpay_gateway_service.dart';

class SubscriptionCheckoutDialog extends StatefulWidget {
  final SubscriptionPlanItem plan;
  final SubscriptionStatusModel? currentStatus;
  final String? outletId;
  final String? branchName;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;
  final ValueChanged<SubscriptionStatusModel> onSuccess;

  const SubscriptionCheckoutDialog({
    super.key,
    required this.plan,
    this.currentStatus,
    this.outletId,
    this.branchName,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
    required this.onSuccess,
  });

  static Future<void> show(
    BuildContext context, {
    required SubscriptionPlanItem plan,
    SubscriptionStatusModel? currentStatus,
    String? outletId,
    String? branchName,
    required Color cardBg,
    required Color borderColor,
    required Color textColor,
    required Color subtitleColor,
    required bool isDark,
    required ValueChanged<SubscriptionStatusModel> onSuccess,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => SubscriptionCheckoutDialog(
        plan: plan,
        currentStatus: currentStatus,
        outletId: outletId,
        branchName: branchName,
        cardBg: cardBg,
        borderColor: borderColor,
        textColor: textColor,
        subtitleColor: subtitleColor,
        isDark: isDark,
        onSuccess: onSuccess,
      ),
    );
  }

  @override
  State<SubscriptionCheckoutDialog> createState() => _SubscriptionCheckoutDialogState();
}

class _SubscriptionCheckoutDialogState extends State<SubscriptionCheckoutDialog> {
  bool _isProcessing = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _launchRazorpayGateway();
    });
  }

  Future<void> _launchRazorpayGateway() async {
    setState(() {
      _isProcessing = true;
      _errorMessage = null;
    });

    try {
      // 1. Create order on backend with plan_code and duration_months
      final orderInfo = await SubscriptionApiService.createRazorpayOrderInfo(
        amount: widget.plan.safeTotalPrice,
        planId: widget.plan.id,
        planCode: widget.plan.planCode,
        durationMonths: widget.plan.durationMonths,
        outletId: widget.outletId,
      );
      final orderId = orderInfo?['order_id']?.toString();
      final paymentLinkUrl = orderInfo?['payment_link_url']?.toString();

      String? userEmail;
      String? userName;
      try {
        final prefs = await SharedPreferences.getInstance();
        final rawUser = prefs.getString('user_id') ?? '';
        final rawName = prefs.getString('user_name') ?? '';
        if (rawUser.contains('@')) userEmail = rawUser;
        if (rawName.isNotEmpty) userName = rawName;
      } catch (_) {}

      // 2. Launch official Razorpay standard checkout
      final result = await launchOfficialRazorpay(
        amount: widget.plan.safeTotalPrice,
        planName: widget.branchName != null
            ? '${widget.branchName} · ${widget.plan.name}'
            : '${widget.plan.name} (${widget.plan.billingCycle})',
        orderId: orderId,
        paymentLinkUrl: paymentLinkUrl,
        userEmail: userEmail,
        userName: userName,
      );

      final paymentId = result?['payment_id'] ?? '';
      if (paymentId.isEmpty) {
        if (mounted) {
          setState(() {
            _isProcessing = false;
            _errorMessage = 'Payment was cancelled or closed.';
          });
        }
        return;
      }

      // 3. Register payment verification with backend
      final updatedStatus = await SubscriptionApiService.verifyAndActivatePayment(
        planId: widget.plan.id,
        planCode: widget.plan.planCode,
        durationMonths: widget.plan.durationMonths,
        paymentReference: paymentId,
        orderId: result?['order_id'],
        signature: result?['signature'],
        outletId: widget.outletId,
      );

      if (mounted) {
        setState(() {
          _isProcessing = false;
          _isSuccess = true;
        });

        await Future.delayed(const Duration(milliseconds: 700));
        if (mounted) {
          widget.onSuccess(updatedStatus);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Payment Verified! Plan: ${updatedStatus.planName} (+${widget.plan.durationDays} Days)',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception:', '').trim();
          _isProcessing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plan = widget.plan;
    final isDark = widget.isDark;
    final keyId = dotenv.env['RAZORPAY_KEY_ID']?.trim().isNotEmpty == true
        ? dotenv.env['RAZORPAY_KEY_ID']!.trim()
        : 'rzp_live_ReRSf5hDkv7b7S';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 440),
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(color: Colors.black38, blurRadius: 32, offset: Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Razorpay Navy Top Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                color: const Color(0xFF0C2340),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: plan.accentColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(plan.icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                widget.branchName != null && widget.branchName!.isNotEmpty
                                    ? widget.branchName!
                                    : 'SirfBill Restaurant',
                                style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.verified_rounded, color: Color(0xFF3395FF), size: 14),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.branchName != null
                                ? 'Branch License · ${plan.name} (${plan.durationDays} Days)'
                                : '${plan.name} · ${plan.durationDays} Days',
                            style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${plan.safeTotalPrice.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900),
                        ),
                        Text(
                          plan.discountLabel.isNotEmpty ? plan.discountLabel : '18% GST Incl.',
                          style: TextStyle(
                            color: plan.discountLabel.isNotEmpty ? const Color(0xFFF59E0B) : const Color(0xFF10B981),
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white70, size: 20),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),

              // Main Gateway Card Body
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isSuccess) ...[
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 54),
                      const SizedBox(height: 14),
                      const Text(
                        'Payment Authorized!',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'License Activated: ${plan.name} (+${plan.durationDays} Days)',
                        style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                      ),
                      const SizedBox(height: 16),
                    ] else ...[
                      // Official Itemized Tax Breakdown Card
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Base License Fee (GST Excluded):', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                Text('₹${plan.safeBasePrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('GST (9% CGST + 9% SGST):', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                Text('₹${plan.safeGstAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ],
                            ),
                            const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: Divider(height: 1)),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Total Payable (Gross):', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
                                Text('₹${plan.safeTotalPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Razorpay Processing Info
                      if (_isProcessing) ...[
                        const SizedBox(
                          width: 36,
                          height: 36,
                          child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFF3395FF)),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Razorpay Checkout window is open...',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Complete your payment in the browser window.\nThis screen will automatically update once verified.',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFF64748B)),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () async {
                            bool verified = false;
                            SubscriptionStatusModel? status;
                            try {
                              status = await SubscriptionApiService.fetchSubscriptionStatus(outletId: widget.outletId);
                              // Strictly check if backend actually has a confirmed payment recorded
                              verified = status.isActive && status.daysRemaining > 0;
                            } catch (_) {}

                            if (verified && status != null) {
                              if (mounted) {
                                setState(() {
                                  _isProcessing = false;
                                  _isSuccess = true;
                                });
                                await Future.delayed(const Duration(milliseconds: 700));
                                if (mounted) {
                                  widget.onSuccess(status);
                                  // ignore: use_build_context_synchronously
                                  Navigator.pop(context);
                                }
                              }
                            } else {
                              if (mounted) {
                                // ignore: use_build_context_synchronously
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('No verified payment detected for this order yet.'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.verified_rounded, size: 16),
                          label: const Text('I Have Completed Payment — Verify Now', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => setState(() => _isProcessing = false),
                          child: const Text('Cancel / Re-open Window', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ),
                      ] else ...[
                        SizedBox(
                          width: double.infinity,
                          height: 46,
                          child: ElevatedButton.icon(
                            onPressed: _launchRazorpayGateway,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF3395FF),
                              foregroundColor: Colors.white,
                              elevation: 2,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.bolt_rounded, size: 18),
                            label: Text(
                              'Pay ₹${plan.price.toStringAsFixed(0)} with Razorpay',
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                            ),
                          ),
                        ),
                      ],

                      if (_errorMessage != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444), fontWeight: FontWeight.w600),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ],
                ),
              ),

              // Bottom Security Footer
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: const BoxDecoration(
                  color: Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock_rounded, size: 12, color: Color(0xFF64748B)),
                    const SizedBox(width: 5),
                    Text(
                      'Secured by Razorpay Payments · Key: ${keyId.substring(0, 12)}...',
                      style: const TextStyle(fontSize: 10, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
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
