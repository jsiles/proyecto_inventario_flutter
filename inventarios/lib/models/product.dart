class Product {
  final String id;
  final String name;
  final double price;
  final String? imagePath;
  final int stock;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.imagePath,
    this.stock = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'imagePath': imagePath,
      'stock': stock,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      price: map['price'],
      imagePath: map['imagePath'],
      stock: map['stock'] ?? 0,
    );
  }

  Product copyWith({
    String? id,
    String? name,
    double? price,
    String? imagePath,
    int? stock,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      imagePath: imagePath ?? this.imagePath,
      stock: stock ?? this.stock,
    );
  }

  // ... (otros métodos existentes)
}