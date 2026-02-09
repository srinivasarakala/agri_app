import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../main.dart';

class AdminTopProductsPage extends StatefulWidget {
  const AdminTopProductsPage({super.key});

  @override
  State<AdminTopProductsPage> createState() => _AdminTopProductsPageState();
}

class _AdminTopProductsPageState extends State<AdminTopProductsPage> {
  List<String> topProductImages = [];
  bool loading = true;
  bool uploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => loading = true);
    try {
      topProductImages = await catalogApi.getTopProductImages();
    } catch (e) {
      print('Error loading top product images: $e');
      topProductImages = [];
    }
    setState(() => loading = false);
  }

  Future<void> _addNewImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => uploading = true);

      final index = topProductImages.length;
      final imageUrl = await catalogApi.uploadTopProductImage(index, image.path);
      
      setState(() {
        topProductImages.add(imageUrl);
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image added successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => uploading = false);
    }
  }

  Future<void> _deleteImage(int index) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Image'),
        content: Text('Are you sure you want to delete image #${index + 1}?'),
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
      setState(() => uploading = true);
      await catalogApi.deleteTopProductImage(index);
      await _load(); // Reload to get updated indices
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Image deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Top Products (${topProductImages.length})'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _load),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : uploading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Uploading image...'),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info card
                      Card(
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, color: Colors.blue.shade700),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  'Add images to display in the Top Products carousel on the home page. Tap the + button to add new images.',
                                  style: TextStyle(color: Colors.blue.shade900),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Images list
                      if (topProductImages.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 80,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No images added yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap the + button to add your first image',
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: topProductImages.length,
                          itemBuilder: (context, index) {
                            return Card(
                              elevation: 4,
                              margin: const EdgeInsets.only(bottom: 16),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    // Position badge
                                    Container(
                                      width: 50,
                                      height: 50,
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade700,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '#${index + 1}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Image preview
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.network(
                                        topProductImages[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        cacheWidth: 300,
                                        errorBuilder: (_, __, ___) => Container(
                                          width: 100,
                                          height: 100,
                                          color: Colors.grey.shade200,
                                          child: const Icon(
                                            Icons.broken_image,
                                            size: 40,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    // Info and actions
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Product Image ${index + 1}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Position: ${index + 1}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // Delete button
                                    IconButton(
                                      onPressed: () => _deleteImage(index),
                                      icon: const Icon(Icons.delete),
                                      color: Colors.red,
                                      tooltip: 'Delete',
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  ),
                ),
      floatingActionButton: uploading
          ? null
          : FloatingActionButton.extended(
              onPressed: _addNewImage,
              icon: const Icon(Icons.add),
              label: const Text('Add Image'),
              backgroundColor: Colors.green.shade700,
            ),
    );
  }
}
