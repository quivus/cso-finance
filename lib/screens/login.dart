import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'dashboard.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isPasswordObscured = true;
  String _role = 'Treasurer';
  final _username = TextEditingController();
  final _password = TextEditingController();

  @override
  void dispose() {
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Widget _roleButton(BuildContext context, String role) {
    final palette = context.colors;
    final selected = _role == role;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _role = role),
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
                              color: palette.bgSurfaceAlt,
                              border: Border.all(
                                color: palette.divider,
                                width: 1.2,
                              ),
                            ),
                            padding: const EdgeInsets.all(0.5),
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
                        const SizedBox(height: 32),
                        Text(
                          'CSO FINANCE',
                          style: AppText.display(
                            context,
                          ).copyWith(fontWeight: FontWeight.w800),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 44),
                        const SectionLabel(
                          'Username',
                          padding: EdgeInsets.only(bottom: 8, left: 4),
                        ),
                        TextField(
                          controller: _username,
                          style: TextStyle(
                            color: palette.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Enter your username',
                            prefixIcon: Icon(
                              Icons.person_outline_rounded,
                              color: palette.accentCyan,
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const SectionLabel(
                          'Password',
                          padding: EdgeInsets.only(bottom: 8, left: 4),
                        ),
                        TextField(
                          controller: _password,
                          obscureText: _isPasswordObscured,
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
                          ),
                        ),
                        const SizedBox(height: 30),
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
                        const SizedBox(height: 30),
                        GradientButton(
                          label: 'Log In',
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    DashboardScreen(officerRole: _role),
                              ),
                            );
                          },
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
