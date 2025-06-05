enum TransactionType { entrada, salida }

class StockTransaction {
  final String id;
  final String productId;
  final int quantity;
  final TransactionType type;
  final DateTime date;

  StockTransaction({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.type,
    required this.date,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'quantity': quantity,
      'type': type.toString(),
      'date': date.toIso8601String(),
    };
  }

  factory StockTransaction.fromMap(Map<String, dynamic> map) {
    return StockTransaction(
      id: map['id'],
      productId: map['productId'],
      quantity: map['quantity'],
      type: TransactionType.values.firstWhere((e) => e.toString() == map['type']),
      date: DateTime.parse(map['date']),
    );
  }
}