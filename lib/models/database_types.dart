// Database type definitions matching Supabase schema
// This file defines the data models for the InCloud mobile app

// Enums
enum ProductStatus { active, inactive, discontinued }

enum PricingTier { wholesale, retail, box }

enum OrderStatus { pending, confirmed, in_transit, delivered, cancelled, returned }

enum PaymentStatus { pending, paid, partial, refunded, cancelled }

enum AlertType { low_stock, expiring_soon, expired, out_of_stock, overstock, order_status, system }

enum AlertSeverity { low, medium, high, critical }

// Core Models
class Product {
  final String id;
  final String name;
  final String? description;
  final String? barcode;
  final String? sku;
  final List<String> images;
  final String unitOfMeasure;
  final bool isFrozen;
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

  Product({
    required this.id,
    required this.name,
    this.description,
    this.barcode,
    this.sku,
    this.images = const [],
    this.unitOfMeasure = 'pieces',
    this.isFrozen = true,
    this.status = ProductStatus.active,
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
    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      barcode: json['barcode'] as String?,
      sku: json['sku'] as String?,
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      unitOfMeasure: json['unit_of_measure'] as String? ?? 'pieces',
      isFrozen: json['is_frozen'] as bool? ?? true,
      status: ProductStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => ProductStatus.active,
      ),
      categoryId: json['category_id'] as String?,
      brandId: json['brand_id'] as String?,
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
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
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'sku': sku,
      'images': images,
      'unit_of_measure': unitOfMeasure,
      'is_frozen': isFrozen,
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
          : DateTime.now(), // Default fallback for nested objects
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
          : DateTime.now(), // Default fallback for nested objects
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
        (e) => e.name == json['tier_type'],
        orElse: () => PricingTier.retail,
      ),
      price: (json['price'] as num).toDouble(),
      minQuantity: json['min_quantity'] as int? ?? 1,
      maxQuantity: json['max_quantity'] as int?,
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(), // Default fallback for nested objects
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(), // Default fallback for nested objects
      createdBy: json['created_by'] as String?,
      updatedBy: json['updated_by'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'tier_type': tierType.name,
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
          : DateTime.now(), // Default fallback for nested objects
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(), // Default fallback for nested objects
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
          : DateTime.now(), // Default fallback for nested objects
      expirationDate: DateTime.parse(json['expiration_date'] as String),
      supplierInfo: json['supplier_info'] as Map<String, dynamic>? ?? {},
      status: json['status'] as String? ?? 'active',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(), // Default fallback for nested objects
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(), // Default fallback for nested objects
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
    final now = DateTime.now();
    final daysUntilExpiry = expirationDate.difference(now).inDays;
    return daysUntilExpiry <= 7 && daysUntilExpiry > 0;
  }

  // Helper method to check if batch is expired
  bool get isExpired {
    return expirationDate.isBefore(DateTime.now());
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
    final priceTier = product.priceTiers.firstWhere(
      (p) => p.tierType == tier,
      orElse: () => product.priceTiers.first,
    );

    final unitPrice = priceTier.price;
    final totalPrice = unitPrice * quantity;

    return CartItem(
      id: '${product.id}_${tier.name}_${DateTime.now().millisecondsSinceEpoch}',
      product: product,
      selectedTier: tier,
      quantity: quantity,
      unitPrice: unitPrice,
      totalPrice: totalPrice,
      addedAt: DateTime.now(),
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
  final double taxAmount;
  final double totalAmount;
  final String? notes;
  final String? createdBy;
  final String? assignedTo;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Related data
  final List<OrderItem> items;

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
    this.taxAmount = 0,
    this.totalAmount = 0,
    this.notes,
    this.createdBy,
    this.assignedTo,
    required this.createdAt,
    required this.updatedAt,
    this.items = const [],
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      orderNumber: json['order_number'] as String,
      customerId: json['customer_id'] as String?,
      branchId: json['branch_id'] as String,
      status: OrderStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => OrderStatus.pending,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.name == json['payment_status'],
        orElse: () => PaymentStatus.pending,
      ),
      orderDate: DateTime.parse(json['order_date'] as String),
      deliveryDate: json['delivery_date'] != null
          ? DateTime.parse(json['delivery_date'])
          : null,
      deliveryAddress: json['delivery_address'] as Map<String, dynamic>?,
      subtotal: (json['subtotal'] as num).toDouble(),
      discountAmount: (json['discount_amount'] as num? ?? 0).toDouble(),
      taxAmount: (json['tax_amount'] as num? ?? 0).toDouble(),
      totalAmount: (json['total_amount'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdBy: json['created_by'] as String?,
      assignedTo: json['assigned_to'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      items: json['order_items'] != null
          ? (json['order_items'] as List)
              .map((item) => OrderItem.fromJson(item))
              .toList()
          : [],
    );
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
    return OrderItem(
      id: json['id'] as String,
      orderId: json['order_id'] as String,
      productId: json['product_id'] as String,
      pricingTier: PricingTier.values.firstWhere(
        (e) => e.name == json['pricing_tier'],
        orElse: () => PricingTier.retail,
      ),
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      totalPrice: (json['total_price'] as num).toDouble(),
      fulfillmentStatus: json['fulfillment_status'] as String? ?? 'pending',
      createdAt: DateTime.parse(json['created_at'] as String),
      product: json['products'] != null
          ? Product.fromJson(json['products'])
          : null,
    );
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