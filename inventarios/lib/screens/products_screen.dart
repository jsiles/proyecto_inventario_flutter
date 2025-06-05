import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import 'dart:io';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'home_screen.dart';
import 'package:uuid/uuid.dart';

class ProductsScreen extends ConsumerWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Productos')),
      drawer: HomeScreen.buildDrawer(context),
      body: productsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (products) {
          if (products.isEmpty) {
            return const Center(child: Text('No existen productos'));
          }
          return ListView.builder(
            itemCount: products.length,
            itemBuilder: (context, index) {
              final product = products[index];
              return ListTile(
                leading: product.imagePath != null
                    ? Image.file(File(product.imagePath!), width: 50, height: 50, fit: BoxFit.cover)
                    : const Icon(Icons.image),
                title: Text(product.name),
                subtitle: Text('Precio: ${product.price.toStringAsFixed(2)}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        _showEditProductDialog(context, ref, product);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () {
                        ref.read(productsProvider.notifier).deleteProduct(product.id);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddProductDialog(context, ref);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _showEditProductDialog(BuildContext context, WidgetRef ref, Product product) async {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(text: product.price.toString());
    String? imagePath = product.imagePath;

    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar Producto'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Nombre Producto'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Precio'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? image = await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          final directory = await getApplicationDocumentsDirectory();
                          final name = path.basename(image.path);
                          final savedImage = await File(image.path).copy('${directory.path}/$name');
                          setState(() {
                            imagePath = savedImage.path;
                          });
                        }
                      },
                      child: const Text('Tomar Foto'),
                    ),
                    if (imagePath != null)
                      Image.file(File(imagePath!), height: 100, width: 100, fit: BoxFit.cover),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                      final updatedProduct = Product(
                        id: product.id,
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        imagePath: imagePath,
                      );
                      ref.read(productsProvider.notifier).editProduct(updatedProduct);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAddProductDialog(BuildContext context, WidgetRef ref) async {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    String? imagePath;

    final ImagePicker picker = ImagePicker();

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add New Product'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Product Name'),
                    ),
                    TextField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Price'),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        final XFile? image = await picker.pickImage(source: ImageSource.camera);
                        if (image != null) {
                          final directory = await getApplicationDocumentsDirectory();
                          final name = path.basename(image.path);
                          final savedImage = await File(image.path).copy('${directory.path}/$name');
                          setState(() {
                            imagePath = savedImage.path;
                          });
                        }
                      },
                      child: const Text('Take Photo'),
                    ),
                    if (imagePath != null)
                      Image.file(File(imagePath!), height: 100, width: 100, fit: BoxFit.cover),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    if (nameController.text.isNotEmpty && priceController.text.isNotEmpty) {
                      final newProduct = Product(
                        id: const Uuid().v4(),
                        name: nameController.text,
                        price: double.parse(priceController.text),
                        imagePath: imagePath,
                      );
                      ref.read(productsProvider.notifier).addProduct(newProduct);
                      Navigator.pop(context);
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}