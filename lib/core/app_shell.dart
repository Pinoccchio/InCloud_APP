import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../screens/splash/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/home/main_app_screen.dart';

/// App shell that handles authentication state and navigation
class AppShell extends ConsumerWidget {
  const AppShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Listen to auth state changes and navigate accordingly
    ref.listen<AuthState>(authProvider, (previous, next) {
      // Only navigate if authentication state actually changed
      if (previous?.isAuthenticated != next.isAuthenticated) {
        if (next.isAuthenticated) {
          // User just logged in, navigate to home
          context.go('/home');
        } else if (previous?.isAuthenticated == true) {
          // User just logged out, navigate to login
          context.go('/login');
        }
      }
    });

    // Show loading screen while initializing
    if (authState.isLoading) {
      return const SplashScreen();
    }

    // Show login screen if not authenticated
    if (!authState.isAuthenticated) {
      return const LoginScreen();
    }

    // Show home screen if authenticated
    return const MainAppScreen();
  }
}