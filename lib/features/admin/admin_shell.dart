import 'package:flutter/material.dart';
import 'pages/admin_orders_page.dart';
import 'pages/admin_products_page.dart';
import 'pages/admin_product_videos_page.dart';
import 'pages/admin_categories_page.dart';
import '../../core/widgets/logout_button.dart'; // adjust path if needed

final titles = ['Orders', 'Products', 'Videos', 'Categories'];

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int index = 0;

  final pages = const [
    AdminOrdersPage(),
    AdminProductsPage(),
    AdminProductVideosPage(),
    AdminCategoriesPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Admin • ${titles[index]}'),
        actions: const [LogoutButton()],
      ),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        selectedFontSize: 11,
        unselectedFontSize: 10,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt_long),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2),
            label: 'Products',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.video_library),
            label: 'Videos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.category),
            label: 'Category',
          ),
        ],
      ),
    );
  }
}
