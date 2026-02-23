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
  List<Product> filteredItems = [];
  List<Category> categories = [];
  
  // Selection mode
  bool isSelectionMode = false;
  Set<int> selectedProductIds = {};

  final searchCtrl = TextEditingController();
  String? selectedBrand;
  int? selectedCategoryId;
  String selectedStockFilter = 'All'; // All, In Stock, Low Stock, Out of Stock

  @override
  void initState() {
    super.initState();
    load();
    searchCtrl.addListener(_applySearch);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> load() async {
    setState(() {
      loading = true;
      error = null;
      isSelectionMode = false;
      selectedProductIds.clear();
    });
    try {
      items = await catalogApi.listProducts();
      categories = await catalogApi.listCategories();
      filteredItems = items;
    } catch (e) {
      error = "Failed to load data: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  void _applySearch() {
    final query = searchCtrl.text.toLowerCase();
    setState(() {
      filteredItems = items.where((p) {
        // Search filter
        if (query.isNotEmpty) {
          if (!p.name.toLowerCase().contains(query) &&
              !p.sku.toLowerCase().contains(query)) {
            return false;
          }
        }

        // Brand filter
        if (selectedBrand != null && p.brand != selectedBrand) {
          return false;
        }

        // Category filter
        if (selectedCategoryId != null && p.categoryId != selectedCategoryId) {
          return false;
        }

        // Stock filter
        if (selectedStockFilter == 'In Stock' && p.globalStock <= 0) {
          return false;
        } else if (selectedStockFilter == 'Low Stock' &&
            (p.globalStock <= 0 || p.globalStock > 10)) {
          return false;
        } else if (selectedStockFilter == 'Out of Stock' && p.globalStock > 0) {
          return false;
        }

        return true;
      }).toList();
    });
  }

  List<String> _getUniqueBrands() {
    final brands = items
        .where((p) => p.brand != null && p.brand!.isNotEmpty)
        .map((p) => p.brand!)
        .toSet()
        .toList();
    brands.sort();
    return brands;
  }

  void _clearFilters() {
    setState(() {
      searchCtrl.clear();
      selectedBrand = null;
      selectedCategoryId = null;
      selectedStockFilter = 'All';
    });
    _applySearch();
  }

  void _toggleSelectionMode() {
    setState(() {
      isSelectionMode = !isSelectionMode;
      if (!isSelectionMode) {
        selectedProductIds.clear();
      }
    });
  }

  void _toggleProductSelection(int productId) {
    setState(() {
      if (selectedProductIds.contains(productId)) {
        selectedProductIds.remove(productId);
      } else {
        selectedProductIds.add(productId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (selectedProductIds.length == filteredItems.length) {
        selectedProductIds.clear();
      } else {
        selectedProductIds = filteredItems.map((p) => p.id).toSet();
      }
    });
  }

  Future<void> _deleteSelectedProducts() async {
    if (selectedProductIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Products?'),
        content: Text(
          'Permanently delete ${selectedProductIds.length} product(s)? This cannot be undone.',
        ),
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

    setState(() => loading = true);

    try {
      // Delete each selected product
      for (final productId in selectedProductIds) {
        await catalogApi.adminDeleteProduct(productId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedProductIds.length} product(s) deleted'),
        ),
      );

      setState(() {
        selectedProductIds.clear();
        isSelectionMode = false;
      });

      load();
    } catch (e) {
      setState(() => loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Product deleted')));
      load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isSelectionMode
              ? '${selectedProductIds.length} selected'
              : 'Manage Products${filteredItems.isNotEmpty ? " (${filteredItems.length})" : ""}',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        leading: isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _toggleSelectionMode,
              )
            : null,
        actions: [
          if (isSelectionMode) ...[
            IconButton(
              icon: Icon(
                selectedProductIds.length == filteredItems.length
                    ? Icons.check_box
                    : Icons.check_box_outline_blank,
              ),
              onPressed: _selectAll,
              tooltip: 'Select All',
            ),
          ] else ...[
            IconButton(
              icon: const Icon(Icons.checklist),
              onPressed: _toggleSelectionMode,
              tooltip: 'Select Items',
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: load,
            ),
          ],
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: load, child: const Text('Retry')),
                ],
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search by name or SKU...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => searchCtrl.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                // Quick Filters
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        // Brand Filter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String?>(
                            value: selectedBrand,
                            hint: const Text('Brand'),
                            underline: const SizedBox(),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Brands'),
                              ),
                              ..._getUniqueBrands().map(
                                (brand) => DropdownMenuItem(
                                  value: brand,
                                  child: Text(brand),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => selectedBrand = value);
                              _applySearch();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Category Filter
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<int?>(
                            value: selectedCategoryId,
                            hint: const Text('Category'),
                            underline: const SizedBox(),
                            items: [
                              const DropdownMenuItem(
                                value: null,
                                child: Text('All Categories'),
                              ),
                              ...categories.map(
                                (cat) => DropdownMenuItem(
                                  value: cat.id,
                                  child: Text(cat.name),
                                ),
                              ),
                            ],
                            onChanged: (value) {
                              setState(() => selectedCategoryId = value);
                              _applySearch();
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Stock Status Filter
                        ...['All', 'In Stock', 'Low Stock', 'Out of Stock'].map(
                          (status) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(status),
                              selected: selectedStockFilter == status,
                              onSelected: (selected) {
                                setState(() => selectedStockFilter = status);
                                _applySearch();
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Clear Filters Button
                        if (selectedBrand != null ||
                            selectedCategoryId != null ||
                            selectedStockFilter != 'All' ||
                            searchCtrl.text.isNotEmpty)
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all, size: 18),
                            label: const Text('Clear'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.red,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: load,
                    child: filteredItems.isEmpty
                        ? Center(
                            child: Text(
                              searchCtrl.text.isEmpty
                                  ? 'No products'
                                  : 'No products match search',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, i) {
                              final p = filteredItems[i];
                              final isSelected = selectedProductIds.contains(p.id);

                              return ListTile(
                                leading: isSelectionMode
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleProductSelection(p.id),
                                      )
                                    : (p.imageUrl != null &&
                                            p.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            p.imageUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.image),
                                          )
                                        : const Icon(Icons.image)),
                                title: Text(p.name),
                                subtitle: Text(
                                  '${p.sku} • ₹${p.sellingPrice.toStringAsFixed(2)} • Stock: ${p.globalStock.toStringAsFixed(2)}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: isSelectionMode
                                    ? null
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.edit),
                                            onPressed: () =>
                                                _openProductForm(product: p),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteProduct(p),
                                          ),
                                        ],
                                      ),
                                onTap: isSelectionMode
                                    ? () => _toggleProductSelection(p.id)
                                    : null,
                              );
                            },
                          ),
                  ),
                ),
              ],
            ),
      floatingActionButton: isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _openProductForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Product'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: isSelectionMode && selectedProductIds.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${selectedProductIds.length} item(s) selected',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _deleteSelectedProducts,
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
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
    descriptionCtrl = TextEditingController(
      text: widget.product?.description ?? '',
    );
    brandCtrl = TextEditingController(text: widget.product?.brand ?? '');
    unitCtrl = TextEditingController(text: widget.product?.unit ?? 'pcs');
    mrpCtrl = TextEditingController(
      text: widget.product?.mrp.toStringAsFixed(2) ?? '',
    );
    priceCtrl = TextEditingController(
      text: widget.product?.sellingPrice.toStringAsFixed(2) ?? '',
    );
    stockCtrl = TextEditingController(
      text: widget.product?.globalStock.toStringAsFixed(2) ?? '',
    );
    minQtyCtrl = TextEditingController(
      text: widget.product?.minQty.toStringAsFixed(0) ?? '1',
    );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }

  Future<void> _save() async {
    if (nameCtrl.text.isEmpty || priceCtrl.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Name and Price required')));
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
        createdOrUpdatedProduct = await catalogApi.adminUpdateProduct(
          widget.product!.id,
          payload,
        );
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
                        .map(
                          (c) =>
                              DropdownMenuItem(value: c, child: Text(c.name)),
                        )
                        .toList(),
                    onChanged: (v) => setState(
                      () => selectedCategory = v ?? selectedCategory,
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
                          label: const Text(
                            'Remove',
                            style: TextStyle(color: Colors.red),
                          ),
                        ),
                      ],
                    ),
                  ] else if (widget.product?.imageUrl != null &&
                      widget.product!.imageUrl!.isNotEmpty) ...[
                    Image.network(
                      widget.product!.imageUrl!,
                      height: 150,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.image, size: 50),
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
