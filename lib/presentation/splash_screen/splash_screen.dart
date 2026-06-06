import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/auth_service.dart';
import '../../services/role_service.dart';

/// Splash Screen for Loliexpress ERP
/// Provides branded app launch experience while initializing core ERP services
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  bool _isInitializing = true;
  String _initializationStatus = 'Initialisation...';

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack),
      ),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      await Future.delayed(const Duration(milliseconds: 800));
      if (mounted) {
        setState(() {
          _initializationStatus = 'Vérification de l\'authentification...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) {
        setState(() {
          _initializationStatus = 'Chargement des préférences...';
        });
      }

      await Future.delayed(const Duration(milliseconds: 800));

      if (mounted) {
        setState(() {
          _isInitializing = false;
        });

        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        if (AuthService.instance.isAuthenticated) {
          if (await AuthService.instance.mustChangePassword()) {
            if (!mounted) return;
            Navigator.pushReplacementNamed(context, '/force-password-change');
            return;
          }
          await RoleService.instance.refreshRole();
          if (!mounted) return;

          Navigator.pushReplacementNamed(
              context, RoleService.instance.getHomeRoute());
        } else {
          Navigator.pushReplacementNamed(context, '/login-screen');
        }
      }
    } catch (e) {
      if (!AuthService.instance.isAuthenticated && mounted) {
        Navigator.pushReplacementNamed(context, '/login-screen');
        return;
      }
      if (mounted) {
        setState(() {
          _initializationStatus = 'Erreur d\'initialisation';
          _isInitializing = false;
        });

        await Future.delayed(const Duration(seconds: 5));
        if (mounted) {
          _showRetryDialog();
        }
      }
    }
  }

  void _showRetryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          title: Text(
            'Erreur de connexion',
            style: theme.textTheme.titleLarge,
          ),
          content: Text(
            'Impossible de se connecter au serveur. Veuillez vérifier votre connexion Internet et réessayer.',
            style: theme.textTheme.bodyMedium,
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                setState(() {
                  _isInitializing = true;
                  _initializationStatus = 'Initialisation...';
                });
                _initializeApp();
              },
              child: Text(
                'Réessayer',
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
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    // Set system UI overlay style
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
    );

    return Scaffold(
      body: Container(
        width: size.width,
        height: size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.primaryContainer,
              theme.colorScheme.secondary,
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Animated Logo
              FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: _buildLogo(theme),
                ),
              ),
              const SizedBox(height: 48),
              // App Name
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Loliexpress ERP',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: theme.colorScheme.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Grandir Ensemble',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.9),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const Spacer(flex: 2),
              // Loading Indicator and Status
              if (_isInitializing) ...[
                SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.onPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _initializationStatus,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              // Version Info
              Text(
                'Version 1.0.0',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onPrimary.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.onPrimary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Image.asset(
        'assets/images/logo_loliexpress.png',
        width: 120,
        height: 120,
        fit: BoxFit.contain,
      ),
    );
  }
}
