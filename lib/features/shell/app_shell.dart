import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../you/you_page.dart';
import '../../core/widgets/top_banner.dart';
import '../../core/cart/cart_state.dart';
import '../catalog/product.dart';
import '../catalog/widgets/product_detail_dialog.dart';
import '../../main.dart'; // for catalogApi
import '../orders/checkout_page.dart';

final appTabIndex = ValueNotifier<int>(0);

class AppShell extends StatefulWidget {
  final String role;
  const AppShell({super.key, required this.role});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  void initState() {
    super.initState();
    _loadUserCartIfNeeded();
  }

  Future<void> _loadUserCartIfNeeded() async {
    // Always try to load cart when AppShell initializes
    print('[AppShell] Loading cart on init...');
    if (currentSession?.phone != null) {
      try {
        print('[AppShell] Loading cart for: ${currentSession!.phone}');
        await loadUserCart(currentSession!.phone!);
        print('[AppShell] Cart loaded successfully');
      } catch (e) {
        print('[AppShell] Error loading cart: $e');
      }
    } else {
      print('[AppShell] No session phone found');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(role: widget.role), // 0 Home
      const _CartPage(), // 1 Cart
      const _FavoritesPage(), // 2 Favorites
      YouPage(role: widget.role), // 3 You (role menus + logout)
    ];

    return ValueListenableBuilder<int>(
      valueListenable: appTabIndex,
      builder: (_, index, __) {
        return ValueListenableBuilder<Map<int, int>>(
          valueListenable: cartQty,
          builder: (__, cartMap, ___) {
            final cartCount = cartMap.values.fold<int>(0, (a, b) => a + b);

            return Scaffold(
              // ✅ No AppBar (top should be only banner inside pages)
              body: IndexedStack(index: index, children: pages),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: index,
                onTap: (i) => appTabIndex.value = i,
                type: BottomNavigationBarType.fixed,
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.home),
                    label: "Home",
                  ),
                  BottomNavigationBarItem(
                    icon: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        const Icon(Icons.shopping_cart),
                        if (cartCount > 0)
                          Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              cartCount > 99 ? "99+" : cartCount.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                    label: "Cart",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.favorite),
                    label: "Favorite",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.menu),
                    label: "Menu",
                  ),
                ],
              ),
            );
          },
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
    return ValueListenableBuilder<Map<int, int>>(
      valueListenable: cartQty,
      builder: (_, m, __) {
        final totalItems = m.values.fold(0, (a, b) => a + b);
        final cartItems = all.where((p) => m.containsKey(p.id)).toList();
        final totalValue = cartItems.fold<double>(0, (sum, p) {
          final qty = m[p.id] ?? 0;
          return sum + (p.sellingPrice * qty);
        });

        return ListView(
          padding: const EdgeInsets.only(top: 12),
          children: [
            if (loading)
              const Padding(
                padding: EdgeInsets.all(18),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (totalItems == 0)
              const Padding(
                padding: EdgeInsets.all(14),
                child: Text("Cart is empty"),
              )
            else
              ...cartItems.map((p) {
                final qty = m[p.id] ?? 0;
                final minQty = p.minQty.toInt();
                return InkWell(
                  onTap: () => showProductDetail(context, p),
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 6,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${p.sellingPrice} × $qty = ₹${(p.sellingPrice * qty).toStringAsFixed(2)}",
                                ),
                                const SizedBox(height: 4),
                                if (minQty > 1)
                                  Text(
                                    "Min Qty: $minQty",
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.orange.shade700,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  final newQty = qty - minQty;
                                  cartSetQty(p.id, newQty <= 0 ? 0 : newQty);
                                },
                              ),
                              Text(
                                "$qty",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add_circle_outline),
                                onPressed: () => cartSetQty(p.id, qty + minQty),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),

            if (totalItems > 0) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "$totalItems item(s)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Total: ₹${totalValue.toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: cartClear,
                          child: const Text("Clear"),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () async {
                        // Navigate to checkout page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const CheckoutPage(),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        "Checkout",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
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

class _FavoritesPage extends StatefulWidget {
  const _FavoritesPage();

  @override
  State<_FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<_FavoritesPage> {
  List<Product> all = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => loading = true);
    try {
      all = await catalogApi.listProducts();
    } catch (e) {
      error = "Failed to load products";
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Set<int>>(
      valueListenable: favorites,
      builder: (_, favSet, __) {
        final favoriteProducts = all
            .where((p) => favSet.contains(p.id))
            .toList();

        return RefreshIndicator(
          onRefresh: _loadProducts,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const TopBanner(subtitle: "Favorites"),
              const SizedBox(height: 14),

              if (loading)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (error != null)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                )
              else if (favoriteProducts.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      "No favorites yet\nHeart your favorite products to see them here",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "${favoriteProducts.length} Favorite(s)",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: favoriteProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 10),
                        itemBuilder: (_, i) {
                          final p = favoriteProducts[i];
                          return InkWell(
                            onTap: () => showProductDetail(context, p),
                            child: Card(
                              elevation: 1,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(10),
                                child: Row(
                                  children: [
                                    // Product image
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        width: 80,
                                        height: 80,
                                        color: Colors.grey.shade100,
                                        child:
                                            (p.imageUrl != null &&
                                                p.imageUrl!.isNotEmpty)
                                            ? Image.network(
                                                p.imageUrl!,
                                                fit: BoxFit.cover,
                                              )
                                            : const Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Product details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w700,
                                              fontSize: 13,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            p.sku,
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 11,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              Text(
                                                "₹${p.sellingPrice.toStringAsFixed(2)}",
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  color: Colors.green,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (p.mrp > p.sellingPrice) ...[
                                                const SizedBox(width: 6),
                                                Text(
                                                  "₹${p.mrp.toStringAsFixed(2)}",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 11,
                                                    decoration: TextDecoration
                                                        .lineThrough,
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Remove from favorites button
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.favorite,
                                            color: Colors.red,
                                            size: 20,
                                          ),
                                          onPressed: () async {
                                            try {
                                              await catalogApi.toggleFavorite(
                                                p.id,
                                              );
                                              toggleFavorite(p.id);
                                            } catch (e) {
                                              if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Error: $e"),
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          padding: EdgeInsets.zero,
                                          constraints: const BoxConstraints(
                                            minWidth: 30,
                                            minHeight: 30,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
