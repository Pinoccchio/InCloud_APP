import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedSortBy = 'Name';

  final List<String> _categories = ['All', 'Chicken', 'Seafood', 'Pork', 'Beef', 'Fish'];
  final List<String> _sortOptions = ['Name', 'Price (Low to High)', 'Price (High to Low)', 'Popular'];

  // Sample products (UI only - no backend)
  final List<Map<String, dynamic>> _sampleProducts = [
    {
      'name': 'Chicken Wings 1kg',
      'price': '₱320',
      'category': 'Chicken',
      'image': Icons.egg_outlined,
      'rating': 4.5,
      'popular': true,
    },
    {
      'name': 'Bangus Whole 500g',
      'price': '₱180',
      'category': 'Fish',
      'image': Icons.set_meal,
      'rating': 4.2,
      'popular': true,
    },
    {
      'name': 'Pork Belly 1kg',
      'price': '₱450',
      'category': 'Pork',
      'image': Icons.lunch_dining,
      'rating': 4.7,
      'popular': false,
    },
    {
      'name': 'Beef Steak 500g',
      'price': '₱380',
      'category': 'Beef',
      'image': Icons.restaurant,
      'rating': 4.3,
      'popular': true,
    },
    {
      'name': 'Tilapia Fresh 1kg',
      'price': '₱220',
      'category': 'Fish',
      'image': Icons.set_meal,
      'rating': 4.0,
      'popular': false,
    },
    {
      'name': 'Shrimp Medium 500g',
      'price': '₱280',
      'category': 'Seafood',
      'image': Icons.set_meal_outlined,
      'rating': 4.6,
      'popular': true,
    },
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _getFilteredProducts() {
    List<Map<String, dynamic>> filtered = _sampleProducts;

    // Filter by category
    if (_selectedCategory != 'All') {
      filtered = filtered.where((product) => product['category'] == _selectedCategory).toList();
    }

    // Filter by search text
    if (_searchController.text.isNotEmpty) {
      filtered = filtered.where((product) =>
        product['name'].toLowerCase().contains(_searchController.text.toLowerCase())
      ).toList();
    }

    // Sort
    switch (_selectedSortBy) {
      case 'Price (Low to High)':
        filtered.sort((a, b) => int.parse(a['price'].substring(1)).compareTo(int.parse(b['price'].substring(1))));
        break;
      case 'Price (High to Low)':
        filtered.sort((a, b) => int.parse(b['price'].substring(1)).compareTo(int.parse(a['price'].substring(1))));
        break;
      case 'Popular':
        filtered.sort((a, b) => (b['popular'] ? 1 : 0).compareTo(a['popular'] ? 1 : 0));
        break;
      case 'Name':
      default:
        filtered.sort((a, b) => a['name'].compareTo(b['name']));
        break;
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    final filteredProducts = _getFilteredProducts();

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
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search for frozen food products...',
                      prefixIcon: const Icon(Icons.search, color: AppColors.primaryBlue),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, color: AppColors.textSecondary),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
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
                          items: _categories.map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                            });
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
                          items: _sortOptions.map((sort) {
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
                ],
              ),
            ),

            // Results Count
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                children: [
                  Text(
                    '${filteredProducts.length} products found',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  if (filteredProducts.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('View options coming soon')),
                        );
                      },
                      icon: const Icon(Icons.view_list, size: 16),
                      label: const Text('Grid'),
                    ),
                ],
              ),
            ),

            // Products List
            Expanded(
              child: filteredProducts.isEmpty
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
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredProducts.length,
                      itemBuilder: (context, index) {
                        final product = filteredProducts[index];
                        return _buildProductCard(product);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: Row(
        children: [
          // Product Icon
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              product['image'],
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
                        product['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (product['popular'])
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'Popular',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: AppColors.success,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 4),

                Text(
                  product['category'],
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 8),

                Row(
                  children: [
                    Text(
                      product['price'],
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryRed,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.star, color: AppColors.warning, size: 16),
                    Text(
                      product['rating'].toString(),
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

          // Add to Cart Button
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product['name']} added to cart')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryRed,
              foregroundColor: AppColors.white,
              minimumSize: const Size(80, 36),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'Add to Cart',
              style: TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}