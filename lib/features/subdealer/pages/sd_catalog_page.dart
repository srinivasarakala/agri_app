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
  List<Product> items = [];

  // cart: productId -> qty
  final Map<int, double> cart = {};

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await catalogApi.listProducts();
    } catch (e) {
      error = "Failed to load products: $e";
    } finally {
      setState(() { loading = false; });
    }
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
        content: TextField(
          controller: noteCtrl,
          decoration: const InputDecoration(labelText: "Note (optional)"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Submit")),
        ],
      ),
    );
    if (ok != true) return;

    final payloadItems = cart.entries
        .map((e) => {"product_id": e.key, "qty": e.value})
        .toList();

    try {
      await ordersApi.createOrder(note: noteCtrl.text.trim(), items: payloadItems);
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
    load();
  }

  @override
  Widget build(BuildContext context) {
    final cartCount = cart.length;

    return Scaffold(
      appBar: AppBar(
        actions: [
          TextButton(
            onPressed: cart.isEmpty ? null : submitOrder,
            child: Text(
              "Submit ($cartCount)",
              style: TextStyle(color: cart.isEmpty ? Colors.grey : Colors.white),
            ),
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!))
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final p = items[i];
                      final inCart = cart[p.id] ?? 0;
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text("${p.sku} • ${p.unit} • ₹${p.sellingPrice}"),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text("Stock: ${p.globalStock}"),
                            if (inCart > 0) Text("Cart: $inCart"),
                          ],
                        ),
                        onTap: () => addToCart(p),
                      );
                    },
                  ),
                ),
    );
  }
}
