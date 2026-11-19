import 'package:flutter/material.dart';

class PoPrintSplitButton extends StatelessWidget {
  final VoidCallback onPrintPdf;
  final VoidCallback onOpenHtml;

  const PoPrintSplitButton({
    super.key,
    required this.onPrintPdf,
    required this.onOpenHtml,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF475569),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onPrintPdf,
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(8)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.print_rounded, size: 15, color: Colors.white),
                  SizedBox(width: 6),
                  Text('Print / Download', style: TextStyle(fontSize: 12.5, color: Colors.white, fontWeight: FontWeight.w500)),
                ],
              ),
            ),
          ),
          Container(width: 1, height: 18, color: Colors.white24),
          PopupMenuButton<String>(
            tooltip: 'More Print Options',
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.arrow_drop_down, size: 18, color: Colors.white),
            onSelected: (val) {
              if (val == 'pdf') onPrintPdf();
              if (val == 'html') onOpenHtml();
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'pdf',
                child: Row(
                  children: [
                    Icon(Icons.picture_as_pdf_outlined, size: 16, color: Color(0xFF10B981)),
                    SizedBox(width: 8),
                    Text('Print / Save PDF (A4)', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'html',
                child: Row(
                  children: [
                    Icon(Icons.open_in_browser_rounded, size: 16, color: Color(0xFF3B82F6)),
                    SizedBox(width: 8),
                    Text('Open Backend HTML Bill', style: TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
