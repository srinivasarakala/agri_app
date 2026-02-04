import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/product.dart';
import 'package:image_picker/image_picker.dart';

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

    final created = await catalogApi.adminCreateProduct({
      "sku": sku.text.trim(),
      "name": name.text.trim(),
      "unit": "pcs",
      "mrp": double.tryParse(price.text) ?? 0,
      "selling_price": double.tryParse(price.text) ?? 0,
      "global_stock": double.tryParse(stock.text) ?? 0,
      "is_active": true,
    });

    // Ask to upload image now
    final uploadNow = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Upload image now?"),
        content: const Text("You can skip and upload later using the photo button."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text("Skip")),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text("Upload")),
        ],
      ),
    );

    if (uploadNow == true) {
      await pickAndUploadImage(created);
    }

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

  final picker = ImagePicker();

  Future<void> pickAndUploadImage(Product p) async {
    final x = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (x == null) return;

    final updated = await catalogApi.adminUploadProductImage(p.id, x.path);

    setState(() {
      final idx = items.indexWhere((e) => e.id == p.id);
      if (idx != -1) items[idx] = updated;
    });
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
                              leading: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 44,
                                  height: 44,
                                  child: (p.imageUrl != null && p.imageUrl!.isNotEmpty)
                                      ? Image.network(p.imageUrl!, fit: BoxFit.cover)
                                      : Container(color: Colors.grey.shade200, child: const Icon(Icons.image)),
                                ),
                              ),

                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // ✅ Upload image button
                                  IconButton(
                                    tooltip: "Upload image",
                                    icon: const Icon(Icons.photo),
                                    onPressed: () => pickAndUploadImage(p),
                                  ),

                                  const SizedBox(width: 6),

                                  Text("Stock: ${p.globalStock}"),
                                ],
                              ),

                              onTap: () => stockAdjust(p),
                            );

                    },
                  ),
                ),
    );
  }
}
