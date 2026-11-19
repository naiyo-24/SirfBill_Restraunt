import 'package:flutter/material.dart';
import '../models/inventory_ops_models.dart';
import 'po_print_split_button.dart';

class PoDetailsActions extends StatelessWidget {
  final PurchaseOrder po;
  final bool isProcessing;
  final bool isMobile;
  final VoidCallback onDelete;
  final VoidCallback onCancel;
  final VoidCallback onEmail;
  final VoidCallback onIssue;
  final VoidCallback onReceive;
  final VoidCallback onPrintPdf;
  final VoidCallback onOpenHtml;
  final VoidCallback onClose;

  const PoDetailsActions({
    super.key,
    required this.po,
    required this.isProcessing,
    required this.isMobile,
    required this.onDelete,
    required this.onCancel,
    required this.onEmail,
    required this.onIssue,
    required this.onReceive,
    required this.onPrintPdf,
    required this.onOpenHtml,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final printButton = PoPrintSplitButton(
      onPrintPdf: onPrintPdf,
      onOpenHtml: onOpenHtml,
    );

    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 6,
            runSpacing: 6,
            children: [
              if (po.status == POStatus.draft)
                OutlinedButton.icon(
                  onPressed: isProcessing ? null : onDelete,
                  icon: const Icon(Icons.delete_outline, size: 15, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else if (po.status == POStatus.sent)
                OutlinedButton.icon(
                  onPressed: isProcessing ? null : onCancel,
                  icon: const Icon(Icons.cancel_outlined, size: 15, color: Colors.orange),
                  label: const Text('Cancel PO', style: TextStyle(color: Colors.orange, fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              OutlinedButton.icon(
                onPressed: onEmail,
                icon: const Icon(Icons.email_outlined, size: 15, color: Color(0xFF3B82F6)),
                label: const Text('Email PO', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFF3B82F6)),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              printButton,
              OutlinedButton(
                onPressed: onClose,
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Close', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
          if (po.status == POStatus.draft || po.status == POStatus.sent || po.status == POStatus.partiallyReceived) ...[
            const SizedBox(height: 8),
            if (po.status == POStatus.draft)
              ElevatedButton.icon(
                onPressed: isProcessing ? null : onIssue,
                icon: const Icon(Icons.send, size: 15),
                label: const Text('Send to Vendor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: onReceive,
                icon: const Icon(Icons.inventory_2_rounded, size: 15),
                label: const Text('Receive Goods (GRN)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
          ],
        ],
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (po.status == POStatus.draft)
          OutlinedButton.icon(
            onPressed: isProcessing ? null : onDelete,
            icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
            label: const Text('Delete Draft', style: TextStyle(color: Colors.red)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.red),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else if (po.status == POStatus.sent)
          OutlinedButton.icon(
            onPressed: isProcessing ? null : onCancel,
            icon: const Icon(Icons.cancel_outlined, size: 16, color: Colors.orange),
            label: const Text('Cancel PO', style: TextStyle(color: Colors.orange)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.orange),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          )
        else
          const SizedBox.shrink(),

        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            OutlinedButton.icon(
              onPressed: onEmail,
              icon: const Icon(Icons.email_outlined, size: 15, color: Color(0xFF3B82F6)),
              label: const Text('Email PO', style: TextStyle(color: Color(0xFF3B82F6), fontSize: 13)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF3B82F6)),
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
            const SizedBox(width: 8),
            printButton,
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: onClose,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('Close', style: TextStyle(fontSize: 13)),
            ),
            if (po.status == POStatus.draft) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: isProcessing ? null : onIssue,
                icon: const Icon(Icons.send, size: 15),
                label: const Text('Send to Vendor', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ] else if (po.status == POStatus.sent || po.status == POStatus.partiallyReceived) ...[
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: onReceive,
                icon: const Icon(Icons.inventory_2_rounded, size: 15),
                label: const Text('Receive Goods (GRN)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
