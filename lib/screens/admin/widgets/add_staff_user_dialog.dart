import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../services/admin_staff_service.dart';
import '../../../services/shop_service.dart';

class AddStaffUserDialog extends StatefulWidget {
  final RestaurantStaffUser? existingUser;
  final List<Shop>? branches;
  final VoidCallback onSaved;

  const AddStaffUserDialog({
    super.key,
    this.existingUser,
    this.branches,
    required this.onSaved,
  });

  @override
  State<AddStaffUserDialog> createState() => _AddStaffUserDialogState();
}

class _AddStaffUserDialogState extends State<AddStaffUserDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  final _passCtrl = TextEditingController();
  late final TextEditingController _phoneCtrl;
  String _selectedRole = 'cashier';
  String? _selectedBranchId;
  bool _isSubmitting = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    final u = widget.existingUser;
    _nameCtrl = TextEditingController(text: u?.name ?? '');
    _emailCtrl = TextEditingController(text: u?.username ?? '');
    
    // Strip prefix if already stored with +91
    String initialPhone = u?.phone ?? '';
    initialPhone = initialPhone.replaceAll(RegExp(r'^\+91\s*'), '').replaceAll(RegExp(r'\D'), '');
    _phoneCtrl = TextEditingController(text: initialPhone);

    if (u != null) {
      _selectedRole = u.role.toLowerCase();
      // Only keep the branchId if it actually exists in the current branches list.
      // If the branch was deleted or the list changed, fall back to null (All Branches).
      final branches = widget.branches;
      final branchExists = branches != null && branches.any((b) => b.id == u.branchId);
      _selectedBranchId = branchExists ? u.branchId : null;
    }

    // Match valid role
    const validRoles = ['admin', 'manager', 'cashier', 'chef', 'inventory', 'waiter'];
    if (!validRoles.contains(_selectedRole)) {
      _selectedRole = 'cashier';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final name = _nameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final rawPhone = _phoneCtrl.text.trim().replaceAll(RegExp(r'\D'), '');

    if (name.isEmpty) {
      _showWarning('Please enter Full Name.');
      return;
    }
    if (email.isEmpty) {
      _showWarning('Please enter Username / Email.');
      return;
    }
    if (widget.existingUser == null && pass.isEmpty) {
      _showWarning('Please enter Password.');
      return;
    }

    if (rawPhone.isNotEmpty && rawPhone.length != 10) {
      _showWarning('Please enter a valid 10-digit mobile number.');
      return;
    }

    final formattedPhone = rawPhone.isNotEmpty ? '+91 $rawPhone' : null;

    setState(() => _isSubmitting = true);
    try {
      if (widget.existingUser != null) {
        await AdminStaffService.updateStaffUser(
          userId: widget.existingUser!.id,
          name: name,
          role: _selectedRole,
          phone: formattedPhone,
          password: pass.isNotEmpty ? pass : null,
          branchId: _selectedBranchId,
        );
      } else {
        await AdminStaffService.createStaffUser(
          username: email,
          password: pass,
          name: name,
          role: _selectedRole,
          phone: formattedPhone,
          branchId: _selectedBranchId,
        );
      }
      if (mounted) {
        Navigator.pop(context);
        widget.onSaved();
      }
    } catch (_) {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showWarning(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existingUser != null;
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text(isEdit ? 'Edit Staff User Account' : 'Add Staff User Account'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Full Name *',
                hintText: 'e.g. Rahul Sharma',
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailCtrl,
              readOnly: isEdit,
              decoration: InputDecoration(
                labelText: 'Username / Email *',
                hintText: 'e.g. cashier1@restaurant.com',
                helperText: isEdit ? 'Username cannot be modified after creation' : null,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _passCtrl,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: isEdit ? 'New Password (Leave blank to keep unchanged)' : 'Password *',
                hintText: isEdit ? 'Enter new password if updating' : 'Enter login password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  tooltip: _obscurePassword ? 'Show password' : 'Hide password',
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(10),
              ],
              decoration: const InputDecoration(
                labelText: 'Phone Number (10 Digits)',
                hintText: '9876543210',
                prefixText: '+91 ',
                prefixStyle: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Security Role *'),
              items: const [
                DropdownMenuItem(value: 'admin', child: Text('Super Admin')),
                DropdownMenuItem(value: 'manager', child: Text('Store Manager')),
                DropdownMenuItem(value: 'cashier', child: Text('Billing Cashier')),
                DropdownMenuItem(value: 'chef', child: Text('Kitchen Chef')),
                DropdownMenuItem(value: 'inventory', child: Text('Inventory Manager')),
                DropdownMenuItem(value: 'waiter', child: Text('Waiter / Captain')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedRole = val);
              },
            ),
            if (widget.branches != null && widget.branches!.isNotEmpty) ...[
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                // Guard: only use _selectedBranchId if it's actually in the list.
                // Prevents the Flutter assertion crash when the saved branchId
                // no longer exists in the loaded branches list.
                initialValue: (widget.branches!.any((b) => b.id == _selectedBranchId))
                    ? _selectedBranchId
                    : null,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Assigned Outlet / Branch'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('All Branches / Global')),
                  ...widget.branches!.map((b) => DropdownMenuItem(
                        value: b.id,
                        child: Text(
                          '${b.name} (${b.code})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      )),
                ],
                onChanged: (val) {
                  setState(() => _selectedBranchId = val);
                },
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981),
            foregroundColor: Colors.white,
          ),
          onPressed: _isSubmitting ? null : _handleSubmit,
          child: _isSubmitting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : Text(isEdit ? 'Save Changes' : 'Create User'),
        ),
      ],
    );
  }
}
