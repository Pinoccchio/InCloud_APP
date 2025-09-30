import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/reset_password_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jxdzdkvnyjgwndxhvtzo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4ZHpka3ZueWpnd25keGh2dHpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NjA5OTMsImV4cCI6MjA3NDAzNjk5M30.J_HCRpXI1FaKPtGFdkHn3f882e2beUDcpRQCZID3MzA',
  );

  runApp(const ProviderScope(child: InCloudApp()));
}

class InCloudApp extends StatefulWidget {
  const InCloudApp({super.key});

  @override
  State<InCloudApp> createState() => _InCloudAppState();
}

class _InCloudAppState extends State<InCloudApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  StreamSubscription<AuthState>? _authStateSubscription;

  @override
  void initState() {
    super.initState();
    _setupDeepLinkListener();
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }

  void _setupDeepLinkListener() {
    print('🔗 Setting up deep link listener for password reset...');

    // Listen to auth state changes for password recovery
    _authStateSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      final AuthChangeEvent event = data.event;

      print('🔔 Auth state changed: $event');

      // Handle password recovery event
      if (event == AuthChangeEvent.passwordRecovery) {
        print('✅ Password recovery event detected!');
        print('   Session: ${data.session != null ? "Active" : "None"}');

        // Navigate to reset password screen
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _navigatorKey.currentState?.push(
            MaterialPageRoute(
              builder: (context) => const ResetPasswordScreen(),
            ),
          );
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
