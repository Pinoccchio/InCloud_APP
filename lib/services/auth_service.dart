import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Get current user
  static User? get currentUser {
    final user = _client.auth.currentUser;
    if (user != null) {
      print('ℹ️ Current user: ${user.email} (${user.id})');
    }
    return user;
  }

  // Get current session
  static Session? get currentSession {
    final session = _client.auth.currentSession;
    if (session != null) {
      print('ℹ️ Current session expires: ${session.expiresAt}');
    }
    return session;
  }

  // Check if user is logged in
  static bool get isLoggedIn {
    final loggedIn = currentUser != null;
    print('ℹ️ User logged in status: $loggedIn');
    return loggedIn;
  }

  // Sign up with email and password
  static Future<AuthResult> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phone,
  }) async {
    print('🚀 SIGNUP STARTED for email: $email, name: $fullName');

    try {
      // Create auth user
      print('📧 Creating Supabase auth user...');
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
        },
      );

      if (response.user != null) {
        print('✅ AUTH USER CREATED SUCCESSFULLY!');
        print('   User ID: ${response.user!.id}');
        print('   Email: ${response.user!.email}');
        print('   Created at: ${response.user!.createdAt}');

        // Create customer profile
        print('👤 Creating customer profile in database...');
        await _createCustomerProfile(
          userId: response.user!.id,
          email: email,
          fullName: fullName,
          phone: phone,
        );

        // Force logout to prevent auto-authentication
        print('🚪 FORCING LOGOUT after signup to prevent auto-authentication...');
        await _client.auth.signOut();
        print('✅ USER LOGGED OUT - must sign in manually');

        print('🎉 SIGNUP COMPLETED SUCCESSFULLY for $email');
        return AuthResult.success(
          user: response.user!,
          message: 'Account created successfully!',
        );
      } else {
        print('❌ SIGNUP FAILED: No user returned from Supabase');
        return AuthResult.error('Failed to create account. Please try again.');
      }
    } on AuthException catch (e) {
      print('❌ SIGNUP AUTH EXCEPTION:');
      print('   Raw message: ${e.message}');
      print('   Status code: ${e.statusCode}');
      final friendlyMessage = _getAuthErrorMessage(e);
      print('   Friendly message: $friendlyMessage');
      return AuthResult.error(friendlyMessage);
    } catch (e) {
      print('❌ SIGNUP UNEXPECTED ERROR: $e');
      debugPrint('Signup error: $e');
      return AuthResult.error('An unexpected error occurred. Please try again.');
    }
  }

  // Sign in with email and password
  static Future<AuthResult> signIn({
    required String email,
    required String password,
  }) async {
    print('🔐 LOGIN STARTED for email: $email');

    try {
      print('🔍 Attempting Supabase authentication...');
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user != null) {
        print('✅ LOGIN SUCCESSFUL!');
        print('   User ID: ${response.user!.id}');
        print('   Email: ${response.user!.email}');
        print('   Last sign in: ${response.user!.lastSignInAt}');
        print('   Session expires: ${response.session?.expiresAt}');

        return AuthResult.success(
          user: response.user!,
          message: 'Login successfully',
        );
      } else {
        print('❌ LOGIN FAILED: No user returned from Supabase');
        return AuthResult.error('Invalid login credentials.');
      }
    } on AuthException catch (e) {
      print('❌ LOGIN AUTH EXCEPTION:');
      print('   Raw message: ${e.message}');
      print('   Status code: ${e.statusCode}');
      final friendlyMessage = _getAuthErrorMessage(e);
      print('   Friendly message: $friendlyMessage');
      return AuthResult.error(friendlyMessage);
    } catch (e) {
      print('❌ LOGIN UNEXPECTED ERROR: $e');
      debugPrint('Login error: $e');
      return AuthResult.error('An unexpected error occurred. Please try again.');
    }
  }

  // Sign out
  static Future<void> signOut() async {
    print('🚪 SIGNOUT STARTED');

    try {
      await _client.auth.signOut();
      print('✅ SIGNOUT SUCCESSFUL');
    } catch (e) {
      print('❌ SIGNOUT ERROR: $e');
      debugPrint('Signout error: $e');
    }
  }

  // Get default active branch ID
  static Future<String?> _getDefaultBranchId() async {
    try {
      print('🏢 FETCHING DEFAULT BRANCH...');
      final response = await _client
          .from('branches')
          .select('id, name')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        print('✅ DEFAULT BRANCH FOUND: ${response['name']} (${response['id']})');
        return response['id'] as String;
      } else {
        print('⚠️ No active branch found in database');
        return null;
      }
    } catch (e) {
      print('❌ ERROR FETCHING DEFAULT BRANCH: $e');
      return null;
    }
  }

  // Create customer profile in database
  static Future<void> _createCustomerProfile({
    required String userId,
    required String email,
    required String fullName,
    required String phone,
  }) async {
    print('💾 CREATING CUSTOMER PROFILE:');
    print('   User ID: $userId');
    print('   Email: $email');
    print('   Full Name: $fullName');
    print('   Phone: $phone');

    try {
      // Get default branch ID
      final defaultBranchId = await _getDefaultBranchId();
      print('🏢 Assigning to branch: $defaultBranchId');

      await _client.from('customers').insert({
        'user_id': userId,
        'email': email,
        'full_name': fullName,
        'phone': phone,
        'customer_type': 'regular',
        'is_active': true,
        'preferred_branch_id': defaultBranchId,
      });

      print('✅ CUSTOMER PROFILE CREATED SUCCESSFULLY in database');
    } catch (e) {
      print('❌ ERROR CREATING CUSTOMER PROFILE: $e');
      debugPrint('Error creating customer profile: $e');
      // Don't throw error here as auth user was already created
    }
  }

  // Get user-friendly error messages
  static String _getAuthErrorMessage(AuthException e) {
    switch (e.message) {
      case 'Invalid login credentials':
        return 'Invalid email or password. Please check your credentials.';
      case 'User already registered':
        return 'Your account already exists. Please sign in instead.';
      case 'Email not confirmed':
        return 'Please check your email and confirm your account.';
      case 'Invalid email':
        return 'Please enter a valid email address.';
      case 'Password should be at least 6 characters':
        return 'Password must be at least 6 characters long.';
      case 'Signup requires a valid password':
        return 'Please enter a valid password.';
      default:
        // Check if it's a duplicate email error
        if (e.message.contains('duplicate') || e.message.contains('already')) {
          return 'Your account already exists. Please sign in instead.';
        }
        return e.message.isNotEmpty ? e.message : 'An error occurred. Please try again.';
    }
  }

  // Get customer profile with branch information
  static Future<Map<String, dynamic>?> getCustomerProfile() async {
    print('👤 FETCHING CUSTOMER PROFILE WITH BRANCH DATA...');

    try {
      if (currentUser == null) {
        print('❌ No current user found');
        return null;
      }

      print('🔍 Querying customer profile with branch for user ID: ${currentUser!.id}');
      final response = await _client
          .from('customers')
          .select('''
            *,
            branches!customers_preferred_branch_id_fkey (
              id,
              name,
              address
            )
          ''')
          .eq('user_id', currentUser!.id)
          .maybeSingle();

      if (response != null) {
        print('✅ CUSTOMER PROFILE WITH BRANCH FETCHED SUCCESSFULLY');
        print('   Profile: $response');

        // Log branch information if available
        if (response['branches'] != null) {
          print('   Branch: ${response['branches']['name']}');
        } else {
          print('   No branch assigned to this customer');
        }
      } else {
        print('⚠️ No customer profile found for user');
      }

      return response;
    } catch (e) {
      print('❌ ERROR FETCHING CUSTOMER PROFILE WITH BRANCH: $e');
      debugPrint('Error fetching customer profile: $e');
      return null;
    }
  }

  // Update customer profile
  static Future<AuthResult> updateCustomerProfile({
    required String fullName,
    required String phone,
    Map<String, dynamic>? address,
  }) async {
    print('📝 UPDATING CUSTOMER PROFILE...');

    try {
      if (currentUser == null) {
        print('❌ No current user found');
        return AuthResult.error('You must be logged in to update your profile.');
      }

      print('🔍 Updating profile for user ID: ${currentUser!.id}');
      final Map<String, dynamic> updateData = {
        'full_name': fullName.trim(),
        'phone': phone.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      // Add address if provided
      if (address != null) {
        updateData['address'] = address;
      }

      await _client
          .from('customers')
          .update(updateData)
          .eq('user_id', currentUser!.id);

      print('✅ CUSTOMER PROFILE UPDATED SUCCESSFULLY');
      return AuthResult.success(
        user: currentUser!,
        message: 'Profile updated successfully!',
      );
    } on PostgrestException catch (e) {
      print('❌ POSTGREST ERROR UPDATING PROFILE:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      return AuthResult.error('Failed to update profile. Please try again.');
    } catch (e) {
      print('❌ ERROR UPDATING CUSTOMER PROFILE: $e');
      debugPrint('Error updating customer profile: $e');
      return AuthResult.error('An unexpected error occurred. Please try again.');
    }
  }

  // Auth state stream
  static Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;
}

// Auth result class
class AuthResult {
  final bool isSuccess;
  final User? user;
  final String message;

  AuthResult._({
    required this.isSuccess,
    this.user,
    required this.message,
  });

  factory AuthResult.success({
    required User user,
    required String message,
  }) {
    return AuthResult._(
      isSuccess: true,
      user: user,
      message: message,
    );
  }

  factory AuthResult.error(String message) {
    return AuthResult._(
      isSuccess: false,
      user: null,
      message: message,
    );
  }
}