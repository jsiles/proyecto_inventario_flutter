import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('Sistema Inventario'),
    ),
    drawer: HomeScreen.buildDrawer(context),
    body: Padding(
      padding: const EdgeInsets.all(20.0),  // Añade padding alrededor de todo el contenido
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Bienvenido al Sistema Inventario',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,  // Centra el texto si ocupa más de una línea
            ),
            const SizedBox(height: 20),
            const Text(
              'Use el menu para navegar entre las diferentes secciones del sistema.',
              style: TextStyle(fontSize: 16),
              textAlign: TextAlign.center,  // Centra el texto si ocupa más de una línea
            ),
            const SizedBox(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildInfoCard(context, 'Productos', Icons.inventory, Colors.blue, '/products'),
                _buildInfoCard(context, 'Stock', Icons.store, Colors.green, '/stock'),
                _buildInfoCard(context, 'Reportes', Icons.bar_chart, Colors.orange, '/reports'),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

  Widget _buildInfoCard(BuildContext context, String title, IconData icon, Color color, String route) {
    return GestureDetector(
      onTap: () => context.go(route),
      child: Card(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Icon(icon, size: 48, color: color),
              const SizedBox(height: 8),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }

  static Widget buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Sistema Inventio',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () {
              context.go('/');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.inventory),
            title: const Text('Productos'),
            onTap: () {
              context.go('/products');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.store),
            title: const Text('Stock'),
            onTap: () {
              context.go('/stock');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.bar_chart),
            title: const Text('Reportes'),
            onTap: () {
              context.go('/reports');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}