import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../main.dart';
import '../../catalog/spare_part.dart';
import '../../catalog/category.dart';

class AdminSparePartsPage extends StatefulWidget {
  const AdminSparePartsPage({super.key});

  @override
  State<AdminSparePartsPage> createState() => _AdminSparePartsPageState();
}

class _AdminSparePartsPageState extends State<AdminSparePartsPage> {
  bool loading = true;
  String? error;
  List<SparePart> items = [];
  List<SparePart> filteredItems = [];
  List<Category> categories = [];
  List<Map<String, dynamic>> brands = [];
  
  // Selection mode
  bool isSelectionMode = false;
  Set<int> selectedSparePartIds = {};

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
      selectedSparePartIds.clear();
    });
    try {
      // Fetch all products and filter only spare parts
      final allProducts = await catalogApi.listProducts();
      // Filter only products where is_spare_part is true
      items = allProducts
          .where((p) => p.isSparePart)
          .map((p) => SparePart(
                id: p.id,
                sku: p.sku,
                name: p.name,
                description: p.description,
                brand: p.brand,
                unit: p.unit,
                mrp: p.mrp,
                sellingPrice: p.sellingPrice,
                minQty: p.minQty,
                globalStock: p.globalStock,
                isActive: p.isActive,
                imageUrl: p.imageUrl,
                createdAt: p.createdAt,
                categoryId: p.categoryId,
                categoryName: p.categoryName,
                tags: p.tags,
                isSparePart: true,
              ))
          .toList();
      categories = await catalogApi.listCategories();
      brands = await catalogApi.listBrands();
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
        selectedSparePartIds.clear();
      }
    });
  }

  void _toggleSparePartSelection(int sparePartId) {
    setState(() {
      if (selectedSparePartIds.contains(sparePartId)) {
        selectedSparePartIds.remove(sparePartId);
      } else {
        selectedSparePartIds.add(sparePartId);
      }
    });
  }

  void _selectAll() {
    setState(() {
      if (selectedSparePartIds.length == filteredItems.length) {
        selectedSparePartIds.clear();
      } else {
        selectedSparePartIds = filteredItems.map((p) => p.id).toSet();
      }
    });
  }

  Future<void> _deleteSelectedSpareParts() async {
    if (selectedSparePartIds.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Spare Parts?'),
        content: Text(
          'Permanently delete ${selectedSparePartIds.length} spare part(s)? This cannot be undone.',
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
      // Delete each selected spare part
      for (final sparePartId in selectedSparePartIds) {
        await catalogApi.adminDeleteProduct(sparePartId);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${selectedSparePartIds.length} spare part(s) deleted'),
        ),
      );

      setState(() {
        selectedSparePartIds.clear();
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

  Future<void> _openSparePartForm({SparePart? sparePart}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SparePartFormSheet(
        sparePart: sparePart,
        categories: categories,
        brands: brands,
        onSave: load,
      ),
    );
  }

  Future<void> _deleteSparePart(SparePart p) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Spare Part?'),
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
      ).showSnackBar(const SnackBar(content: Text('Spare part deleted')));
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
              ? '${selectedSparePartIds.length} selected'
              : 'Manage Spare Parts${filteredItems.isNotEmpty ? " (${filteredItems.length})" : ""}',
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
                selectedSparePartIds.length == filteredItems.length
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
                                  ? 'No spare parts'
                                  : 'No spare parts match search',
                              style: const TextStyle(color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 80),
                            itemCount: filteredItems.length,
                            itemBuilder: (context, i) {
                              final p = filteredItems[i];
                              final isSelected = selectedSparePartIds.contains(p.id);

                              return ListTile(
                                leading: isSelectionMode
                                    ? Checkbox(
                                        value: isSelected,
                                        onChanged: (_) =>
                                            _toggleSparePartSelection(p.id),
                                      )
                                    : (p.imageUrl != null &&
                                            p.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            p.imageUrl!,
                                            width: 50,
                                            height: 50,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Icon(Icons.build),
                                          )
                                        : const Icon(Icons.build)),
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
                                                _openSparePartForm(sparePart: p),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.delete,
                                              color: Colors.red,
                                            ),
                                            onPressed: () => _deleteSparePart(p),
                                          ),
                                        ],
                                      ),
                                onTap: isSelectionMode
                                    ? () => _toggleSparePartSelection(p.id)
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
              onPressed: () => _openSparePartForm(),
              icon: const Icon(Icons.add),
              label: const Text('Add Spare Part'),
            ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: isSelectionMode && selectedSparePartIds.isNotEmpty
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
                        '${selectedSparePartIds.length} item(s) selected',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _deleteSelectedSpareParts,
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

// Spare Part Form Sheet
class SparePartFormSheet extends StatefulWidget {
  final SparePart? sparePart;
  final List<Category> categories;
  final List<Map<String, dynamic>> brands;
  final VoidCallback onSave;

  const SparePartFormSheet({
    super.key,
    this.sparePart,
    required this.categories,
    required this.brands,
    required this.onSave,
  });

  @override
  State<SparePartFormSheet> createState() => _SparePartFormSheetState();
}

class _SparePartFormSheetState extends State<SparePartFormSheet> {
  late TextEditingController skuCtrl;
  late TextEditingController nameCtrl;
  late TextEditingController descriptionCtrl;
  int? selectedBrandId;
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
    skuCtrl = TextEditingController(text: widget.sparePart?.sku ?? '');
    nameCtrl = TextEditingController(text: widget.sparePart?.name ?? '');
    descriptionCtrl = TextEditingController(
      text: widget.sparePart?.description ?? '',
    );
    if (widget.sparePart?.brand != null) {
      final matchingBrands = widget.brands
          .cast<Map<String, dynamic>>()
          .where((b) => b['name'] == widget.sparePart!.brand)
          .toList();
      selectedBrandId = matchingBrands.isNotEmpty
          ? matchingBrands.first['id'] as int?
          : null;
    }
    unitCtrl = TextEditingController(text: widget.sparePart?.unit ?? 'pcs');
    mrpCtrl = TextEditingController(
      text: widget.sparePart?.mrp.toStringAsFixed(2) ?? '',
    );
    priceCtrl = TextEditingController(
      text: widget.sparePart?.sellingPrice.toStringAsFixed(2) ?? '',
    );
    stockCtrl = TextEditingController(
      text: widget.sparePart?.globalStock.toStringAsFixed(2) ?? '',
    );
    minQtyCtrl = TextEditingController(
      text: widget.sparePart?.minQty.toStringAsFixed(0) ?? '1',
    );
    imageUrlCtrl = TextEditingController(text: widget.sparePart?.imageUrl ?? '');
    isActive = widget.sparePart?.isActive ?? true;

    if (widget.categories.isNotEmpty) {
      final matchingCats = widget.categories
          .where((c) => c.id == widget.sparePart?.categoryId)
          .toList();
      selectedCategory = matchingCats.isNotEmpty
          ? matchingCats.first
          : widget.categories.first;
    }
  }

  @override
  void dispose() {
    skuCtrl.dispose();
    nameCtrl.dispose();
    descriptionCtrl.dispose();
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
        'brand': selectedBrandId,
        'unit': unitCtrl.text,
        'mrp': double.tryParse(mrpCtrl.text) ?? 0,
        'selling_price': double.tryParse(priceCtrl.text) ?? 0,
        'global_stock': double.tryParse(stockCtrl.text) ?? 0,
        'min_qty': int.tryParse(minQtyCtrl.text) ?? 1,
        'is_active': isActive,
        'image_url': imageUrlCtrl.text.isEmpty ? null : imageUrlCtrl.text,
        'category': selectedCategory?.id,
        'is_spare_part': true, // ✅ Flag to mark as spare part
      };

      dynamic createdOrUpdatedSparePart;
      if (widget.sparePart == null) {
        createdOrUpdatedSparePart = await catalogApi.adminCreateProduct(payload);
      } else {
        createdOrUpdatedSparePart = await catalogApi.adminUpdateProduct(
          widget.sparePart!.id,
          payload,
        );
      }

      // Upload image if one was picked
      if (pickedImage != null) {
        final productId = createdOrUpdatedSparePart is SparePart
            ? createdOrUpdatedSparePart.id
            : createdOrUpdatedSparePart.id;
        await catalogApi.adminUploadProductImage(
          productId,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.sparePart == null ? 'Add Spare Part' : 'Edit Spare Part',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: skuCtrl,
              decoration: const InputDecoration(
                labelText: 'SKU (auto-generated if empty)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descriptionCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int?>(
              value: selectedBrandId,
              decoration: const InputDecoration(
                labelText: 'Brand',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                ...widget.brands.map(
                  (b) => DropdownMenuItem(
                    value: b['id'] as int?,
                    child: Text(b['name'] as String),
                  ),
                ),
              ],
              onChanged: (v) => setState(() => selectedBrandId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<Category?>(
              value: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              items: widget.categories
                  .map(
                    (c) => DropdownMenuItem(
                      value: c,
                      child: Text(c.name),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => selectedCategory = v),
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
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: minQtyCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Min Qty',
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
                    controller: mrpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'MRP',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
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
            TextField(
              controller: stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: imageUrlCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Image URL (optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _pickImage,
                  icon: const Icon(Icons.image),
                  label: const Text('Pick'),
                ),
              ],
            ),
            if (pickedImage != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: Colors.green),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Image selected: ${pickedImage!.name}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Active'),
              value: isActive,
              onChanged: (v) => setState(() => isActive = v),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: saving ? null : _save,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Save'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
