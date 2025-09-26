import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/supabase_service.dart';

// Authentication state class
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final User? user;
  final Session? session;
  final Map<String, dynamic>? customerProfile;
  final String? error;
  final String? successMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.user,
    this.session,
    this.customerProfile,
    this.error,
    this.successMessage,
  });

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    User? user,
    Session? session,
    Map<String, dynamic>? customerProfile,
    String? error,
    String? successMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      session: session ?? this.session,
      customerProfile: customerProfile ?? this.customerProfile,
      error: error,
      successMessage: successMessage,
    );
  }
}

// Authentication notifier
class AuthNotifier extends Notifier<AuthState> {
  @override
  AuthState build() {
    // Return initial state immediately, defer initialization
    Future.microtask(() => _initializeAuth());
    return const AuthState(isLoading: true);
  }

  Future<void> _initializeAuth() async {
    // No need to set loading here as it's already set in build()

    try {
      final session = SupabaseService.client.auth.currentSession;
      if (session?.user != null) {
        // Get customer profile
        final customerProfile = await SupabaseService.getCustomerByUserId(session!.user.id);

        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: session.user,
          session: session,
          customerProfile: customerProfile,
        );
      } else {
        state = state.copyWith(isLoading: false);
      }

      // Listen to auth state changes
      SupabaseService.client.auth.onAuthStateChange.listen((data) async {
        final session = data.session;
        final user = session?.user;

        if (user != null && session != null) {
          // User signed in
          final customerProfile = await SupabaseService.getCustomerByUserId(user.id);
          state = state.copyWith(
            isAuthenticated: true,
            user: user,
            session: session,
            customerProfile: customerProfile,
            error: null,
          );
        } else {
          // User signed out
          state = const AuthState();
        }
      });
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await SupabaseService.signInCustomer(
        email: email,
        password: password,
      );

      if (result.success) {
        state = state.copyWith(
          isAuthenticated: true,
          isLoading: false,
          user: result.user,
          session: result.session,
          customerProfile: result.customerProfile,
          error: null, // Clear any previous errors
          successMessage: result.successMessage, // Use success message from result
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage,
          successMessage: null, // Clear any previous success messages
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        successMessage: null, // Clear any previous success messages
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? preferredBranchId,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await SupabaseService.signUpCustomer(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
        preferredBranchId: preferredBranchId,
      );

      if (result.success) {
        if (result.emailConfirmationRequired) {
          // Email confirmation required - this is a SUCCESS, not an error!
          state = state.copyWith(
            isLoading: false,
            error: null, // Clear any previous errors
            successMessage: 'Account created successfully! Please check your email to confirm your account and then sign in.',
          );
        } else {
          // Account created successfully but force logout to require manual sign in
          // This ensures consistent auth flow and prevents auto-login
          await SupabaseService.signOut(); // Force logout any existing session
          state = state.copyWith(
            isAuthenticated: false, // Keep user logged out
            isLoading: false,
            user: null, // Clear user data
            session: null, // Clear session
            customerProfile: null, // Clear profile
            error: null, // Clear any previous errors
            successMessage: 'Account created successfully! Please sign in with your new credentials to continue.',
          );
        }
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.errorMessage,
          successMessage: null, // Clear any previous success messages
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
        successMessage: null, // Clear any previous success messages
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await SupabaseService.signOut();
      state = const AuthState();
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await SupabaseService.resetPassword(email);
      state = state.copyWith(
        isLoading: false,
        error: 'Password reset email sent. Please check your inbox.',
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }

  void clearSuccessMessage() {
    state = state.copyWith(successMessage: null);
  }

  void clearMessages() {
    state = state.copyWith(error: null, successMessage: null);
  }
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

final customerProfileProvider = Provider<Map<String, dynamic>?>((ref) {
  return ref.watch(authProvider).customerProfile;
});

final authLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});

final authErrorProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).error;
});

final authSuccessProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).successMessage;
});