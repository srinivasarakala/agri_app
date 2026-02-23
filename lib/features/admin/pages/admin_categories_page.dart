import 'package:flutter/material.dart';
import '../../../main.dart';
import '../../catalog/category.dart';

class AdminCategoriesPage extends StatefulWidget {
  const AdminCategoriesPage({super.key});

  @override
  State<AdminCategoriesPage> createState() => _AdminCategoriesPageState();
}

class _AdminCategoriesPageState extends State<AdminCategoriesPage> {
  bool loading = true;
  String? error;
  List<Category> categories = [];

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
      final cats = await catalogApi.listCategories();
      categories = cats;
    } catch (e) {
      error = "Failed to load categories: $e";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _openCategoryForm({Category? category}) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CategoryFormSheet(
        category: category,
        onSave: _load,
      ),
    );
  }

  Future<void> _deleteCategory(Category cat) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Category?'),
        content: Text(
          'Delete "${cat.name}"? This cannot be undone.',
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

    try {
      await catalogApi.adminDeleteCategory(cat.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted')),
      );
      _load();
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Categories'),
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
                      ...categories.map((cat) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          child: Card(
                            child: ListTile(
                              leading: cat.imageUrl != null && cat.imageUrl!.isNotEmpty
                                  ? Image.network(
                                      cat.imageUrl!,
                                      width: 50,
                                      height: 50,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(Icons.category),
                                    )
                                  : const Icon(Icons.category),
                              title: Text(cat.name),
                              subtitle: Text(
                                '${cat.productCount} product${cat.productCount != 1 ? 's' : ''}',
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit),
                                    onPressed: () =>
                                        _openCategoryForm(category: cat),
                                  ),
                                  IconButton(
                                    icon:
                                        const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _deleteCategory(cat),
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
        onPressed: () => _openCategoryForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class CategoryFormSheet extends StatefulWidget {
  final Category? category;
  final VoidCallback onSave;

  const CategoryFormSheet({
    super.key,
    this.category,
    required this.onSave,
  });

  @override
  State<CategoryFormSheet> createState() => _CategoryFormSheetState();
}

class _CategoryFormSheetState extends State<CategoryFormSheet> {
  late TextEditingController nameCtrl;
  late TextEditingController descriptionCtrl;
  late TextEditingController imageUrlCtrl;
  bool isActive = true;
  bool saving = false;

  @override
  void initState() {
    super.initState();
    nameCtrl = TextEditingController(text: widget.category?.name ?? '');
    descriptionCtrl =
        TextEditingController(text: widget.category?.description ?? '');
    imageUrlCtrl =
        TextEditingController(text: widget.category?.imageUrl ?? '');
    isActive = widget.category?.is_active ?? true;
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    descriptionCtrl.dispose();
    imageUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (nameCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category name is required')),
      );
      return;
    }

    setState(() => saving = true);
    try {
      final payload = {
        'name': nameCtrl.text,
        'description': descriptionCtrl.text,
        'image_url': imageUrlCtrl.text.isEmpty ? null : imageUrlCtrl.text,
        'is_active': isActive,
      };

      if (widget.category == null) {
        await catalogApi.adminCreateCategory(payload);
      } else {
        await catalogApi.adminUpdateCategory(widget.category!.id, payload);
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
              widget.category == null ? 'Add Category' : 'Edit Category',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Category Name *',
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
            TextField(
              controller: imageUrlCtrl,
              decoration: const InputDecoration(
                labelText: 'Image URL',
                border: OutlineInputBorder(),
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
                widget.category == null ? 'Create Category' : 'Update Category',
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
