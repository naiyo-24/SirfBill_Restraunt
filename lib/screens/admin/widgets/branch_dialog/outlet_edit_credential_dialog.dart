import 'package:flutter/material.dart';

class OutletEditCredentialDialog extends StatefulWidget {
  final String moduleTitle;
  final String initialUsername;
  final String initialPassword;
  final Future<void> Function(String newUsername, String newPassword) onSave;

  const OutletEditCredentialDialog({
    super.key,
    required this.moduleTitle,
    required this.initialUsername,
    required this.initialPassword,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required String moduleTitle,
    required String initialUsername,
    required String initialPassword,
    required Future<void> Function(String newUsername, String newPassword) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => OutletEditCredentialDialog(
        moduleTitle: moduleTitle,
        initialUsername: initialUsername,
        initialPassword: initialPassword,
        onSave: onSave,
      ),
    );
  }

  @override
  State<OutletEditCredentialDialog> createState() => _OutletEditCredentialDialogState();
}

class _OutletEditCredentialDialogState extends State<OutletEditCredentialDialog> {
  late final TextEditingController _usernameCtrl;
  late final TextEditingController _passwordCtrl;
  bool _obscurePassword = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _usernameCtrl = TextEditingController(text: widget.initialUsername);
    _passwordCtrl = TextEditingController(text: widget.initialPassword);
  }

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          const Icon(Icons.key_rounded, color: Color(0xFF6366F1)),
          const SizedBox(width: 8),
          Text('Update ${widget.moduleTitle} Login', style: const TextStyle(fontSize: 15)),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Change the username or login password for this outlet station:',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _usernameCtrl,
            decoration: const InputDecoration(
              labelText: 'Login User ID / Email *',
              prefixIcon: Icon(Icons.person_rounded, size: 18),
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _passwordCtrl,
            obscureText: _obscurePassword,
            decoration: InputDecoration(
              labelText: 'New Password *',
              prefixIcon: const Icon(Icons.lock_rounded, size: 18),
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              border: const OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSaving
              ? null
              : () async {
                  setState(() => _isSaving = true);
                  final u = _usernameCtrl.text.trim();
                  final p = _passwordCtrl.text.trim();
                  try {
                    await widget.onSave(u, p);
                    if (context.mounted) Navigator.pop(context);
                  } finally {
                    if (mounted) setState(() => _isSaving = false);
                  }
                },
          child: _isSaving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Save & Apply'),
        ),
      ],
    );
  }
}
