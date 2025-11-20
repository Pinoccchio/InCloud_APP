import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/database_types.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../core/utils/date_utils.dart' as app_date_utils;

class OrderService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Create a new order from cart items
  static Future<String?> createOrder({
    required List<CartItem> cartItems,
    String? notes,
    Map<String, dynamic>? deliveryAddress,
    String paymentMethod = 'cash_on_delivery',  // 'cash_on_delivery' or 'online_payment'
    String? gcashReferenceNumber,               // Required for online_payment
  }) async {
    try {
      print('🛒 CREATING ORDER FROM CART...');
      print('   Items: ${cartItems.length}');

      // Validate input
      if (cartItems.isEmpty) {
        throw Exception('Cannot create order with empty cart');
      }

      // Validate user is logged in
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to place orders');
      }
      print('   User ID: ${user.id}');

      // Get customer profile
      final customerProfile = await AuthService.getCustomerProfile();
      if (customerProfile == null) {
        throw Exception('Customer profile not found. Please complete your profile setup.');
      }

      final customerId = customerProfile['id'] as String?;
      final branchId = customerProfile['preferred_branch_id'] as String?;

      if (customerId == null || customerId.isEmpty) {
        throw Exception('Customer ID not found in profile');
      }

      if (branchId == null || branchId.isEmpty) {
        throw Exception('No preferred branch set for customer. Please update your profile.');
      }

      // Validate cart items have valid pricing
      for (final item in cartItems) {
        if (item.unitPrice <= 0 || item.totalPrice <= 0) {
          throw Exception('Invalid pricing found for item: ${item.product.name}');
        }
        if (item.quantity <= 0) {
          throw Exception('Invalid quantity found for item: ${item.product.name}');
        }
      }

      // Calculate totals (no tax/VAT as per business requirements)
      final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      final totalAmount = subtotal; // Total equals subtotal (no tax)

      if (subtotal <= 0) {
        throw Exception('Order total cannot be zero or negative');
      }

      // Generate order number
      final orderNumber = 'ORD-${app_date_utils.DateUtils.nowInUtc().millisecondsSinceEpoch}';

      print('   Order Number: $orderNumber');
      print('   Customer: $customerId');
      print('   Branch: $branchId');
      print('   Subtotal: ₱${subtotal.toStringAsFixed(2)}');
      print('   Total: ₱${totalAmount.toStringAsFixed(2)}');

      // Validate payment method and reference number
      if (paymentMethod == 'online_payment' && (gcashReferenceNumber == null || gcashReferenceNumber.trim().isEmpty)) {
        throw Exception('GCash reference number is required for online payment');
      }

      // Create order
      final orderData = {
        'order_number': orderNumber,
        'customer_id': customerId,
        'branch_id': branchId,
        'status': 'pending',
        'payment_status': 'pending',
        'order_date': app_date_utils.DateUtils.nowInUtcString(),
        'delivery_address': deliveryAddress ?? customerProfile['address'] ?? {},
        'subtotal': subtotal,
        'discount_amount': 0,
        'total_amount': totalAmount,
        'notes': notes,
        'created_by_user_id': user.id, // User who created this order
        'payment_method': paymentMethod,
        'gcash_reference_number': gcashReferenceNumber,
      };

      final orderResponse = await _client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      if (orderResponse == null || orderResponse['id'] == null) {
        throw Exception('Failed to create order - no response from server');
      }

      final orderId = orderResponse['id'] as String;
      print('✅ ORDER CREATED: $orderId');

      // Create order items
      final orderItems = cartItems.map((item) => {
        'order_id': orderId,
        'product_id': item.product.id,
        'pricing_type': item.selectedTier.name,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.totalPrice,
        'fulfillment_status': 'pending',
      }).toList();

      if (orderItems.isEmpty) {
        throw Exception('No order items to insert');
      }

      final itemsResponse = await _client.from('order_items').insert(orderItems);

      // Verify items were created (Supabase insert doesn't throw on failure)
      if (itemsResponse == null) {
        print('⚠️ Warning: Order items insert returned null response');
      }

      print('✅ ORDER ITEMS CREATED: ${orderItems.length} items');

      // Note: Order status history is automatically created by database trigger
      print('✅ ORDER STATUS HISTORY: Handled by database trigger automatically');

      return orderId;
    } on PostgrestException catch (e) {
      print('❌ DATABASE ERROR CREATING ORDER:');
      print('   Code: ${e.code}');
      print('   Message: ${e.message}');
      print('   Details: ${e.details}');

      // Provide user-friendly error messages
      if (e.code == '23503') {
        throw Exception('Invalid reference data. Please refresh and try again.');
      } else if (e.code == '23505') {
        throw Exception('Duplicate order detected. Please try again.');
      } else {
        throw Exception('Database error: ${e.message}');
      }
    } on AuthException catch (e) {
      print('❌ AUTH ERROR CREATING ORDER: ${e.message}');
      throw Exception('Authentication error. Please sign in again.');
    } catch (e) {
      print('❌ UNEXPECTED ERROR CREATING ORDER: $e');
      debugPrint('Order creation error: $e');

      // Provide more specific error messages based on the error content
      final errorStr = e.toString().toLowerCase();
      if (errorStr.contains('network') || errorStr.contains('connection')) {
        throw Exception('Network error. Please check your connection and try again.');
      } else if (errorStr.contains('timeout')) {
        throw Exception('Request timed out. Please try again.');
      } else {
        throw Exception('Failed to create order: ${e.toString()}');
      }
    }
  }

  /// Get orders for current customer
  static Future<List<Order>> getCustomerOrders() async {
    try {
      print('📋 FETCHING CUSTOMER ORDERS...');

      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User must be logged in');
      }

      // Get customer profile
      final customerProfile = await AuthService.getCustomerProfile();
      if (customerProfile == null) {
        throw Exception('Customer profile not found');
      }

      final customerId = customerProfile['id'] as String;

      final List<dynamic> response = await _client
          .from('orders')
          .select('''
            *,
            order_items!order_items_order_id_fkey (
              *,
              products!order_items_product_id_fkey (
                id,
                name,
                description,
                images,
                unit_of_measure
              )
            ),
            order_status_history!order_status_history_order_id_fkey (
              id,
              old_status,
              new_status,
              changed_by_user_id,
              notes,
              created_at
            )
          ''')
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);

      final orders = response.map((json) => Order.fromJson(json)).toList();

      print('✅ CUSTOMER ORDERS FETCHED: ${orders.length} orders');
      return orders;
    } catch (e) {
      print('❌ ERROR FETCHING CUSTOMER ORDERS: $e');
      debugPrint('Customer orders fetch error: $e');
      return [];
    }
  }

  /// Get a specific order by ID
  static Future<Order?> getOrderById(String orderId) async {
    try {
      print('🔍 FETCHING ORDER BY ID: $orderId');

      final response = await _client
          .from('orders')
          .select('''
            *,
            order_items!order_items_order_id_fkey (
              *,
              products!order_items_product_id_fkey (
                id,
                name,
                description,
                images,
                unit_of_measure,
                status,
                categories!products_category_id_fkey (
                  id,
                  name
                ),
                brands!products_brand_id_fkey (
                  id,
                  name
                ),
                price_tiers!price_tiers_product_id_fkey (
                  id,
                  pricing_type,
                  price,
                  min_quantity,
                  max_quantity,
                  is_active
                )
              )
            ),
            order_status_history!order_status_history_order_id_fkey (
              id,
              old_status,
              new_status,
              changed_by_user_id,
              notes,
              created_at
            )
          ''')
          .eq('id', orderId)
          .maybeSingle();

      if (response != null) {
        print('✅ ORDER FOUND: ${response['order_number']}');
        return Order.fromJson(response);
      } else {
        print('⚠️ ORDER NOT FOUND: $orderId');
        return null;
      }
    } catch (e) {
      print('❌ ERROR FETCHING ORDER BY ID: $e');
      debugPrint('Order by ID fetch error: $e');
      return null;
    }
  }

  /// Cancel an order using secure RPC function (only if status is pending)
  static Future<bool> cancelOrder(String orderId, String reason) async {
    try {
      print('❌ CANCELLING ORDER: $orderId');
      print('   Reason: $reason');

      // Check if order can be cancelled
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      if (order.status != OrderStatus.pending) {
        throw Exception('Order cannot be cancelled (status: ${order.status.name})');
      }

      // Get current user
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to cancel orders');
      }

      // Use secure RPC function to cancel order
      final response = await _client.rpc('customer_cancel_order', params: {
        'p_order_id': orderId,
        'p_reason': reason,
      });

      // Check if the RPC call was successful
      if (response == null) {
        throw Exception('No response from server');
      }

      final result = response as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to cancel order');
      }

      print('✅ ORDER CANCELLED SUCCESSFULLY VIA RPC');
      return true;
    } catch (e) {
      print('❌ ERROR CANCELLING ORDER: $e');
      debugPrint('Order cancellation error: $e');
      return false;
    }
  }

  /// Reorder items from a previous order
  static Future<List<CartItem>> getReorderItems(String orderId) async {
    try {
      print('🔄 PREPARING REORDER FROM: $orderId');

      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      List<CartItem> cartItems = [];
      List<String> skippedItems = [];
      List<String> unavailableItems = [];

      for (final orderItem in order.items) {
        if (orderItem.product == null) {
          skippedItems.add('Product data missing');
          print('⚠️ Skipping item ${orderItem.productId}: Product data is null');
          continue;
        }

        final product = orderItem.product!;

        // Check if product is still available
        if (product.status != ProductStatus.available) {
          unavailableItems.add(product.name);
          print('⚠️ Skipping ${product.name}: Product is no longer available (${product.status})');
          continue;
        }

        // Check if product has price tiers
        if (product.priceTiers.isEmpty) {
          skippedItems.add('${product.name} (no pricing available)');
          print('⚠️ Skipping ${product.name}: No price tiers available');
          continue;
        }

        try {
          final cartItem = CartItem.fromProduct(
            product: product,
            tier: orderItem.pricingTier,
            quantity: orderItem.quantity,
          );
          cartItems.add(cartItem);
          print('✅ Added ${product.name} to reorder cart');
        } catch (e) {
          skippedItems.add('${product.name} (${e.toString()})');
          print('⚠️ Skipping ${product.name}: $e');
        }
      }

      // Log summary
      print('✅ REORDER ITEMS PREPARED: ${cartItems.length} items successfully added');
      if (skippedItems.isNotEmpty) {
        print('⚠️ SKIPPED ITEMS: ${skippedItems.length} - ${skippedItems.join(', ')}');
      }
      if (unavailableItems.isNotEmpty) {
        print('🚫 UNAVAILABLE ITEMS: ${unavailableItems.length} - ${unavailableItems.join(', ')}');
      }

      return cartItems;
    } catch (e) {
      print('❌ ERROR PREPARING REORDER: $e');
      debugPrint('Reorder preparation error: $e');
      return [];
    }
  }

  /// Get order status counts for customer
  static Future<Map<String, int>> getOrderStatusCounts() async {
    try {
      print('📊 FETCHING ORDER STATUS COUNTS...');

      final user = AuthService.currentUser;
      if (user == null) {
        return {};
      }

      final customerProfile = await AuthService.getCustomerProfile();
      if (customerProfile == null) {
        return {};
      }

      final customerId = customerProfile['id'] as String;

      final List<dynamic> response = await _client
          .from('orders')
          .select('status')
          .eq('customer_id', customerId);

      Map<String, int> counts = {
        'pending': 0,
        'confirmed': 0,
        'in_transit': 0,
        'delivered': 0,
        'cancelled': 0,
        'returned': 0,
      };

      for (final order in response) {
        final status = order['status'] as String;
        counts[status] = (counts[status] ?? 0) + 1;
      }

      print('✅ ORDER STATUS COUNTS: $counts');
      return counts;
    } catch (e) {
      print('❌ ERROR FETCHING ORDER STATUS COUNTS: $e');
      debugPrint('Order status counts error: $e');
      return {};
    }
  }

  /// Subscribe to order status changes
  static Stream<List<Map<String, dynamic>>> subscribeToOrderUpdates() async* {
    try {
      print('🔔 SUBSCRIBING TO ORDER UPDATES...');

      final user = AuthService.currentUser;
      if (user == null) {
        yield [];
        return;
      }

      final customerProfile = await AuthService.getCustomerProfile();
      if (customerProfile == null) {
        yield [];
        return;
      }

      final customerId = customerProfile['id'] as String;

      // Subscribe to changes in orders table for this customer
      yield* _client
          .from('orders')
          .stream(primaryKey: ['id'])
          .eq('customer_id', customerId)
          .order('created_at', ascending: false);
    } catch (e) {
      print('❌ ERROR SUBSCRIBING TO ORDER UPDATES: $e');
      debugPrint('Order updates subscription error: $e');
      yield [];
    }
  }

  /// Check if order can be cancelled
  static bool canCancelOrder(Order order) {
    return order.status == OrderStatus.pending;
  }

  /// Check if order can be reordered
  static bool canReorderOrder(Order order) {
    return order.status == OrderStatus.delivered || order.status == OrderStatus.cancelled;
  }

  /// Get order status display info
  static Map<String, dynamic> getOrderStatusInfo(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return {
          'icon': '🟡',
          'color': 'orange',
          'title': 'Pending',
          'description': 'Awaiting admin confirmation',
        };
      case OrderStatus.confirmed:
        return {
          'icon': '🔵',
          'color': 'blue',
          'title': 'Confirmed',
          'description': 'Order accepted, preparing items',
        };
      case OrderStatus.in_transit:
        return {
          'icon': '🟠',
          'color': 'orange',
          'title': 'In Transit',
          'description': 'Out for delivery',
        };
      case OrderStatus.delivered:
        return {
          'icon': '🟢',
          'color': 'green',
          'title': 'Delivered',
          'description': 'Order completed successfully',
        };
      case OrderStatus.cancelled:
        return {
          'icon': '❌',
          'color': 'red',
          'title': 'Cancelled',
          'description': 'Order was cancelled',
        };
      case OrderStatus.returned:
        return {
          'icon': '🔄',
          'color': 'purple',
          'title': 'Returned',
          'description': 'Order was returned',
        };
    }
  }

  /// Get payment status display info
  static Map<String, dynamic> getPaymentStatusInfo(PaymentStatus status) {
    switch (status) {
      case PaymentStatus.pending:
        return {
          'icon': '⏳',
          'color': 'orange',
          'title': 'Payment Pending',
          'description': 'Payment due on delivery',
        };
      case PaymentStatus.paid:
        return {
          'icon': '✅',
          'color': 'green',
          'title': 'Paid',
          'description': 'Payment received',
        };
      case PaymentStatus.partial:
        return {
          'icon': '⚠️',
          'color': 'yellow',
          'title': 'Partial Payment',
          'description': 'Partial payment received',
        };
      case PaymentStatus.refunded:
        return {
          'icon': '💰',
          'color': 'blue',
          'title': 'Refunded',
          'description': 'Payment refunded',
        };
      case PaymentStatus.cancelled:
        return {
          'icon': '❌',
          'color': 'red',
          'title': 'Payment Cancelled',
          'description': 'Payment was cancelled',
        };
    }
  }

  /// Upload proof of payment for an order using secure RPC function
  static Future<bool> uploadProofOfPayment({
    required String orderId,
    required File imageFile,
  }) async {
    try {
      print('📤 UPLOADING PROOF OF PAYMENT FOR ORDER: $orderId');

      // Verify order exists and belongs to current user
      final order = await getOrderById(orderId);
      if (order == null) {
        throw Exception('Order not found');
      }

      // Upload image to Supabase Storage
      final imageUrl = await StorageService.uploadProofOfPayment(
        orderId: orderId,
        imageFile: imageFile,
      );

      if (imageUrl == null) {
        throw Exception('Failed to upload image to storage');
      }

      print('✅ IMAGE UPLOADED: $imageUrl');

      // Use secure RPC function to update order with proof of payment
      final response = await _client.rpc('customer_upload_proof_of_payment', params: {
        'p_order_id': orderId,
        'p_proof_url': imageUrl,
      });

      // Check if the RPC call was successful
      if (response == null) {
        throw Exception('No response from server');
      }

      final result = response as Map<String, dynamic>;
      if (result['success'] != true) {
        throw Exception(result['error'] ?? 'Failed to upload proof of payment');
      }

      print('✅ PROOF OF PAYMENT UPLOADED SUCCESSFULLY VIA RPC');
      return true;
    } catch (e) {
      print('❌ ERROR UPLOADING PROOF OF PAYMENT: $e');
      debugPrint('Proof of payment upload error: $e');
      return false;
    }
  }

  /// Check if order can upload proof of payment
  static bool canUploadProofOfPayment(Order order) {
    // Can upload if order is confirmed or in_transit and payment is pending
    return (order.status == OrderStatus.confirmed ||
            order.status == OrderStatus.in_transit ||
            order.status == OrderStatus.delivered) &&
           order.paymentStatus == PaymentStatus.pending;
  }
}