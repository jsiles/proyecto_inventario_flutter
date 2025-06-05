import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../services/database_helper.dart';

class ProductNotifier extends StateNotifier<AsyncValue<List<Product>>> {
  ProductNotifier() : super(const AsyncValue.loading()) {
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    try {
      final products = await DatabaseHelper.instance.getProducts();
      state = AsyncValue.data(products);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  Future<void> addProduct(Product product) async {
    await DatabaseHelper.instance.insertProduct(product);
    _loadProducts();
  }

  Future<void> deleteProduct(String id) async {
    await DatabaseHelper.instance.deleteProduct(id);
    _loadProducts();
  }

  Future<void> editProduct(Product product) async {
    await DatabaseHelper.instance.updateProduct(product);
    _loadProducts();
  }

  Future<void> updateProductStock(String productId, int stockChange) async {
    state.whenData((products) async {
      final index = products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final updatedProduct = products[index].copyWith(
          stock: products[index].stock + stockChange,
        );
        await DatabaseHelper.instance.updateProduct(updatedProduct);
        final updatedProducts = List<Product>.from(products);
        updatedProducts[index] = updatedProduct;
        state = AsyncValue.data(updatedProducts);
      }
    });
  }
}

final productsProvider = StateNotifierProvider<ProductNotifier, AsyncValue<List<Product>>>((ref) {
  return ProductNotifier();
});

final productProvider = Provider.family<AsyncValue<Product>, String>((ref, productId) {
  final productsAsyncValue = ref.watch(productsProvider);
  return productsAsyncValue.whenData(
    (products) => products.firstWhere((p) => p.id == productId),
  );
});