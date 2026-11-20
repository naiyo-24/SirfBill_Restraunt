import 'package:flutter/material.dart';
import '../../../../models/restaurant_crm_models.dart';

class CrmCustomerCard extends StatelessWidget {
  final RestaurantCustomer customer;
  final VoidCallback onTap;
  final VoidCallback onSettleKhata;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const CrmCustomerCard({
    super.key,
    required this.customer,
    required this.onTap,
    required this.onSettleKhata,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final segment = customer.segment;
    final hasDue = customer.creditBalance > 0;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Row 1: Initials avatar + Name + Phone + Segment badge
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _getSegmentColor(segment).withValues(alpha: 0.15),
                    child: Text(
                      customer.initials,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: _getSegmentColor(segment),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                customer.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            _buildSegmentBadge(segment),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone_iphone_rounded, size: 12, color: Colors.grey.shade500),
                            const SizedBox(width: 4),
                            Text(
                              customer.phone,
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: Icon(Icons.more_vert_rounded, size: 18, color: Colors.grey.shade400),
                    onSelected: (val) {
                      if (val == '360') onTap();
                      if (val == 'khata') onSettleKhata();
                      if (val == 'edit') onEdit();
                      if (val == 'delete') onDelete();
                    },
                    itemBuilder: (ctx) => [
                      const PopupMenuItem(
                        value: '360',
                        child: Row(
                          children: [
                            Icon(Icons.insights_rounded, size: 16, color: Color(0xFF3B82F6)),
                            SizedBox(width: 8),
                            Text('360° Insights'),
                          ],
                        ),
                      ),
                      if (hasDue)
                        const PopupMenuItem(
                          value: 'khata',
                          child: Row(
                            children: [
                              Icon(Icons.payments_rounded, size: 16, color: Color(0xFFEF4444)),
                              SizedBox(width: 8),
                              Text('Settle Khata Due'),
                            ],
                          ),
                        ),
                      const PopupMenuItem(
                        value: 'edit',
                        child: Row(
                          children: [
                            Icon(Icons.edit_rounded, size: 16, color: Color(0xFF10B981)),
                            SizedBox(width: 8),
                            Text('Edit Guest'),
                          ],
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Row(
                          children: [
                            Icon(Icons.delete_outline_rounded, size: 16, color: Colors.red),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 10),

              // Row 2: RFM Stats (Visits, Total Spent, Avg Order Value)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildStatItem('VISITS', customer.totalVisits.toString(), isDark),
                  _buildStatItem('TOTAL SPENT', '₹${customer.totalSpent.toStringAsFixed(0)}', isDark),
                  _buildStatItem('AVG TICKET', '₹${customer.avgOrderValue.toStringAsFixed(0)}', isDark),
                  _buildStatItem('LOYALTY', '${customer.loyaltyPoints} pts', isDark, color: const Color(0xFF10B981)),
                ],
              ),

              // Row 3: Khata outstanding banner if due
              if (hasDue) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Text(
                        'Khata Due: ₹${customer.creditBalance.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFEF4444),
                        ),
                      ),
                      const Spacer(),
                      InkWell(
                        onTap: onSettleKhata,
                        child: const Text(
                          'Settle Dues →',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFEF4444),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, bool isDark, {Color? color}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 1),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color ?? (isDark ? Colors.white : const Color(0xFF0F172A)),
          ),
        ),
      ],
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
      case CustomerSegment.hasDue:
      case CustomerSegment.all:
        bg = Colors.grey.withValues(alpha: 0.15);
        fg = Colors.grey.shade700;
        text = 'GUEST';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: fg),
      ),
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
