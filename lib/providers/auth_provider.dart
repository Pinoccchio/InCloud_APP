import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../services/branch_service.dart';

// Auth state provider - tracks the current auth state
final authStateProvider = NotifierProvider<AuthStateNotifier, AuthStateData>(
  AuthStateNotifier.new,
);

// Current user provider
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.user;
});

// Is logged in provider
final isLoggedInProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

// Customer profile provider
final customerProfileProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  return await AuthService.getCustomerProfile();
});

// Default branch provider - fetches the active branch from database
final defaultBranchProvider = FutureProvider<BranchData?>((ref) async {
  return await BranchService.getDefaultBranch();
});

// All active branches provider
final activeBranchesProvider = FutureProvider<List<BranchData>>((ref) async {
  return await BranchService.getAllActiveBranches();
});

// Auth state data class
class AuthStateData {
  final User? user;
  final Session? session;
  final bool isLoading;
  final String? error;

  const AuthStateData({
    this.user,
    this.session,
    this.isLoading = false,
    this.error,
  });

  AuthStateData copyWith({
    User? user,
    Session? session,
    bool? isLoading,
    String? error,
  }) {
    return AuthStateData(
      user: user ?? this.user,
      session: session ?? this.session,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

// Auth state notifier
class AuthStateNotifier extends Notifier<AuthStateData> {
  @override
  AuthStateData build() {
    final authState = const AuthStateData();
    _init();
    return authState;
  }

  void _init() {
    // Initialize with current auth state
    final currentUser = AuthService.currentUser;
    final currentSession = AuthService.currentSession;

    state = state.copyWith(
      user: currentUser,
      session: currentSession,
    );

    // Listen to auth state changes
    AuthService.authStateChanges.listen((authState) {
      state = state.copyWith(
        user: authState.session?.user,
        session: authState.session,
        error: null,
      );
    });
  }

  Future<void> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AuthService.signIn(
        email: email,
        password: password,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final result = await AuthService.signUp(
        email: email,
        password: password,
        fullName: fullName,
        phone: phone,
      );

      if (result.isSuccess) {
        state = state.copyWith(
          user: result.user,
          isLoading: false,
          error: null,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: result.message,
        );
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'An unexpected error occurred',
      );
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);

    try {
      await AuthService.signOut();
      state = const AuthStateData(); // Reset to initial state
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Error signing out',
      );
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}