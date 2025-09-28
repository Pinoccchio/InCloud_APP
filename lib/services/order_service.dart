import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/database_types.dart';
import '../services/auth_service.dart';
import '../core/utils/date_utils.dart' as app_date_utils;

class OrderService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Create a new order from cart items
  static Future<String?> createOrder({
    required List<CartItem> cartItems,
    String? notes,
    Map<String, dynamic>? deliveryAddress,
  }) async {
    try {
      print('🛒 CREATING ORDER FROM CART...');
      print('   Items: ${cartItems.length}');

      // Validate user is logged in
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to place orders');
      }

      // Get customer profile
      final customerProfile = await AuthService.getCustomerProfile();
      if (customerProfile == null) {
        throw Exception('Customer profile not found');
      }

      final customerId = customerProfile['id'] as String;
      final branchId = customerProfile['preferred_branch_id'] as String?;

      if (branchId == null) {
        throw Exception('No preferred branch set for customer');
      }

      // Calculate totals
      final subtotal = cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
      final taxAmount = subtotal * 0.12; // 12% VAT
      final totalAmount = subtotal + taxAmount;

      // Generate order number
      final orderNumber = 'ORD-${app_date_utils.DateUtils.nowInUtc().millisecondsSinceEpoch}';

      print('   Order Number: $orderNumber');
      print('   Customer: $customerId');
      print('   Branch: $branchId');
      print('   Total: ₱${totalAmount.toStringAsFixed(2)}');

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
        'tax_amount': taxAmount,
        'total_amount': totalAmount,
        'notes': notes,
        'created_by_user_id': user.id, // User who created this order
      };

      final orderResponse = await _client
          .from('orders')
          .insert(orderData)
          .select()
          .single();

      final orderId = orderResponse['id'] as String;
      print('✅ ORDER CREATED: $orderId');

      // Create order items
      final orderItems = cartItems.map((item) => {
        'order_id': orderId,
        'product_id': item.product.id,
        'pricing_tier': item.selectedTier.name,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.totalPrice,
        'fulfillment_status': 'pending',
      }).toList();

      await _client.from('order_items').insert(orderItems);
      print('✅ ORDER ITEMS CREATED: ${orderItems.length} items');

      // Create initial status history record
      try {
        await _client.from('order_status_history').insert({
          'order_id': orderId,
          'old_status': null, // No previous status for new orders
          'new_status': 'pending',
          'changed_by_user_id': user.id, // Customer who created the order
          'notes': 'Order created',
          'created_at': app_date_utils.DateUtils.nowInUtcString(),
        });
        print('✅ ORDER STATUS HISTORY CREATED: Initial pending status');
      } catch (historyError) {
        // Log warning but don't fail the entire order creation
        print('⚠️ WARNING: Failed to create order status history: $historyError');
        debugPrint('Order status history creation error: $historyError');
      }

      return orderId;
    } catch (e) {
      print('❌ ERROR CREATING ORDER: $e');
      debugPrint('Order creation error: $e');
      rethrow;
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
                categories!products_category_id_fkey (
                  id,
                  name
                ),
                brands!products_brand_id_fkey (
                  id,
                  name
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

  /// Cancel an order (only if status is pending)
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

      // Get current user and customer profile for proper attribution
      final user = AuthService.currentUser;
      if (user == null) {
        throw Exception('User must be logged in to cancel orders');
      }

      final customerProfile = await AuthService.getCustomerProfile();
      if (customerProfile == null) {
        throw Exception('Customer profile not found');
      }
      // Customer ID not needed for order cancellation - order validation is sufficient

      // Update order status
      await _client
          .from('orders')
          .update({
            'status': 'cancelled',
            'notes': order.notes != null
                ? '${order.notes}\nCancelled by customer: $reason'
                : 'Cancelled by customer: $reason',
            'updated_at': app_date_utils.DateUtils.nowInUtcString(),
          })
          .eq('id', orderId);

      // Update order items status
      await _client
          .from('order_items')
          .update({'fulfillment_status': 'cancelled'})
          .eq('order_id', orderId);

      // Create status history record for cancellation
      await _client
          .from('order_status_history')
          .insert({
            'order_id': orderId,
            'old_status': order.status.name,
            'new_status': 'cancelled',
            'changed_by_user_id': user.id, // User ID for proper attribution
            'notes': reason,
            'created_at': app_date_utils.DateUtils.nowInUtcString(),
          });

      print('✅ ORDER CANCELLED SUCCESSFULLY');
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

      for (final orderItem in order.items) {
        if (orderItem.product != null) {
          try {
            final cartItem = CartItem.fromProduct(
              product: orderItem.product!,
              tier: orderItem.pricingTier,
              quantity: orderItem.quantity,
            );
            cartItems.add(cartItem);
          } catch (e) {
            print('⚠️ Skipping item ${orderItem.productId}: $e');
          }
        }
      }

      print('✅ REORDER ITEMS PREPARED: ${cartItems.length} items');
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
}