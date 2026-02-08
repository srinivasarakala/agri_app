import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';
import '../../../core/cart/cart_state.dart';
import '../../shell/app_shell.dart';
import '../../../core/utils/profile_validator.dart';

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

  // ✅ cart: productId -> qty (int)

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      all = await catalogApi.listProducts();
      _applyFilter();
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

      // Filter by category if provided
      if (widget.categoryId != null && p.categoryId != widget.categoryId) {
        return false;
      }

      // Filter by tag if provided
      if (widget.tag != null && widget.tag!.isNotEmpty) {
        if (p.tags == null ||
            !p.tags!.toLowerCase().contains(widget.tag!.toLowerCase())) {
          return false;
        }
      }

      return true;
    }).toList();

    setState(() {});
  }

  Future<void> placeOrder() async {
    if (cartQty.value.isEmpty) return;

    try {
      // Check profile completeness before placing order
      final profile = await profileApi.getProfile();

      if (!ProfileValidator.isProfileComplete(profile)) {
        final missing = ProfileValidator.getMissingFields(profile);
        if (mounted) {
          ProfileValidator.showIncompleteProfileDialog(context, missing);
        }
        return;
      }

      // Profile is complete, proceed with order
      final items = cartQty.value.entries
          .map((e) => {"product_id": e.key, "qty": e.value})
          .toList();

      await ordersApi.createOrder(items: items);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully")),
      );

      cartClear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Failed to place order: $e")));
    }
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

    // ✅ bus listener: tap search on home -> open catalog + focus
    _busListener = () {
      if (!mounted) return;
      if (!catalogSearchBus.goToCatalog) return;

      final t = catalogSearchBus.text;
      searchCtrl.text = t;
      searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: t.length),
      );

      // Use post frame callback to ensure widgets are built
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && searchFocus.canRequestFocus) {
          FocusScope.of(context).requestFocus(searchFocus);
        }
      });

      catalogSearchBus.consumeGoToCatalog();
      _applyFilter();
    };

    catalogSearchBus.addListener(_busListener!);

    // live filter while typing
    searchCtrl.addListener(_applyFilter);

    load();
    _loadFavorites();

    // Auto-focus search bar when page opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && searchFocus.canRequestFocus) {
        FocusScope.of(context).requestFocus(searchFocus);
      }
    });
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
    return ValueListenableBuilder<Map<int, int>>(
      valueListenable: cartQty,
      builder: (_, cartMap, __) {
        final cartCount = cartMap.values.fold<int>(0, (a, b) => a + b);

        return Stack(
          children: [
            Column(
              children: [
                // Green banner with search bar overlay
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    // Green banner background
                    Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade800,
                            Colors.green.shade500,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                    // Search bar with back button overlay
                    Positioned(
                      bottom: 16,
                      left: 12,
                      right: 12,
                      child: SafeArea(
                        bottom: false,
                        child: Row(
                          children: [
                            // Back button (only show if page can be popped)
                            if (Navigator.canPop(context))
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back),
                                  onPressed: () => Navigator.pop(context),
                                  padding: const EdgeInsets.all(8),
                                ),
                              ),
                            if (Navigator.canPop(context))
                              const SizedBox(width: 8),
                            // Search bar
                            Expanded(
                              child: TextField(
                                controller: searchCtrl,
                                focusNode: searchFocus,
                                decoration: InputDecoration(
                                  hintText: "Search product…",
                                  prefixIcon: const Icon(Icons.search),
                                  filled: true,
                                  fillColor: Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

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
            ),

            // Floating Cart Button
            if (cartCount > 0)
              Positioned(
                bottom: 20,
                right: 20,
                child: Builder(
                  builder: (context) {
                    // Calculate cart total value
                    double cartTotal = 0;
                    for (var entry in cartMap.entries) {
                      final product = all.firstWhere(
                        (p) => p.id == entry.key,
                        orElse: () => all.first,
                      );
                      cartTotal += product.sellingPrice * entry.value;
                    }

                    return FloatingActionButton.extended(
                      onPressed: () {
                        // Check if this page was pushed (has a route to pop)
                        if (Navigator.canPop(context)) {
                          // Pop the catalog page first, then navigate to cart
                          Navigator.pop(context);
                          // Use Future.microtask to ensure pop completes before changing tab
                          Future.microtask(() => appTabIndex.value = 1);
                        } else {
                          // We're in a tab view, just change the tab
                          appTabIndex.value = 1;
                        }
                      },
                      backgroundColor: Colors.green,
                      icon: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          const Icon(Icons.shopping_cart, color: Colors.white),
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  cartCount > 99 ? "99+" : cartCount.toString(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      label: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "View Cart",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            "₹${cartTotal.toStringAsFixed(2)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        );
      },
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

        return Card(
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
                                        borderRadius: BorderRadius.circular(8),
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
                                    contentPadding: const EdgeInsets.symmetric(
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
                                        borderRadius: BorderRadius.circular(8),
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
                              padding: const EdgeInsets.symmetric(vertical: 10),
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
        );
      },
    );
  }
}
