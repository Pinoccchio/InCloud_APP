class EnvConfig {
  // Supabase Configuration
  static const String supabaseUrl = 'https://jxdzdkvnyjgwndxhvtzo.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4ZHpka3ZueWpnd25keGh2dHpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTg0NjA5OTMsImV4cCI6MjA3NDAzNjk5M30.J_HCRpXI1FaKPtGFdkHn3f882e2beUDcpRQCZID3MzA';

  // Application Settings
  static const String appName = 'InCloud Inventory Management';
  static const String companyName = "J.A's Food Trading";

  // Environment flags
  static const bool isDevelopment = true;
  static const bool enableLogging = isDevelopment;

  // API Endpoints (if needed for custom endpoints)
  static String get apiBaseUrl => '$supabaseUrl/rest/v1/';
  static String get authUrl => '$supabaseUrl/auth/v1/';
  static String get realtimeUrl => '${supabaseUrl.replaceFirst('https', 'wss')}/realtime/v1/';
}