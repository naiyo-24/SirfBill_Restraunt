import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/restaurant_crm_models.dart';
import 'crm_360_subviews.dart';

class Crm360InsightsModal extends StatefulWidget {
  final RestaurantCustomer customer;
  final CustomerInsights? insights;
  final List<KhataLedgerEntry> khataLedger;
  final bool isLoading;
  final VoidCallback onClose;
  final VoidCallback onSettleKhata;
  final VoidCallback onAdjustLoyalty;
  final VoidCallback onEditProfile;

  const Crm360InsightsModal({
    super.key,
    required this.customer,
    required this.insights,
    required this.khataLedger,
    required this.isLoading,
    required this.onClose,
    required this.onSettleKhata,
    required this.onAdjustLoyalty,
    required this.onEditProfile,
  });

  @override
  State<Crm360InsightsModal> createState() => _Crm360InsightsModalState();
}

class _Crm360InsightsModalState extends State<Crm360InsightsModal> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _sendWhatsAppMessage() async {
    final phone = widget.customer.phone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.startsWith('91') ? phone : '91$phone';
    final name = widget.customer.name;
    final points = widget.customer.loyaltyPoints;
    final due = widget.customer.creditBalance;

    String msg = 'Hello $name, thank you for dining with us at SirfBill Restaurant! '
        'Your current loyalty reward points balance is: $points pts.';
    if (due > 0) {
      msg += ' Current store credit outstanding dues: ₹${due.toStringAsFixed(2)}.';
    }

    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
    try {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final c = widget.customer;
    final seg = c.segment;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header with Avatar + Name + WhatsApp Quick Action + Close
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: const Color(0xFF10B981).withValues(alpha: 0.15),
                  child: Text(
                    c.initials,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              c.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _buildSegmentBadge(seg),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${c.phone} ${c.email.isNotEmpty ? "• ${c.email}" : ""}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF10B981), size: 20),
                  tooltip: 'WhatsApp Bill / Statement',
                  onPressed: _sendWhatsAppMessage,
                ),
                IconButton(
                  icon: const Icon(Icons.edit_outlined, size: 20),
                  tooltip: 'Edit Profile',
                  onPressed: widget.onEditProfile,
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20),
                  tooltip: 'Close Pane',
                  onPressed: widget.onClose,
                ),
              ],
            ),
          ),

          // Tab Bar
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF10B981),
            unselectedLabelColor: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            indicatorColor: const Color(0xFF10B981),
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Overview'),
              Tab(text: 'Top Dishes'),
              Tab(text: 'Recent Bills'),
              Tab(text: 'Khata & Points'),
            ],
          ),
          const Divider(height: 1),

          // Tab View Content
          Expanded(
            child: widget.isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF10B981)))
                : TabBarView(
                    controller: _tabController,
                    children: [
                      CrmOverviewTabView(customer: c, isDark: isDark),
                      CrmTopDishesTabView(topDishes: widget.insights?.topDishes ?? [], isDark: isDark),
                      CrmRecentBillsTabView(recentBills: widget.insights?.recentBills ?? [], isDark: isDark),
                      CrmKhataTabView(
                        customer: c,
                        ledger: widget.khataLedger,
                        isDark: isDark,
                        onSettleKhata: widget.onSettleKhata,
                        onAdjustLoyalty: widget.onAdjustLoyalty,
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentBadge(CustomerSegment segment) {
    Color bg;
    Color fg;
    String text;

    switch (segment) {
      case CustomerSegment.vip:
        bg = const Color(0xFFF59E0B).withValues(alpha: 0.15);
        fg = const Color(0xFFF59E0B);
        text = 'VIP';
        break;
      case CustomerSegment.regular:
        bg = const Color(0xFF10B981).withValues(alpha: 0.15);
        fg = const Color(0xFF10B981);
        text = 'REGULAR';
        break;
      case CustomerSegment.newGuest:
        bg = const Color(0xFF3B82F6).withValues(alpha: 0.15);
        fg = const Color(0xFF3B82F6);
        text = 'NEW';
        break;
      case CustomerSegment.atRisk:
        bg = const Color(0xFF8B5CF6).withValues(alpha: 0.15);
        fg = const Color(0xFF8B5CF6);
        text = 'AT RISK';
        break;
      default:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
        text = 'GUEST';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: fg)),
    );
  }
}
