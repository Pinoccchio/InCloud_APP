import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Authentication state class
class AuthState {
  final User? user;
  final bool isLoading;
  final String? error;
  final bool isAuthenticated;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isAuthenticated = false,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    String? error,
    bool? isAuthenticated,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
    );
  }
}

// Authentication notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    _initialize();
    return const AuthState();
  }

  void _initialize() {
    // For frontend-only testing, skip Supabase initialization
    // TODO: Uncomment when backend is ready
    /*
    // Listen to auth state changes
    final supabase = Supabase.instance.client;
    final currentUser = supabase.auth.currentUser;

    if (currentUser != null) {
      state = state.copyWith(
        user: currentUser,
        isAuthenticated: true,
      );
    }

    // Listen for auth changes
    supabase.auth.onAuthStateChange.listen((data) {
      final user = data.session?.user;
      state = state.copyWith(
        user: user,
        isAuthenticated: user != null,
        error: null,
      );
    });
    */
  }

  // Sign in with email and password
  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // For frontend-only testing, simulate successful login
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Replace with actual Supabase auth when backend is ready
      /*
      final response = await Supabase.instance.client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isAuthenticated: true,
          isLoading: false,
        );
      }
      */

      // Simulate successful login for frontend testing
      state = state.copyWith(
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
      rethrow;
    }
  }

  // Sign up with email and password
  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? branchPreference,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // For frontend-only testing, simulate successful registration
      await Future.delayed(const Duration(seconds: 2));

      // TODO: Replace with actual Supabase auth when backend is ready
      /*
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'phone': phone,
          'branch_preference': branchPreference,
          'role': 'customer', // Default role for mobile app users
        },
      );

      // Note: User might need to verify email before being fully authenticated
      if (response.user != null) {
        state = state.copyWith(
          user: response.user,
          isAuthenticated: response.user!.emailConfirmedAt != null,
          isLoading: false,
        );
      }
      */

      // Simulate successful registration for frontend testing
      state = state.copyWith(
        isLoading: false,
        // Note: For signup, we don't auto-authenticate to show login flow
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred during registration',
      );
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await Supabase.instance.client.auth.signOut();
      state = const AuthState(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to sign out',
      );
      rethrow;
    }
  }

  // Reset password
  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await Supabase.instance.client.auth.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
    } on AuthException catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.message,
      );
      rethrow;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to send reset password email',
      );
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  // Check if user is authenticated
  bool get isAuthenticated => state.isAuthenticated;

  // Get current user
  User? get currentUser => state.user;
}

// Provider for authentication state
final authProvider = NotifierProvider<AuthNotifier, AuthState>(() {
  return AuthNotifier();
});

// Convenience providers
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});