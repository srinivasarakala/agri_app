import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';

class SdCatalogPage extends StatefulWidget {
  const SdCatalogPage({super.key});

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
  final Map<int, int> cartQty = {};
  int get totalCartQty => cartQty.values.fold(0, (a, b) => a + b);

  void setQty(int productId, int newQty) {
    setState(() {
      if (newQty <= 0) {
        cartQty.remove(productId);
      } else {
        cartQty[productId] = newQty;
      }
    });
  }

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
    if (cartQty.isEmpty) return;

    try {
      // ✅ your endpoint is /api/orders/create inside OrdersService
      await ordersApi.createOrder(
        items: cartQty.entries
            .map((e) => {"product_id": e.key, "qty": e.value})
            .toList(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Order placed successfully")),
      );

      setState(() => cartQty.clear());
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
        final cartItems = all.where((p) => cartQty.containsKey(p.id)).toList();

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
                    final qty = cartQty[p.id] ?? 0;
                    return ListTile(
                      title: Text(p.name, maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text("₹${p.sellingPrice} • ${p.unit}"),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () => setQty(p.id, qty - 1),
                          ),
                          Text("$qty", style: const TextStyle(fontWeight: FontWeight.w800)),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setQty(p.id, qty + 1),
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
                              final qty = cartQty[p.id] ?? 0;

                              return ProductRow(
                                p: p,
                                qty: qty,
                                onMinus: () => setQty(p.id, qty - 1),
                                onPlus: () => setQty(p.id, qty + 1),
                                onQtyTextChanged: (v) => setQty(p.id, int.tryParse(v.trim()) ?? 0),
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
      bottomNavigationBar: totalCartQty == 0
          ? null
          : SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  boxShadow: [
                    BoxShadow(
                      blurRadius: 12,
                      color: Colors.black.withOpacity(0.08),
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "$totalCartQty item(s) in cart",
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: openCartSheet,
                      child: const Text("View Cart"),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      onPressed: placeOrder,
                      child: const Text("Place Order"),
                    ),
                  ],
                ),
              ),
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
                      SizedBox(
                        width: 64,
                        child: TextField(
                          textAlign: TextAlign.center,
                          keyboardType: TextInputType.number,
                          controller: TextEditingController(text: qty.toString()),
                          onChanged: onQtyTextChanged,
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
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
