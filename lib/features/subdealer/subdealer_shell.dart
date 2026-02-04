import 'package:flutter/material.dart';
import 'pages/sd_home_page.dart';
import 'pages/sd_catalog_page.dart';
import 'pages/sd_orders_page.dart';
import 'pages/sd_stock_page.dart';
import 'pages/sd_ledger_page.dart';
import '../../core/widgets/logout_button.dart';
import 'pages/sd_my_orders_page.dart';


final titles = ['Home', 'Catalog', 'Orders', 'Stock', 'Ledger'];

class SubdealerShell extends StatefulWidget {
  const SubdealerShell({super.key});

  @override
  State<SubdealerShell> createState() => _SubdealerShellState();
}

class _SubdealerShellState extends State<SubdealerShell> {
  int index = 0;

  final pages = const [
    SdHomePage(),
    SdCatalogPage(),
    SdMyOrdersPage(),
    SdStockPage(),
    SdLedgerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Subdealer • ${titles[index]}'),
        actions: const [LogoutButton()],
      ),
      body: pages[index],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: index,
        onTap: (i) => setState(() => index = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Catalog'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt), label: 'My Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: 'Stock'),
          BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Ledger'),
        ],
      ),
    );
  }
}
