import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stock_transaction.dart';
import '../providers/product_provider.dart';
import '../providers/stock_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:go_router/go_router.dart';

class StockScreen extends ConsumerWidget {
  final String productId;

  const StockScreen({Key? key, required this.productId}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productProvider(productId));
    final stockTransactions = ref.watch(stockProvider(productId));

    return Scaffold(
      appBar: AppBar(
        title: productAsync.when(
          loading: () => const Text('Cargando...'),
          error: (_, __) => const Text('Error'),
          data: (product) => Text('Stock para ${product.name}'),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/stock'),
        ),
      ),
      body: productAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (product) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(productProvider(productId));
            ref.invalidate(stockProvider(productId));
          },
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Stock Actual: ${product.stock}', style: Theme.of(context).textTheme.titleLarge),
              ),
              Expanded(
                child: stockTransactions.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(child: Text('Error: $err')),
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(child: Text('Sin transacciones registradas.'),);
                    }
                    return ListView.builder(
                      itemCount: transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = transactions[index];
                        return ListTile(
                          title: Text(transaction.type == TransactionType.entrada ? 'Entrada' : 'Salida'),
                          subtitle: Text('Cantidad: ${transaction.quantity}'),
                          trailing: Text(transaction.date.toString()),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddTransactionDialog(BuildContext context, WidgetRef ref) {
    int? quantity;
    TransactionType? type;
    final productAsync = ref.read(productProvider(productId));

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Adicionar Stock'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButton<TransactionType>(
                    value: type,
                    hint: const Text('Seleccione tipo'),
                    items: TransactionType.values.map((TransactionType value) {
                      return DropdownMenuItem<TransactionType>(
                        value: value,
                        child: Text(value == TransactionType.entrada ? 'Entrada' : 'Salida'),
                      );
                    }).toList(),
                    onChanged: (TransactionType? newValue) {
                      setState(() {
                        type = newValue;
                      });
                    },
                  ),
                  TextField(
                    decoration: const InputDecoration(labelText: 'Quantity'),
                    keyboardType: TextInputType.number,
                    onChanged: (value) {
                      setState(() {
                        quantity = int.tryParse(value);
                      });
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  child: const Text('Cancel'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
                TextButton(
                  onPressed: productAsync.when(
                    loading: () => null,
                    error: (_, __) => null,
                    data: (product) => (type == TransactionType.salida && (quantity ?? 0) > product.stock)
                        ? null
                        : () {
                            if (type != null && quantity != null) {
                              final transaction = StockTransaction(
                                id: const Uuid().v4(),
                                productId: productId,
                                type: type!,
                                quantity: quantity!,
                                date: DateTime.now(),
                              );
                              ref.read(stockProvider(productId).notifier).addTransaction(transaction);
                              ref.read(productsProvider.notifier).updateProductStock(
                                    productId,
                                    type == TransactionType.entrada ? quantity! : -quantity!,
                                  );
                              Navigator.of(context).pop();
                              // Invalidate the product and stock data
                              ref.invalidate(productProvider(productId));
                              ref.invalidate(stockProvider(productId));
                            }
                          },
                  ),
                  child: const Text('Adicionar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}