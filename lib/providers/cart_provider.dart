import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/database_types.dart';
import '../services/product_service.dart';

// Cart state class
class CartState {
  final List<CartItem> items;
  final bool isLoading;
  final String? error;

  const CartState({
    this.items = const [],
    this.isLoading = false,
    this.error,
  });

  CartState copyWith({
    List<CartItem>? items,
    bool? isLoading,
    String? error,
  }) {
    return CartState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Clear error by setting it to null
  CartState clearError() {
    return copyWith(error: null);
  }

  // Calculated properties
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal => items.fold(0.0, (sum, item) => sum + item.totalPrice);

  double get taxAmount => subtotal * 0.12; // 12% VAT in Philippines

  double get total => subtotal + taxAmount;

  bool get isEmpty => items.isEmpty;

  bool get isNotEmpty => items.isNotEmpty;

  // Get item count for a specific product and tier
  int getItemCount(String productId, PricingTier tier) {
    try {
      final item = items.firstWhere(
        (item) => item.product.id == productId && item.selectedTier == tier,
      );
      return item.quantity;
    } catch (e) {
      return 0;
    }
  }

  // Check if product with tier exists in cart
  bool hasItem(String productId, PricingTier tier) {
    return items.any(
      (item) => item.product.id == productId && item.selectedTier == tier,
    );
  }

  // Get cart item by product and tier
  CartItem? getItem(String productId, PricingTier tier) {
    try {
      return items.firstWhere(
        (item) => item.product.id == productId && item.selectedTier == tier,
      );
    } catch (e) {
      return null;
    }
  }
}

// Cart provider
class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  // Add item to cart or update quantity if it exists
  Future<bool> addToCart({
    required Product product,
    required PricingTier tier,
    required int quantity,
  }) async {
    if (quantity <= 0) {
      state = state.copyWith(error: 'Quantity must be greater than 0');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Validate price tier exists
      final priceTier = product.priceTiers.firstWhere(
        (p) => p.tierType == tier && p.isActive,
        orElse: () => throw Exception('Price tier not available'),
      );

      // Check minimum quantity requirement
      if (quantity < priceTier.minQuantity) {
        state = state.copyWith(
          isLoading: false,
          error: 'Minimum quantity for ${tier.name} pricing is ${priceTier.minQuantity}',
        );
        return false;
      }

      // Check maximum quantity requirement
      if (priceTier.maxQuantity != null && quantity > priceTier.maxQuantity!) {
        state = state.copyWith(
          isLoading: false,
          error: 'Maximum quantity for ${tier.name} pricing is ${priceTier.maxQuantity}',
        );
        return false;
      }

      // Check stock availability
      final branchId = await ProductService.getDefaultBranchId();
      if (branchId != null) {
        final availableStock = await ProductService.getAvailableStock(
          productId: product.id,
          branchId: branchId,
        );

        // Calculate total quantity needed (including existing cart items)
        final existingQuantity = state.getItemCount(product.id, tier);
        final totalNeeded = existingQuantity + quantity;

        if (totalNeeded > availableStock) {
          state = state.copyWith(
            isLoading: false,
            error: 'Only $availableStock units available in stock',
          );
          return false;
        }
      }

      // Create or update cart item
      final existingItemIndex = state.items.indexWhere(
        (item) => item.product.id == product.id && item.selectedTier == tier,
      );

      List<CartItem> updatedItems = List.from(state.items);

      if (existingItemIndex >= 0) {
        // Update existing item
        final existingItem = updatedItems[existingItemIndex];
        final newQuantity = existingItem.quantity + quantity;
        final newTotalPrice = priceTier.price * newQuantity;

        updatedItems[existingItemIndex] = existingItem.copyWith(
          quantity: newQuantity,
          totalPrice: newTotalPrice,
        );

        print('✅ CART UPDATED: ${product.name} (${tier.name}) -> $newQuantity units');
      } else {
        // Add new item
        final cartItem = CartItem.fromProduct(
          product: product,
          tier: tier,
          quantity: quantity,
        );

        updatedItems.add(cartItem);
        print('✅ CART ADDED: ${product.name} (${tier.name}) -> $quantity units');
      }

      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );

      return true;
    } catch (e) {
      print('❌ ERROR ADDING TO CART: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to add item to cart: ${e.toString()}',
      );
      return false;
    }
  }

  // Update item quantity
  Future<bool> updateQuantity({
    required String productId,
    required PricingTier tier,
    required int newQuantity,
  }) async {
    if (newQuantity <= 0) {
      return removeItem(productId: productId, tier: tier);
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final itemIndex = state.items.indexWhere(
        (item) => item.product.id == productId && item.selectedTier == tier,
      );

      if (itemIndex < 0) {
        state = state.copyWith(
          isLoading: false,
          error: 'Item not found in cart',
        );
        return false;
      }

      final item = state.items[itemIndex];
      final priceTier = item.product.priceTiers.firstWhere(
        (p) => p.tierType == tier && p.isActive,
      );

      // Validate quantity constraints
      if (newQuantity < priceTier.minQuantity) {
        state = state.copyWith(
          isLoading: false,
          error: 'Minimum quantity for ${tier.name} pricing is ${priceTier.minQuantity}',
        );
        return false;
      }

      if (priceTier.maxQuantity != null && newQuantity > priceTier.maxQuantity!) {
        state = state.copyWith(
          isLoading: false,
          error: 'Maximum quantity for ${tier.name} pricing is ${priceTier.maxQuantity}',
        );
        return false;
      }

      // Check stock availability
      final branchId = await ProductService.getDefaultBranchId();
      if (branchId != null) {
        final availableStock = await ProductService.getAvailableStock(
          productId: productId,
          branchId: branchId,
        );

        if (newQuantity > availableStock) {
          state = state.copyWith(
            isLoading: false,
            error: 'Only $availableStock units available in stock',
          );
          return false;
        }
      }

      // Update item
      List<CartItem> updatedItems = List.from(state.items);
      updatedItems[itemIndex] = item.copyWith(
        quantity: newQuantity,
        totalPrice: priceTier.price * newQuantity,
      );

      state = state.copyWith(
        items: updatedItems,
        isLoading: false,
      );

      print('✅ CART QUANTITY UPDATED: ${item.product.name} -> $newQuantity units');
      return true;
    } catch (e) {
      print('❌ ERROR UPDATING CART QUANTITY: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to update quantity',
      );
      return false;
    }
  }

  // Remove item from cart
  bool removeItem({
    required String productId,
    required PricingTier tier,
  }) {
    final updatedItems = state.items.where(
      (item) => !(item.product.id == productId && item.selectedTier == tier),
    ).toList();

    state = state.copyWith(items: updatedItems);
    print('✅ CART ITEM REMOVED: $productId (${tier.name})');
    return true;
  }

  // Clear entire cart
  void clearCart() {
    state = state.copyWith(items: []);
    print('✅ CART CLEARED');
  }

  // Change pricing tier for an item
  Future<bool> changePricingTier({
    required String productId,
    required PricingTier currentTier,
    required PricingTier newTier,
  }) async {
    final item = state.getItem(productId, currentTier);
    if (item == null) return false;

    // Remove old item and add with new tier
    removeItem(productId: productId, tier: currentTier);
    return await addToCart(
      product: item.product,
      tier: newTier,
      quantity: item.quantity,
    );
  }

  // Get cart summary for checkout
  Map<String, dynamic> getCartSummary() {
    return {
      'items': state.items.map((item) => {
        'product_id': item.product.id,
        'product_name': item.product.name,
        'pricing_tier': item.selectedTier.name,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'total_price': item.totalPrice,
      }).toList(),
      'total_items': state.totalItems,
      'subtotal': state.subtotal,
      'tax_amount': state.taxAmount,
      'total_amount': state.total,
    };
  }

  // Validate cart before checkout
  Future<bool> validateCart() async {
    if (state.isEmpty) {
      state = state.copyWith(error: 'Cart is empty');
      return false;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final branchId = await ProductService.getDefaultBranchId();
      if (branchId == null) {
        state = state.copyWith(
          isLoading: false,
          error: 'Unable to validate stock - branch not found',
        );
        return false;
      }

      // Check stock for each item
      for (final item in state.items) {
        final availableStock = await ProductService.getAvailableStock(
          productId: item.product.id,
          branchId: branchId,
        );

        if (item.quantity > availableStock) {
          state = state.copyWith(
            isLoading: false,
            error: '${item.product.name} has only $availableStock units available',
          );
          return false;
        }
      }

      state = state.copyWith(isLoading: false);
      print('✅ CART VALIDATION PASSED');
      return true;
    } catch (e) {
      print('❌ ERROR VALIDATING CART: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to validate cart',
      );
      return false;
    }
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }

  // Get item suggestions based on cart content
  Future<List<Product>> getItemSuggestions() async {
    try {
      if (state.isEmpty) return [];

      // Get category IDs from current cart items
      final categoryIds = state.items
          .map((item) => item.product.categoryId)
          .where((id) => id != null)
          .toSet()
          .cast<String>();

      if (categoryIds.isEmpty) return [];

      // Get recommended products from the same categories
      final suggestions = await ProductService.getRecommendedProducts(
        categoryId: categoryIds.first,
        limit: 5,
      );

      // Filter out products already in cart
      final cartProductIds = state.items.map((item) => item.product.id).toSet();
      return suggestions.where((product) => !cartProductIds.contains(product.id)).toList();
    } catch (e) {
      print('❌ ERROR GETTING SUGGESTIONS: $e');
      return [];
    }
  }
}

// Providers
final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

// Individual providers for easy access
final cartItemsProvider = Provider<List<CartItem>>((ref) {
  return ref.watch(cartProvider).items;
});

final cartTotalItemsProvider = Provider<int>((ref) {
  return ref.watch(cartProvider).totalItems;
});

final cartSubtotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).subtotal;
});

final cartTotalProvider = Provider<double>((ref) {
  return ref.watch(cartProvider).total;
});

final cartIsEmptyProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isEmpty;
});

final cartIsLoadingProvider = Provider<bool>((ref) {
  return ref.watch(cartProvider).isLoading;
});

final cartErrorProvider = Provider<String?>((ref) {
  return ref.watch(cartProvider).error;
});

// Cart item count for specific product and tier
final cartItemCountProvider = Provider.family<int, Map<String, dynamic>>((ref, params) {
  final productId = params['productId'] as String;
  final tier = params['tier'] as PricingTier;
  return ref.watch(cartProvider).getItemCount(productId, tier);
});

// Cart item suggestions provider
final cartSuggestionsProvider = FutureProvider<List<Product>>((ref) async {
  return await ref.watch(cartProvider.notifier).getItemSuggestions();
});