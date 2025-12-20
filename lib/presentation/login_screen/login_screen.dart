import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/email_input_widget.dart';
import './widgets/login_button_widget.dart';
import './widgets/logo_section_widget.dart';
import './widgets/password_input_widget.dart';
import './widgets/role_selector_widget.dart';

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

  String? _selectedRole;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;
  String? _roleError;
  String? _generalError;

  // Mock credentials for different roles
  final Map<String, Map<String, String>> _mockCredentials = {
    'admin': {
      'email': 'admin@loliexpress.com',
      'password': 'Admin@2024',
    },
    'sales': {
      'email': 'sales@loliexpress.com',
      'password': 'Sales@2024',
    },
    'warehouse': {
      'email': 'warehouse@loliexpress.com',
      'password': 'Warehouse@2024',
    },
    'customer': {
      'email': 'customer@loliexpress.com',
      'password': 'Customer@2024',
    },
  };

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
      _roleError = null;
      _generalError = null;
    });

    // Validate email
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

    // Validate password
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

    // Validate role
    if (_selectedRole == null) {
      setState(() {
        _roleError = 'Veuillez sélectionner un rôle';
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

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));

    // Validate credentials
    final credentials = _mockCredentials[_selectedRole];
    if (credentials != null &&
        credentials['email'] == _emailController.text.trim() &&
        credentials['password'] == _passwordController.text) {
      // Success - trigger haptic feedback
      HapticFeedback.mediumImpact();

      if (!mounted) return;

      // Navigate to appropriate dashboard based on role
      String route = '/main-dashboard';
      if (_selectedRole == 'customer') {
        route = '/customer-portal';
      }

      Navigator.pushReplacementNamed(context, route);
    } else {
      setState(() {
        _isLoading = false;
        _generalError =
            'Email, mot de passe ou rôle incorrect. Veuillez réessayer.';
      });

      // Error haptic feedback
      HapticFeedback.lightImpact();
    }
  }

  void _handleForgotPassword() {
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Mot de passe oublié',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            'Veuillez contacter votre administrateur système pour réinitialiser votre mot de passe.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Fermer',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
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
                    SizedBox(height: 4.h),

                    // Logo Section
                    const LogoSectionWidget(),

                    SizedBox(height: 5.h),

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
                              if (_emailError != null) {
                                setState(() => _emailError = null);
                              }
                            },
                          ),

                          SizedBox(height: 3.h),

                          // Password Input
                          PasswordInputWidget(
                            controller: _passwordController,
                            errorText: _passwordError,
                            onChanged: (_) {
                              if (_passwordError != null) {
                                setState(() => _passwordError = null);
                              }
                            },
                            onSubmitted: _handleLogin,
                          ),

                          SizedBox(height: 3.h),

                          // Role Selector
                          RoleSelectorWidget(
                            selectedRole: _selectedRole,
                            errorText: _roleError,
                            onRoleChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                                _roleError = null;
                              });
                            },
                          ),

                          SizedBox(height: 2.h),

                          // Forgot Password Link
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: _handleForgotPassword,
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 2.w,
                                  vertical: 1.h,
                                ),
                              ),
                              child: Text(
                                'Mot de passe oublié?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w500,
                                ),
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
                            isEnabled: _emailController.text.isNotEmpty &&
                                _passwordController.text.isNotEmpty &&
                                _selectedRole != null,
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
