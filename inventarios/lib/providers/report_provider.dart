import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_transaction.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class ReportData {
  final Product product;
  final List<StockTransaction> transactions;
  final int totalEntradas;
  final int totalSalidas;

  ReportData(this.product, this.transactions, this.totalEntradas, this.totalSalidas);
}

final reportProvider = StateNotifierProvider<ReportNotifier, AsyncValue<List<ReportData>>>((ref) {
  return ReportNotifier();
});

class ReportNotifier extends StateNotifier<AsyncValue<List<ReportData>>> {
  ReportNotifier() : super(const AsyncValue.loading());

  Future<void> getReport(DateTime startDate, DateTime endDate) async {
    try {
      state = const AsyncValue.loading();
      final db = await DatabaseHelper.instance.database;
      
      final products = await db.query('products');
      final List<ReportData> reportData = [];

      for (final product in products) {
        final transactions = await db.query(
          'stock_transactions',
          where: 'productId = ? AND date BETWEEN ? AND ?',
          whereArgs: [product['id'], startDate.toIso8601String(), endDate.toIso8601String()],
          orderBy: 'date ASC',
        );

        final stockTransactions = transactions.map((t) => StockTransaction.fromMap(t)).toList();
        final totalEntradas = stockTransactions.where((t) => t.type == TransactionType.entrada).fold(0, (sum, t) => sum + t.quantity);
        final totalSalidas = stockTransactions.where((t) => t.type == TransactionType.salida).fold(0, (sum, t) => sum + t.quantity);

        reportData.add(ReportData(
          Product.fromMap(product),
          stockTransactions,
          totalEntradas,
          totalSalidas,
        ));
      }

      state = AsyncValue.data(reportData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}