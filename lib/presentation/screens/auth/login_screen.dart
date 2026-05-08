import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/app_background_scaffold.dart';
import '../../widgets/common/app_colors.dart';
import '../../widgets/common/loading_overlay.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _images = const [
    'assets/images/login_1.png',
    'assets/images/login_2.png',
    'assets/images/login_3.png',
  ];

  bool _hide = true;
  bool _remember = true;
  int _imageIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted) return;
      setState(() => _imageIndex = (_imageIndex + 1) % _images.length);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    final ok = await context.read<AuthProvider>().login(
          email: _email.text.trim(),
          password: _password.text,
          remember: _remember,
        );
    if (!ok && mounted) {
      final error = context.read<AuthProvider>().error ?? 'No se pudo ingresar';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return LoadingOverlay(
      loading: auth.loading,
      child: AppBackgroundScaffold(
          imagePath: _images[_imageIndex],
          overlayOpacity: 0.35,
          enableSpeedLines: true,
          showSidebar: false,
          scrollContent: false,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isMobile = constraints.maxWidth < 700;
                final bottomPadding = isMobile
                    ? 24 + MediaQuery.of(context).viewPadding.bottom
                    : 32.0;

                return Align(
                  alignment:
                      isMobile ? Alignment.bottomCenter : Alignment.centerRight,
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 2 : 32,
                      20,
                      isMobile ? 2 : 48,
                      bottomPadding,
                    ),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isMobile ? 390 : 430,
                        maxHeight: isMobile
                            ? constraints.maxHeight * 0.45
                            : double.infinity,
                      ),
                      child: _LoginGlassCard(
                        formKey: _formKey,
                        email: _email,
                        password: _password,
                        hidePassword: _hide,
                        remember: _remember,
                        error: auth.error,
                        loading: auth.loading,
                        onTogglePassword: () => setState(() => _hide = !_hide),
                        onRememberChanged: (value) =>
                            setState(() => _remember = value),
                        onLogin: _login,
                        onBiometricLogin: () =>
                            context.read<AuthProvider>().biometricLogin(),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
    );
  }
}

class _LoginGlassCard extends StatelessWidget {
  const _LoginGlassCard({
    required this.formKey,
    required this.email,
    required this.password,
    required this.hidePassword,
    required this.remember,
    required this.error,
    required this.loading,
    required this.onTogglePassword,
    required this.onRememberChanged,
    required this.onLogin,
    required this.onBiometricLogin,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController email;
  final TextEditingController password;
  final bool hidePassword;
  final bool remember;
  final String? error;
  final bool loading;
  final VoidCallback onTogglePassword;
  final ValueChanged<bool> onRememberChanged;
  final VoidCallback onLogin;
  final VoidCallback onBiometricLogin;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.38),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.22)),
            boxShadow: [
              BoxShadow(
                color: AppColors.cyan.withValues(alpha: 0.12),
                blurRadius: 28,
                spreadRadius: 1,
              ),
            ],
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Iniciar sesion',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Accede a FINASANGRE',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _CompactField(
                    child: TextFormField(
                      controller: email,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email o usuario',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Ingresa el email'
                              : null,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _CompactField(
                    child: TextFormField(
                      controller: password,
                      obscureText: hidePassword,
                      decoration: InputDecoration(
                        labelText: 'Contrasena',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: onTogglePassword,
                          icon: Icon(
                            hidePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                        ),
                      ),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Ingresa la contrasena'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 6),
                  SwitchListTile(
                    dense: true,
                    visualDensity: VisualDensity.compact,
                    value: remember,
                    onChanged: onRememberChanged,
                    title: const Text(
                      'Recordar sesion',
                      style: TextStyle(fontSize: 13),
                    ),
                    activeThumbColor: AppColors.cyan,
                    contentPadding: EdgeInsets.zero,
                  ),
                  if (error != null) ...[
                    Text(error!, style: const TextStyle(color: AppColors.red)),
                    const SizedBox(height: 8),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 56,
                          child: FilledButton.icon(
                            onPressed: loading ? null : onLogin,
                            icon: const Icon(Icons.login),
                            label: const Text('Ingresar'),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 58,
                        height: 58,
                        child: IconButton.filled(
                          icon: const Icon(Icons.fingerprint, size: 30),
                          onPressed: loading ? null : onBiometricLogin,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CompactField extends StatelessWidget {
  const _CompactField({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(height: 56, child: child);
  }
}
