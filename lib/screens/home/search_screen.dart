import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/date_utils.dart' as app_date_utils;
import '../../models/database_types.dart';
import '../../providers/product_provider.dart';
import 'product_details_screen.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  String? _selectedBrandId; // Store brand ID instead of name
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

  void _handleBrandChange(String? brandId) {
    setState(() {
      _selectedBrandId = brandId;
    });
    ref.read(productProvider.notifier).setBrand(
      brandId == 'All' ? null : brandId,
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
    // Get all active tiers of the selected type
    final tiersOfType = product.priceTiers
        .where((t) => t.tierType == _selectedPricingTier && t.isActive)
        .toList();

    if (tiersOfType.isEmpty) {
      // Fallback to any active tier
      final anyTier = product.priceTiers.firstWhere(
        (t) => t.isActive,
        orElse: () => PriceTier(
          id: '',
          productId: product.id,
          tierType: PricingTier.retail,
          price: 0.0,
          createdAt: app_date_utils.DateUtils.nowInUtc(),
          updatedAt: app_date_utils.DateUtils.nowInUtc(),
        ),
      );
      return anyTier.price;
    }

    // If multiple tiers exist, return the lowest price (best deal for customer)
    // Sort by price ascending and return the first (lowest)
    tiersOfType.sort((a, b) => a.price.compareTo(b.price));
    return tiersOfType.first.price;
  }

  @override
  Widget build(BuildContext context) {
    final products = ref.watch(productsListProvider);
    final brands = ref.watch(brandsProvider);
    final isLoading = ref.watch(isLoadingProductsProvider);
    final error = ref.watch(productErrorProvider);

    // Get sorted products
    final sortedProducts = _getSortedProducts(products);

    // Build brand options with proper ID mapping
    final brandOptions = [
      {'id': 'All', 'name': 'All'},
      ...brands.map((b) => {'id': b.id, 'name': b.name})
    ];

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
                          : null,
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
                      // Brand Filter
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedBrandId ?? 'All',
                          decoration: InputDecoration(
                            labelText: 'Brand',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: brandOptions.map((option) {
                            return DropdownMenuItem(
                              value: option['id'],
                              child: Text(option['name']!),
                            );
                          }).toList(),
                          onChanged: (brandId) {
                            _handleBrandChange(brandId);
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
                            selectedColor: AppColors.primaryBlue.withValues(alpha: 0.2),
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
                      ),
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

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductDetailsScreen(product: product),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: AppColors.gray300.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Images Section
            _buildProductImages(product),

            // Product Content
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name and Low Stock Badge
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
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.warning.withValues(alpha: 0.1),
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

                  const SizedBox(height: 8),

                  // Description (if available)
                  if (product.description != null && product.description!.isNotEmpty) ...[
                    Text(
                      product.description!,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Category and Brand
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      if (product.category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryBlue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.category!.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (product.brand != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.success.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            product.brand!.name,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.success,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Unit of Measure and Product ID
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Unit: ${product.unitOfMeasure}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ),
                      if (product.productId != null)
                        Expanded(
                          child: Text(
                            'Product ID: ${product.productId}',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                            textAlign: TextAlign.end,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Price and Stock Information
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (price != null) ...[
                              Text(
                                '₱${price.toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryRed,
                                ),
                              ),
                              Text(
                                '(${_selectedPricingTier.name.toUpperCase()} Price)',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Stock: $totalStock',
                            style: TextStyle(
                              fontSize: 14,
                              color: isInStock ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (product.isFrozen)
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.ac_unit,
                                  size: 12,
                                  color: AppColors.primaryBlue,
                                ),
                                const SizedBox(width: 2),
                                Text(
                                  'Frozen',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Tap to view details hint
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.primaryBlue.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app,
                          size: 16,
                          color: AppColors.primaryBlue,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Tap to view details & add to cart',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductImages(Product product) {
    if (product.images.isEmpty) {
      // Fallback when no images
      return Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppColors.primaryBlue.withValues(alpha: 0.1),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              product.isFrozen ? Icons.ac_unit : Icons.fastfood,
              color: AppColors.primaryBlue,
              size: 64,
            ),
            const SizedBox(height: 8),
            Text(
              'No Image Available',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    if (product.images.length == 1) {
      // Single image
      return Container(
        height: 200,
        width: double.infinity,
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(12),
            topRight: Radius.circular(12),
          ),
          child: Image.network(
            product.images.first,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.primaryBlue.withValues(alpha: 0.1),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      product.isFrozen ? Icons.ac_unit : Icons.fastfood,
                      color: AppColors.primaryBlue,
                      size: 64,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Image Load Error',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }

    // Multiple images - Image carousel
    return SizedBox(
      height: 200,
      child: Stack(
        children: [
          PageView.builder(
            itemCount: product.images.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                child: Image.network(
                  product.images[index],
                  fit: BoxFit.cover,
                  width: double.infinity,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.primaryBlue.withValues(alpha: 0.1),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            product.isFrozen ? Icons.ac_unit : Icons.fastfood,
                            color: AppColors.primaryBlue,
                            size: 64,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Image ${index + 1} Load Error',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
          // Image count indicator
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${product.images.length} Photos',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          // Frozen indicator
          if (product.isFrozen)
            Positioned(
              top: 12,
              left: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.ac_unit,
                      color: Colors.white,
                      size: 12,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'FROZEN',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}