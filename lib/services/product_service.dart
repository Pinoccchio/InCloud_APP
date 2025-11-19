import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/database_types.dart';
import '../core/utils/date_utils.dart' as app_date_utils;

class ProductService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get all active products with their related data (categories, brands, price tiers, inventory)
  ///
  /// **Architecture**: Products are centralized - all products are visible system-wide regardless of branch.
  /// This matches the web dashboard behavior where all 49 products are always visible.
  ///
  /// **Branch Filtering**: The [branchId] parameter is optional and used ONLY for inventory filtering.
  /// - If provided: Returns all products, but filters inventory records to show only the specified branch
  /// - If null: Returns all products with inventory from all branches
  ///
  /// **Use Cases**:
  /// - Show all products in catalog (pass branchId=null)
  /// - Show products with branch-specific inventory (pass branchId)
  /// - Filter products by category/brand (use categoryId/brandId parameters)
  ///
  /// Products without stock in a branch are still returned - the UI layer handles display logic.
  static Future<List<Product>> getProducts({
    String? searchQuery,
    String? categoryId,
    String? brandId,
    String? branchId, // Used only for inventory filtering, not product fetching
  }) async {
    try {
      print('🔍 FETCHING PRODUCTS (CENTRALIZED)...');
      if (searchQuery != null) print('   Search: "$searchQuery"');
      if (categoryId != null) print('   Category: $categoryId');
      if (brandId != null) print('   Brand: $brandId');
      if (branchId != null) print('   Branch filter for inventory: $branchId');

      // Build query with filters
      var query = _client
          .from('products')
          .select('''
            *,
            categories!products_category_id_fkey (
              id,
              name,
              description
            ),
            brands!products_brand_id_fkey (
              id,
              name,
              description,
              logo_url
            ),
            price_tiers!price_tiers_product_id_fkey (
              id,
              pricing_type,
              price,
              min_quantity,
              max_quantity,
              is_active
            ),
            inventory!inventory_product_id_fkey (
              id,
              quantity,
              available_quantity,
              reserved_quantity,
              low_stock_threshold,
              branch_id,
              product_batches!product_batches_inventory_id_fkey (
                id,
                batch_number,
                quantity,
                expiration_date,
                status,
                is_active
              )
            )
          ''')
          .eq('status', 'available');

      // Apply filters
      if (categoryId != null && categoryId.isNotEmpty) {
        query = query.eq('category_id', categoryId);
      }

      if (brandId != null && brandId.isNotEmpty) {
        query = query.eq('brand_id', brandId);
      }

      // Execute query with ordering
      final List<dynamic> response = await query.order('name');

      print('✅ RAW PRODUCT DATA FETCHED: ${response.length} products');

      // Parse products and filter by search query and branch
      List<Product> products = response.map((json) {
        try {
          return Product.fromJson(json);
        } catch (e) {
          print('❌ Error parsing product: $e');
          print('   Raw data: $json');
          rethrow;
        }
      }).toList();

      // Filter by search query if provided
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        products = products.where((product) {
          return product.name.toLowerCase().contains(query) ||
              (product.description?.toLowerCase().contains(query) ?? false) ||
              (product.productId?.toLowerCase().contains(query) ?? false) ||
              (product.category?.name.toLowerCase().contains(query) ?? false) ||
              (product.brand?.name.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Filter by branch inventory if provided
      if (branchId != null && branchId.isNotEmpty) {
        products = products.where((product) {
          // **P0 CRITICAL FIX**: Filter using non-expired stock only
          return product.inventory.any((inv) =>
            inv.branchId == branchId && inv.getAvailableNonExpiredQuantity() > 0
          );
        }).toList();
      }

      print('✅ PRODUCTS PROCESSED: ${products.length} products after filtering');

      // Log sample data for debugging
      if (products.isNotEmpty) {
        final sample = products.first;
        print('   Sample product: ${sample.name}');
        print('   Price tiers: ${sample.priceTiers.length}');
        print('   Inventory records: ${sample.inventory.length}');
        if (sample.inventory.isNotEmpty) {
          // **P0 CRITICAL FIX**: Log non-expired stock for debugging
          print('   Non-expired stock: ${sample.inventory.first.getAvailableNonExpiredQuantity()}');
        }
      }

      return products;
    } catch (e) {
      print('❌ ERROR FETCHING PRODUCTS: $e');
      debugPrint('Product fetch error: $e');
      rethrow;
    }
  }

  /// Get a single product by ID with all related data
  static Future<Product?> getProductById(String productId) async {
    try {
      print('🔍 FETCHING PRODUCT BY ID: $productId');

      final response = await _client
          .from('products')
          .select('''
            *,
            categories!products_category_id_fkey (
              id,
              name,
              description
            ),
            brands!products_brand_id_fkey (
              id,
              name,
              description,
              logo_url
            ),
            price_tiers!price_tiers_product_id_fkey (
              id,
              pricing_type,
              price,
              min_quantity,
              max_quantity,
              is_active
            ),
            inventory!inventory_product_id_fkey (
              id,
              quantity,
              available_quantity,
              reserved_quantity,
              low_stock_threshold,
              branch_id,
              product_batches!product_batches_inventory_id_fkey (
                id,
                batch_number,
                quantity,
                expiration_date,
                status,
                is_active
              )
            )
          ''')
          .eq('id', productId)
          .eq('status', 'available')
          .maybeSingle();

      if (response != null) {
        print('✅ PRODUCT FOUND: ${response['name']}');
        return Product.fromJson(response);
      } else {
        print('⚠️ PRODUCT NOT FOUND: $productId');
        return null;
      }
    } catch (e) {
      print('❌ ERROR FETCHING PRODUCT BY ID: $e');
      debugPrint('Product by ID fetch error: $e');
      return null;
    }
  }

  /// Get all categories
  static Future<List<Category>> getCategories() async {
    try {
      print('🏷️ FETCHING CATEGORIES...');

      final List<dynamic> response = await _client
          .from('categories')
          .select('*')
          .eq('is_active', true)
          .order('name');

      final categories = response.map((json) => Category.fromJson(json)).toList();

      print('✅ CATEGORIES FETCHED: ${categories.length} categories');
      return categories;
    } catch (e) {
      print('❌ ERROR FETCHING CATEGORIES: $e');
      debugPrint('Categories fetch error: $e');
      return [];
    }
  }

  /// Get all brands
  static Future<List<Brand>> getBrands() async {
    try {
      print('🏪 FETCHING BRANDS...');

      final List<dynamic> response = await _client
          .from('brands')
          .select('*')
          .eq('is_active', true)
          .order('name');

      final brands = response.map((json) => Brand.fromJson(json)).toList();

      print('✅ BRANDS FETCHED: ${brands.length} brands');
      return brands;
    } catch (e) {
      print('❌ ERROR FETCHING BRANDS: $e');
      debugPrint('Brands fetch error: $e');
      return [];
    }
  }

  /// Get available stock for a product in a specific branch (excluding expired batches)
  ///
  /// **CRITICAL**: This method filters out expired batches to prevent customers from
  /// ordering products that have passed their expiration date.
  ///
  /// Uses the database function `get_available_stock_excluding_expired` which:
  /// - Sums quantities from active, non-expired batches only
  /// - Filters batches where expiration_date > NOW()
  /// - Ensures food safety compliance
  static Future<int> getAvailableStock({
    required String productId,
    required String branchId,
  }) async {
    try {
      print('📦 CHECKING NON-EXPIRED STOCK: Product $productId in Branch $branchId');

      // Call RPC function that excludes expired batches
      final response = await _client.rpc(
        'get_available_stock_excluding_expired',
        params: {
          'p_product_id': productId,
          'p_branch_id': branchId,
        },
      );

      final stock = response as int;
      print('✅ NON-EXPIRED STOCK FOUND: $stock units available');
      return stock;
    } catch (e) {
      print('❌ ERROR CHECKING NON-EXPIRED STOCK: $e');
      debugPrint('Stock check error: $e');
      return 0;
    }
  }

  /// Get available non-expired stock grouped by branches for a product
  ///
  /// Returns a map of branch_id -> available quantity (excluding expired batches).
  /// Used for displaying multi-branch stock availability in product details.
  static Future<Map<String, int>> getNonExpiredStockByBranches({
    required String productId,
  }) async {
    try {
      print('📦 FETCHING NON-EXPIRED STOCK BY BRANCHES for Product $productId');

      final response = await _client.rpc(
        'get_non_expired_stock_by_branches',
        params: {
          'p_product_id': productId,
        },
      );

      if (response == null || response is! List) {
        print('⚠️ NO BRANCH STOCK DATA FOUND');
        return {};
      }

      // Parse response into map
      final Map<String, int> branchStockMap = {};
      for (final item in response) {
        final branchId = item['branch_id'] as String;
        final quantity = item['available_quantity'] as int;
        branchStockMap[branchId] = quantity;
        print('   Branch $branchId: $quantity units');
      }

      print('✅ BRANCH STOCK FETCHED: ${branchStockMap.length} branches');
      return branchStockMap;
    } catch (e) {
      print('❌ ERROR FETCHING BRANCH STOCK: $e');
      debugPrint('Branch stock fetch error: $e');
      return {};
    }
  }

  /// Get the correct price tier for a specific quantity (quantity-aware)
  /// This handles products with multiple tiers of the same type (e.g., retail 1-19 units vs retail 20+ units)
  static PriceTier? getTierForQuantity({
    required Product product,
    required PricingTier tierType,
    required int quantity,
  }) {
    try {
      // Get all active tiers of the requested type
      final tiersOfType = product.priceTiers
          .where((t) => t.tierType == tierType && t.isActive)
          .toList();

      if (tiersOfType.isEmpty) {
        print('⚠️ No active tiers found for ${tierType.name}');
        return null;
      }

      // Sort by min_quantity descending to find the highest applicable tier first
      // This ensures we get the best price for the quantity
      tiersOfType.sort((a, b) => b.minQuantity.compareTo(a.minQuantity));

      // Find the first tier where quantity meets requirements
      for (final tier in tiersOfType) {
        // Check if quantity meets minimum requirement
        if (quantity >= tier.minQuantity) {
          // Check max_quantity if set
          if (tier.maxQuantity == null || quantity <= tier.maxQuantity!) {
            print('✅ Found tier for $quantity units of ${tierType.name}: ₱${tier.price} (min: ${tier.minQuantity}, max: ${tier.maxQuantity ?? "unlimited"})');
            return tier;
          }
        }
      }

      // If no tier matches, try to find any tier (for edge cases)
      final anyTier = tiersOfType.firstOrNull;
      if (anyTier != null) {
        print('⚠️ No exact tier match for $quantity units, using default tier: ₱${anyTier.price}');
      }
      return anyTier;
    } catch (e) {
      print('❌ ERROR FINDING TIER FOR QUANTITY: $e');
      return null;
    }
  }

  /// Validate if a quantity meets the minimum/maximum requirements for a specific price tier
  ///
  /// **P0 Critical Fix**: Prevents customers from adding items below the minimum quantity
  /// for their selected pricing tier.
  ///
  /// Returns:
  /// - `true` if quantity is valid (>= minQuantity and <= maxQuantity if set)
  /// - `false` if quantity is invalid
  static bool validateQuantityForTier({
    required PriceTier tier,
    required int quantity,
  }) {
    if (quantity < tier.minQuantity) {
      print('❌ VALIDATION FAILED: Quantity $quantity is below minimum ${tier.minQuantity}');
      return false;
    }

    if (tier.maxQuantity != null && quantity > tier.maxQuantity!) {
      print('❌ VALIDATION FAILED: Quantity $quantity exceeds maximum ${tier.maxQuantity}');
      return false;
    }

    print('✅ VALIDATION PASSED: Quantity $quantity is valid for ${tier.tierType.name} tier');
    return true;
  }

  /// Get the minimum quantity required for a specific pricing tier
  ///
  /// Returns the minimum quantity, or null if the tier doesn't exist on the product.
  static int? getMinimumQuantityForTier({
    required Product product,
    required PricingTier tierType,
  }) {
    try {
      final matchingTiers = product.priceTiers.where(
        (t) => t.tierType == tierType && t.isActive,
      ).toList();

      if (matchingTiers.isEmpty) return null;

      return matchingTiers.first.minQuantity;
    } catch (e) {
      print('❌ ERROR GETTING MINIMUM QUANTITY: $e');
      return null;
    }
  }

  /// Get price for a product based on tier and quantity (DEPRECATED - use getTierForQuantity)
  /// Kept for backward compatibility
  static double? getPrice({
    required Product product,
    required PricingTier tier,
    required int quantity,
  }) {
    try {
      // Use the new quantity-aware method
      final priceTier = getTierForQuantity(
        product: product,
        tierType: tier,
        quantity: quantity,
      );

      if (priceTier == null) {
        print('⚠️ No valid price tier found for $quantity units of ${tier.name}');
        return null;
      }

      return priceTier.price;
    } catch (e) {
      print('❌ ERROR CALCULATING PRICE: $e');
      return null;
    }
  }

  /// Get the default branch ID (first active branch)
  static Future<String?> getDefaultBranchId() async {
    try {
      print('🏢 FETCHING DEFAULT BRANCH...');

      final response = await _client
          .from('branches')
          .select('id, name')
          .eq('is_active', true)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        final branchId = response['id'] as String;
        final branchName = response['name'] as String;
        print('✅ DEFAULT BRANCH: $branchName ($branchId)');
        return branchId;
      } else {
        print('⚠️ NO ACTIVE BRANCH FOUND');
        return null;
      }
    } catch (e) {
      print('❌ ERROR FETCHING DEFAULT BRANCH: $e');
      debugPrint('Default branch fetch error: $e');
      return null;
    }
  }

  /// Search products with advanced filtering
  ///
  /// **Note**: Like [getProducts], this returns all matching products regardless of branch.
  /// The [branchId] and [inStockOnly] parameters control inventory filtering, not product visibility.
  ///
  /// When [inStockOnly] is true and [branchId] is provided, only products with stock in that
  /// branch are returned. Otherwise, all products matching the search criteria are returned.
  static Future<List<Product>> searchProducts({
    required String query,
    String? categoryId,
    String? brandId,
    String? branchId,
    PricingTier? pricingTier,
    double? minPrice,
    double? maxPrice,
    bool? inStockOnly,
  }) async {
    try {
      print('🔍 ADVANCED PRODUCT SEARCH: "$query"');

      // Get base products
      List<Product> products = await getProducts(
        searchQuery: query,
        categoryId: categoryId,
        brandId: brandId,
        branchId: branchId,
      );

      // Apply additional filters
      if (pricingTier != null) {
        products = products.where((product) {
          return product.priceTiers.any((tier) =>
            tier.tierType == pricingTier && tier.isActive
          );
        }).toList();
      }

      if (minPrice != null || maxPrice != null) {
        products = products.where((product) {
          final prices = product.priceTiers
              .where((tier) => tier.isActive)
              .map((tier) => tier.price)
              .toList();

          if (prices.isEmpty) return false;

          final minProductPrice = prices.reduce((a, b) => a < b ? a : b);
          final maxProductPrice = prices.reduce((a, b) => a > b ? a : b);

          bool meetsMin = minPrice == null || maxProductPrice >= minPrice;
          bool meetsMax = maxPrice == null || minProductPrice <= maxPrice;

          return meetsMin && meetsMax;
        }).toList();
      }

      if (inStockOnly == true && branchId != null) {
        products = products.where((product) {
          // **P0 CRITICAL FIX**: Filter using non-expired stock only
          return product.inventory.any((inv) =>
            inv.branchId == branchId && inv.getAvailableNonExpiredQuantity() > 0
          );
        }).toList();
      }

      print('✅ SEARCH COMPLETED: ${products.length} products found');
      return products;
    } catch (e) {
      print('❌ ERROR IN ADVANCED SEARCH: $e');
      debugPrint('Advanced search error: $e');
      return [];
    }
  }

  /// Get product recommendations based on category or past orders
  static Future<List<Product>> getRecommendedProducts({
    String? categoryId,
    String? customerId,
    int limit = 10,
  }) async {
    try {
      print('💡 FETCHING RECOMMENDED PRODUCTS...');

      // For now, get popular products (this can be enhanced with ML in the future)
      final products = await getProducts();

      // Sort by availability and return limited results
      // **P0 CRITICAL FIX**: Sort using non-expired stock only
      products.sort((a, b) {
        final aStock = a.inventory.fold(0, (sum, inv) => sum + inv.getAvailableNonExpiredQuantity());
        final bStock = b.inventory.fold(0, (sum, inv) => sum + inv.getAvailableNonExpiredQuantity());
        return bStock.compareTo(aStock);
      });

      final recommended = products.take(limit).toList();
      print('✅ RECOMMENDATIONS: ${recommended.length} products');
      return recommended;
    } catch (e) {
      print('❌ ERROR FETCHING RECOMMENDATIONS: $e');
      debugPrint('Recommendations error: $e');
      return [];
    }
  }

  /// Check if a product is low in stock
  static bool isLowStock(Product product, String branchId) {
    final inventory = product.inventory.firstWhere(
      (inv) => inv.branchId == branchId,
      orElse: () => Inventory(
        id: '',
        productId: product.id,
        branchId: branchId,
        availableQuantity: 0,
        createdAt: app_date_utils.DateUtils.nowInUtc(),
        updatedAt: app_date_utils.DateUtils.nowInUtc(),
      ),
    );

    // **P0 CRITICAL FIX**: Check non-expired stock against threshold
    return inventory.getAvailableNonExpiredQuantity() <= inventory.lowStockThreshold;
  }

  /// Check if a product has expiring batches
  static bool hasExpiringBatches(Product product, String branchId) {
    final inventory = product.inventory.firstWhere(
      (inv) => inv.branchId == branchId,
      orElse: () => Inventory(
        id: '',
        productId: product.id,
        branchId: branchId,
        availableQuantity: 0,
        createdAt: app_date_utils.DateUtils.nowInUtc(),
        updatedAt: app_date_utils.DateUtils.nowInUtc(),
      ),
    );

    return inventory.batches.any((batch) => batch.isExpiringSoon);
  }
}