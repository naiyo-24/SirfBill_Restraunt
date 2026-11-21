import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../models/restaurant_crm_models.dart';

class CrmCustomerTable extends StatelessWidget {
  final List<RestaurantCustomer> customers;
  final RestaurantCustomer? selectedCustomer;
  final ValueChanged<RestaurantCustomer> onSelectCustomer;
  final ValueChanged<RestaurantCustomer> onSettleKhata;
  final ValueChanged<RestaurantCustomer> onEdit;
  final ValueChanged<RestaurantCustomer> onDelete;
  final int currentPage;
  final int totalPages;
  final int totalRecords;
  final ValueChanged<int> onPageChanged;

  const CrmCustomerTable({
    super.key,
    required this.customers,
    required this.selectedCustomer,
    required this.onSelectCustomer,
    required this.onSettleKhata,
    required this.onEdit,
    required this.onDelete,
    required this.currentPage,
    required this.totalPages,
    required this.totalRecords,
    required this.onPageChanged,
  });

  static Future<void> _handleQuickNotify(BuildContext context, RestaurantCustomer c) async {
    final phone = c.phone.replaceAll(RegExp(r'\D'), '');
    final cleanPhone = phone.length == 10 ? '91$phone' : phone;
    final due = c.creditBalance;
    final points = c.loyaltyPoints;

    String msg;
    if (due > 0) {
      msg = 'Hello ${c.name}, gentle reminder from SirfBill Restaurant regarding pending Khata dues of ₹${due.toStringAsFixed(2)}. Thank you!';
    } else if (points > 0) {
      msg = 'Hello ${c.name}, you have $points loyalty reward points at SirfBill Restaurant! Visit us today to unlock special treats.';
    } else {
      msg = 'Hello ${c.name}, greetings from SirfBill Restaurant! We look forward to serving you again soon.';
    }

    final url = Uri.parse('https://wa.me/$cleanPhone?text=${Uri.encodeComponent(msg)}');
    try {
      final launched = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!launched) await launchUrl(url);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open WhatsApp for ${c.phone}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final headerBg = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    if (customers.isEmpty) {
      return Container(
        height: 280,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No customer profiles found',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try adjusting your search query or segment filters',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: 800,
          child: Column(
            children: [
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
            child: const Row(
              children: [
                Expanded(flex: 3, child: _HeaderText('GUEST & CONTACT')),
                Expanded(flex: 2, child: _HeaderText('SEGMENT')),
                Expanded(flex: 2, child: _HeaderText('VISITS')),
                Expanded(flex: 2, child: _HeaderText('TOTAL SPENT')),
                Expanded(flex: 2, child: _HeaderText('AOV')),
                Expanded(flex: 2, child: _HeaderText('KHATA DUE')),
                Expanded(flex: 2, child: _HeaderText('LOYALTY')),
                SizedBox(width: 124, child: _HeaderText('ACTIONS', align: TextAlign.end)),
              ],
            ),
          ),

          // Table rows
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: customers.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: borderColor),
            itemBuilder: (ctx, i) {
              final c = customers[i];
              final isSelected = selectedCustomer?.id == c.id;
              final seg = c.segment;
              final hasDue = c.creditBalance > 0;

              return InkWell(
                onTap: () => onSelectCustomer(c),
                child: Container(
                  color: isSelected
                      ? const Color(0xFF10B981).withValues(alpha: 0.08)
                      : Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      // 1. Guest & Contact
                      Expanded(
                        flex: 3,
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: _getSegmentColor(seg).withValues(alpha: 0.15),
                              child: Text(
                                c.initials,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: _getSegmentColor(seg),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    c.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                                    ),
                                  ),
                                  Text(
                                    c.phone,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 2. Segment
                      Expanded(
                        flex: 2,
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _buildSegmentBadge(seg),
                        ),
                      ),

                      // 3. Visits
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${c.totalVisits} visits',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white70 : const Color(0xFF334155),
                          ),
                        ),
                      ),

                      // 4. Total Spent
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(c.totalSpent),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ),

                      // 5. AOV
                      Expanded(
                        flex: 2,
                        child: Text(
                          NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(c.avgOrderValue),
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ),

                      // 6. Khata Due
                      Expanded(
                        flex: 2,
                        child: hasDue
                            ? InkWell(
                                onTap: () => onSettleKhata(c),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    '${NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2).format(c.creditBalance)} Due',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                              )
                            : Text(
                                '₹0',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade400,
                                ),
                              ),
                      ),

                      // 7. Loyalty Points
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            const Icon(Icons.stars_rounded, size: 14, color: Color(0xFF10B981)),
                            const SizedBox(width: 4),
                            Text(
                              '${c.loyaltyPoints} pts',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 8. Actions
                      SizedBox(
                        width: 124,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_outlined, size: 16),
                              tooltip: 'WhatsApp / Send Message',
                              color: const Color(0xFF25D366),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => _handleQuickNotify(context, c),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.insights_rounded, size: 16),
                              tooltip: '360° Insights',
                              color: const Color(0xFF3B82F6),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => onSelectCustomer(c),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.edit_rounded, size: 16),
                              tooltip: 'Edit Profile',
                              color: const Color(0xFF10B981),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => onEdit(c),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.delete_outline_rounded, size: 16),
                              tooltip: 'Delete',
                              color: Colors.red.shade400,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              onPressed: () => onDelete(c),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Pagination Footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Showing ${customers.length} of $totalRecords guests',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left_rounded, size: 18),
                      onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
                    ),
                    Text(
                      'Page $currentPage of $totalPages',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.chevron_right_rounded, size: 18),
                      onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
                    ),
                  ],
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

  Color _getSegmentColor(CustomerSegment seg) {
    switch (seg) {
      case CustomerSegment.vip:
        return const Color(0xFFF59E0B);
      case CustomerSegment.regular:
        return const Color(0xFF10B981);
      case CustomerSegment.newGuest:
        return const Color(0xFF3B82F6);
      case CustomerSegment.atRisk:
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFF64748B);
    }
  }
}

class _HeaderText extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HeaderText(this.text, {this.align = TextAlign.start});



  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Text(
      text,
      textAlign: align,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
      ),
    );
  }
}
