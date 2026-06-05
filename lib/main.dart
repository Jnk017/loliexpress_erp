import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../core/app_export.dart';
import '../widgets/custom_error_widget.dart';
import './services/role_service.dart';
import './services/supabase_service.dart';
import './services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  try {
    await SupabaseService.initialize();
  } catch (e) {
    debugPrint('Failed to initialize Supabase: $e');
  }

  // Initialize ThemeService
  await ThemeService.instance.initialize();

  bool hasShownError = false;

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    if (!hasShownError) {
      hasShownError = true;

      // Reset flag after 3 seconds to allow error widget on new screens
      Future.delayed(Duration(seconds: 5), () {
        hasShownError = false;
      });

      return CustomErrorWidget(errorDetails: details);
    }
    return SizedBox.shrink();
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    runApp(MyApp());
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ThemeService.instance,
      builder: (context, _) {
        return Sizer(
          builder: (context, orientation, screenType) {
            return MaterialApp(
              title: 'loliexpress_erp',
              theme: AppTheme.lightTheme,
              darkTheme: AppTheme.darkTheme,
              themeMode: ThemeService.instance.themeMode,
              // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
              builder: (context, child) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(1.0)),
                  child: child!,
                );
              },
              // 🚨 END CRITICAL SECTION
              debugShowCheckedModeBanner: false,
              initialRoute: AppRoutes.initial,
              onGenerateRoute: (settings) {
                final routeName = settings.name ?? '/';

                // Always allow these routes
                if (routeName == '/' ||
                    routeName == '/splash-screen' ||
                    routeName == '/login-screen' ||
                    routeName == '/force-password-change') {
                  final routes = AppRoutes.routes;
                  final builder = routes[routeName];
                  if (builder != null) {
                    return MaterialPageRoute(
                        builder: builder, settings: settings);
                  }
                }

                // Check role access
                if (!RoleService.instance.canAccess(routeName)) {
                  return MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(title: const Text('Accès refusé')),
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock,
                                size: 64, color: Colors.grey),
                            const SizedBox(height: 16),
                            const Text('Vous n\'avez pas accès à cette page.',
                                style: TextStyle(fontSize: 16)),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () => Navigator.pushReplacementNamed(
                                  context, RoleService.instance.getHomeRoute()),
                              child: const Text('Retour'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final routes = AppRoutes.routes;
                final builder = routes[routeName];
                if (builder != null) {
                  return MaterialPageRoute(
                      builder: builder, settings: settings);
                }
                return null;
              },
            );
          },
        );
      },
    );
  }
}
