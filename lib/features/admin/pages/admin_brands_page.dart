import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import '../../../main.dart' show baseUrl, catalogApi;
import '../../catalog/brand.dart';

class AdminBrandsPage extends StatefulWidget {
  const AdminBrandsPage({super.key});

  @override
  State<AdminBrandsPage> createState() => _AdminBrandsPageState();
}

class _AdminBrandsPageState extends State<AdminBrandsPage> {
    void _openBrandForm({Brand? brand}) async {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        builder: (context) => BrandFormSheet(
          brand: brand,
          onSave: _load,
        ),
      );
    }

    void _deleteBrand(Brand brand) async {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Brand'),
          content: Text('Are you sure you want to delete "${brand.name}"?'),
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
      if (confirm == true) {
        try {
          await catalogApi.adminDeleteBrand(brand.id);
          _load();
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete brand: $e')),
          );
        }
      }
    }
  bool loading = true;
  String? error;
  List<Brand> brands = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final brandList = await catalogApi.listBrands();
      brands = brandList.map((b) => Brand.fromJson(b)).toList();
    } catch (e) {
      error = "Failed to load brands: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Brands'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
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
                      ElevatedButton(
                        onPressed: _load,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 10, bottom: 80),
                    children: [
                      ...brands.map((brand) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Card(
                            child: ListTile(
                              leading: brand.imageUrl != null && brand.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      brand.imageUrl ?? '',
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const Icon(Icons.store),
                                    )
                                  : const Icon(Icons.store),
                              title: Text(brand.name),
                              subtitle: Text(
                                '${brand.productCount} product${brand.productCount != 1 ? 's' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () => _openBrandForm(brand: brand),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteBrand(brand),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openBrandForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class BrandFormSheet extends StatefulWidget {
  final Brand? brand;
  final VoidCallback onSave;
  const BrandFormSheet({this.brand, required this.onSave, super.key});

  @override
  State<BrandFormSheet> createState() => _BrandFormSheetState();
}

class _BrandFormSheetState extends State<BrandFormSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController descriptionCtrl;
  XFile? pickedImage;
  final ImagePicker _picker = ImagePicker();
  bool isActive = true;
  bool saving = false;
  // Removed _localImagePath and imageUrlCtrl

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.brand?.name ?? '');
    descriptionCtrl = TextEditingController(text: widget.brand?.description ?? '');
    isActive = widget.brand?.is_active ?? true;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() => pickedImage = image);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error picking image: $e')));
    }
  }


  Future<void> _save() async {
    if (nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Brand name is required')),
      );
      return;
    }
    setState(() => saving = true);
    try {
      if (pickedImage == null && widget.brand == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Brand image is required')));
        setState(() => saving = false);
        return;
      }
      final payload = {
        'name': nameCtrl.text,
        'description': descriptionCtrl.text,
        'is_active': isActive,
      };
      var createdOrUpdatedBrand;
      if (widget.brand == null) {
        createdOrUpdatedBrand = await catalogApi.adminCreateBrand(payload);
      } else {
        createdOrUpdatedBrand = await catalogApi.adminUpdateBrand(widget.brand!.id, payload);
      }
      // Upload image if one was picked
      if (pickedImage != null) {
        await catalogApi.adminUploadBrandImage(
          createdOrUpdatedBrand.id,
          pickedImage!.path,
        );
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSave();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
              widget.brand == null ? 'Add Brand' : 'Edit Brand',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Brand Name *',
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
                pickedImage != null
                  ? Image.file(File(pickedImage!.path), width: 50, height: 50)
                  : widget.brand?.imageUrl != null && widget.brand!.imageUrl!.isNotEmpty
                    ? Image.network(widget.brand!.imageUrl!, width: 50, height: 50, errorBuilder: (_, __, ___) => const Icon(Icons.store))
                    : Container(width: 50, height: 50, color: Colors.grey[300]),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: saving ? null : _pickImage,
                  child: const Text('Pick Image'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Removed Image URL field
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
                widget.brand == null ? 'Create Brand' : 'Update Brand',
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
