import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';

class RoleLoginFormCard extends StatefulWidget {
  final String roleName;
  final Color themeColor;
  final bool isLoading;
  final bool isMobile;
  final bool isCompactHeight;
  final Future<void> Function(String userId, String password) onLogin;
  final VoidCallback onCheckUpdate;
  final bool isCheckingUpdate;

  const RoleLoginFormCard({
    super.key,
    required this.roleName,
    required this.themeColor,
    required this.isLoading,
    this.isMobile = false,
    this.isCompactHeight = false,
    required this.onLogin,
    required this.onCheckUpdate,
    required this.isCheckingUpdate,
  });

  @override
  State<RoleLoginFormCard> createState() => _RoleLoginFormCardState();
}

class _RoleLoginFormCardState extends State<RoleLoginFormCard> {
  final _userIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _hasSavedCredentials = false;

  @override
  void initState() {
    super.initState();
    _loadSavedCredentials();
  }

  @override
  void didUpdateWidget(covariant RoleLoginFormCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.roleName != widget.roleName) {
      _loadSavedCredentials();
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final creds = await AuthService.getRememberedCredentials(widget.roleName);
      if (!mounted) return;
      final savedUser = (creds['userId'] ?? '').toString();
      final savedPass = (creds['password'] ?? '').toString();
      final isRemembered = creds['rememberMe'] == true;

      if (isRemembered && (savedUser.isNotEmpty || savedPass.isNotEmpty)) {
        setState(() {
          _userIdController.text = savedUser;
          _passwordController.text = savedPass;
          _rememberMe = true;
          _hasSavedCredentials = true;
        });
      } else {
        setState(() {
          _userIdController.clear();
          _passwordController.clear();
          _rememberMe = false;
          _hasSavedCredentials = false;
        });
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _userIdController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _clearSaved() async {
    await AuthService.clearRememberedCredentials(widget.roleName);
    if (!mounted) return;
    setState(() {
      _userIdController.clear();
      _passwordController.clear();
      _hasSavedCredentials = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Saved credentials cleared on this device.'),
        duration: Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final userId = _userIdController.text.trim();
      final password = _passwordController.text.trim();

      await AuthService.saveRememberedCredentials(
        roleName: widget.roleName,
        userId: userId,
        password: password,
        rememberMe: _rememberMe,
      );

      widget.onLogin(userId, password);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1E293B);
    final subtitleColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final inputFillColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    final isMobile = widget.isMobile;
    final isCompact = widget.isCompactHeight;

    return Container(
      padding: EdgeInsets.all(isMobile ? (isCompact ? 16 : 20) : 32),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(isMobile ? 18 : 24),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 40,
            offset: Offset(0, 20),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isCompact) ...[
              Container(
                padding: EdgeInsets.all(isMobile ? 12 : 16),
                decoration: BoxDecoration(
                  color: widget.themeColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.roleName.contains('Waiter')
                      ? Icons.room_service_rounded
                      : widget.roleName == 'Kitchen Display'
                          ? Icons.soup_kitchen_rounded
                          : widget.roleName.contains('Inventory')
                              ? Icons.inventory_2_rounded
                              : Icons.admin_panel_settings,
                  size: isMobile ? 36 : 64,
                  color: widget.themeColor,
                ),
              ),
              SizedBox(height: isMobile ? 10 : 16),
            ],
            Text(
              'Access ${widget.roleName} Module',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMobile ? 18 : 22,
                fontWeight: FontWeight.w900,
                color: textColor,
              ),
            ),
            SizedBox(height: isMobile ? 3 : 8),
            Text(
              'Sign in with ${widget.roleName} credentials',
              style: TextStyle(color: subtitleColor, fontSize: isMobile ? 12.5 : 14),
            ),
            SizedBox(height: isMobile ? (isCompact ? 12 : 16) : 24),
            TextFormField(
              controller: _userIdController,
              textInputAction: TextInputAction.next,
              style: TextStyle(color: textColor, fontSize: isMobile ? 13.5 : 14),
              decoration: InputDecoration(
                hintText: 'User ID / Email',
                hintStyle: TextStyle(color: subtitleColor, fontSize: isMobile ? 13 : 14),
                prefixIcon: Icon(Icons.person_outline, color: const Color(0xFF94A3B8), size: isMobile ? 18 : 22),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 12 : 16),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.themeColor, width: 1.6),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter User ID' : null,
            ),
            SizedBox(height: isMobile ? 10 : 16),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              style: TextStyle(color: textColor, fontSize: isMobile ? 13.5 : 14),
              onFieldSubmitted: (_) => _submit(),
              decoration: InputDecoration(
                hintText: 'Password',
                hintStyle: TextStyle(color: subtitleColor, fontSize: isMobile ? 13 : 14),
                prefixIcon: Icon(Icons.lock_outline, color: const Color(0xFF94A3B8), size: isMobile ? 18 : 22),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: const Color(0xFF94A3B8),
                    size: isMobile ? 18 : 22,
                  ),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
                isDense: true,
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: isMobile ? 12 : 16),
                filled: true,
                fillColor: inputFillColor,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: borderColor)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: widget.themeColor, width: 1.6),
                ),
              ),
              validator: (v) => v!.isEmpty ? 'Enter password' : null,
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                InkWell(
                  onTap: () => setState(() => _rememberMe = !_rememberMe),
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 18,
                          height: 18,
                          child: Checkbox(
                            value: _rememberMe,
                            onChanged: (val) => setState(() => _rememberMe = val ?? false),
                            activeColor: widget.themeColor,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Save ID & Password',
                          style: TextStyle(
                            color: textColor,
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_hasSavedCredentials)
                  TextButton(
                    onPressed: _clearSaved,
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(50, 24),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Clear Saved',
                      style: TextStyle(
                        color: subtitleColor,
                        fontSize: isMobile ? 11 : 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: isMobile ? (isCompact ? 10 : 14) : 18),
            SizedBox(
              width: double.infinity,
              height: isMobile ? 44 : 50,
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.themeColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: widget.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'LOGIN',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: isMobile ? 14 : 16,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: isMobile ? 16 : 18),
                        ],
                      ),
              ),
            ),
            SizedBox(height: isMobile ? 12 : 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.security_rounded, size: isMobile ? 13 : 16, color: const Color(0xFF64748B)),
                const SizedBox(width: 6),
                Text(
                  'Authorized ${widget.roleName} personnel only.',
                  style: TextStyle(color: const Color(0xFF64748B), fontSize: isMobile ? 10.5 : 12),
                ),
              ],
            ),
            if (!kIsWeb && !isMobile) ...[
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: widget.isCheckingUpdate ? null : widget.onCheckUpdate,
                  icon: widget.isCheckingUpdate
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF64748B)),
                        )
                      : const Icon(Icons.system_update_alt_rounded, size: 16, color: Color(0xFF64748B)),
                  label: Text(
                    widget.isCheckingUpdate ? 'Checking for updates...' : 'Check for app updates',
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
