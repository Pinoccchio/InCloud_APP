import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';

// Screen imports
import 'screens/splash/splash_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/main_app_screen.dart';

void main() {
  runApp(
    const ProviderScope(
      child: InCloudApp(),
    ),
  );
}

class InCloudApp extends StatelessWidget {
  const InCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      routerConfig: _router,
      debugShowCheckedModeBanner: false,
    );
  }
}

// GoRouter configuration
final GoRouter _router = GoRouter(
  routes: [
    // Splash screen
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),

    // Onboarding screen
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingScreen(),
    ),

    // Authentication routes
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupScreen(),
    ),

    // Main app route (placeholder)
    GoRoute(
      path: '/home',
      builder: (context, state) => const MainAppScreen(),
    ),
  ],
);
