import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../models/database_types.dart';
import '../../providers/product_provider.dart';

// Dashboard metrics model
class DashboardMetrics {
  final int totalProducts;
  final int totalCategories;
  final int totalBrands;
  final int totalStock;
  final int lowStockItems;
  final int totalOrders;
  final int activeOrders;
  final int deliveredOrders;

  DashboardMetrics({
    required this.totalProducts,
    required this.totalCategories,
    required this.totalBrands,
    required this.totalStock,
    required this.lowStockItems,
    required this.totalOrders,
    required this.activeOrders,
    required this.deliveredOrders,
  });
}

// Dashboard provider
final dashboardMetricsProvider = FutureProvider<DashboardMetrics>((ref) async {
  final supabase = Supabase.instance.client;

  try {
    // Fetch all metrics in parallel
    final results = await Future.wait<dynamic>([
      // Products count
      supabase
          .from('products')
          .select('id')
          .eq('status', 'available')
          .count(CountOption.exact),
      // Categories count
      supabase
          .from('categories')
          .select('id')
          .eq('is_active', true)
          .count(CountOption.exact),
      // Brands count
      supabase
          .from('brands')
          .select('id')
          .eq('is_active', true)
          .count(CountOption.exact),
      // Total stock and low stock items - **P0 CRITICAL FIX**: Include only non-expired batches
      supabase.from('inventory').select('''
        id,
        low_stock_threshold,
        batches:product_batches(quantity, is_active, status, expiration_date)
      '''),
      // Orders count and status
      supabase.from('orders').select('id, status'),
    ]);

    // Parse products count
    final productsCount = (results[0] as PostgrestResponse).count;

    // Parse categories count
    final categoriesCount = (results[1] as PostgrestResponse).count;

    // Parse brands count
    final brandsCount = (results[2] as PostgrestResponse).count;

    // Calculate stock metrics - **P0 CRITICAL FIX**: Filter expired batches
    final inventoryData = results[3] as List<dynamic>;
    int totalStock = 0;
    int lowStockItems = 0;
    final now = DateTime.now().toUtc();

    for (var inv in inventoryData) {
      final threshold = inv['low_stock_threshold'] as int? ?? 10;
      final batches = inv['batches'] as List<dynamic>? ?? [];

      // Calculate non-expired stock for this inventory record
      int nonExpiredStock = 0;
      for (var batch in batches) {
        final isActive = batch['is_active'] as bool? ?? false;
        final status = batch['status'] as String? ?? '';
        final expirationStr = batch['expiration_date'] as String?;

        if (isActive && status == 'active' && expirationStr != null) {
          final expiration = DateTime.parse(expirationStr);
          if (expiration.isAfter(now)) {
            nonExpiredStock += batch['quantity'] as int? ?? 0;
          }
        }
      }

      totalStock += nonExpiredStock;
      if (nonExpiredStock <= threshold && nonExpiredStock > 0) {
        lowStockItems++;
      }
    }

    // Calculate order metrics
    final ordersData = results[4] as List<dynamic>;
    int totalOrders = ordersData.length;
    int activeOrders = 0;
    int deliveredOrders = 0;
    for (var order in ordersData) {
      final status = order['status']?.toString() ?? '';
      if (status == 'pending' || status == 'confirmed' || status == 'in_transit') {
        activeOrders++;
      } else if (status == 'delivered') {
        deliveredOrders++;
      }
    }

    return DashboardMetrics(
      totalProducts: productsCount,
      totalCategories: categoriesCount,
      totalBrands: brandsCount,
      totalStock: totalStock,
      lowStockItems: lowStockItems,
      totalOrders: totalOrders,
      activeOrders: activeOrders,
      deliveredOrders: deliveredOrders,
    );
  } catch (e) {
    print('❌ ERROR LOADING DASHBOARD METRICS: $e');
    rethrow;
  }
});

class DashboardScreen extends ConsumerStatefulWidget {
  final void Function(int)? onNavigateToTab;

  const DashboardScreen({super.key, this.onNavigateToTab});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize product data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    final metricsAsync = ref.watch(dashboardMetricsProvider);
    final products = ref.watch(productsListProvider);

    return Scaffold(
      backgroundColor: AppColors.surfacePrimary,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardMetricsProvider);
            await ref.read(productProvider.notifier).refreshProducts();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Welcome Header
                  _buildWelcomeHeader(context),
                  const SizedBox(height: 24),

                  // Metrics Section
                  metricsAsync.when(
                    data: (metrics) => _buildMetricsCards(context, metrics),
                    loading: () => _buildMetricsLoading(),
                    error: (error, stack) => _buildErrorCard(error.toString()),
                  ),

                  const SizedBox(height: 24),

                  // Quick Stats
                  _buildQuickStats(context, metricsAsync),

                  const SizedBox(height: 24),

                  // Featured Products Section
                  _buildFeaturedProducts(context, products),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryRed, AppColors.primaryRed.withValues(alpha: 0.85)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primaryRed.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.dashboard_rounded,
              size: 32,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Dashboard',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  AppConstants.companyName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(BuildContext context, DashboardMetrics metrics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: [
            _buildMetricCard(
              context,
              'Products',
              metrics.totalProducts.toString(),
              Icons.inventory_2_outlined,
              AppColors.primaryRed,
            ),
            _buildMetricCard(
              context,
              'Total Stock',
              '${metrics.totalStock}',
              Icons.warehouse_outlined,
              AppColors.success,
            ),
            _buildMetricCard(
              context,
              'Active Orders',
              metrics.activeOrders.toString(),
              Icons.shopping_cart_outlined,
              AppColors.warning,
            ),
            _buildMetricCard(
              context,
              'Low Stock',
              metrics.lowStockItems.toString(),
              Icons.warning_amber_rounded,
              AppColors.error,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: 18,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsLoading() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        const Center(
          child: CircularProgressIndicator(),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String error) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Failed to load metrics',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats(BuildContext context, AsyncValue<DashboardMetrics> metricsAsync) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Stats',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
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
          child: metricsAsync.when(
            data: (metrics) => Column(
              children: [
                _buildStatRow('Categories', metrics.totalCategories.toString(), Icons.category),
                const Divider(height: 24),
                _buildStatRow('Brands', metrics.totalBrands.toString(), Icons.business),
                const Divider(height: 24),
                _buildStatRow('Total Orders', metrics.totalOrders.toString(), Icons.receipt_long),
                const Divider(height: 24),
                _buildStatRow('Delivered', metrics.deliveredOrders.toString(), Icons.check_circle_outline),
              ],
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, stack) => const SizedBox(),
          ),
        ),
      ],
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryRed.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20, color: AppColors.primaryRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedProducts(BuildContext context, List<Product> products) {
    final featured = products.take(3).toList();

    if (featured.isEmpty) {
      return const SizedBox();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Featured Products',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
            ),
            TextButton(
              onPressed: () {
                // Navigate to search screen (index 1 in bottom nav)
                widget.onNavigateToTab?.call(1);
              },
              child: Text('View All', style: TextStyle(color: AppColors.primaryRed)),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...featured.map((product) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _buildProductCard(product),
            )),
      ],
    );
  }

  Widget _buildProductCard(Product product) {
    // **P0 CRITICAL FIX**: Use non-expired stock only
    final totalStock = product.inventory.fold(0, (sum, inv) => sum + inv.getAvailableNonExpiredQuantity());
    final isInStock = totalStock > 0;

    return Container(
      padding: const EdgeInsets.all(12),
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
      child: Row(
        children: [
          // Product Image
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.gray100,
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
                          color: AppColors.textSecondary,
                          size: 30,
                        );
                      },
                    ),
                  )
                : Icon(
                    product.isFrozen ? Icons.ac_unit : Icons.fastfood,
                    color: AppColors.textSecondary,
                    size: 30,
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product.category?.name ?? 'No category',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isInStock ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Stock: $totalStock',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isInStock ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              if (product.isFrozen)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.ac_unit,
                        size: 12,
                        color: AppColors.info,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Frozen',
                        style: TextStyle(
                          fontSize: 10,
                          color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}