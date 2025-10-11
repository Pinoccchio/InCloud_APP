import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/database_types.dart';
import '../services/product_service.dart';
import '../core/utils/date_utils.dart' as app_date_utils;

// Product state class
class ProductState {
  final List<Product> products;
  final List<Category> categories;
  final List<Brand> brands;
  final bool isLoading;
  final String? error;
  final String? selectedCategoryId;
  final String? selectedBrandId;
  final String searchQuery;
  final String? currentBranchId;

  const ProductState({
    this.products = const [],
    this.categories = const [],
    this.brands = const [],
    this.isLoading = false,
    this.error,
    this.selectedCategoryId,
    this.selectedBrandId,
    this.searchQuery = '',
    this.currentBranchId,
  });

  ProductState copyWith({
    List<Product>? products,
    List<Category>? categories,
    List<Brand>? brands,
    bool? isLoading,
    String? error,
    String? selectedCategoryId,
    String? selectedBrandId,
    String? searchQuery,
    String? currentBranchId,
  }) {
    return ProductState(
      products: products ?? this.products,
      categories: categories ?? this.categories,
      brands: brands ?? this.brands,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      selectedCategoryId: selectedCategoryId ?? this.selectedCategoryId,
      selectedBrandId: selectedBrandId ?? this.selectedBrandId,
      searchQuery: searchQuery ?? this.searchQuery,
      currentBranchId: currentBranchId ?? this.currentBranchId,
    );
  }

  // Clear error by setting it to null
  ProductState clearError() {
    return copyWith(error: null);
  }

  // Filtered products based on current filters
  List<Product> get filteredProducts {
    List<Product> filtered = List.from(products);

    // Filter by search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((product) {
        return product.name.toLowerCase().contains(query) ||
            (product.description?.toLowerCase().contains(query) ?? false) ||
            (product.productId?.toLowerCase().contains(query) ?? false) ||
            (product.category?.name.toLowerCase().contains(query) ?? false) ||
            (product.brand?.name.toLowerCase().contains(query) ?? false);
      }).toList();
    }

    // Filter by category
    if (selectedCategoryId != null && selectedCategoryId!.isNotEmpty) {
      filtered = filtered.where((product) => product.categoryId == selectedCategoryId).toList();
    }

    // Filter by brand
    if (selectedBrandId != null && selectedBrandId!.isNotEmpty) {
      filtered = filtered.where((product) => product.brandId == selectedBrandId).toList();
    }

    // NOTE: Branch filter removed - show all products regardless of stock in current branch
    // Products are centralized; inventory is branch-specific. UI shows stock badges for context.
    // This matches web dashboard behavior where all 49 products are visible.

    return filtered;
  }

  // Get brands that actually have products (to avoid showing brands with no products)
  List<Brand> get brandsWithProducts {
    if (products.isEmpty) return brands;

    // Get unique brand IDs from available products
    final brandIds = products
        .where((p) => p.brandId != null)
        .map((p) => p.brandId!)
        .toSet();

    // Return only brands that have at least one product
    return brands.where((b) => brandIds.contains(b.id)).toList();
  }
}

// Product provider
class ProductNotifier extends Notifier<ProductState> {
  @override
  ProductState build() {
    return const ProductState();
  }

  // Initialize data
  Future<void> initialize() async {
    if (state.isLoading) return; // Prevent multiple simultaneous loads

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Get default branch ID
      final branchId = await ProductService.getDefaultBranchId();

      // Load all data in parallel - products are centralized, not branch-specific
      final results = await Future.wait([
        ProductService.getProducts(), // No branchId - products are centralized
        ProductService.getCategories(),
        ProductService.getBrands(),
      ]);

      state = state.copyWith(
        products: results[0] as List<Product>,
        categories: results[1] as List<Category>,
        brands: results[2] as List<Brand>,
        currentBranchId: branchId,
        isLoading: false,
      );

      debugPrint('✅ PRODUCT PROVIDER INITIALIZED');
      debugPrint('   Products: ${state.products.length}');
      debugPrint('   Categories: ${state.categories.length}');
      debugPrint('   Brands: ${state.brands.length}');
      debugPrint('   Branch: ${state.currentBranchId}');
    } catch (e) {
      debugPrint('❌ ERROR INITIALIZING PRODUCT PROVIDER: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load products. Please try again.',
      );
    }
  }

  // Refresh products (fetches all products without filters - filtering happens client-side)
  Future<void> refreshProducts() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch ALL products without any filters - client-side filtering via filteredProducts getter
      final products = await ProductService.getProducts();

      state = state.copyWith(
        products: products,
        isLoading: false,
      );

      debugPrint('✅ PRODUCTS REFRESHED: ${products.length} products');
    } catch (e) {
      debugPrint('❌ ERROR REFRESHING PRODUCTS: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh products. Please try again.',
      );
    }
  }

  // Search products (client-side filtering via filteredProducts getter)
  // This method updates the search query state only - the actual filtering happens
  // in the filteredProducts getter, ensuring state.products always contains the full list
  void searchProducts(String query) {
    state = state.copyWith(searchQuery: query);
    debugPrint('✅ SEARCH QUERY SET: "$query"');
  }

  // Set category filter
  void setCategory(String? categoryId) {
    state = state.copyWith(selectedCategoryId: categoryId);
    // Don't re-fetch - let filteredProducts getter handle filtering client-side
    debugPrint('✅ CATEGORY FILTER SET: $categoryId');
  }

  // Set brand filter
  void setBrand(String? brandId) {
    state = state.copyWith(selectedBrandId: brandId);
    // Don't re-fetch - let filteredProducts getter handle filtering client-side
    debugPrint('✅ BRAND FILTER SET: $brandId');
  }

  // Clear all filters
  void clearFilters() {
    state = state.copyWith(
      selectedCategoryId: null,
      selectedBrandId: null,
      searchQuery: '',
    );
    _refreshAllProducts();
  }

  // Refresh all products without any filters (products are centralized)
  Future<void> _refreshAllProducts() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      // Fetch ALL products without any filters - products are centralized
      final products = await ProductService.getProducts();

      state = state.copyWith(
        products: products,
        isLoading: false,
      );

      debugPrint('✅ ALL PRODUCTS REFRESHED: ${products.length} products');
    } catch (e) {
      debugPrint('❌ ERROR REFRESHING ALL PRODUCTS: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to refresh products. Please try again.',
      );
    }
  }

  // Get product by ID
  Product? getProductById(String productId) {
    try {
      return state.products.firstWhere((product) => product.id == productId);
    } catch (e) {
      return null;
    }
  }

  // Check if product is available in current branch
  bool isProductAvailable(String productId) {
    final product = getProductById(productId);
    if (product == null || state.currentBranchId == null) return false;

    return product.inventory.any((inv) =>
      inv.branchId == state.currentBranchId && inv.availableQuantity > 0
    );
  }

  // Get available stock for product
  int getAvailableStock(String productId) {
    final product = getProductById(productId);
    if (product == null || state.currentBranchId == null) return 0;

    final inventory = product.inventory.firstWhere(
      (inv) => inv.branchId == state.currentBranchId,
      orElse: () => Inventory(
        id: '',
        productId: productId,
        branchId: state.currentBranchId!,
        availableQuantity: 0,
        createdAt: app_date_utils.DateUtils.nowInUtc(),
        updatedAt: app_date_utils.DateUtils.nowInUtc(),
      ),
    );

    return inventory.availableQuantity;
  }

  // Get price for product with specific tier and quantity
  double? getProductPrice({
    required String productId,
    required PricingTier tier,
    required int quantity,
  }) {
    final product = getProductById(productId);
    if (product == null) return null;

    return ProductService.getPrice(
      product: product,
      tier: tier,
      quantity: quantity,
    );
  }

  // Clear error
  void clearError() {
    state = state.clearError();
  }
}

// Providers
final productProvider = NotifierProvider<ProductNotifier, ProductState>(ProductNotifier.new);

// Individual providers for easy access
final productsListProvider = Provider<List<Product>>((ref) {
  return ref.watch(productProvider).filteredProducts;
});

final categoriesProvider = Provider<List<Category>>((ref) {
  return ref.watch(productProvider).categories;
});

final brandsProvider = Provider<List<Brand>>((ref) {
  return ref.watch(productProvider).brands;
});

// Provider for brands that have products (filtered)
final brandsWithProductsProvider = Provider<List<Brand>>((ref) {
  return ref.watch(productProvider).brandsWithProducts;
});

final isLoadingProductsProvider = Provider<bool>((ref) {
  return ref.watch(productProvider).isLoading;
});

final productErrorProvider = Provider<String?>((ref) {
  return ref.watch(productProvider).error;
});

// Individual product provider
final productByIdProvider = Provider.family<Product?, String>((ref, productId) {
  return ref.watch(productProvider.notifier).getProductById(productId);
});

// Product availability provider
final productAvailabilityProvider = Provider.family<bool, String>((ref, productId) {
  return ref.watch(productProvider.notifier).isProductAvailable(productId);
});

// Product stock provider
final productStockProvider = Provider.family<int, String>((ref, productId) {
  return ref.watch(productProvider.notifier).getAvailableStock(productId);
});

// Product recommendations provider
final recommendedProductsProvider = FutureProvider<List<Product>>((ref) async {
  try {
    return await ProductService.getRecommendedProducts(limit: 6);
  } catch (e) {
    return [];
  }
});