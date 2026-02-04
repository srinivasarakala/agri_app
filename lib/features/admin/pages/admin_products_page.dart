import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  bool loading = true;
  String? error;
  List<Product> items = [];

  Future<void> load() async {
    setState(() { loading = true; error = null; });
    try {
      items = await catalogApi.listProducts();
    } catch (e) {
      error = "Failed to load products";
    } finally {
      setState(() { loading = false; });
    }
  }

  Future<void> addProductDialog() async {
    final sku = TextEditingController();
    final name = TextEditingController();
    final price = TextEditingController(text: "0");
    final stock = TextEditingController(text: "0");

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Product"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: sku, decoration: const InputDecoration(labelText: "SKU")),
            TextField(controller: name, decoration: const InputDecoration(labelText: "Name")),
            TextField(controller: price, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Selling Price")),
            TextField(controller: stock, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Global Stock")),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Save")),
        ],
      ),
    );

    if (ok != true) return;

    await catalogApi.adminCreateProduct({
      "sku": sku.text.trim(),
      "name": name.text.trim(),
      "unit": "pcs",
      "mrp": double.tryParse(price.text) ?? 0,
      "selling_price": double.tryParse(price.text) ?? 0,
      "global_stock": double.tryParse(stock.text) ?? 0,
      "is_active": true,
    });

    await load();
  }

  Future<void> stockAdjust(Product p) async {
    final deltaCtrl = TextEditingController(text: "0");
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("Adjust Stock: ${p.sku}"),
        content: TextField(
          controller: deltaCtrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: "Delta (use - to reduce)",
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Cancel")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Apply")),
        ],
      ),
    );
    if (ok != true) return;

    final delta = double.tryParse(deltaCtrl.text.trim()) ?? 0;
    await catalogApi.adminStockAdjust(p.id, delta);
    await load();
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: addProductDialog,
          )
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
                      return ListTile(
                        title: Text(p.name),
                        subtitle: Text("${p.sku} • ₹${p.sellingPrice}"),
                        trailing: Text("Stock: ${p.globalStock}"),
                        onTap: () => stockAdjust(p),
                      );
                    },
                  ),
                ),
    );
  }
}
