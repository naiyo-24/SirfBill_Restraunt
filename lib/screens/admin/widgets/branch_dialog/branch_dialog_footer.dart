import 'package:flutter/material.dart';

class BranchDialogFooter extends StatelessWidget {
  final bool isMobile;
  final int currentStep;
  final List<Map<String, dynamic>> tabs;
  final Color textColor;
  final Color borderColor;
  final Color subtitleColor;
  final bool isSubmitting;
  final bool isEdit;
  final VoidCallback onBack;
  final VoidCallback onContinue;
  final VoidCallback onSave;

  const BranchDialogFooter({
    super.key,
    required this.isMobile,
    required this.currentStep,
    required this.tabs,
    required this.textColor,
    required this.borderColor,
    required this.subtitleColor,
    required this.isSubmitting,
    required this.isEdit,
    required this.onBack,
    required this.onContinue,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 22,
        vertical: isMobile ? 10 : 14,
      ),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          if (!isMobile) ...[
            Text(
              'Step ${currentStep + 1} of 5: ${tabs[currentStep]['title']}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: subtitleColor,
              ),
            ),
            const Spacer(),
          ],
          if (currentStep > 0) ...[
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: textColor,
                side: BorderSide(color: borderColor),
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 12 : 16,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onBack,
              child: const Text('Back'),
            ),
            const SizedBox(width: 8),
          ],
          if (isMobile) const Spacer(),
          if (currentStep < 4)
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 18,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: onContinue,
              icon: const Icon(Icons.arrow_forward_rounded, size: 16),
              label: const Text('Continue'),
            )
          else
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 14 : 22,
                  vertical: 11,
                ),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: isSubmitting ? null : onSave,
              icon: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check_circle_rounded, size: 18),
              label: Text(
                isSubmitting
                    ? 'Saving...'
                    : (isEdit
                        ? 'Save Changes'
                        : (isMobile ? 'Save Outlet' : 'Create & Activate Outlet')),
              ),
            ),
        ],
      ),
    );
  }
}
