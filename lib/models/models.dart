class User {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String? avatar;
  final String? token;
  final DateTime? createdAt;
  final bool isActive;

  User({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.avatar,
    this.token,
    this.createdAt,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      role: json['role'] as String? ?? 'Vendeur',
      avatar: json['avatar'] as String?,
      token: json['token'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isActive: (json['is_active'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'avatar': avatar,
      'token': token,
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? avatar,
    String? token,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      avatar: avatar ?? this.avatar,
      token: token ?? this.token,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, role: $role)';
}

class Category {
  final int? id;
  final String name;
  final String? imageUrl;
  final String color;
  final int? productCount;
  final DateTime? createdAt;
  final bool isActive;

  Category({
    this.id,
    required this.name,
    this.imageUrl,
    required this.color,
    this.productCount = 0,
    this.createdAt,
    this.isActive = true,
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      color: json['color'] as String? ?? '#1B3A5C',
      productCount: json['product_count'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isActive: (json['is_active'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'image_url': imageUrl,
      'color': color,
      'product_count': productCount,
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  Category copyWith({
    int? id,
    String? name,
    String? imageUrl,
    String? color,
    int? productCount,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      color: color ?? this.color,
      productCount: productCount ?? this.productCount,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'Category(id: $id, name: $name)';
}

class Product {
  final int? id;
  final String name;
  final String? description;
  final String barcode;
  final double price;
  final double costPrice;
  final int categoryId;
  final String? categoryName;
  final int stock;
  final int minStock;
  final String? imageUrl;
  final int discount;
  final DateTime? createdAt;
  final bool isActive;

  Product({
    this.id,
    required this.name,
    this.description,
    required this.barcode,
    required this.price,
    required this.costPrice,
    required this.categoryId,
    this.categoryName,
    this.stock = 0,
    this.minStock = 5,
    this.imageUrl,
    this.discount = 0,
    this.createdAt,
    this.isActive = true,
  });

  double get profitPrice => price - costPrice;
  double get profitPercent => costPrice > 0 ? (profitPrice / costPrice) * 100 : 0;
  double get salePrice => price - (price * (discount / 100));

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String?,
      barcode: json['barcode'] as String? ?? '',
      price: double.tryParse(json['price'].toString()) ?? 0.0,
      costPrice: double.tryParse(json['cost_price'].toString()) ?? 0.0,
      categoryId: json['category_id'] as int? ?? 0,
      categoryName: json['category_name'] as String?,
      stock: json['stock'] as int? ?? 0,
      minStock: json['min_stock'] as int? ?? 5,
      imageUrl: json['image_url'] as String?,
      discount: json['discount'] as int? ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      isActive: (json['is_active'] as int?) == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'barcode': barcode,
      'price': price,
      'cost_price': costPrice,
      'category_id': categoryId,
      'category_name': categoryName,
      'stock': stock,
      'min_stock': minStock,
      'image_url': imageUrl,
      'discount': discount,
      'created_at': createdAt?.toIso8601String(),
      'is_active': isActive ? 1 : 0,
    };
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    String? barcode,
    double? price,
    double? costPrice,
    int? categoryId,
    String? categoryName,
    int? stock,
    int? minStock,
    String? imageUrl,
    int? discount,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      barcode: barcode ?? this.barcode,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      stock: stock ?? this.stock,
      minStock: minStock ?? this.minStock,
      imageUrl: imageUrl ?? this.imageUrl,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() => 'Product(id: $id, name: $name, barcode: $barcode)';
}

class CartItem {
  final Product product;
  int quantity;
  int discount;

  CartItem({
    required this.product,
    required this.quantity,
    this.discount = 0,
  });

  double get subtotal => product.salePrice * quantity;
  double get discountAmount => subtotal * (discount / 100);
  double get total => subtotal - discountAmount;

  CartItem copyWith({
    Product? product,
    int? quantity,
    int? discount,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }

  @override
  String toString() =>
      'CartItem(product: ${product.name}, quantity: $quantity, total: $total)';
}

class Sale {
  final int? id;
  final String saleNumber;
  final int userId;
  final double subtotal;
  final double discount;
  final double tax;
  final double total;
  final String paymentMethod;
  final String? notes;
  final List<CartItem> items;
  final DateTime? createdAt;

  Sale({
    this.id,
    required this.saleNumber,
    required this.userId,
    required this.subtotal,
    required this.discount,
    required this.tax,
    required this.total,
    required this.paymentMethod,
    this.notes,
    required this.items,
    this.createdAt,
  });

  factory Sale.fromJson(Map<String, dynamic> json) {
    return Sale(
      id: json['id'] as int?,
      saleNumber: json['sale_number'] as String? ?? '',
      userId: json['user_id'] as int? ?? 0,
      subtotal: double.tryParse(json['subtotal'].toString()) ?? 0.0,
      discount: double.tryParse(json['discount'].toString()) ?? 0.0,
      tax: double.tryParse(json['tax'].toString()) ?? 0.0,
      total: double.tryParse(json['total'].toString()) ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'Espèces',
      notes: json['notes'] as String?,
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => CartItem(
                    product: Product.fromJson(item),
                    quantity: item['quantity'] as int? ?? 1,
                  ))
              .toList() ??
          [],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sale_number': saleNumber,
      'user_id': userId,
      'subtotal': subtotal,
      'discount': discount,
      'tax': tax,
      'total': total,
      'payment_method': paymentMethod,
      'notes': notes,
      'items': items.map((item) => item.product.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
    };
  }

  @override
  String toString() =>
      'Sale(id: $id, saleNumber: $saleNumber, total: $total, items: ${items.length})';
}

class AppSettings {
  final String shopName;
  final String shopSlogan;
  final String shopAddress;
  final String shopCity;
  final String shopPhone;
  final String shopEmail;
  final String shopMF;
  final String shopRNE;
  final String? shopLogo;
  final String? shopImage;
  final String currency;
  final int taxRate;
  final String welcomeMessage;
  final String? themeColor;

  AppSettings({
    this.shopName = 'Mon SuperMarché',
    this.shopSlogan = 'Qualité & Fraîcheur',
    this.shopAddress = 'Avenue Habib Bourguiba',
    this.shopCity = 'Tunis',
    this.shopPhone = '+216 71 000 000',
    this.shopEmail = 'contact@supermarche.tn',
    this.shopMF = '1234567/A/M/000',
    this.shopRNE = 'J0123456',
    this.shopLogo,
    this.shopImage,
    this.currency = 'DT',
    this.taxRate = 19,
    this.welcomeMessage = 'Merci de votre visite !',
    this.themeColor = '#1B3A5C',
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      shopName: json['shop_name'] as String? ?? 'Mon SuperMarché',
      shopSlogan: json['shop_slogan'] as String? ?? 'Qualité & Fraîcheur',
      shopAddress: json['shop_address'] as String? ?? '',
      shopCity: json['shop_city'] as String? ?? 'Tunis',
      shopPhone: json['shop_phone'] as String? ?? '',
      shopEmail: json['shop_email'] as String? ?? '',
      shopMF: json['shop_mf'] as String? ?? '',
      shopRNE: json['shop_rne'] as String? ?? '',
      shopLogo: json['shop_logo'] as String?,
      shopImage: json['shop_image'] as String?,
      currency: json['currency'] as String? ?? 'DT',
      taxRate: int.tryParse(json['tax_rate'].toString()) ?? 19,
      welcomeMessage: json['welcome_message'] as String? ?? 'Merci de votre visite !',
      themeColor: json['theme_color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'shop_name': shopName,
      'shop_slogan': shopSlogan,
      'shop_address': shopAddress,
      'shop_city': shopCity,
      'shop_phone': shopPhone,
      'shop_email': shopEmail,
      'shop_mf': shopMF,
      'shop_rne': shopRNE,
      'shop_logo': shopLogo,
      'shop_image': shopImage,
      'currency': currency,
      'tax_rate': taxRate,
      'welcome_message': welcomeMessage,
      'theme_color': themeColor,
    };
  }

  AppSettings copyWith({
    String? shopName,
    String? shopSlogan,
    String? shopAddress,
    String? shopCity,
    String? shopPhone,
    String? shopEmail,
    String? shopMF,
    String? shopRNE,
    String? shopLogo,
    String? shopImage,
    String? currency,
    int? taxRate,
    String? welcomeMessage,
    String? themeColor,
  }) {
    return AppSettings(
      shopName: shopName ?? this.shopName,
      shopSlogan: shopSlogan ?? this.shopSlogan,
      shopAddress: shopAddress ?? this.shopAddress,
      shopCity: shopCity ?? this.shopCity,
      shopPhone: shopPhone ?? this.shopPhone,
      shopEmail: shopEmail ?? this.shopEmail,
      shopMF: shopMF ?? this.shopMF,
      shopRNE: shopRNE ?? this.shopRNE,
      shopLogo: shopLogo ?? this.shopLogo,
      shopImage: shopImage ?? this.shopImage,
      currency: currency ?? this.currency,
      taxRate: taxRate ?? this.taxRate,
      welcomeMessage: welcomeMessage ?? this.welcomeMessage,
      themeColor: themeColor ?? this.themeColor,
    );
  }

  @override
  String toString() => 'AppSettings(shopName: $shopName, currency: $currency)';
}
