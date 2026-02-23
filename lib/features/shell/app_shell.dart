import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../you/you_page.dart';
import '../../core/cart/cart_state.dart';
import '../catalog/product.dart';
import '../catalog/widgets/product_detail_dialog.dart';
import '../../main.dart'; // for catalogApi
import '../orders/checkout_page.dart';
import '../subdealer/pages/sd_catalog_page.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

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
      SdCatalogPage(), // 4 Products (hidden, switched to programmatically)
    ];

    return ValueListenableBuilder<int>(
      valueListenable: appTabIndex,
      builder: (_, index, __) {
        return ValueListenableBuilder<Map<int, int>>(
          valueListenable: cartQty,
          builder: (__, cartMap, ___) {
            final cartCount = cartMap.values.fold<int>(0, (a, b) => a + b);
            // Clamp index for bottom nav (0-3), but allow 4 for hidden catalog page
            final navIndex = index > 3 ? 0 : index;

            return Scaffold(
              // ✅ No AppBar (top should be only banner inside pages)
              body: IndexedStack(index: index, children: pages),
              bottomNavigationBar: BottomNavigationBar(
                currentIndex: navIndex,
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        // Session expired, redirect to login
        currentSession = null;
        if (mounted) context.go('/login');
      }
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

        return Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
                color: Colors.white,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.green,
                      size: 32,
                    ),
                    SizedBox(width: 8),
                    Text(
                      "Your Cart",
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              // Cart Items List
              Expanded(
                child: loading
                    ? const Center(child: CircularProgressIndicator())
                    : totalItems == 0
                        ? const Center(
                            child: Text(
                              "Cart is empty",
                              style: TextStyle(fontSize: 16),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            itemCount: cartItems.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (_, idx) {
                              final p = cartItems[idx];
                              final qty = m[p.id] ?? 0;
                              final itemTotal = p.sellingPrice * qty;

                              return InkWell(
                                onTap: () => showProductDetail(context, p),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Product Image
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                      ),
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                p.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder:
                                                    (_, __, ___) => const Icon(
                                                  Icons.image,
                                                  size: 40,
                                                  color: Colors.grey,
                                                ),
                                              )
                                            : const Icon(
                                                Icons.image,
                                                size: 40,
                                                color: Colors.grey,
                                              ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),

                                    // Product Details
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
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              const Text(
                                                "Qty:",
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Decrement button
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.green),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: InkWell(
                                                  onTap: () {
                                                    if (qty > 1) cartSetQty(p.id, qty - 1);
                                                  },
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.remove,
                                                      size: 16,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Editable quantity field
                                              Container(
                                                width: 50,
                                                height: 32,
                                                alignment: Alignment.center,
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.grey.shade300),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: TextField(
                                                  controller: TextEditingController(text: "$qty"),
                                                  keyboardType: TextInputType.number,
                                                  textAlign: TextAlign.center,
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                  decoration: const InputDecoration(
                                                    border: InputBorder.none,
                                                    contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                                                  ),
                                                  onSubmitted: (value) {
                                                    final newQty = int.tryParse(value) ?? qty;
                                                    if (newQty > 0) {
                                                      cartSetQty(p.id, newQty);
                                                    }
                                                  },
                                                ),
                                              ),
                                              const SizedBox(width: 8),
                                              // Increment button
                                              Container(
                                                decoration: BoxDecoration(
                                                  border: Border.all(color: Colors.green),
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: InkWell(
                                                  onTap: () => cartSetQty(p.id, qty + 1),
                                                  child: const Padding(
                                                    padding: EdgeInsets.all(4),
                                                    child: Icon(
                                                      Icons.add,
                                                      size: 16,
                                                      color: Colors.green,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            "₹${itemTotal.toStringAsFixed(2)}",
                                            style: const TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Delete Button
                                    IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.red,
                                        size: 28,
                                      ),
                                      onPressed: () => cartSetQty(p.id, 0),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
              ),

              // Bottom Summary Section
              if (totalItems > 0)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    border: Border(
                      top: BorderSide(color: Colors.grey.shade300),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Items:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "$totalItems",
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Total Amount:",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            "₹${totalValue.toStringAsFixed(2)}",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
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
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          "Checkout",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        // Session expired, redirect to login
        currentSession = null;
        if (mounted) context.go('/login');
      } else {
        error = "Failed to load products";
      }
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
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.green.shade800, Colors.green.shade500],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Text(
                  "Favorites (${favoriteProducts.length})",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
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
                                            } on DioException catch (e) {
                                              if (e.response?.statusCode == 401 && mounted) {
                                                // Session expired, redirect to login
                                                currentSession = null;
                                                if (mounted) context.go('/login');
                                              } else if (mounted) {
                                                ScaffoldMessenger.of(
                                                  context,
                                                ).showSnackBar(
                                                  SnackBar(
                                                    content: Text("Error: $e"),
                                                  ),
                                                );
                                              }
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
