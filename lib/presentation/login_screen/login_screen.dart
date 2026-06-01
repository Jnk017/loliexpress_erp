import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/role_service.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/email_input_widget.dart';
import './widgets/login_button_widget.dart';
import './widgets/logo_section_widget.dart';
import './widgets/password_input_widget.dart';

/// Login Screen for Loliexpress ERP
/// Provides secure multi-role authentication for business owners, staff, and B2B customers
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _generalError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  bool _validateInputs() {
    bool isValid = true;
    setState(() {
      _emailError = null;
      _passwordError = null;
      _generalError = null;
    });

    if (_emailController.text.trim().isEmpty) {
      setState(() {
        _emailError = 'L\'email ou nom d\'utilisateur est requis';
      });
      isValid = false;
    } else if (!_emailController.text.contains('@') &&
        !_emailController.text.contains('.')) {
      setState(() {
        _emailError = 'Format d\'email invalide';
      });
      isValid = false;
    }

    if (_passwordController.text.isEmpty) {
      setState(() {
        _passwordError = 'Le mot de passe est requis';
      });
      isValid = false;
    } else if (_passwordController.text.length < 6) {
      setState(() {
        _passwordError = 'Le mot de passe doit contenir au moins 6 caractères';
      });
      isValid = false;
    }

    return isValid;
  }

  Future<void> _handleLogin() async {
    if (!_validateInputs()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _generalError = null;
    });

    try {
      await AuthService.instance.signIn(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (!mounted) return;

      HapticFeedback.mediumImpact();

      await RoleService.instance.refreshRole();
      if (!mounted) return;

      Navigator.pushReplacementNamed(
          context, RoleService.instance.getHomeRoute());
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _generalError = e.toString().replaceFirst('Exception: ', '');
      });
      HapticFeedback.lightImpact();
    }
  }

  void _handleForgotPassword() {
    final resetEmailController = TextEditingController();
    final otpController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool codeSent = false;
    bool isSubmitting = false;
    String? resetError;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final rootMessenger = ScaffoldMessenger.of(this.context);
            Future<void> requestOtp() async {
              final email = resetEmailController.text.trim();
              if (email.isEmpty || isSubmitting) return;
              setDialogState(() {
                isSubmitting = true;
                resetError = null;
              });
              try {
                await AuthService.instance.resetPassword(email);
                setDialogState(() {
                  codeSent = true;
                  isSubmitting = false;
                });
              } catch (e) {
                setDialogState(() {
                  resetError = e.toString().replaceFirst('Exception: ', '');
                  isSubmitting = false;
                });
              }
            }

            Future<void> verifyOtp() async {
              final email = resetEmailController.text.trim();
              final password = newPasswordController.text;
              if (isSubmitting) return;
              if (password.length < 8) {
                setDialogState(() {
                  resetError =
                      'Le mot de passe doit contenir au moins 8 caractères.';
                });
                return;
              }
              if (password != confirmPasswordController.text) {
                setDialogState(() {
                  resetError = 'Les mots de passe ne correspondent pas.';
                });
                return;
              }
              setDialogState(() {
                isSubmitting = true;
                resetError = null;
              });
              try {
                await AuthService.instance.verifyPasswordResetOtp(
                  email: email,
                  otp: otpController.text.trim(),
                  password: password,
                );
                if (!mounted) return;
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
                rootMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Mot de passe réinitialisé. Connectez-vous.'),
                  ),
                );
              } catch (e) {
                setDialogState(() {
                  resetError = e.toString().replaceFirst('Exception: ', '');
                  isSubmitting = false;
                });
              }
            }

            return AlertDialog(
              title: Text(
                'Réinitialisation par OTP',
                style: theme.textTheme.titleLarge,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      codeSent
                          ? 'Entrez le code reçu par email et votre nouveau mot de passe.'
                          : 'Entrez votre email pour recevoir un code OTP à 6 chiffres.',
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: resetEmailController,
                      enabled: !codeSent,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        hintText: 'votre@email.com',
                      ),
                    ),
                    if (codeSent) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        decoration: const InputDecoration(
                          labelText: 'Code OTP',
                          counterText: '',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: newPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Nouveau mot de passe',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                        ),
                      ),
                    ],
                    if (resetError != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        resetError!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.pop(dialogContext),
                  child: Text(
                    'Annuler',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                TextButton(
                  onPressed:
                      isSubmitting ? null : (codeSent ? verifyOtp : requestOtp),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          codeSent ? 'Valider' : 'Envoyer le code',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      resetEmailController.dispose();
      otpController.dispose();
      newPasswordController.dispose();
      confirmPasswordController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 6.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SizedBox(height: 2.h),

                    // Logo Section
                    const LogoSectionWidget(),

                    SizedBox(height: 2.5.h),

                    // Login Form
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Email Input
                          EmailInputWidget(
                            controller: _emailController,
                            errorText: _emailError,
                            onChanged: (_) {
                              setState(() => _emailError = null);
                            },
                          ),

                          SizedBox(height: 2.h),

                          // Password Input
                          PasswordInputWidget(
                            controller: _passwordController,
                            errorText: _passwordError,
                            onChanged: (_) {
                              setState(() => _passwordError = null);
                            },
                            onSubmitted: _handleLogin,
                          ),

                          SizedBox(height: 2.h),

                          // Forgot Password Link
                          OutlinedButton.icon(
                            onPressed: _handleForgotPassword,
                            icon: const Icon(Icons.lock_reset),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 1.5.h),
                              side: BorderSide(
                                color: theme.colorScheme.primary,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            label: Text(
                              'Mot de passe oublié ? Réinitialiser par OTP',
                              textAlign: TextAlign.center,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          SizedBox(height: 2.h),

                          // General Error Message
                          if (_generalError != null) ...[
                            Container(
                              padding: EdgeInsets.all(3.w),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.error
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: theme.colorScheme.error
                                      .withValues(alpha: 0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  CustomIconWidget(
                                    iconName: 'error_outline',
                                    size: 20,
                                    color: theme.colorScheme.error,
                                  ),
                                  SizedBox(width: 3.w),
                                  Expanded(
                                    child: Text(
                                      _generalError!,
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 3.h),
                          ],

                          // Login Button
                          LoginButtonWidget(
                            onPressed: _handleLogin,
                            isLoading: _isLoading,
                            isEnabled: true,
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 4.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
