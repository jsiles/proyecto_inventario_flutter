import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/product_provider.dart';
import 'home_screen.dart';  // Asegúrate de importar esto

class StockListScreen extends ConsumerWidget {
  const StockListScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manejo de Stock'),
      ),
      drawer: HomeScreen.buildDrawer(context),  // Añade el drawer aquí
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No existen productos.'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                title: Text(product.name),
                subtitle: Text('Stock Actual: ${product.stock}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  context.go('/stock/${product.id}');
                },
              );
            },
          );
        },
      ),
    );
  }
}