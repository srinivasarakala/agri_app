import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../main.dart';
import '../../catalog/product.dart';
import '../../catalog/category.dart';

class AdminProductsPage extends StatefulWidget {
  const AdminProductsPage({super.key});

  @override
  State<AdminProductsPage> createState() => _AdminProductsPageState();
}

class _AdminProductsPageState extends State<AdminProductsPage> {
  bool loading = true;
  String? error;
  List<Product> items = [];
  List<Category> categories = [];

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      items = await catalogApi.listProducts();
      categories = await catalogApi.listCategories();
    } catch (e) {
      error = "Failed to load data: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openProductForm({Product? product}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ProductFormSheet(
        product: product,
        categories: categories,
        onSave: load,
      ),
    );
  }

  Future<void> _deleteProduct(Product p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Product?'),
        content: Text('Permanently delete "${p.name}"? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await catalogApi.adminDeleteProduct(p.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product deleted')),
      );
      load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: load,
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final p = items[i];
                      return ListTile(
                        leading: p.imageUrl != null && p.imageUrl!.isNotEmpty
                            ? Image.network(
                                p.imageUrl!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.image),
                              )
                            : const Icon(Icons.image),
                        title: Text(p.name),
                        subtitle: Text(
                          '${p.sku} • ₹${p.sellingPrice.toStringAsFixed(2)} • Stock: ${p.globalStock.toStringAsFixed(2)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => _openProductForm(product: p),
                            ),
                            IconButton(
                              icon:
                                  const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteProduct(p),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openProductForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class ProductFormSheet extends StatefulWidget {
  final Product? product;
  final List<Category> categories;
  final VoidCallback onSave;

  const ProductFormSheet({
    super.key,
    this.product,
    required this.categories,
    required this.onSave,
  });

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  late TextEditingController skuCtrl;
  late TextEditingController nameCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController brandCtrl;
  late TextEditingController unitCtrl;
  late TextEditingController mrpCtrl;
  late TextEditingController priceCtrl;
  late TextEditingController stockCtrl;
  late TextEditingController minQtyCtrl;
  late TextEditingController imageUrlCtrl;

  Category? selectedCategory;
  bool isActive = true;
  bool saving = false;
  XFile? pickedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    skuCtrl = TextEditingController(text: widget.product?.sku ?? '');
    nameCtrl = TextEditingController(text: widget.product?.name ?? '');
    descriptionCtrl =
        TextEditingController(text: widget.product?.description ?? '');
    brandCtrl = TextEditingController(text: widget.product?.brand ?? '');
    unitCtrl = TextEditingController(text: widget.product?.unit ?? 'pcs');
    mrpCtrl = TextEditingController(
        text: widget.product?.mrp.toStringAsFixed(2) ?? '');
    priceCtrl = TextEditingController(
        text: widget.product?.sellingPrice.toStringAsFixed(2) ?? '');
    stockCtrl = TextEditingController(
        text: widget.product?.globalStock.toStringAsFixed(2) ?? '');
    minQtyCtrl = TextEditingController(
        text: widget.product?.minQty.toStringAsFixed(0) ?? '1');
    imageUrlCtrl = TextEditingController(text: widget.product?.imageUrl ?? '');
    isActive = widget.product?.isActive ?? true;

    if (widget.categories.isNotEmpty) {
      selectedCategory = widget.categories.first;
    }
  }

  @override
  void dispose() {
    skuCtrl.dispose();
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    brandCtrl.dispose();
    unitCtrl.dispose();
    mrpCtrl.dispose();
    priceCtrl.dispose();
    stockCtrl.dispose();
    minQtyCtrl.dispose();
    imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (image != null) {
        setState(() => pickedImage = image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error picking image: $e')),
      );
    }
  }

  Future<void> _save() async {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and Price required')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final payload = {
        'sku': skuCtrl.text.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : skuCtrl.text,
        'name': nameCtrl.text,
        'description': descriptionCtrl.text,
        'brand': brandCtrl.text.isEmpty ? null : brandCtrl.text,
        'unit': unitCtrl.text,
        'mrp': double.tryParse(mrpCtrl.text) ?? 0,
        'selling_price': double.tryParse(priceCtrl.text) ?? 0,
        'global_stock': double.tryParse(stockCtrl.text) ?? 0,
        'min_qty': int.tryParse(minQtyCtrl.text) ?? 1,
        'is_active': isActive,
        'image_url': imageUrlCtrl.text.isEmpty ? null : imageUrlCtrl.text,
        'category': selectedCategory?.id,
      };

      Product createdOrUpdatedProduct;
      if (widget.product == null) {
        createdOrUpdatedProduct = await catalogApi.adminCreateProduct(payload);
      } else {
        createdOrUpdatedProduct = await catalogApi.adminUpdateProduct(widget.product!.id, payload);
      }

      // Upload image if one was picked
      if (pickedImage != null) {
        await catalogApi.adminUploadProductImage(
          createdOrUpdatedProduct.id,
          pickedImage!.path,
        );
      }

      if (!mounted) return;
      Navigator.pop(context);
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 16,
        right: 16,
        top: 16,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.product == null ? 'Add Product' : 'Edit Product',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Product Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: skuCtrl,
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      hintText: 'Auto if empty',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: brandCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: unitCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: DropdownButtonFormField<Category>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.categories
                        .map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c.name),
                            ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => selectedCategory = v ?? selectedCategory),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: mrpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'MRP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Selling Price *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: stockCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Stock Quantity',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: minQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Quantity',
                      hintText: '1',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Image picker section
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Product Image',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  if (pickedImage != null) ...[
                    Image.file(
                      File(pickedImage!.path),
                      height: 150,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton.icon(
                          onPressed: _pickImage,
                          icon: const Icon(Icons.change_circle),
                          label: const Text('Change Image'),
                        ),
                        TextButton.icon(
                          onPressed: () => setState(() => pickedImage = null),
                          icon: const Icon(Icons.delete, color: Colors.red),
                          label: const Text('Remove', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  ] else if (widget.product?.imageUrl != null && widget.product!.imageUrl!.isNotEmpty) ...[
                    Image.network(
                      widget.product!.imageUrl!,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 50),
                    ),
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Change Image'),
                    ),
                  ] else ...[
                    OutlinedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Pick Image from Gallery'),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            CheckboxListTile(
              title: const Text('Active'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v ?? true),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: saving ? null : _save,
              icon: saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.save),
              label: Text(
                widget.product == null ? 'Create Product' : 'Update Product',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

