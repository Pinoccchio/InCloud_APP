import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'screens/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await Supabase.initialize(
    url: 'https://jxdzdkvnyjgwndxhvtzo.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4ZHpka3ZueWpnd25keGh2dHpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NjA5OTMsImV4cCI6MjA3NDAzNjk5M30.J_HCRpXI1FaKPtGFdkHn3f882e2beUDcpRQCZID3MzA',
  );

  runApp(const ProviderScope(child: InCloudApp()));
}

class InCloudApp extends StatelessWidget {
  const InCloudApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appName,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
