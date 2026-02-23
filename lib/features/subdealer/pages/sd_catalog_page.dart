import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';
import '../../catalog/product_details_page.dart';
import '../../../core/cart/cart_state.dart';
import '../../shell/app_shell.dart';
import '../../orders/checkout_page.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';

class SdCatalogPage extends StatefulWidget {
  final String initialQuery;
  final int? categoryId;
  final String? tag;

  const SdCatalogPage({
    super.key,
    this.initialQuery = "",
    this.categoryId,
    this.tag,
  });

  @override
  State<SdCatalogPage> createState() => _SdCatalogPageState();
}

class _SdCatalogPageState extends State<SdCatalogPage> {
  bool loading = true;
  String? error;

  List<Product> all = [];
  List<Product> shown = [];

  final searchCtrl = TextEditingController();
  late final FocusNode searchFocus;

  VoidCallback? _busListener;

  // Active filters that can be set by widget params or catalog search bus
  int? _activeCategoryId;
  String? _activeTag;

  // ✅ cart: productId -> qty (int)

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      all = await catalogApi.listProducts();
      _applyFilter();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        // Session expired, redirect to login
        currentSession = null;
        if (mounted) context.go('/login');
      } else {
        error = "Failed to load products: $e";
      }
    } catch (e) {
      error = "Failed to load products: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadFavorites() async {
    try {
      final favIds = await catalogApi.getFavorites();
      setFavorites(favIds);
    } catch (e) {
      // Silent fail, favorites aren't critical
    }
  }

  void _applyFilter() {
    final q = searchCtrl.text.trim().toLowerCase();
    shown = all.where((p) {
      // Filter by search query
      if (q.isNotEmpty) {
        if (!p.name.toLowerCase().contains(q) &&
            !p.sku.toLowerCase().contains(q)) {
          return false;
        }
      }

      // Filter by category if active
      if (_activeCategoryId != null && p.categoryId != _activeCategoryId) {
        return false;
      }

      // Filter by tag if active
      if (_activeTag != null && _activeTag!.isNotEmpty) {
        if (p.tags == null ||
            !p.tags!.toLowerCase().contains(_activeTag!.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();

    setState(() {});
  }

  Future<void> placeOrder() async {
    if (cartQty.value.isEmpty) return;

    // Navigate to checkout page
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CheckoutPage()),
    );
  }

  void openCartSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) {
        return ValueListenableBuilder<Map<int, int>>(
          valueListenable: cartQty,
          builder: (context, cartMap, __) {
            final cartItems = all
                .where((p) => cartMap.containsKey(p.id))
                .toList();
            final total = cartItems.fold<double>(0, (sum, p) {
              final qty = cartMap[p.id] ?? 0;
              return sum + (p.sellingPrice * qty);
            });

            if (cartItems.isEmpty) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(
                  child: Text("Cart is empty", style: TextStyle(fontSize: 16)),
                ),
              );
            }

            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Cart",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "${cartItems.length} item(s)",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: cartItems.length,
                      itemBuilder: (_, i) {
                        final p = cartItems[i];
                        final currentQty = cartMap[p.id] ?? 0;
                        final minQty = p.minQty.toInt();

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 4,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        p.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "₹${p.sellingPrice} × $currentQty = ₹${(p.sellingPrice * currentQty).toStringAsFixed(2)}",
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                      if (minQty > 1) ...[
                                        const SizedBox(height: 4),
                                        Text(
                                          "Min Qty: $minQty",
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.orange.shade700,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                                Column(
                                  children: [
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(
                                            Icons.remove_circle_outline,
                                            size: 20,
                                          ),
                                          onPressed: currentQty > 0
                                              ? () {
                                                  final newQty =
                                                      currentQty - minQty;
                                                  if (newQty <= 0) {
                                                    cartSetQty(p.id, 0);
                                                  } else {
                                                    cartSetQty(p.id, newQty);
                                                  }
                                                }
                                              : null,
                                        ),
                                        Text(
                                          "$currentQty",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                        IconButton(
                                          icon: const Icon(
                                            Icons.add_circle_outline,
                                            size: 20,
                                          ),
                                          onPressed: () {
                                            cartSetQty(
                                              p.id,
                                              currentQty + minQty,
                                            );
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const Divider(height: 24, thickness: 2),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Total:",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "₹${total.toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        await placeOrder();
                      },
                      child: const Text("Place Order"),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();

    searchFocus = FocusNode();
    searchCtrl.text = widget.initialQuery;
    
    // Initialize active filters from widget parameters
    _activeCategoryId = widget.categoryId;
    _activeTag = widget.tag;

    // ✅ bus listener: tap search/category on home -> switch to catalog tab + apply filter
    _busListener = () {
      if (!mounted) return;
      if (!catalogSearchBus.goToCatalog) return;

      final t = catalogSearchBus.text;
      final catId = catalogSearchBus.categoryId;
      final tag = catalogSearchBus.tag;
      
      // Update search text
      searchCtrl.text = t;
      searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: t.length),
      );
      
      // Update active filters
      _activeCategoryId = catId;
      _activeTag = tag;

      // Focus search bar only if text search was triggered
      if (t.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && searchFocus.canRequestFocus) {
            FocusScope.of(context).requestFocus(searchFocus);
          }
        });
      }

      catalogSearchBus.consumeGoToCatalog();
      
      // Only apply filter if products are already loaded
      if (all.isNotEmpty) {
        _applyFilter();
      }
    };

    catalogSearchBus.addListener(_busListener!);

    // live filter while typing
    searchCtrl.addListener(_applyFilter);

    load();
    _loadFavorites();
  }

  @override
  void dispose() {
    if (_busListener != null) catalogSearchBus.removeListener(_busListener!);
    searchCtrl.removeListener(_applyFilter);
    searchFocus.dispose();
    searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: (Navigator.canPop(context) || appTabIndex.value == 4)
              ? IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      // Return to home tab in AppShell
                      appTabIndex.value = 0;
                    }
                  },
                )
              : null,
          title: const Text(
            'Products',
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        body: ValueListenableBuilder<Map<int, int>>(
          valueListenable: cartQty,
          builder: (_, cartMap, __) {
            return Column(
              children: [
                Expanded(
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : error != null
                      ? Center(child: Text(error!))
                      : shown.isEmpty
                      ? const Center(child: Text("No products"))
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                          itemCount: shown.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 8),
                          itemBuilder: (context, i) {
                            final p = shown[i];
                            final qty = cartMap[p.id] ?? 0;
                            final minQty = p.minQty.toInt();

                            return ProductRow(
                              p: p,
                              qty: qty,
                              onMinus: () {
                                final newQty = qty - minQty;
                                cartSetQty(p.id, newQty < minQty ? 0 : newQty);
                              },
                              onPlus: () => cartSetQty(
                                p.id,
                                qty == 0 ? minQty : qty + minQty,
                              ),
                              onQtyTextChanged: (v) {
                                final enteredQty = int.tryParse(v.trim()) ?? 0;
                                if (enteredQty == 0) {
                                  cartSetQty(p.id, 0);
                                } else if (enteredQty < minQty) {
                                  cartSetQty(p.id, minQty);
                                } else {
                                  // Round to nearest multiple of minQty
                                  final rounded =
                                      (enteredQty / minQty).round() * minQty;
                                  cartSetQty(p.id, rounded);
                                }
                              },
                              onAddPressed: qty > 0
                                  ? () {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            "✓ Added $qty × ${p.name}",
                                          ),
                                        ),
                                      );
                                    }
                                  : null,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ProductRow extends StatefulWidget {
  final Product p;
  final int qty;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<String> onQtyTextChanged;
  final VoidCallback? onAddPressed;

  const ProductRow({
    super.key,
    required this.p,
    required this.qty,
    required this.onMinus,
    required this.onPlus,
    required this.onQtyTextChanged,
    this.onAddPressed,
  });

  @override
  State<ProductRow> createState() => _ProductRowState();
}

class _ProductRowState extends State<ProductRow> {
  late TextEditingController qtyController;

  @override
  void initState() {
    super.initState();
    qtyController = TextEditingController(text: widget.qty.toString());
  }

  @override
  void didUpdateWidget(ProductRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.qty != widget.qty) {
      qtyController.text = widget.qty.toString();
    }
  }

  @override
  void dispose() {
    qtyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final inStock = widget.p.globalStock > 0;

    return ValueListenableBuilder<Set<int>>(
      valueListenable: favorites,
      builder: (_, favSet, __) {
        final isFav = favSet.contains(widget.p.id);

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailsPage(product: widget.p),
              ),
            );
          },
          child: Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  // Top row with image on left, details on right
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Image (left side - larger)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: 120,
                          height: 140,
                          color: Colors.grey.shade100,
                          child:
                              (widget.p.imageUrl != null &&
                                  widget.p.imageUrl!.isNotEmpty)
                              ? Image.network(
                                  widget.p.imageUrl!,
                                  fit: BoxFit.cover,
                                )
                              : const Icon(
                                  Icons.image,
                                  color: Colors.grey,
                                  size: 40,
                                ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Details (right side)
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Product name
                            Text(
                              widget.p.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // In Stock label
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: inStock
                                    ? Colors.green.withValues(alpha: 0.12)
                                    : Colors.red.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                inStock ? "In Stock" : "Out of Stock",
                                style: TextStyle(
                                  color: inStock
                                      ? Colors.green.shade800
                                      : Colors.red.shade800,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Brand
                            if (widget.p.brand != null &&
                                widget.p.brand!.isNotEmpty)
                              Text(
                                "Brand: ${widget.p.brand}",
                                style: TextStyle(
                                  color: Colors.grey.shade700,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),

                            // Description (short)
                            if (widget.p.description != null &&
                                widget.p.description!.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  widget.p.description!,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            const SizedBox(height: 8),

                            // Price
                            Row(
                              children: [
                                Text(
                                  "₹${widget.p.sellingPrice.toStringAsFixed(2)}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.green,
                                  ),
                                ),
                                if (widget.p.mrp > widget.p.sellingPrice) ...[
                                  const SizedBox(width: 8),
                                  Text(
                                    "₹${widget.p.mrp.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Minimum quantity
                            if (widget.p.minQty > 1)
                              Text(
                                "Min Qty: ${widget.p.minQty.toInt()} ${widget.p.unit}",
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                          ],
                        ),
                      ),

                      // Favourite button
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          IconButton(
                            icon: Icon(
                              isFav ? Icons.favorite : Icons.favorite_outline,
                              color: isFav ? Colors.red : Colors.grey,
                              size: 22,
                            ),
                            onPressed: () async {
                              try {
                                await catalogApi.toggleFavorite(widget.p.id);
                                toggleFavorite(widget.p.id);
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      isFav
                                          ? "Removed from favorites"
                                          : "Added to favorites",
                                    ),
                                    duration: const Duration(seconds: 1),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Error: $e")),
                                );
                              }
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(
                              minWidth: 40,
                              minHeight: 40,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  const Divider(height: 1),
                  const SizedBox(height: 12),

                  // Bottom row with quantity, add to cart
                  Row(
                    children: [
                      // Quantity selection
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Qty (${widget.p.unit})",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: widget.qty > 0
                                          ? widget.onMinus
                                          : null,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.remove,
                                          size: 18,
                                          color: widget.qty > 0
                                              ? Colors.grey.shade700
                                              : Colors.grey.shade300,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 50,
                                  child: TextField(
                                    controller: qtyController,
                                    onChanged: (value) {
                                      widget.onQtyTextChanged(value);
                                    },
                                    keyboardType: TextInputType.number,
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            vertical: 8,
                                          ),
                                    ),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: widget.onPlus,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        height: 36,
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: Colors.grey.shade300,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 12),

                      // Add to cart button
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              "Action",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            ElevatedButton(
                              onPressed: widget.qty > 0
                                  ? widget.onAddPressed
                                  : null,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                ),
                                backgroundColor: Colors.green,
                                disabledBackgroundColor: Colors.grey.shade300,
                              ),
                              child: const Text(
                                "Add to Cart",
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
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
    );
  }
}
