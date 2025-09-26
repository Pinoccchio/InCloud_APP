import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/env_config.dart';
import '../core/utils/validators.dart';
import '../core/utils/logger.dart';
import '../core/enums/auth_error.dart';

// Customer authentication result model
class CustomerAuthResult {
  final bool success;
  final AuthError? error;
  final String? successMessage;
  final User? user;
  final Session? session;
  final Map<String, dynamic>? customerProfile;
  final bool emailConfirmationRequired;

  CustomerAuthResult({
    required this.success,
    this.error,
    this.successMessage,
    this.user,
    this.session,
    this.customerProfile,
    this.emailConfirmationRequired = false,
  });

  /// Get user-friendly error message
  String? get errorMessage => error?.userMessage;

  /// Get debug information for logging
  String? get debugInfo => error?.debugMessage;
}

class SupabaseService {
  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  // Get Supabase client instance
  static SupabaseClient get client => Supabase.instance.client;

  // Auth helper methods
  static User? get currentUser => client.auth.currentUser;
  static bool get isAuthenticated => currentUser != null;

  // Customer sign in with email and password
  static Future<CustomerAuthResult> signInCustomer({
    required String email,
    required String password,
  }) async {
    AppLogger.logAuthEvent(
      event: 'SIGN_IN_ATTEMPT',
      email: email,
      success: false,
      additionalInfo: 'Starting sign in process',
    );

    try {
      final authResponse = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (authResponse.user == null) {
        final error = AuthError(
          type: AuthErrorType.invalidCredentials,
          userMessage: 'Authentication failed',
          debugMessage: 'Authentication response contains no user',
        );
        AppLogger.logAuthEvent(
          event: 'SIGN_IN_FAILED',
          email: email,
          success: false,
          error: error.debugMessage,
        );
        return CustomerAuthResult(
          success: false,
          error: error,
        );
      }

      AppLogger.logAuthEvent(
        event: 'AUTH_SUCCESS',
        email: email,
        success: true,
        additionalInfo: 'User: ${authResponse.user!.id}, Confirmed: ${authResponse.user!.emailConfirmedAt != null}',
      );

      // Get customer profile
      var customerProfile = await getCustomerByUserId(authResponse.user!.id);

      if (customerProfile == null) {
        AppLogger.logAuthEvent(
          event: 'CUSTOMER_PROFILE_NOT_FOUND',
          email: email,
          success: false,
          additionalInfo: 'No customer profile found for user ${authResponse.user!.id}',
        );

        // If no customer profile found, try to link existing customer
        customerProfile = await linkCustomerToAuthUser(
          authResponse.user!.id,
          authResponse.user!.email!,
        );

        if (customerProfile != null) {
          AppLogger.logAuthEvent(
            event: 'CUSTOMER_LINKED',
            email: email,
            success: true,
            additionalInfo: 'Successfully linked existing customer to auth user',
          );
        }
      }

      // If still no profile, this might be an orphaned auth user - try to create profile
      if (customerProfile == null) {
        AppLogger.logAuthEvent(
          event: 'ORPHANED_USER_RECOVERY_ATTEMPT',
          email: email,
          success: false,
          additionalInfo: 'Attempting to recover orphaned auth user ${authResponse.user!.id}',
        );

        try {
          // Get user metadata to reconstruct customer profile
          final userMetadata = authResponse.user!.userMetadata;
          final fullName = userMetadata?['full_name'] as String? ??
                          authResponse.user!.email!.split('@')[0]; // fallback to email prefix

          // Create customer profile for orphaned user
          await createCustomer(
            userId: authResponse.user!.id,
            fullName: fullName,
            email: authResponse.user!.email!,
            phone: '', // Will need to be updated by user later
            branchPreference: 'ab2ecdc9-58ca-4445-8e56-2048e83c4819', // Main branch
          );

          // Try to get the newly created profile
          customerProfile = await getCustomerByUserId(authResponse.user!.id);

          if (customerProfile != null) {
            AppLogger.logAuthEvent(
              event: 'ORPHANED_USER_RECOVERED',
              email: email,
              success: true,
              additionalInfo: 'Successfully recovered orphaned user ${authResponse.user!.id}',
            );

            return CustomerAuthResult(
              success: true,
              user: authResponse.user,
              session: authResponse.session,
              customerProfile: customerProfile,
              successMessage: 'Welcome back! We\'ve successfully recovered your account profile.',
            );
          }
        } catch (recoveryError) {
          AppLogger.logAuthEvent(
            event: 'ORPHANED_USER_RECOVERY_FAILED',
            email: email,
            success: false,
            error: getErrorMessage(recoveryError),
            additionalInfo: 'Failed to create customer profile for orphaned user',
          );
        }

        // If recovery failed, sign out and return error
        await client.auth.signOut();
        AppLogger.logAuthEvent(
          event: 'SIGN_IN_FAILED',
          email: email,
          success: false,
          error: 'Customer profile missing and recovery failed',
        );

        final error = AuthError.orphanedUser(
          authResponse.user!.id,
          'Your account exists but is missing profile information. '
          'This usually happens when registration was interrupted. '
          'Please contact support for assistance.',
        );

        return CustomerAuthResult(
          success: false,
          error: error,
        );
      }

      AppLogger.logAuthEvent(
        event: 'SIGN_IN_SUCCESS',
        email: email,
        success: true,
        additionalInfo: 'Complete sign in successful for user ${authResponse.user!.id}',
      );

      return CustomerAuthResult(
        success: true,
        user: authResponse.user,
        session: authResponse.session,
        customerProfile: customerProfile,
      );
    } catch (e) {
      final error = AuthError.fromException(e, customUserMessage: 'Login failed');

      AppLogger.logAuthEvent(
        event: 'SIGN_IN_ERROR',
        email: email,
        success: false,
        error: error.debugMessage,
        additionalInfo: 'Unexpected error during sign in process: ${error.category}',
      );

      return CustomerAuthResult(
        success: false,
        error: error,
      );
    }
  }

  // Customer sign up with email and password - ATOMIC with rollback
  static Future<CustomerAuthResult> signUpCustomer({
    required String email,
    required String password,
    required String fullName,
    required String phone,
    String? preferredBranchId,
  }) async {
    AppLogger.logAuthEvent(
      event: 'SIGN_UP_ATTEMPT',
      email: email,
      success: false,
      additionalInfo: 'Starting signup process for $fullName, phone: $phone',
    );

    User? createdUser;

    try {
      // Step 1: Create auth user
      AppLogger.logAuthEvent(
        event: 'AUTH_USER_CREATION_START',
        email: email,
        success: false,
        additionalInfo: 'Creating auth user with metadata',
      );

      final authResponse = await client.auth.signUp(
        email: email,
        password: password,
        data: {
          'full_name': fullName,
          'role': 'customer',
          'email_verified': false,
        },
      );

      if (authResponse.user == null) {
        final error = AuthError(
          type: AuthErrorType.serviceUnavailable,
          userMessage: 'Account creation failed',
          debugMessage: 'Auth response contains no user',
        );
        AppLogger.logAuthEvent(
          event: 'AUTH_USER_CREATION_FAILED',
          email: email,
          success: false,
          error: error.debugMessage,
        );
        return CustomerAuthResult(
          success: false,
          error: error,
        );
      }

      createdUser = authResponse.user;

      AppLogger.logAuthEvent(
        event: 'AUTH_USER_CREATED',
        email: email,
        success: true,
        additionalInfo: 'Auth user created: ${createdUser!.id}, email confirmation required: ${authResponse.session == null}',
      );

      // Step 2: Create customer profile (critical section)
      try {
        AppLogger.logAuthEvent(
          event: 'CUSTOMER_PROFILE_CREATION_START',
          email: email,
          success: false,
          additionalInfo: 'Creating customer profile for user ${createdUser!.id}',
        );

        await createCustomer(
          userId: createdUser.id,
          fullName: fullName,
          email: email,
          phone: phone,
          branchPreference: preferredBranchId,
        );

        AppLogger.logAuthEvent(
          event: 'CUSTOMER_PROFILE_CREATED',
          email: email,
          success: true,
          additionalInfo: 'Customer profile creation call completed',
        );

        // Step 3: Verify customer profile was created
        AppLogger.logAuthEvent(
          event: 'CUSTOMER_PROFILE_VERIFICATION_START',
          email: email,
          success: false,
          additionalInfo: 'Verifying customer profile exists in database',
        );

        final customerProfile = await getCustomerByUserId(createdUser.id);

        if (customerProfile == null) {
          AppLogger.logAuthEvent(
            event: 'CUSTOMER_PROFILE_VERIFICATION_FAILED',
            email: email,
            success: false,
            error: 'Customer profile not found after creation',
            additionalInfo: 'This indicates a database constraint or RLS policy issue',
          );
          throw Exception('Customer profile creation verification failed');
        }

        AppLogger.logAuthEvent(
          event: 'SIGN_UP_SUCCESS',
          email: email,
          success: true,
          additionalInfo: 'Complete signup successful for user ${createdUser.id}, profile: ${customerProfile['id']}',
        );

        return CustomerAuthResult(
          success: true,
          user: createdUser,
          session: authResponse.session,
          customerProfile: customerProfile,
          emailConfirmationRequired: authResponse.session == null,
        );

      } catch (customerError) {
        // ROLLBACK: Mark the error as needing cleanup (can't delete user from client)
        final error = AuthError.profileCreationFailed(
          'Registration partially completed but profile creation failed. '
          'Please contact support or try signing in - your account may already exist.',
          'CRITICAL: Split-brain state - auth user ${createdUser.id} exists but customer profile failed: ${getErrorMessage(customerError)}',
        );

        AppLogger.logAuthEvent(
          event: 'CUSTOMER_PROFILE_CREATION_FAILED',
          email: email,
          success: false,
          error: error.debugMessage,
          additionalInfo: 'Split-brain state detected - requires manual cleanup',
        );

        return CustomerAuthResult(
          success: false,
          error: error,
        );
      }

    } catch (e) {
      // Use AuthError to automatically categorize and handle the error
      final error = AuthError.fromException(e, customUserMessage: 'Registration failed. Please try again.');

      AppLogger.logAuthEvent(
        event: 'SIGN_UP_ERROR',
        email: email,
        success: false,
        error: error.debugMessage,
        additionalInfo: 'Error category: ${error.category}, Type: ${error.type}',
      );

      return CustomerAuthResult(
        success: false,
        error: error,
      );
    }
  }

  // Sign out
  static Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Reset password
  static Future<void> resetPassword(String email) async {
    await client.auth.resetPasswordForEmail(email);
  }

  // Customer database operations
  static Future<List<Map<String, dynamic>>> getCustomers() async {
    final response = await client
        .from('customers')
        .select()
        .order('created_at', ascending: false);
    return response;
  }

  static Future<Map<String, dynamic>?> getCustomerByUserId(String userId) async {
    try {
      final response = await client
          .from('customers')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      // If user_id lookup fails, fall back to email matching for existing customers
      // This handles the transition period where some customers might not have user_id set
      final user = client.auth.currentUser;
      if (user?.email == null) return null;

      try {
        final response = await client
            .from('customers')
            .select()
            .eq('email', user!.email!)
            .isFilter('user_id', null)
            .maybeSingle();
        return response;
      } catch (fallbackError) {
        return null;
      }
    }
  }

  static Future<void> createCustomer({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    String? branchPreference,
  }) async {
    // Normalize phone number for consistent storage
    final normalizedPhone = Validators.normalizePhoneNumber(phone);

    await client.from('customers').insert({
      'user_id': userId, // Link to auth.users
      'full_name': fullName,
      'email': email,
      'phone': normalizedPhone, // Store normalized phone
      'preferred_branch_id': branchPreference,
      'customer_type': 'regular',
      'is_active': true,
      'address': {}, // JSON field for address
    });
  }


  static Future<void> updateCustomer({
    required String customerId,
    required Map<String, dynamic> updates,
  }) async {
    await client
        .from('customers')
        .update(updates)
        .eq('id', customerId);
  }

  // Helper method to link existing customer to auth user
  static Future<Map<String, dynamic>?> linkCustomerToAuthUser(String userId, String email) async {
    try {
      // Find customer by email that doesn't have user_id set
      final existingCustomer = await client
          .from('customers')
          .select()
          .eq('email', email)
          .isFilter('user_id', null)
          .maybeSingle();

      if (existingCustomer != null) {
        // Update the customer record with user_id
        await client
            .from('customers')
            .update({'user_id': userId})
            .eq('id', existingCustomer['id']);

        // Return the updated customer data
        return await client
            .from('customers')
            .select()
            .eq('user_id', userId)
            .single();
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Products database operations
  static Future<List<Map<String, dynamic>>> getProducts({
    String? categoryFilter,
    String? searchQuery,
    int? limit,
  }) async {
    final query = client
        .from('products')
        .select('''
          *,
          brands!inner(*),
          categories!inner(*),
          price_tiers!inner(*)
        ''')
        .eq('is_active', true);

    // Apply filters if provided
    var filteredQuery = query;

    if (categoryFilter != null && categoryFilter.isNotEmpty) {
      filteredQuery = filteredQuery.eq('categories.name', categoryFilter);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      filteredQuery = filteredQuery.or('name.ilike.%$searchQuery%,description.ilike.%$searchQuery%');
    }

    // Apply ordering and limit
    final orderedQuery = filteredQuery.order('name');

    if (limit != null) {
      return await orderedQuery.limit(limit);
    }

    return await orderedQuery;
  }

  static Future<Map<String, dynamic>?> getProduct(String productId) async {
    final response = await client
        .from('products')
        .select('''
          *,
          brands(*),
          categories(*),
          price_tiers(*)
        ''')
        .eq('id', productId)
        .maybeSingle();
    return response;
  }

  // Orders database operations
  static Future<List<Map<String, dynamic>>> getCustomerOrders(String customerId) async {
    final response = await client
        .from('orders')
        .select('''
          *,
          order_items!inner(
            *,
            products(*)
          )
        ''')
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return response;
  }

  static Future<String> createOrder({
    required String customerId,
    required List<Map<String, dynamic>> orderItems,
    String? specialInstructions,
  }) async {
    // Start a transaction
    final response = await client
        .from('orders')
        .insert({
          'customer_id': customerId,
          'status': 'pending',
          'special_instructions': specialInstructions,
        })
        .select()
        .single();

    final orderId = response['id'];

    // Insert order items
    final itemsToInsert = orderItems.map((item) => {
          'order_id': orderId,
          'product_id': item['product_id'],
          'quantity': item['quantity'],
          'unit_price': item['unit_price'],
          'pricing_tier': item['pricing_tier'],
        }).toList();

    await client.from('order_items').insert(itemsToInsert);

    return orderId;
  }

  // Real-time subscriptions
  static RealtimeChannel subscribeToOrderUpdates({
    required String customerId,
    required void Function(Map<String, dynamic>) onOrderUpdate,
  }) {
    return client
        .channel('order_updates')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'customer_id',
            value: customerId,
          ),
          callback: (payload) {
            onOrderUpdate(payload.newRecord);
          },
        )
        .subscribe();
  }

  // Utility methods
  static String? getErrorMessage(Object error) {
    if (error is AuthException) {
      return error.message;
    } else if (error is PostgrestException) {
      return error.message;
    } else {
      return error.toString();
    }
  }

  static bool isEmailConfirmed(User? user) {
    return user?.emailConfirmedAt != null;
  }

  static String getUserRole(User? user) {
    return user?.userMetadata?['role'] ?? 'customer';
  }
}