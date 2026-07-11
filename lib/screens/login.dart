import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _authService = AuthService();
  bool _isPasswordObscured = true;
  bool _isLoading = false;
  String? _errorMessage;
  String _role = 'Treasurer';
  final _password = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  void _clearError() {
    if (_errorMessage != null) setState(() => _errorMessage = null);
  }

  void _selectRole(String role) {
    if (_role == role) return;
    setState(() => _role = role);
    _clearError();
  }

  String get _emailForRole => _role == 'Auditor'
      ? AuthService.auditorEmail
      : AuthService.treasurerEmail;

  Future<void> _handleLogin() async {
    if (_isLoading) return;

    if (_password.text.isEmpty) {
      setState(() => _errorMessage = 'Required');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final user = await _authService.loginWithEmail(
        _emailForRole,
        _password.text,
      );
      if (!mounted) return;

      final role = AuthService.roleFromEmail(user?.email ?? _emailForRole);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => DashboardScreen(officerRole: role),
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = AuthService.messageForError(e));
    } catch (_) {
      setState(() => _errorMessage = 'Could not sign in.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _roleButton(BuildContext context, String role) {
    final palette = context.colors;
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: _isLoading ? null : () => _selectRole(role),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: selected ? palette.primaryGradient : null,
            color: selected ? null : palette.bgSurfaceAlt,
            border: Border.all(
              color: selected ? Colors.transparent : palette.divider,
              width: 1.2,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            role,
            style: TextStyle(
              color: selected ? Colors.white : palette.textSecondary,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      child: Builder(
        builder: (context) {
          final palette = context.colors;
          final hasError = _errorMessage != null;

          return Scaffold(
            backgroundColor: Theme.of(context).brightness == Brightness.dark
                ? palette.bgDeep
                : palette.bgSurface,
            body: Container(
              decoration: BoxDecoration(gradient: palette.heroGradient),
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28.0,
                      vertical: 32.0,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        Center(
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: palette.divider,
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.all(0.5),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/CSO.png',
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return Icon(
                                    Icons.account_balance_rounded,
                                    size: 76,
                                    color: palette.accentCyan,
                                  );
                                },
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          'CSO FINANCE',
                          style: AppText.display(
                            context,
                          ).copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40),
                        const SectionLabel(
                          'Log in as',
                          padding: EdgeInsets.only(bottom: 8, left: 4),
                        ),
                        Row(
                          children: [
                            _roleButton(context, 'Treasurer'),
                            const SizedBox(width: 12),
                            _roleButton(context, 'Auditor'),
                          ],
                        ),
                        const SizedBox(height: 22),
                        const SectionLabel(
                          'Password',
                          padding: EdgeInsets.only(bottom: 8, left: 4),
                        ),
                        TextField(
                          controller: _password,
                          enabled: !_isLoading,
                          obscureText: _isPasswordObscured,
                          onChanged: (_) => _clearError(),
                          onSubmitted: (_) => _handleLogin(),
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            prefixIcon: Icon(
                              Icons.lock_outline_rounded,
                              color: palette.accentCyan,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordObscured
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: palette.textSecondary,
                              ),
                              onPressed: () => setState(
                                () =>
                                    _isPasswordObscured = !_isPasswordObscured,
                              ),
                            ),
                            enabledBorder: hasError
                                ? OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: palette.danger,
                                      width: 1.4,
                                    ),
                                  )
                                : null,
                            focusedBorder: hasError
                                ? OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: BorderSide(
                                      color: palette.danger,
                                      width: 1.6,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        if (hasError) ...[
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Text(
                              _errorMessage!,
                              style: TextStyle(
                                color: palette.danger,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 35),
                        Theme(
                          data: Theme.of(context).copyWith(
                            shadowColor: Colors.transparent,
                            elevatedButtonTheme: ElevatedButtonThemeData(
                              style: ElevatedButton.styleFrom(elevation: 0),
                            ),
                          ),
                          child: GradientButton(
                            label: _isLoading ? 'Signing In…' : 'Log In',
                            onPressed: _isLoading ? null : _handleLogin,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
