import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:pavan_agro/core/theme/app_theme.dart';
import '../home/home_page.dart';
import '../menu/menu_page.dart';
import '../../core/cart/cart_state.dart';
import '../catalog/product.dart';
import '../catalog/widgets/product_detail_dialog.dart';
import '../../main.dart'; // for catalogApi
import '../orders/checkout_page.dart';
import 'categories_nav_page.dart';
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
    if (currentSession?.phone != null) {
      try {
        await loadUserCart(currentSession!.phone!);
      } catch (e) {
      }
    } else {
    }
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomePage(role: widget.role), // 0 Home
      CategoriesNavPage(), // 1 Categories (moved up)
      const _CartPage(), // 2 Cart
      MenuPage(role: widget.role), // 3 Menu (role menus + logout)
      // SdCatalogPage(), // 4 Products (hidden, switched to programmatically)
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

            return PopScope(
              canPop: false,
              onPopInvokedWithResult: (didPop, _) async {
                if (didPop) return;
                // If not on Home tab, navigate back to Home
                if (index != 0) {
                  appTabIndex.value = 0;
                  return;
                }
                // On Home tab — ask exit confirmation
                final shouldExit = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Exit App'),
                    content: const Text('Are you sure you want to exit?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(ctx).pop(true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Exit'),
                      ),
                    ],
                  ),
                );
                if (shouldExit == true) exit(0);
              },
              child: Scaffold(
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
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.category),
                    label: "Spare Parts",
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
                    icon: Icon(Icons.menu),
                    label: "Menu",
                  ),
                ],
              ),
            ),  // end Scaffold
            );  // end PopScope
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
      final allProducts = await catalogApi.listProducts();
      // Show all products in cart (including spare parts)
      all = allProducts;
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
          body: CustomScrollView(
            slivers: [
              // Sticky Top Banner with Title
              SliverAppBar(
                pinned: true,
                floating: false,
                backgroundColor: AppTheme.backgroundColor,
                elevation: 0,
                toolbarHeight: 100, // Adjusted height for banner (55) + title (45)
                automaticallyImplyLeading: false,
                flexibleSpace: SafeArea(
                  child: Container(
                    color: AppTheme.backgroundColor,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          height: 55,
                          alignment: Alignment.center,
                          child: FractionallySizedBox(
                            widthFactor: 0.5,
                            child: Image.asset(
                              'assets/images/top_banner.png',
                              height: 55,
                              fit: BoxFit.contain,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        // Header
                        Container(
                          height: 45,
                          alignment: Alignment.center,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Cart Items List
              SliverFillRemaining(
                child: Column(
                  children: [
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
                                            ? CachedNetworkImage(
                                                imageUrl: p.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorWidget:
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
              ),
            ],
          ),
        );
      },
    );
  }
}

