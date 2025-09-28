import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' hide Category;
import '../models/database_types.dart';

class ProductService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get all active products with their related data (categories, brands, price tiers, inventory)
  /// Products are centralized and not branch-specific. Branch filtering is applied only for inventory.
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
              tier_type,
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
          .eq('status', 'active');

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
              (product.sku?.toLowerCase().contains(query) ?? false) ||
              (product.barcode?.toLowerCase().contains(query) ?? false) ||
              (product.category?.name.toLowerCase().contains(query) ?? false) ||
              (product.brand?.name.toLowerCase().contains(query) ?? false);
        }).toList();
      }

      // Filter by branch inventory if provided
      if (branchId != null && branchId.isNotEmpty) {
        products = products.where((product) {
          return product.inventory.any((inv) =>
            inv.branchId == branchId && inv.availableQuantity > 0
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
          print('   Available stock: ${sample.inventory.first.availableQuantity}');
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
              tier_type,
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
          .eq('status', 'active')
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

  /// Get available stock for a product in a specific branch
  static Future<int> getAvailableStock({
    required String productId,
    required String branchId,
  }) async {
    try {
      print('📦 CHECKING STOCK: Product $productId in Branch $branchId');

      final response = await _client
          .from('inventory')
          .select('available_quantity')
          .eq('product_id', productId)
          .eq('branch_id', branchId)
          .maybeSingle();

      if (response != null) {
        final stock = response['available_quantity'] as int;
        print('✅ STOCK FOUND: $stock units available');
        return stock;
      } else {
        print('⚠️ NO INVENTORY RECORD FOUND');
        return 0;
      }
    } catch (e) {
      print('❌ ERROR CHECKING STOCK: $e');
      debugPrint('Stock check error: $e');
      return 0;
    }
  }

  /// Get price for a product based on tier and quantity
  static double? getPrice({
    required Product product,
    required PricingTier tier,
    required int quantity,
  }) {
    try {
      // Find the appropriate price tier
      final priceTier = product.priceTiers.firstWhere(
        (p) => p.tierType == tier && p.isActive,
        orElse: () => product.priceTiers.firstWhere(
          (p) => p.isActive,
          orElse: () => throw Exception('No active price tiers found'),
        ),
      );

      // Check if quantity meets minimum requirement
      if (quantity < priceTier.minQuantity) {
        print('⚠️ Quantity $quantity below minimum ${priceTier.minQuantity} for ${tier.name}');
        return null;
      }

      // Check if quantity exceeds maximum (if set)
      if (priceTier.maxQuantity != null && quantity > priceTier.maxQuantity!) {
        print('⚠️ Quantity $quantity exceeds maximum ${priceTier.maxQuantity} for ${tier.name}');
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
          return product.inventory.any((inv) =>
            inv.branchId == branchId && inv.availableQuantity > 0
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
      products.sort((a, b) {
        final aStock = a.inventory.fold(0, (sum, inv) => sum + inv.availableQuantity);
        final bStock = b.inventory.fold(0, (sum, inv) => sum + inv.availableQuantity);
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return inventory.availableQuantity <= inventory.lowStockThreshold;
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
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );

    return inventory.batches.any((batch) => batch.isExpiringSoon);
  }
}