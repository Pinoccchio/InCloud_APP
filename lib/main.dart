import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Core imports
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';

// Service imports
import 'services/supabase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  await SupabaseService.initialize();

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
      routerConfig: appRouter,
      debugShowCheckedModeBanner: false,
    );
  }
}
