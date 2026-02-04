import 'package:flutter/material.dart';
import 'pages/admin_orders_page.dart';
import 'pages/admin_products_page.dart';
import 'pages/admin_stock_page.dart';
import 'pages/admin_subdealers_page.dart';
import 'pages/admin_settlements_page.dart';
import '../../core/widgets/logout_button.dart'; // adjust path if needed

final titles = ['Orders', 'Products', 'Stock', 'Subdealers', 'Settlements'];
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
    AdminStockPage(),
    AdminSubdealersPage(),
    AdminSettlementsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(
      title: Text('Admin • ${titles[index]}'),
    actions: const [LogoutButton()],),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory_2), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.warehouse), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: 'Subdealers'),
          BottomNavigationBarItem(icon: Icon(Icons.payments), label: 'Settlements'),
        ],
      ),
    );
  }
}
