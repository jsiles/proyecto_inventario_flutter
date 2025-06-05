import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_transaction.dart';
import '../services/database_helper.dart';

final stockProvider = StateNotifierProvider.family<StockNotifier, AsyncValue<List<StockTransaction>>, String>(
  (ref, productId) => StockNotifier(productId),
);

class StockNotifier extends StateNotifier<AsyncValue<List<StockTransaction>>> {
  final String productId;
  bool _mounted = true;

  StockNotifier(this.productId) : super(const AsyncValue.loading()) {
    loadTransactions();
  }

  @override
  void dispose() {
    _mounted = false;
    super.dispose();
  }

  Future<void> loadTransactions() async {
    if (!_mounted) return;
    try {
      final db = await DatabaseHelper.instance.database;
      final transactions = await db.query(
        'stock_transactions',
        where: 'productId = ?',
        whereArgs: [productId],
        orderBy: 'date DESC',
      );
      if (_mounted) {
        state = AsyncValue.data(transactions.map((t) => StockTransaction.fromMap(t)).toList());
      }
    } catch (e) {
      if (_mounted) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }

  Future<void> addTransaction(StockTransaction transaction) async {
    if (!_mounted) return;
    try {
      final db = await DatabaseHelper.instance.database;
      await db.insert('stock_transactions', transaction.toMap());
      await db.rawUpdate(
        'UPDATE products SET stock = stock + ? WHERE id = ?',
        [transaction.type == TransactionType.entrada ? transaction.quantity : -transaction.quantity, transaction.productId],
      );
      await loadTransactions();
    } catch (e) {
      if (_mounted) {
        state = AsyncValue.error(e, StackTrace.current);
      }
    }
  }
}