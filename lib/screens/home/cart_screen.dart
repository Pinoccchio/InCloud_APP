import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/database_types.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';

class CartScreen extends ConsumerWidget {
  final void Function(int)? onNavigateToTab;

  const CartScreen({super.key, this.onNavigateToTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartItemsProvider);
    final totalItems = ref.watch(cartTotalItemsProvider);
    final subtotal = ref.watch(cartSubtotalProvider);
    final total = ref.watch(cartTotalProvider);
    final isEmpty = ref.watch(cartIsEmptyProvider);
    final isLoading = ref.watch(cartIsLoadingProvider);
    final error = ref.watch(cartErrorProvider);

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await ref.read(cartProvider.notifier).validateCart();
          },
          child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Text(
                    'Shopping Cart',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  if (!isEmpty)
                    TextButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Clear Cart'),
                            content: const Text('Are you sure you want to remove all items from your cart?'),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('Cancel'),
                              ),
                              TextButton(
                                onPressed: () {
                                  ref.read(cartProvider.notifier).clearCart();
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Clear', style: TextStyle(color: Colors.red)),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.clear_all, size: 20),
                      label: const Text('Clear All'),
                    ),
                ],
              ),
            ),

            // Error Display
            if (error != null)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: Colors.red.shade600, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        error,
                        style: TextStyle(color: Colors.red.shade600, fontSize: 14),
                      ),
                    ),
                    TextButton(
                      onPressed: () => ref.read(cartProvider.notifier).clearError(),
                      child: Text('Dismiss', style: TextStyle(color: Colors.red.shade600)),
                    ),
                  ],
                ),
              ),

            // Cart Items
            Expanded(
              child: isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.6,
                        child: _buildEmptyCart(context),
                      ),
                    )
                  : Column(
                      children: [
                        // Items Count
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Row(
                            children: [
                              Text(
                                '$totalItems items in cart',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // Cart Items List
                        Expanded(
                          child: ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: cartItems.length,
                            itemBuilder: (context, index) {
                              final item = cartItems[index];
                              return _buildCartItem(context, ref, item);
                            },
                          ),
                        ),
                      ],
                    ),
            ),

            // Cart Summary and Checkout
            if (!isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gray300.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Order Summary
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Subtotal:',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '₱${subtotal.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total:',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '₱${total.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: AppColors.primaryRed,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Checkout Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isLoading
                            ? null
                            : () async {
                                // Additional validation before checkout
                                if (cartItems.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Your cart is empty'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                // Validate minimum order amount if needed
                                if (total < 100) { // Minimum order of ₱100
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Minimum order amount is ₱100.00'),
                                      backgroundColor: AppColors.error,
                                    ),
                                  );
                                  return;
                                }

                                final isValid = await ref.read(cartProvider.notifier).validateCart();
                                if (isValid) {
                                  _showCheckoutDialog(context, ref);
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryRed,
                          foregroundColor: AppColors.white,
                          minimumSize: const Size(double.infinity, 50),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Proceed to Checkout',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        ),
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_cart_outlined,
            size: 80,
            color: AppColors.textTertiary,
          ),
          const SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            'Add some delicious frozen foods to get started!',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              // Navigate to search screen (index 1 in BottomNavigationBar)
              onNavigateToTab?.call(1);
            },
            icon: const Icon(Icons.search),
            label: const Text('Browse Products'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: AppColors.white,
              minimumSize: const Size(200, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartItem(BuildContext context, WidgetRef ref, CartItem item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppColors.gray300.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Product Image/Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: item.product.images.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.product.images.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              item.product.isFrozen ? Icons.ac_unit : Icons.fastfood,
                              color: AppColors.primaryBlue,
                              size: 30,
                            );
                          },
                        ),
                      )
                    : Icon(
                        item.product.isFrozen ? Icons.ac_unit : Icons.fastfood,
                        color: AppColors.primaryBlue,
                        size: 30,
                      ),
              ),

              const SizedBox(width: 16),

              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.product.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            item.selectedTier.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '₱${item.unitPrice.toStringAsFixed(2)} each',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Remove Button
              IconButton(
                onPressed: () {
                  ref.read(cartProvider.notifier).removeItem(
                    productId: item.product.id,
                    tier: item.selectedTier,
                  );
                },
                icon: Icon(
                  Icons.delete_outline,
                  color: AppColors.error,
                  size: 20,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Quantity Controls and Total
          Row(
            children: [
              // Quantity Controls
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: item.quantity > 1
                          ? () {
                              ref.read(cartProvider.notifier).updateQuantity(
                                productId: item.product.id,
                                tier: item.selectedTier,
                                newQuantity: item.quantity - 1,
                              );
                            }
                          : null,
                      icon: const Icon(Icons.remove, size: 20),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        item.quantity.toString(),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).updateQuantity(
                          productId: item.product.id,
                          tier: item.selectedTier,
                          newQuantity: item.quantity + 1,
                        );
                      },
                      icon: const Icon(Icons.add, size: 20),
                      constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Item Total
              Text(
                '₱${item.totalPrice.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showCheckoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Proceed to Checkout'),
        content: const Text(
          'Your order request will be sent to J.A\'s Food Trading for processing. '
          'You will receive a confirmation and delivery details shortly.\n\n'
          'Payment will be collected upon delivery.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processCheckout(context, ref);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
            ),
            child: const Text('Submit Order Request'),
          ),
        ],
      ),
    );
  }

  void _processCheckout(BuildContext context, WidgetRef ref) async {
    final cartItems = ref.read(cartItemsProvider);

    if (cartItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    // Capture context-dependent objects before async operation
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 16),
              Text('Creating your order...'),
            ],
          ),
        ),
      );

      // Create order using order provider
      final orderId = await ref.read(orderProvider.notifier).createOrderFromCart(
        cartItems: cartItems,
        notes: null, // Could add notes field in the future
        deliveryAddress: null, // Uses customer's default address
      );

      // Close loading dialog
      if (navigator.canPop()) {
        navigator.pop();
      }

      if (orderId != null) {
        // Order created successfully - clear cart after successful order
        ref.read(cartProvider.notifier).clearCart();

        // Safe orderId display
        final displayOrderId = orderId.length >= 8 ? orderId.substring(0, 8) : orderId;

        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text('Order #$displayOrderId created successfully!'),
            backgroundColor: AppColors.success,
            action: SnackBarAction(
              label: 'View Orders',
              textColor: AppColors.white,
              onPressed: () {
                // Navigate to orders tab (index 3 in BottomNavigationBar)
                onNavigateToTab?.call(3);
              },
            ),
          ),
        );
      } else {
        // Order creation failed
        final error = ref.read(orderErrorProvider);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(error ?? 'Failed to create order. Please try again.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      // Close loading dialog if still open
      if (navigator.canPop()) {
        navigator.pop();
      }

      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Error creating order: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}