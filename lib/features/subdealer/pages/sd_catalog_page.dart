import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';
import '../../../core/cart/cart_state.dart';


class SdCatalogPage extends StatefulWidget {
  final String initialQuery;
  const SdCatalogPage({super.key, this.initialQuery = ""});
  
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

  void _applyFilter() {
    final q = searchCtrl.text.trim().toLowerCase();
    shown = all.where((p) {
      if (q.isEmpty) return true;
      return p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q);
    }).toList();

    setState(() {});
  }

  Future<void> placeOrder() async {
    if (cartQty.value.isEmpty) return;

    try {
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to place order: $e")),
      );
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
        final cartItems = all.where((p) => cartQty.value.containsKey(p.id)).toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Cart", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
              const SizedBox(height: 12),
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: cartItems.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = cartItems[i];
                    final qty = cartQty.value[p.id] ?? 0;
                    return ListTile(
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text("₹${p.sellingPrice} • ${p.unit}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => cartSetQty(p.id, qty-1),
                          ),
                          Text("$qty", style: const TextStyle(fontWeight: FontWeight.w800)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => cartSetQty(p.id, qty+1),
                          ),
                        ],
                      ),
                    );
                  },
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
      searchCtrl.selection = TextSelection.fromPosition(TextPosition(offset: t.length));

      if (searchFocus.canRequestFocus) {
        FocusScope.of(context).requestFocus(searchFocus);
      }

      catalogSearchBus.consumeGoToCatalog();
      _applyFilter();
    };

    catalogSearchBus.addListener(_busListener!);

    // live filter while typing
    searchCtrl.addListener(_applyFilter);

    load();
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
    return Scaffold(
      appBar: AppBar(
        title: const Text("Catalog"),
        actions: [
          IconButton(
            tooltip: "Refresh",
            onPressed: load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
            child: TextField(
              controller: searchCtrl,
              focusNode: searchFocus,
              decoration: InputDecoration(
                hintText: "Search product…",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
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
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, i) {
                              final p = shown[i];
                              final qty = cartQty.value[p.id] ?? 0;

                              return ProductRow(
                                p: p,
                                qty: qty,
                                onMinus: () => cartSetQty(p.id, qty-1),
                                onPlus: () => cartSetQty(p.id, qty+1),
                                onQtyTextChanged: (v) => cartSetQty(p.id, int.tryParse(v.trim()) ?? 0),
                                onAddPressed: qty > 0
                                    ? () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text("Added $qty x ${p.name}")),
                                        );
                                      }
                                    : null,
                              );
                            },
                          ),
          ),
        ],
      ),

      // ✅ bottom cart bar
      bottomNavigationBar: ValueListenableBuilder<Map<int,int>>(
        valueListenable: cartQty,
        builder: (_, m, __) {
          final total = m.values.fold(0, (a,b) => a + b);
          if (total == 0) return const SizedBox.shrink();

          return SafeArea(
            child: Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(child: Text("$total item(s) in cart", style: const TextStyle(fontWeight: FontWeight.w800))),
                  ElevatedButton(onPressed: openCartSheet, child: const Text("View Cart")),
                  const SizedBox(width: 10),
                  ElevatedButton(onPressed: placeOrder, child: const Text("Place Order")),
                ],
              ),
            ),
          );
        },
      ),

    );
  }
}

class ProductRow extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final inStock = p.globalStock > 0;

    return Card(
      elevation: 0.8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // thumbnail
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 64,
                height: 64,
                child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                    ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                    : Container(
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.image, color: Colors.grey),
                      ),
              ),
            ),
            const SizedBox(width: 10),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "${p.sku} • ${p.unit}",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Text(
                        "₹${p.sellingPrice}",
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: inStock ? Colors.green.withOpacity(0.12) : Colors.red.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          inStock ? "In Stock" : "Out",
                          style: TextStyle(
                            color: inStock ? Colors.green.shade800 : Colors.red.shade800,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        "Stock: ${p.globalStock}",
                        style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                      ),
                    ],
                  ),

                  const SizedBox(height: 10),

                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: qty > 0 ? onMinus : null,
                      ),
                      Container(
                        width: 64,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text("$qty", style: const TextStyle(fontWeight: FontWeight.w800)),
                      ),

                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: onPlus,
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: qty > 0 ? onAddPressed : null,
                        child: const Text("Add"),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
