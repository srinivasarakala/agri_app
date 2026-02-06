import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../you/you_page.dart';
import '../../core/widgets/top_banner.dart';
import '../../core/cart/cart_state.dart';
import '../catalog/product.dart';
import '../../main.dart'; // for catalogApi


final appTabIndex = ValueNotifier<int>(0);

class AppShell extends StatelessWidget {
  final String role;
  const AppShell({super.key, required this.role});

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(role: role),             // 0 Home
      const _CartPage(),                // 1 Cart
      const _FavoritesPage(),           // 2 Favorites
      YouPage(role: role),              // 3 You (role menus + logout)
    ];

    return ValueListenableBuilder<int>(
      valueListenable: appTabIndex,
      builder: (_, index, __) {
        return Scaffold(
          // ✅ No AppBar (top should be only banner inside pages)
          body: IndexedStack(
            index: index,
            children: pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => appTabIndex.value = i,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
              BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: "Cart"),
              BottomNavigationBarItem(icon: Icon(Icons.favorite), label: "Favorite"),
              BottomNavigationBarItem(icon: Icon(Icons.person), label: "You"),
            ],
          ),
        );
      },
    );
  }
}

class _CartPage extends StatefulWidget {
  const _CartPage();

  @override
  State<_CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<_CartPage> {
  List<Product> all = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => loading = true);
    try {
      all = await catalogApi.listProducts();
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<int,int>>(
      valueListenable: cartQty,
      builder: (_, m, __) {
        final total = m.values.fold(0, (a,b) => a + b);
        final cartItems = all.where((p) => m.containsKey(p.id)).toList();

        return ListView(
          padding: EdgeInsets.zero,
          children: [
            const TopBanner(subtitle: "Cart"),
            const SizedBox(height: 12),

            if (loading)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (total == 0)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text("Cart is empty"),
              )
            else
              ...cartItems.map((p) {
                final qty = m[p.id] ?? 0;
                return ListTile(
                  title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                  subtitle: Text("₹${p.sellingPrice} • ${p.unit}"),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => cartSetQty(p.id, qty - 1),
                      ),
                      Text("$qty", style: const TextStyle(fontWeight: FontWeight.w900)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => cartSetQty(p.id, qty + 1),
                      ),
                    ],
                  ),
                );
              }),

            if (total > 0) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: [
                    Expanded(child: Text("$total item(s)", style: const TextStyle(fontWeight: FontWeight.w900))),
                    TextButton(
                      onPressed: cartClear,
                      child: const Text("Clear"),
                    ),
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}


class _FavoritesPage extends StatelessWidget {
  const _FavoritesPage();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.zero,
      children: const [
        TopBanner(subtitle: "Favorites"),
        SizedBox(height: 14),
        Padding(
          padding: EdgeInsets.all(14),
          child: Text("Favorites UI coming next (save/unsave products)."),
        ),
      ],
    );
  }
}
