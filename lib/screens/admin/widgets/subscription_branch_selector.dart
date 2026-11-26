import 'package:flutter/material.dart';

class SubscriptionBranchSelector extends StatelessWidget {
  final List<Map<String, dynamic>> branches;
  final String? selectedOutletId;
  final ValueChanged<String> onBranchSelected;
  final Color cardBg;
  final Color borderColor;
  final Color textColor;
  final Color subtitleColor;
  final bool isDark;

  const SubscriptionBranchSelector({
    super.key,
    required this.branches,
    required this.selectedOutletId,
    required this.onBranchSelected,
    required this.cardBg,
    required this.borderColor,
    required this.textColor,
    required this.subtitleColor,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (branches.isEmpty) return const SizedBox.shrink();

    final currentBranch = branches.firstWhere(
      (b) => b['outlet_id']?.toString() == selectedOutletId,
      orElse: () => branches.first,
    );
    final isSubActive = currentBranch['is_active'] == true;
    final statusStr = (currentBranch['status'] ?? 'UNPAID').toString().toUpperCase();
    final daysRemaining = (currentBranch['days_remaining'] is num)
        ? (currentBranch['days_remaining'] as num).toInt()
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.storefront_rounded, size: 18, color: Color(0xFF6366F1)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Branch License & Renewal Target',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Each restaurant outlet requires its own active license. Switch branches below to view or renew.',
                      style: TextStyle(fontSize: 11, color: subtitleColor),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isSubActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isSubActive ? 'ACTIVE ($daysRemaining d)' : statusStr,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: borderColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                isExpanded: true,
                value: selectedOutletId ?? branches.first['outlet_id']?.toString(),
                icon: Icon(Icons.arrow_drop_down_rounded, color: subtitleColor),
                dropdownColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                items: branches.map((b) {
                  final bId = b['outlet_id']?.toString() ?? '';
                  final bName = b['outlet_name']?.toString() ?? 'Outlet';
                  final bCode = b['outlet_code']?.toString() ?? '';
                  final bActive = b['is_active'] == true;
                  final bDays = (b['days_remaining'] is num) ? (b['days_remaining'] as num).toInt() : 0;
                  final isPrimary = b['is_primary'] == true;

                  return DropdownMenuItem<String>(
                    value: bId,
                    child: Row(
                      children: [
                        Icon(
                          bActive ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 15,
                          color: bActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '$bName ${bCode.isNotEmpty ? "($bCode)" : ""}${isPrimary ? " · Primary HQ" : ""}',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          bActive ? '$bDays days left' : 'License Expired',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: bActive ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    onBranchSelected(val);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
