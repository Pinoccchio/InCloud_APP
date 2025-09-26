class AppLogger {
  /// Log authentication events directly to terminal
  static void logAuthEvent({
    required String event,
    required String email,
    bool success = false,
    String? error,
    String? additionalInfo,
  }) {
    final timestamp = DateTime.now().toString().substring(11, 19); // Just time
    final status = success ? '✅ SUCCESS' : '❌ FAIL';
    final maskedEmail = _maskEmail(email);

    print('');
    print('🔐 AUTH [$timestamp] $event');
    print('   User: $maskedEmail');
    print('   Status: $status');

    if (!success && error != null) {
      print('   Error: $error');
    }

    if (additionalInfo != null) {
      print('   Info: $additionalInfo');
    }
    print('');
  }

  /// Log general events
  static void logInfo(String message, {String? category}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    final prefix = category != null ? '[$category]' : '[INFO]';
    print('💡 $prefix [$timestamp] $message');
  }

  /// Log errors
  static void logError(String error, {String? context}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    print('');
    print('❌ ERROR [$timestamp] $error');
    if (context != null) {
      print('   Context: $context');
    }
    print('');
  }

  /// Log critical errors
  static void logCritical(String error, {String? context}) {
    final timestamp = DateTime.now().toString().substring(11, 19);
    print('');
    print('🚨 CRITICAL [$timestamp] $error');
    if (context != null) {
      print('   Context: $context');
    }
    print('   >>> This needs immediate attention! <<<');
    print('');
  }

  /// Mask email for privacy while keeping it recognizable
  static String _maskEmail(String email) {
    if (email.length < 3) return email;
    final parts = email.split('@');
    if (parts.length != 2) return email;

    final username = parts[0];
    final domain = parts[1];

    String maskedUsername;
    if (username.length <= 2) {
      maskedUsername = username;
    } else if (username.length <= 4) {
      maskedUsername = '${username[0]}***${username[username.length - 1]}';
    } else {
      maskedUsername = '${username.substring(0, 2)}***${username.substring(username.length - 2)}';
    }

    return '$maskedUsername@$domain';
  }
}