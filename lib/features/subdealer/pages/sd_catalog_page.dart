import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';
import '../../catalog/widgets/product_card.dart';

final FocusNode searchFocus = FocusNode();

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

  late final FocusNode searchFocus;
  VoidCallback? _busListener;


  final searchCtrl = TextEditingController();
  final Map<int, double> cart = {}; // productId -> qty

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      all = await catalogApi.listProducts();
      _applyFilter();
    } catch (e) {
      error = "Failed to load products: $e";
    } finally {
      setState(() { loading = false; });
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

  Future<void> addToCart(Product p) async {
    final ctrl = TextEditingController(text: "1");
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Add: ${p.name}"),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(labelText: "Qty (${p.unit})"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Add")),
        ],
      ),
    );
    if (ok != true) return;

    final qty = double.tryParse(ctrl.text.trim()) ?? 0;
    if (qty <= 0) return;

    setState(() {
      cart[p.id] = (cart[p.id] ?? 0) + qty;
    });
  }

  Future<void> submitOrder() async {
    if (cart.isEmpty) return;

    final noteCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Submit Order"),
        content: TextField(controller: noteCtrl, decoration: const InputDecoration(labelText: "Note (optional)")),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Submit")),
        ],
      ),
    );
    if (ok != true) return;

    final itemsPayload = cart.entries
        .map((e) => {"product_id": e.key, "qty": e.value})
        .toList();

    try {
      await ordersApi.createOrder(note: noteCtrl.text.trim(), items: itemsPayload);
      if (!mounted) return;
      setState(() => cart.clear());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Order placed")));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Order failed: $e")));
    }
  }

  @override
  void initState() {
    super.initState();

    searchFocus = FocusNode();

    _busListener = () {
      if (!mounted) return;
      if (!catalogSearchBus.goToCatalog) return;

      final t = catalogSearchBus.text;
      searchCtrl.text = t;
      searchCtrl.selection = TextSelection.fromPosition(
        TextPosition(offset: t.length),
      );

      if (searchFocus.canRequestFocus) {
        FocusScope.of(context).requestFocus(searchFocus);
      }

      catalogSearchBus.consumeGoToCatalog();
    };

    // ✅ add AFTER assignment
    catalogSearchBus.addListener(_busListener!);

    load();
  }



  @override
  void dispose() {
    if (_busListener != null) {
      catalogSearchBus.removeListener(_busListener!);
    }
    searchFocus.dispose();
    searchCtrl.dispose();
    super.dispose();
  }



  @override
  Widget build(BuildContext context) {
    final cartCount = cart.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Catalog"),
        actions: [
          TextButton(
            onPressed: cart.isEmpty ? null : submitOrder,
            child: Text(
              "Submit ($cartCount)",
              style: TextStyle(color: cart.isEmpty ? Colors.grey : Colors.white),
            ),
          )
        ],
      ),
      body: Column(
        children: [
          // Search (like your screenshot)
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
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          // Sort/Filter row (like screenshot)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                TextButton.icon(
                  onPressed: () {
                    // simple sort: stock desc
                    all.sort((a, b) => b.globalStock.compareTo(a.globalStock));
                    _applyFilter();
                  },
                  icon: const Icon(Icons.sort),
                  label: const Text("Sort"),
                ),
                const SizedBox(width: 8),
                TextButton.icon(
                  onPressed: () {
                    // simple filter: in-stock only toggle
                    setState(() {
                      all = all.where((p) => p.globalStock > 0).toList();
                      _applyFilter();
                    });
                  },
                  icon: const Icon(Icons.filter_alt),
                  label: const Text("Filter"),
                ),
                const Spacer(),
                IconButton(
                  tooltip: "Refresh",
                  onPressed: load,
                  icon: const Icon(Icons.refresh),
                )
              ],
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
                        : GridView.builder(
                            padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.70,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: shown.length,
                            itemBuilder: (context, i) {
                              final p = shown[i];
                              return ProductCard(
                                p: p,
                                onAdd: () => addToCart(p),
                                onTap: () => addToCart(p), // for now tap also adds
                              );
                            },
                          ),
          ),
        ],
      ),
    );
  }
}
