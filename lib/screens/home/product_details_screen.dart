import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/database_types.dart';
import '../../providers/cart_provider.dart';
import '../../widgets/image_gallery_widget.dart';

class ProductDetailsScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailsScreen({
    super.key,
    required this.product,
  });

  @override
  ConsumerState<ProductDetailsScreen> createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends ConsumerState<ProductDetailsScreen> {
  PricingTier _selectedPricingTier = PricingTier.retail;
  int _selectedQuantity = 1;

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final totalStock = _getTotalStock(product);
    final isInStock = totalStock > 0;
    final isLowStock = totalStock > 0 && totalStock <= 10;
    final selectedPrice = _getProductPrice(product, _selectedPricingTier);

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: CustomScrollView(
        slivers: [
          // App Bar with Image Gallery
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: AppColors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: ImageGalleryWidget(
                images: product.images,
                fallbackIcon: product.isFrozen ? Icons.ac_unit : Icons.fastfood,
                isFrozen: product.isFrozen,
                showFrozenBadge: false,
              ),
            ),
          ),

          // Product Content
          SliverToBoxAdapter(
            child: Container(
              color: AppColors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Header
                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Product Name and Stock Status
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (isLowStock)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Low Stock',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.warning,
                                  ),
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Description
                        if (product.description != null && product.description!.isNotEmpty) ...[
                          Text(
                            product.description!,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.textSecondary,
                              height: 1.5,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],

                        // Category and Brand Tags
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (product.category != null)
                              _buildInfoChip(
                                'Category: ${product.category!.name}',
                                AppColors.primaryBlue,
                                Icons.category,
                              ),
                            if (product.brand != null)
                              _buildInfoChip(
                                'Brand: ${product.brand!.name}',
                                AppColors.success,
                                Icons.store,
                              ),
                            if (product.isFrozen)
                              _buildInfoChip(
                                'Frozen Product',
                                AppColors.primaryBlue,
                                Icons.ac_unit,
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Product Information Table
                        _buildProductInfoTable(product),

                        const SizedBox(height: 24),

                        // Pricing Tiers
                        _buildPricingSection(product),

                        const SizedBox(height: 24),

                        // Stock Information
                        _buildStockSection(product, totalStock, isInStock),

                        const SizedBox(height: 24),

                        // Quantity Selector and Add to Cart
                        _buildAddToCartSection(product, selectedPrice, isInStock, totalStock),
                      ],
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

  Widget _buildInfoChip(String text, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductInfoTable(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Product Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Unit of Measure', product.unitOfMeasure),
          if (product.productId != null) _buildInfoRow('Product ID', product.productId!),
          _buildInfoRow('Status', product.status.name.toUpperCase()),
          _buildInfoRow('Product Type', product.isFrozen ? 'Frozen' : 'Fresh'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const Text(': ', style: TextStyle(color: AppColors.textSecondary)),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPricingSection(Product product) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pricing Tiers',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          ...product.priceTiers.where((tier) => tier.isActive).map((tier) {
            final isSelected = tier.tierType == _selectedPricingTier;
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryRed.withValues(alpha: 0.1) : AppColors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected ? AppColors.primaryRed : AppColors.gray300.withValues(alpha: 0.5),
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: InkWell(
                onTap: () {
                  setState(() {
                    _selectedPricingTier = tier.tierType;
                  });
                },
                child: Row(
                  children: [
                    Radio<PricingTier>(
                      value: tier.tierType,
                      groupValue: _selectedPricingTier,
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedPricingTier = value;
                          });
                        }
                      },
                      activeColor: AppColors.primaryRed,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tier.tierType.name.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? AppColors.primaryRed : AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Min: ${tier.minQuantity}${tier.maxQuantity != null ? ' - Max: ${tier.maxQuantity}' : '+'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '₱${tier.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.primaryRed : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStockSection(Product product, int totalStock, bool isInStock) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfacePrimary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Stock Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isInStock ? AppColors.success : AppColors.error,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isInStock ? 'IN STOCK' : 'OUT OF STOCK',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Total Available: $totalStock units',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isInStock ? AppColors.success : AppColors.error,
            ),
          ),
          const SizedBox(height: 8),
          // Branch-wise stock (if multiple branches)
          if (product.inventory.length > 1) ...[
            const Text(
              'Stock by Branch:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            ...product.inventory.map((inv) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: inv.availableQuantity > 0 ? AppColors.success : AppColors.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Branch ${inv.branchId.substring(0, 8)}...',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  Text(
                    '${inv.availableQuantity} units',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            )),
          ],
        ],
      ),
    );
  }

  Widget _buildAddToCartSection(Product product, double? selectedPrice, bool isInStock, int totalStock) {
    return Container(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 16 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gray300.withValues(alpha: 0.3)),
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
          Row(
            children: [
              const Text(
                'Add to Cart',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const Spacer(),
              if (selectedPrice != null)
                Text(
                  '₱${(selectedPrice * _selectedQuantity).toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryRed,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Quantity Selector
          Row(
            children: [
              const Text(
                'Quantity:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(width: 16),
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: _selectedQuantity > 1
                          ? () => setState(() => _selectedQuantity--)
                          : null,
                      icon: const Icon(Icons.remove),
                      color: AppColors.textPrimary,
                    ),
                    Container(
                      width: 60,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Text(
                        _selectedQuantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _selectedQuantity < totalStock
                          ? () => setState(() => _selectedQuantity++)
                          : null,
                      icon: const Icon(Icons.add),
                      color: AppColors.textPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Cart Status
          Consumer(
            builder: (context, ref, _) {
              final cartItemCount = ref.watch(cartItemCountProvider({
                'productId': product.id,
                'tier': _selectedPricingTier,
              }));

              return Column(
                children: [
                  if (cartItemCount > 0)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.primaryRed.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$cartItemCount item${cartItemCount > 1 ? 's' : ''} already in cart (${_selectedPricingTier.name})',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.primaryRed,
                          fontWeight: FontWeight.w600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  if (cartItemCount > 0) const SizedBox(height: 12),

                  // Add to Cart Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: !isInStock || selectedPrice == null
                          ? null
                          : () async {
                              // Capture ScaffoldMessenger before async operations
                              final scaffoldMessenger = ScaffoldMessenger.of(context);

                              final cartNotifier = ref.read(cartProvider.notifier);
                              final success = await cartNotifier.addToCart(
                                product: product,
                                tier: _selectedPricingTier,
                                quantity: _selectedQuantity,
                              );

                              if (!mounted) return;

                              if (success) {
                                scaffoldMessenger.showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} (${_selectedQuantity}x) added to cart'),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              } else {
                                final error = ref.read(cartErrorProvider);
                                if (error != null) {
                                  scaffoldMessenger.showSnackBar(
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
                        backgroundColor: isInStock ? AppColors.primaryRed : AppColors.gray300,
                        foregroundColor: AppColors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        isInStock ? 'Add to Cart' : 'Out of Stock',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  int _getTotalStock(Product product) {
    return product.inventory.fold(0, (sum, inv) => sum + inv.availableQuantity);
  }

  double? _getProductPrice(Product product, PricingTier tier) {
    try {
      final priceTier = product.priceTiers.firstWhere(
        (p) => p.tierType == tier && p.isActive,
        orElse: () => product.priceTiers.firstWhere(
          (p) => p.isActive,
          orElse: () => throw Exception('No active price tiers found'),
        ),
      );
      return priceTier.price;
    } catch (e) {
      return null;
    }
  }
}