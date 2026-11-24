import 'package:flutter/material.dart';
import '../../../../services/shop_service.dart';

class OutletProfileTab extends StatelessWidget {
  final Shop outlet;
  final Color textColor;
  final Color subtitleColor;
  final Color borderColor;
  final Color cardBg;

  const OutletProfileTab({
    super.key,
    required this.outlet,
    required this.textColor,
    required this.subtitleColor,
    required this.borderColor,
    required this.cardBg,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
