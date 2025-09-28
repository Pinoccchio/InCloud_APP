import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/database_types.dart';
import '../../providers/product_provider.dart';
import '../../providers/cart_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Name';
  PricingTier _selectedPricingTier = PricingTier.retail;

  @override
  void initState() {
    super.initState();
    // Initialize product data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).initialize();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handleSearch(String query) {
    ref.read(productProvider.notifier).searchProducts(query);
  }

  void _handleCategoryChange(String? categoryId) {
    setState(() {
      _selectedCategory = categoryId ?? 'All';
    });
    ref.read(productProvider.notifier).setCategory(
      categoryId == 'All' ? null : categoryId,
    );
  }

  List<Product> _getSortedProducts(List<Product> products) {
    List<Product> sorted = List.from(products);

    switch (_selectedSortBy) {
      case 'Price (Low to High)':
        sorted.sort((a, b) {
          final aPrice = _getLowestPrice(a);
          final bPrice = _getLowestPrice(b);
          return aPrice.compareTo(bPrice);
        });
        break;
      case 'Price (High to Low)':
        sorted.sort((a, b) {
          final aPrice = _getHighestPrice(a);
          final bPrice = _getHighestPrice(b);
          return bPrice.compareTo(aPrice);
        });
        break;
      case 'Popular':
        sorted.sort((a, b) {
          final aStock = _getTotalStock(a);
          final bStock = _getTotalStock(b);
          return bStock.compareTo(aStock); // Higher stock = more popular
        });
        break;
      case 'Name':
      default:
        sorted.sort((a, b) => a.name.compareTo(b.name));
        break;
    }

    return sorted;
  }

  double _getLowestPrice(Product product) {
    if (product.priceTiers.isEmpty) return 0.0;
    return product.priceTiers
        .where((tier) => tier.isActive)
        .map((tier) => tier.price)
        .reduce((a, b) => a < b ? a : b);
  }

  double _getHighestPrice(Product product) {
    if (product.priceTiers.isEmpty) return 0.0;
    return product.priceTiers
        .where((tier) => tier.isActive)
        .map((tier) => tier.price)
        .reduce((a, b) => a > b ? a : b);
  }

  int _getTotalStock(Product product) {
    return product.inventory.fold(0, (sum, inv) => sum + inv.availableQuantity);
  }

  double? _getProductPrice(Product product) {
    final tier = product.priceTiers.firstWhere(
      (t) => t.tierType == _selectedPricingTier && t.isActive,
      orElse: () => product.priceTiers.firstWhere(
        (t) => t.isActive,
        orElse: () => PriceTier(
          id: '',
          productId: product.id,
          tierType: PricingTier.retail,
          price: 0.0,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ),
    );
    return tier.price;
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    final products = ref.watch(productsListProvider);
    final categories = ref.watch(categoriesProvider);
    final isLoading = ref.watch(isLoadingProductsProvider);
    final error = ref.watch(productErrorProvider);

    // Get sorted products
    final sortedProducts = _getSortedProducts(products);

    // Build category options
    final categoryOptions = ['All'] + categories.map((c) => c.name).toList();

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Products',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Search Bar
                  TextField(
                    controller: _searchController,
                    onChanged: _handleSearch,
                    decoration: InputDecoration(
                      hintText: 'Search for frozen food products...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                _handleSearch('');
                              },
                            )
                          : IconButton(
                              icon: const Icon(Icons.qr_code_scanner, color: AppColors.primaryBlue),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Barcode scanner coming soon')),
                                );
                              },
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.gray300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filters Row
                  Row(
                    children: [
                      // Category Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          decoration: InputDecoration(
                            labelText: 'Category',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: categoryOptions.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            final categoryId = value == 'All' ? null :
                                categories.firstWhere((c) => c.name == value,
                                orElse: () => Category(id: '', name: '', createdAt: DateTime.now())).id;
                            _handleCategoryChange(categoryId);
                          },
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Sort Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSortBy,
                          decoration: InputDecoration(
                            labelText: 'Sort by',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: ['Name', 'Price (Low to High)', 'Price (High to Low)', 'Popular'].map((sort) {
                            return DropdownMenuItem(
                              value: sort,
                              child: Text(sort),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedSortBy = value!;
                            });
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Pricing Tier Selector
                  Row(
                    children: [
                      Text(
                        'Pricing: ',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      ...PricingTier.values.map((tier) =>
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(tier.name.toUpperCase()),
                            selected: _selectedPricingTier == tier,
                            onSelected: (selected) {
                              setState(() {
                                _selectedPricingTier = tier;
                              });
                            },
                            selectedColor: AppColors.primaryBlue.withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: _selectedPricingTier == tier
                                  ? AppColors.primaryBlue
                                  : AppColors.textSecondary,
                              fontWeight: _selectedPricingTier == tier
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ).toList(),
                    ],
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
                      onPressed: () => ref.read(productProvider.notifier).clearError(),
                      child: Text('Dismiss', style: TextStyle(color: Colors.red.shade600)),
                    ),
                  ],
                ),
              ),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '${sortedProducts.length} products found',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (sortedProducts.isNotEmpty && !isLoading)
                    TextButton.icon(
                      onPressed: () => ref.read(productProvider.notifier).refreshProducts(),
                      icon: const Icon(Icons.refresh, size: 16),
                      label: const Text('Refresh'),
                    ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : sortedProducts.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 64,
                                color: AppColors.textTertiary,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No products found',
                                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                      color: AppColors.textSecondary,
                                    ),
                              ),
                              Text(
                                'Try adjusting your search or filters',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textTertiary,
                                    ),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => ref.read(productProvider.notifier).clearFilters(),
                                child: const Text('Clear Filters'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: sortedProducts.length,
                          itemBuilder: (context, index) {
                            final product = sortedProducts[index];
                            return _buildProductCard(product);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    final price = _getProductPrice(product);
    final totalStock = _getTotalStock(product);
    final isInStock = totalStock > 0;
    final isLowStock = totalStock > 0 && totalStock <= 10;

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
      child: Row(
        children: [
          // Product Image/Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: product.images.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.images.first,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          product.isFrozen ? Icons.ac_unit : Icons.fastfood,
                          color: AppColors.primaryBlue,
                          size: 30,
                        );
                      },
                    ),
                  )
                : Icon(
                    product.isFrozen ? Icons.ac_unit : Icons.fastfood,
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (isLowStock)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Low Stock',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.warning,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    if (product.category != null) ...[
                      Flexible(
                        child: Text(
                          product.category!.name,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    if (product.brand != null) ...[
                      Flexible(
                        child: Text(
                          '• ${product.brand!.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 4),

                Row(
                  children: [
                    Flexible(
                      child: Text(
                        '${product.unitOfMeasure}',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (product.sku != null) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          'SKU: ${product.sku}',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ],
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    if (price != null) ...[
                      Flexible(
                        flex: 2,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '₱${price.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryRed,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                '(${_selectedPricingTier.name})',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'Stock: $totalStock',
                        style: TextStyle(
                          fontSize: 12,
                          color: isInStock ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.end,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // Add to Cart Button
          Column(
            children: [
              Consumer(
                builder: (context, ref, _) {
                  final cartItemCount = ref.watch(cartItemCountProvider({
                    'productId': product.id,
                    'tier': _selectedPricingTier,
                  }));

                  if (cartItemCount > 0) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$cartItemCount in cart',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
              const SizedBox(height: 4),
              ElevatedButton(
                onPressed: !isInStock || price == null
                    ? null
                    : () async {
                        final cartNotifier = ref.read(cartProvider.notifier);
                        final success = await cartNotifier.addToCart(
                          product: product,
                          tier: _selectedPricingTier,
                          quantity: 1,
                        );

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        } else {
                          final error = ref.read(cartErrorProvider);
                          if (error != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error),
                                backgroundColor: AppColors.error,
                              ),
                            );
                            ref.read(cartProvider.notifier).clearError();
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isInStock
                      ? AppColors.primaryRed
                      : AppColors.gray300,
                  foregroundColor: AppColors.white,
                  minimumSize: const Size(80, 36),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  isInStock ? 'Add to Cart' : 'Out of Stock',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}