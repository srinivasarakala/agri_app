import 'package:flutter/material.dart';
import 'pages/sd_home_page.dart';
import 'pages/sd_catalog_page.dart';
import 'pages/sd_ledger_page.dart';
import '../../core/widgets/logout_button.dart';
import 'pages/sd_my_orders_page.dart';

final titles = ['Home', 'Catalog', 'Orders', 'Ledger'];
final subdealerTabIndex = ValueNotifier<int>(0);

class SubdealerShell extends StatefulWidget {
  const SubdealerShell({super.key});

  @override
  State<SubdealerShell> createState() => _SubdealerShellState();
}

class _SubdealerShellState extends State<SubdealerShell> {
  final pages = const [
    SdHomePage(),
    SdCatalogPage(),
    SdMyOrdersPage(),
    SdLedgerPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: subdealerTabIndex,
      builder: (_, index, __) {
        return Scaffold(
          appBar: AppBar(
            title: Text('Subdealer • ${titles[index]}'),
            actions: const [LogoutButton()],
          ),
          body: pages[index],
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => subdealerTabIndex.value = i,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.search),
                label: 'Catalog',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.list_alt),
                label: 'My Orders',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.account_balance_wallet),
                label: 'Ledger',
              ),
            ],
          ),
        );
      },
    );
  }
}
