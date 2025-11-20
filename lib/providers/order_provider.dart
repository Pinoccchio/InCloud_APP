import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/database_types.dart';
import '../services/order_service.dart';
import '../providers/cart_provider.dart';

// Order state class
class OrderState {
  final List<Order> orders;
  final Map<String, int> statusCounts;
  final bool isLoading;
  final String? error;
  final String? selectedOrderId;

  const OrderState({
    this.orders = const [],
    this.statusCounts = const {},
    this.isLoading = false,
    this.error,
    this.selectedOrderId,
  });

  OrderState copyWith({
    List<Order>? orders,
    Map<String, int>? statusCounts,
    bool? isLoading,
    String? error,
    String? selectedOrderId,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      statusCounts: statusCounts ?? this.statusCounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedOrderId: selectedOrderId ?? this.selectedOrderId,
    );
  }

  // Clear error by setting it to null
  OrderState clearError() {
    return copyWith(error: null);
  }

  // Get order by ID
  Order? getOrderById(String orderId) {
    try {
      return orders.firstWhere((order) => order.id == orderId);
    } catch (e) {
      return null;
    }
  }

  // Filter orders by status
  List<Order> getOrdersByStatus(OrderStatus status) {
    return orders.where((order) => order.status == status).toList();
  }

  // Get recent orders (last 10)
  List<Order> get recentOrders {
    final sortedOrders = List<Order>.from(orders);
    sortedOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sortedOrders.take(10).toList();
  }

  // Check if has any active orders
  bool get hasActiveOrders {
    return orders.any((order) =>
      order.status == OrderStatus.pending ||
      order.status == OrderStatus.confirmed ||
      order.status == OrderStatus.in_transit
    );
  }
}

// Order provider
class OrderNotifier extends Notifier<OrderState> {
  @override
  OrderState build() {
    return const OrderState();
  }

  // Load customer orders
  Future<void> loadOrders() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Load orders and status counts in parallel
      final results = await Future.wait([
        OrderService.getCustomerOrders(),
        OrderService.getOrderStatusCounts(),
      ]);

      final orders = results[0] as List<Order>;
      final statusCounts = results[1] as Map<String, int>;

      state = state.copyWith(
        orders: orders,
        statusCounts: statusCounts,
        isLoading: false,
      );

      print('✅ ORDERS LOADED: ${orders.length} orders');
    } catch (e) {
      print('❌ ERROR LOADING ORDERS: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load orders. Please try again.',
      );
    }
  }

  // Create order from cart
  Future<String?> createOrderFromCart({
    required List<CartItem> cartItems,
    String? notes,
    Map<String, dynamic>? deliveryAddress,
    String paymentMethod = 'cash_on_delivery',
    String? gcashReferenceNumber,
  }) async {
    if (state.isLoading) return null;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final orderId = await OrderService.createOrder(
        cartItems: cartItems,
        notes: notes,
        deliveryAddress: deliveryAddress,
        paymentMethod: paymentMethod,
        gcashReferenceNumber: gcashReferenceNumber,
      );

      if (orderId != null) {
        // Refresh orders to include the new one
        await loadOrders();
      }

      state = state.copyWith(isLoading: false);
      return orderId;
    } catch (e) {
      print('❌ ERROR CREATING ORDER: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create order: ${e.toString()}',
      );
      return null;
    }
  }

  // Cancel order
  Future<bool> cancelOrder(String orderId, String reason) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final success = await OrderService.cancelOrder(orderId, reason);

      if (success) {
        // Refresh orders to reflect the cancellation
        await loadOrders();
      }

      state = state.copyWith(isLoading: false);
      return success;
    } catch (e) {
      print('❌ ERROR CANCELLING ORDER: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel order: ${e.toString()}',
      );
      return false;
    }
  }

  // Select order for details view
  void selectOrder(String? orderId) {
    state = state.copyWith(selectedOrderId: orderId);
  }

  // Refresh orders
  Future<void> refreshOrders() async {
    await loadOrders();
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }

  // Get order by ID with fresh data
  Future<Order?> getOrderById(String orderId) async {
    try {
      return await OrderService.getOrderById(orderId);
    } catch (e) {
      print('❌ ERROR FETCHING ORDER BY ID: $e');
      return null;
    }
  }
}

// Providers
final orderProvider = NotifierProvider<OrderNotifier, OrderState>(OrderNotifier.new);

// Individual providers for easy access
final ordersListProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderProvider).orders;
});

final orderStatusCountsProvider = Provider<Map<String, int>>((ref) {
  return ref.watch(orderProvider).statusCounts;
});

final isLoadingOrdersProvider = Provider<bool>((ref) {
  return ref.watch(orderProvider).isLoading;
});

final orderErrorProvider = Provider<String?>((ref) {
  return ref.watch(orderProvider).error;
});

final selectedOrderProvider = Provider<Order?>((ref) {
  final state = ref.watch(orderProvider);
  if (state.selectedOrderId != null) {
    return state.getOrderById(state.selectedOrderId!);
  }
  return null;
});

final recentOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderProvider).recentOrders;
});

final hasActiveOrdersProvider = Provider<bool>((ref) {
  return ref.watch(orderProvider).hasActiveOrders;
});

// Orders by status providers
final pendingOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderProvider).getOrdersByStatus(OrderStatus.pending);
});

final confirmedOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderProvider).getOrdersByStatus(OrderStatus.confirmed);
});

final inTransitOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderProvider).getOrdersByStatus(OrderStatus.in_transit);
});

final deliveredOrdersProvider = Provider<List<Order>>((ref) {
  return ref.watch(orderProvider).getOrdersByStatus(OrderStatus.delivered);
});

// Order creation provider
final orderCreationProvider = NotifierProvider<OrderCreationNotifier, OrderCreationState>(OrderCreationNotifier.new);

class OrderCreationState {
  final bool isCreating;
  final String? error;
  final String? notes;
  final Map<String, dynamic>? deliveryAddress;

  const OrderCreationState({
    this.isCreating = false,
    this.error,
    this.notes,
    this.deliveryAddress,
  });

  OrderCreationState copyWith({
    bool? isCreating,
    String? error,
    String? notes,
    Map<String, dynamic>? deliveryAddress,
  }) {
    return OrderCreationState(
      isCreating: isCreating ?? this.isCreating,
      error: error,
      notes: notes ?? this.notes,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
    );
  }
}

class OrderCreationNotifier extends Notifier<OrderCreationState> {
  @override
  OrderCreationState build() {
    return const OrderCreationState();
  }

  void setNotes(String notes) {
    state = state.copyWith(notes: notes);
  }

  void setDeliveryAddress(Map<String, dynamic> address) {
    state = state.copyWith(deliveryAddress: address);
  }

  Future<String?> createOrder() async {
    final cartItems = ref.read(cartItemsProvider);
    if (cartItems.isEmpty) {
      state = state.copyWith(error: 'Cart is empty');
      return null;
    }

    state = state.copyWith(isCreating: true, error: null);

    try {
      final orderId = await ref.read(orderProvider.notifier).createOrderFromCart(
        cartItems: cartItems,
        notes: state.notes,
        deliveryAddress: state.deliveryAddress,
      );

      if (orderId != null) {
        // Clear cart after successful order creation
        ref.read(cartProvider.notifier).clearCart();

        // Reset creation state
        state = const OrderCreationState();
      }

      return orderId;
    } catch (e) {
      state = state.copyWith(
        isCreating: false,
        error: 'Failed to create order: ${e.toString()}',
      );
      return null;
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Real-time order updates provider
final orderUpdatesProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return OrderService.subscribeToOrderUpdates();
});