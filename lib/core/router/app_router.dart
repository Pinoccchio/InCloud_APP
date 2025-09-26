import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Core
import '../app_shell.dart';

// Screens
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/home/main_app_screen.dart';

// Simple router with app shell handling auth state
final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
      // App shell handles all authentication routing
      GoRoute(
        path: '/',
        builder: (context, state) => const AppShell(),
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

      // Protected routes
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainAppScreen(),
      ),
    ],
  errorBuilder: (context, state) => Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.red,
          ),
          const SizedBox(height: 16),
          Text(
            'Page not found',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(
            state.error?.toString() ?? 'Unknown error',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go('/'),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  ),
);