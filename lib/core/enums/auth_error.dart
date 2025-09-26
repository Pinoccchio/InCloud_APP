/// Enumeration of authentication error types for better error handling and debugging
enum AuthErrorType {
  // Network/Connection errors
  networkError,
  connectionTimeout,

  // Authentication errors
  invalidCredentials,
  userNotFound,
  emailAlreadyExists,
  weakPassword,
  invalidEmail,
  emailNotConfirmed,

  // Database/Profile errors
  profileCreationFailed,
  profileNotFound,
  orphanedUser,

  // System errors
  unknownError,
  serviceUnavailable,
  rateLimitExceeded,

  // Validation errors
  invalidInput,
  missingRequiredField,

  // Session errors
  sessionExpired,
  invalidSession,
}

/// Authentication error class with type, message, and debugging information
class AuthError {
  final AuthErrorType type;
  final String userMessage;
  final String? debugMessage;
  final String? originalError;
  final Map<String, dynamic>? metadata;

  const AuthError({
    required this.type,
    required this.userMessage,
    this.debugMessage,
    this.originalError,
    this.metadata,
  });

  /// Factory constructor to create AuthError from exception
  factory AuthError.fromException(
    dynamic exception, {
    AuthErrorType? fallbackType,
    String? customUserMessage,
  }) {
    final errorString = exception.toString().toLowerCase();

    // Determine error type based on exception content
    AuthErrorType type;
    String userMessage;

    if (errorString.contains('network') || errorString.contains('connection')) {
      type = AuthErrorType.networkError;
      userMessage = 'Network error. Please check your internet connection and try again.';
    } else if (errorString.contains('timeout')) {
      type = AuthErrorType.connectionTimeout;
      userMessage = 'Connection timeout. Please try again.';
    } else if (errorString.contains('invalid credentials') ||
               errorString.contains('invalid login') ||
               errorString.contains('wrong password')) {
      type = AuthErrorType.invalidCredentials;
      userMessage = 'Invalid email or password. Please check your credentials and try again.';
    } else if (errorString.contains('user not found') ||
               errorString.contains('no user found')) {
      type = AuthErrorType.userNotFound;
      userMessage = 'No account found with this email. Please check your email or sign up.';
    } else if (errorString.contains('already registered') ||
               errorString.contains('email address already')) {
      type = AuthErrorType.emailAlreadyExists;
      userMessage = 'An account with this email already exists. Please try signing in instead.';
    } else if (errorString.contains('weak password') ||
               errorString.contains('password')) {
      type = AuthErrorType.weakPassword;
      userMessage = 'Password is too weak. Please use at least 8 characters with letters and numbers.';
    } else if (errorString.contains('invalid email') ||
               errorString.contains('malformed email')) {
      type = AuthErrorType.invalidEmail;
      userMessage = 'Please enter a valid email address.';
    } else if (errorString.contains('email not confirmed') ||
               errorString.contains('confirm your email')) {
      type = AuthErrorType.emailNotConfirmed;
      userMessage = 'Please confirm your email address before signing in.';
    } else if (errorString.contains('profile creation') ||
               errorString.contains('customer profile')) {
      type = AuthErrorType.profileCreationFailed;
      userMessage = 'Account creation failed. Please try again or contact support.';
    } else if (errorString.contains('profile not found') ||
               errorString.contains('customer not found')) {
      type = AuthErrorType.profileNotFound;
      userMessage = 'Your account profile is missing. Please contact support for assistance.';
    } else if (errorString.contains('orphaned') ||
               errorString.contains('missing profile information')) {
      type = AuthErrorType.orphanedUser;
      userMessage = 'Your account exists but is missing profile information. Please contact support.';
    } else if (errorString.contains('rate limit') ||
               errorString.contains('too many requests')) {
      type = AuthErrorType.rateLimitExceeded;
      userMessage = 'Too many attempts. Please wait a moment before trying again.';
    } else if (errorString.contains('service unavailable') ||
               errorString.contains('server error')) {
      type = AuthErrorType.serviceUnavailable;
      userMessage = 'Service temporarily unavailable. Please try again later.';
    } else if (errorString.contains('session expired') ||
               errorString.contains('token expired')) {
      type = AuthErrorType.sessionExpired;
      userMessage = 'Your session has expired. Please sign in again.';
    } else {
      type = fallbackType ?? AuthErrorType.unknownError;
      userMessage = customUserMessage ?? 'Something went wrong. Please try again.';
    }

    return AuthError(
      type: type,
      userMessage: userMessage,
      debugMessage: 'Original error: $exception',
      originalError: exception.toString(),
      metadata: {
        'timestamp': DateTime.now().toIso8601String(),
        'error_classification': 'auto_detected',
      },
    );
  }

  /// Factory constructor for specific error types
  factory AuthError.networkError([String? customMessage]) {
    return AuthError(
      type: AuthErrorType.networkError,
      userMessage: customMessage ?? 'Network error. Please check your internet connection.',
      debugMessage: 'Network connectivity issue detected',
    );
  }

  factory AuthError.invalidCredentials([String? customMessage]) {
    return AuthError(
      type: AuthErrorType.invalidCredentials,
      userMessage: customMessage ?? 'Invalid email or password.',
      debugMessage: 'Authentication credentials rejected',
    );
  }

  factory AuthError.profileCreationFailed([String? customMessage, String? debugInfo]) {
    return AuthError(
      type: AuthErrorType.profileCreationFailed,
      userMessage: customMessage ?? 'Account creation failed. Please try again.',
      debugMessage: debugInfo ?? 'Customer profile creation process failed',
      metadata: {
        'critical': true,
        'requires_investigation': true,
      },
    );
  }

  factory AuthError.orphanedUser(String userId, [String? customMessage]) {
    return AuthError(
      type: AuthErrorType.orphanedUser,
      userMessage: customMessage ?? 'Your account exists but is missing profile information.',
      debugMessage: 'Auth user exists without corresponding customer profile',
      metadata: {
        'user_id': userId,
        'recovery_attempted': false,
        'critical': true,
      },
    );
  }

  /// Convert to JSON for logging
  Map<String, dynamic> toJson() {
    return {
      'type': type.toString(),
      'user_message': userMessage,
      'debug_message': debugMessage,
      'original_error': originalError,
      'metadata': metadata ?? {},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get error category for analytics
  String get category {
    switch (type) {
      case AuthErrorType.networkError:
      case AuthErrorType.connectionTimeout:
        return 'NETWORK';
      case AuthErrorType.invalidCredentials:
      case AuthErrorType.userNotFound:
      case AuthErrorType.emailNotConfirmed:
        return 'AUTHENTICATION';
      case AuthErrorType.emailAlreadyExists:
      case AuthErrorType.weakPassword:
      case AuthErrorType.invalidEmail:
        return 'VALIDATION';
      case AuthErrorType.profileCreationFailed:
      case AuthErrorType.profileNotFound:
      case AuthErrorType.orphanedUser:
        return 'PROFILE';
      case AuthErrorType.sessionExpired:
      case AuthErrorType.invalidSession:
        return 'SESSION';
      case AuthErrorType.serviceUnavailable:
      case AuthErrorType.rateLimitExceeded:
        return 'SERVICE';
      default:
        return 'UNKNOWN';
    }
  }

  /// Check if this is a critical error that needs immediate attention
  bool get isCritical {
    return type == AuthErrorType.profileCreationFailed ||
           type == AuthErrorType.orphanedUser ||
           type == AuthErrorType.serviceUnavailable ||
           (metadata?['critical'] == true);
  }

  /// Check if this error suggests user should contact support
  bool get shouldContactSupport {
    return type == AuthErrorType.profileNotFound ||
           type == AuthErrorType.orphanedUser ||
           type == AuthErrorType.profileCreationFailed ||
           isCritical;
  }

  @override
  String toString() {
    return 'AuthError(type: $type, message: $userMessage)';
  }
}