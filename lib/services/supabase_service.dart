import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String supabaseUrl = 'YOUR_SUPABASE_URL_HERE';
  static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY_HERE';

  // Initialize Supabase
  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
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

  // Sign in with email and password
  static Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  // Sign up with email and password
  static Future<AuthResponse> signUpWithEmail({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    return await client.auth.signUp(
      email: email,
      password: password,
      data: data,
    );
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
    final response = await client
        .from('customers')
        .select()
        .eq('user_id', userId)
        .maybeSingle();
    return response;
  }

  static Future<void> createCustomer({
    required String userId,
    required String fullName,
    required String email,
    required String phone,
    String? branchPreference,
  }) async {
    await client.from('customers').insert({
      'user_id': userId,
      'full_name': fullName,
      'email': email,
      'phone': phone,
      'branch_preference': branchPreference,
      'is_active': true,
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