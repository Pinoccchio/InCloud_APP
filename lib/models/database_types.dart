// Database type definitions matching Supabase schema
// This file defines the data models for the InCloud mobile app

import '../core/utils/date_utils.dart' as app_date_utils;

// Enums
enum ProductStatus { available, unavailable, discontinued }

enum PricingTier { wholesale, retail, bulk }

enum OrderStatus { pending, confirmed, in_transit, delivered, cancelled, returned }

enum PaymentStatus { pending, paid, partial, refunded, cancelled }

enum AlertType { low_stock, expiring_soon, expired, out_of_stock, overstock, order_status, system }

enum AlertSeverity { low, medium, high, critical }

// Core Models
class Product {
  final String id;
  final String name;
  final String? description;
  final String? productId;
  final List<String> images;
  final String unitOfMeasure;
  final ProductStatus status;
  final String? categoryId;
  final String? brandId;
  final String? createdBy;
  final String? updatedBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final Category? category;
  final Brand? brand;
  final List<PriceTier> priceTiers;
  final List<Inventory> inventory;

  // Computed property: Products are frozen if their category name contains "frozen"
  bool get isFrozen => category?.name.toLowerCase().contains('frozen') ?? false;

  Product({
    required this.id,
    required this.name,
    this.description,
    this.productId,
    this.images = const [],
    this.unitOfMeasure = 'pieces',
    this.status = ProductStatus.available,
    this.categoryId,
    this.brandId,
    this.createdBy,
    this.updatedBy,
    required this.createdAt,
    required this.updatedAt,
    this.category,
    this.brand,
    this.priceTiers = const [],
    this.inventory = const [],
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    try {
      print('DEBUG: Parsing Product from JSON: ${json.keys.toList()}');

      return Product(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Unknown Product',
        description: json['description']?.toString(),
        productId: json['product_id']?.toString(),
        images: json['images'] != null
            ? (json['images'] as List).map((img) {
                // Handle both string format (legacy) and object format (new)
                if (img is String) return img;
                if (img is Map<String, dynamic>) return img['url']?.toString() ?? '';
                return '';
              }).where((url) => url.isNotEmpty).toList()
            : [],
        unitOfMeasure: json['unit_of_measure']?.toString() ?? 'pieces',
        status: ProductStatus.values.firstWhere(
          (e) => e.name == json['status']?.toString(),
          orElse: () => ProductStatus.available,
        ),
        categoryId: json['category_id']?.toString(),
        brandId: json['brand_id']?.toString(),
        createdBy: json['created_by']?.toString(),
        updatedBy: json['updated_by']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : app_date_utils.DateUtils.nowInUtc(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'].toString())
            : app_date_utils.DateUtils.nowInUtc(),
        category: json['categories'] != null
            ? Category.fromJson(json['categories'])
            : null,
        brand: json['brands'] != null
            ? Brand.fromJson(json['brands'])
            : null,
        priceTiers: json['price_tiers'] != null
            ? (json['price_tiers'] as List)
                .map((tier) => PriceTier.fromJson(tier))
                .toList()
            : [],
        inventory: json['inventory'] != null
            ? (json['inventory'] as List)
                .map((inv) => Inventory.fromJson(inv))
                .toList()
            : [],
      );
    } catch (e) {
      print('ERROR: Failed to parse Product from JSON: $e');
      print('JSON data: $json');
      rethrow;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'product_id': productId,
      'images': images,
      'unit_of_measure': unitOfMeasure,
      'status': status.name,
      'category_id': categoryId,
      'brand_id': brandId,
      'created_by': createdBy,
      'updated_by': updatedBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}

class Category {
  final String id;
  final String name;
  final String? description;
  final String? parentId;
  final bool isActive;
  final DateTime createdAt;
  final String? createdBy;
  final String? updatedBy;

  Category({
    required this.id,
    required this.name,
    this.description,
    this.parentId,
    this.isActive = true,
    required this.createdAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      parentId: json['parent_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'parent_id': parentId,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }
}

class Brand {
  final String id;
  final String name;
  final String? description;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final String? createdBy;
  final String? updatedBy;

  Brand({
    required this.id,
    required this.name,
    this.description,
    this.logoUrl,
    this.isActive = true,
    required this.createdAt,
    this.createdBy,
    this.updatedBy,
  });

  factory Brand.fromJson(Map<String, dynamic> json) {
    return Brand(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'logo_url': logoUrl,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }
}

class PriceTier {
  final String id;
  final String productId;
  final PricingTier tierType;
  final double price;
  final int minQuantity;
  final int? maxQuantity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  PriceTier({
    required this.id,
    required this.productId,
    required this.tierType,
    required this.price,
    this.minQuantity = 1,
    this.maxQuantity,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
  });

  factory PriceTier.fromJson(Map<String, dynamic> json) {
    return PriceTier(
      id: json['id'] as String,
      productId: json['product_id'] as String? ?? '', // Default for nested objects
      tierType: PricingTier.values.firstWhere(
        (e) => e.name == json['pricing_type'],
        orElse: () => PricingTier.retail,
      ),
      price: (json['price'] as num).toDouble(),
      minQuantity: json['min_quantity'] as int? ?? 1,
      maxQuantity: json['max_quantity'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'pricing_type': tierType.name,
      'price': price,
      'min_quantity': minQuantity,
      'max_quantity': maxQuantity,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'created_by': createdBy,
      'updated_by': updatedBy,
    };
  }
}

class Inventory {
  final String id;
  final String productId;
  final String branchId;
  final int quantity;
  final int reservedQuantity;
  final int availableQuantity;
  final int minStockLevel;
  final int? maxStockLevel;
  final String? location;
  final double? costPerUnit;
  final DateTime? lastRestockDate;
  final DateTime? lastCountedDate;
  final int lowStockThreshold;
  final bool autoReorder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? createdBy;
  final String? updatedBy;

  // Related data
  final List<ProductBatch> batches;

  Inventory({
    required this.id,
    required this.productId,
    required this.branchId,
    this.quantity = 0,
    this.reservedQuantity = 0,
    required this.availableQuantity,
    this.minStockLevel = 10,
    this.maxStockLevel,
    this.location,
    this.costPerUnit,
    this.lastRestockDate,
    this.lastCountedDate,
    this.lowStockThreshold = 10,
    this.autoReorder = false,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.batches = const [],
  });

  factory Inventory.fromJson(Map<String, dynamic> json) {
    return Inventory(
      id: json['id'] as String,
      productId: json['product_id'] as String? ?? '', // Default for nested objects
      branchId: json['branch_id'] as String,
      quantity: json['quantity'] as int? ?? 0,
      reservedQuantity: json['reserved_quantity'] as int? ?? 0,
      availableQuantity: json['available_quantity'] as int,
      minStockLevel: json['min_stock_level'] as int? ?? 10,
      maxStockLevel: json['max_stock_level'] as int?,
      location: json['location'] as String?,
      costPerUnit: json['cost_per_unit'] != null
          ? (json['cost_per_unit'] as num).toDouble()
          : null,
      lastRestockDate: json['last_restock_date'] != null
          ? DateTime.parse(json['last_restock_date'])
          : null,
      lastCountedDate: json['last_counted_date'] != null
          ? DateTime.parse(json['last_counted_date'])
          : null,
      lowStockThreshold: json['low_stock_threshold'] as int? ?? 10,
      autoReorder: json['auto_reorder'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      batches: json['product_batches'] != null
          ? (json['product_batches'] as List)
              .map((batch) => ProductBatch.fromJson(batch))
              .toList()
          : [],
    );
  }
}

class ProductBatch {
  final String id;
  final String inventoryId;
  final String batchNumber;
  final int quantity;
  final DateTime receivedDate;
  final DateTime expirationDate;
  final Map<String, dynamic> supplierInfo;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double? costPerUnit;
  final String? supplierName;
  final bool isActive;
  final String? createdBy;
  final String? updatedBy;

  ProductBatch({
    required this.id,
    required this.inventoryId,
    required this.batchNumber,
    required this.quantity,
    required this.receivedDate,
    required this.expirationDate,
    this.supplierInfo = const {},
    this.status = 'active',
    required this.createdAt,
    required this.updatedAt,
    this.costPerUnit,
    this.supplierName,
    this.isActive = true,
    this.createdBy,
    this.updatedBy,
  });

  factory ProductBatch.fromJson(Map<String, dynamic> json) {
    return ProductBatch(
      id: json['id'] as String,
      inventoryId: json['inventory_id'] as String? ?? '', // Default for nested objects
      batchNumber: json['batch_number'] as String,
      quantity: json['quantity'] as int,
      receivedDate: json['received_date'] != null
          ? DateTime.parse(json['received_date'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      expirationDate: DateTime.parse(json['expiration_date'] as String),
      supplierInfo: json['supplier_info'] as Map<String, dynamic>? ?? {},
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : app_date_utils.DateUtils.nowInUtc(), // Default fallback for nested objects
      costPerUnit: json['cost_per_unit'] != null
          ? (json['cost_per_unit'] as num).toDouble()
          : null,
      supplierName: json['supplier_name'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  // Helper method to check if batch is expiring soon (within 7 days)
  bool get isExpiringSoon {
    final now = app_date_utils.DateUtils.nowInUtc();
    final daysUntilExpiry = expirationDate.difference(now).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  // Helper method to check if batch is expired
  bool get isExpired {
    return expirationDate.isBefore(app_date_utils.DateUtils.nowInUtc());
  }
}

// Cart and Order models
class CartItem {
  final String id;
  final Product product;
  final PricingTier selectedTier;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.product,
    required this.selectedTier,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    required this.addedAt,
  });

  factory CartItem.fromProduct({
    required Product product,
    required PricingTier tier,
    required int quantity,
  }) {
    if (product.priceTiers.isEmpty) {
      throw Exception('Product ${product.name} has no price tiers available');
    }

    // Try to find the exact tier requested
    PriceTier? priceTier;
    try {
      priceTier = product.priceTiers.firstWhere(
        (p) => p.tierType == tier,
      );
    } catch (e) {
      // If exact tier not found, try to find a suitable fallback
      if (product.priceTiers.isNotEmpty) {
        // Prefer retail as fallback, then any available tier
        priceTier = product.priceTiers.firstWhere(
          (p) => p.tierType == PricingTier.retail,
          orElse: () => product.priceTiers.first,
        );
        print('⚠️ Pricing tier $tier not found for ${product.name}, using ${priceTier.tierType} instead');
      } else {
        throw Exception('No valid pricing tier found for product ${product.name}');
      }
    }

    final unitPrice = priceTier.price;
    final totalPrice = unitPrice * quantity;

    return CartItem(
      id: '${product.id}_${tier.name}_${app_date_utils.DateUtils.nowInUtc().millisecondsSinceEpoch}',
      product: product,
      selectedTier: priceTier.tierType, // Use the actual tier found
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      addedAt: app_date_utils.DateUtils.nowInUtc(),
    );
  }

  CartItem copyWith({
    String? id,
    Product? product,
    PricingTier? selectedTier,
    int? quantity,
    double? unitPrice,
    double? totalPrice,
    DateTime? addedAt,
  }) {
    final newQuantity = quantity ?? this.quantity;
    final newUnitPrice = unitPrice ?? this.unitPrice;

    return CartItem(
      id: id ?? this.id,
      product: product ?? this.product,
      selectedTier: selectedTier ?? this.selectedTier,
      quantity: newQuantity,
      unitPrice: newUnitPrice,
      totalPrice: totalPrice ?? (newUnitPrice * newQuantity),
      addedAt: addedAt ?? this.addedAt,
    );
  }
}

class Order {
  final String id;
  final String orderNumber;
  final String? customerId;
  final String branchId;
  final OrderStatus status;
  final PaymentStatus paymentStatus;
  final DateTime orderDate;
  final DateTime? deliveryDate;
  final Map<String, dynamic>? deliveryAddress;
  final double subtotal;
  final double discountAmount;
  final double totalAmount;
  final String? notes;
  final String? createdBy;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? proofOfPaymentUrl;
  final String? proofOfPaymentStatus;
  final String? proofRejectionReason;

  // Related data
  final List<OrderItem> items;
  final List<OrderStatusHistory> statusHistory;

  Order({
    required this.id,
    required this.orderNumber,
    this.customerId,
    required this.branchId,
    this.status = OrderStatus.pending,
    this.paymentStatus = PaymentStatus.pending,
    required this.orderDate,
    this.deliveryDate,
    this.deliveryAddress,
    this.subtotal = 0,
    this.discountAmount = 0,
    this.totalAmount = 0,
    this.notes,
    this.createdBy,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.proofOfPaymentUrl,
    this.proofOfPaymentStatus,
    this.proofRejectionReason,
    this.items = const [],
    this.statusHistory = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    try {
      // Helper function for safe DateTime parsing
      DateTime parseDateTime(dynamic value, DateTime fallback) {
        if (value == null) return fallback;
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          print('Warning: Failed to parse DateTime: $value, using fallback');
          return fallback;
        }
      }

      // Helper function for safe number parsing
      double parseDouble(dynamic value, double fallback) {
        if (value == null) return fallback;
        try {
          return (value as num).toDouble();
        } catch (e) {
          print('Warning: Failed to parse double: $value, using fallback: $fallback');
          return fallback;
        }
      }

      final now = DateTime.now();

      return Order(
        id: json['id']?.toString() ?? '',
        orderNumber: json['order_number']?.toString() ?? 'UNKNOWN-ORDER',
        customerId: json['customer_id']?.toString(),
        branchId: json['branch_id']?.toString() ?? '',
        status: OrderStatus.values.firstWhere(
          (e) => e.name == json['status']?.toString(),
          orElse: () => OrderStatus.pending,
        ),
        paymentStatus: PaymentStatus.values.firstWhere(
          (e) => e.name == json['payment_status']?.toString(),
          orElse: () => PaymentStatus.pending,
        ),
        orderDate: parseDateTime(json['order_date'], now),
        deliveryDate: json['delivery_date'] != null
            ? parseDateTime(json['delivery_date'], now)
            : null,
        deliveryAddress: json['delivery_address'] is Map<String, dynamic>
            ? json['delivery_address'] as Map<String, dynamic>
            : null,
        subtotal: parseDouble(json['subtotal'], 0.0),
        discountAmount: parseDouble(json['discount_amount'], 0.0),
        totalAmount: parseDouble(json['total_amount'], 0.0),
        notes: json['notes']?.toString(),
        createdBy: json['created_by_user_id']?.toString(),
        assignedTo: json['assigned_to']?.toString(),
        createdAt: parseDateTime(json['created_at'], now),
        updatedAt: parseDateTime(json['updated_at'], now),
        proofOfPaymentUrl: json['proof_of_payment_url']?.toString(),
        proofOfPaymentStatus: json['proof_of_payment_status']?.toString(),
        proofRejectionReason: json['proof_rejection_reason']?.toString(),
        items: _parseOrderItems(json['order_items']),
        statusHistory: _parseOrderStatusHistory(json['order_status_history']),
      );
    } catch (e) {
      print('Error parsing Order from JSON: $e');
      print('JSON data: $json');
      // Return a minimal valid order to prevent crashes
      final now = DateTime.now();
      return Order(
        id: json['id']?.toString() ?? 'unknown',
        orderNumber: json['order_number']?.toString() ?? 'ERROR-ORDER',
        branchId: json['branch_id']?.toString() ?? 'unknown',
        orderDate: now,
        createdAt: now,
        updatedAt: now,
        items: [],
        statusHistory: [],
      );
    }
  }

  // Helper method for parsing order items safely
  static List<OrderItem> _parseOrderItems(dynamic itemsData) {
    if (itemsData == null) return [];

    try {
      if (itemsData is List) {
        return itemsData
            .map((item) {
              try {
                return OrderItem.fromJson(item);
              } catch (e) {
                print('Warning: Failed to parse order item: $e');
                return null;
              }
            })
            .where((item) => item != null)
            .cast<OrderItem>()
            .toList();
      }
    } catch (e) {
      print('Error parsing order items: $e');
    }

    return [];
  }

  // Helper method for parsing order status history safely
  static List<OrderStatusHistory> _parseOrderStatusHistory(dynamic historyData) {
    if (historyData == null) return [];

    try {
      if (historyData is List) {
        return historyData
            .map((history) {
              try {
                return OrderStatusHistory.fromJson(history);
              } catch (e) {
                print('Warning: Failed to parse order status history: $e');
                return null;
              }
            })
            .where((history) => history != null)
            .cast<OrderStatusHistory>()
            .toList();
      }
    } catch (e) {
      print('Error parsing order status history: $e');
    }

    return [];
  }
}

class OrderItem {
  final String id;
  final String orderId;
  final String productId;
  final PricingTier pricingTier;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String fulfillmentStatus;
  final DateTime createdAt;

  // Related data
  final Product? product;

  OrderItem({
    required this.id,
    required this.orderId,
    required this.productId,
    required this.pricingTier,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.fulfillmentStatus = 'pending',
    required this.createdAt,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    try {
      print('DEBUG: Parsing OrderItem from JSON: ${json.keys.toList()}');
      // Helper function for safe number parsing
      double parseDouble(dynamic value, double fallback) {
        if (value == null) return fallback;
        try {
          return (value as num).toDouble();
        } catch (e) {
          print('Warning: Failed to parse double in OrderItem: $value, using fallback: $fallback');
          return fallback;
        }
      }

      // Helper function for safe int parsing
      int parseInt(dynamic value, int fallback) {
        if (value == null) return fallback;
        try {
          return (value as num).toInt();
        } catch (e) {
          print('Warning: Failed to parse int in OrderItem: $value, using fallback: $fallback');
          return fallback;
        }
      }

      // Helper function for safe DateTime parsing
      DateTime parseDateTime(dynamic value, DateTime fallback) {
        if (value == null) return fallback;
        try {
          return DateTime.parse(value.toString());
        } catch (e) {
          print('Warning: Failed to parse DateTime in OrderItem: $value, using fallback');
          return fallback;
        }
      }

      // Safe product parsing
      Product? parseProduct(dynamic productData) {
        if (productData == null) {
          print('DEBUG: Product data is null in OrderItem');
          return null;
        }
        try {
          print('DEBUG: Parsing product data in OrderItem: $productData');
          final product = Product.fromJson(productData);
          print('DEBUG: Successfully parsed product: ${product.name}');
          return product;
        } catch (e) {
          print('WARNING: Failed to parse Product in OrderItem: $e');
          print('DEBUG: Product data that failed: $productData');
          return null;
        }
      }

      final parsedProduct = parseProduct(json['products']);
      print('DEBUG: Final parsed product for OrderItem: ${parsedProduct?.name ?? 'NULL'}');

      return OrderItem(
        id: json['id']?.toString() ?? '',
        orderId: json['order_id']?.toString() ?? '',
        productId: json['product_id']?.toString() ?? '',
        pricingTier: PricingTier.values.firstWhere(
          (e) => e.name == json['pricing_type']?.toString(),
          orElse: () => PricingTier.retail,
        ),
        quantity: parseInt(json['quantity'], 1),
        unitPrice: parseDouble(json['unit_price'], 0.0),
        totalPrice: parseDouble(json['total_price'], 0.0),
        fulfillmentStatus: json['fulfillment_status']?.toString() ?? 'pending',
        createdAt: parseDateTime(json['created_at'], DateTime.now()),
        product: parsedProduct,
      );
    } catch (e) {
      print('Error parsing OrderItem from JSON: $e');
      print('JSON data: $json');
      // Return a minimal valid order item to prevent crashes
      return OrderItem(
        id: json['id']?.toString() ?? 'unknown',
        orderId: json['order_id']?.toString() ?? 'unknown',
        productId: json['product_id']?.toString() ?? 'unknown',
        pricingTier: PricingTier.retail,
        quantity: 1,
        unitPrice: 0.0,
        totalPrice: 0.0,
        fulfillmentStatus: 'pending',
        createdAt: DateTime.now(),
        product: null,
      );
    }
  }
}

class Customer {
  final String id;
  final String email;
  final String fullName;
  final String? phone;
  final Map<String, dynamic> address;
  final String customerType;
  final String? preferredBranchId;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? userId;

  Customer({
    required this.id,
    required this.email,
    required this.fullName,
    this.phone,
    this.address = const {},
    this.customerType = 'regular',
    this.preferredBranchId,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
    this.userId,
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] as String,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      phone: json['phone'] as String?,
      address: json['address'] as Map<String, dynamic>? ?? {},
      customerType: json['customer_type'] as String? ?? 'regular',
      preferredBranchId: json['preferred_branch_id'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      userId: json['user_id'] as String?,
    );
  }
}

class OrderStatusHistory {
  final String id;
  final String orderId;
  final OrderStatus? oldStatus;
  final OrderStatus newStatus;
  final String? changedByUserId;
  final String? notes;
  final DateTime createdAt;
  final String? changedByName;

  OrderStatusHistory({
    required this.id,
    required this.orderId,
    this.oldStatus,
    required this.newStatus,
    this.changedByUserId,
    this.notes,
    required this.createdAt,
    this.changedByName,
  });

  factory OrderStatusHistory.fromJson(Map<String, dynamic> json) {
    try {
      return OrderStatusHistory(
        id: json['id']?.toString() ?? '',
        orderId: json['order_id']?.toString() ?? '',
        oldStatus: json['old_status'] != null
            ? OrderStatus.values.firstWhere(
                (e) => e.name == json['old_status']?.toString(),
                orElse: () => OrderStatus.pending,
              )
            : null,
        newStatus: OrderStatus.values.firstWhere(
          (e) => e.name == json['new_status']?.toString(),
          orElse: () => OrderStatus.pending,
        ),
        changedByUserId: json['changed_by_user_id']?.toString(),
        notes: json['notes']?.toString(),
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'].toString())
            : DateTime.now(),
        changedByName: json['changed_by_name']?.toString(),
      );
    } catch (e) {
      print('Error parsing OrderStatusHistory from JSON: $e');
      print('JSON data: $json');
      // Return a minimal valid status history to prevent crashes
      return OrderStatusHistory(
        id: json['id']?.toString() ?? 'unknown',
        orderId: json['order_id']?.toString() ?? 'unknown',
        newStatus: OrderStatus.pending,
        createdAt: DateTime.now(),
      );
    }
  }
}