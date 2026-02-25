
import 'package:flutter/material.dart';
import '../catalog/brand.dart';
import '../../main.dart';

class BrandsPage extends StatefulWidget {
  const BrandsPage({super.key});

  @override
  State<BrandsPage> createState() => _BrandsPageState();
}

class _BrandsPageState extends State<BrandsPage> {
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
      appBar: AppBar(title: const Text('Brands')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: brands.length,
                  itemBuilder: (context, index) {
                    final brand = brands[index];
                    return GestureDetector(
                      onTap: () {
                        // TODO: Implement navigation to BrandProductsPage if needed, or use callback from parent
                      },
                      child: Column(
                        children: [
                          brand.imageUrl != null && brand.imageUrl!.isNotEmpty
                              ? Image.network(
                                  brand.imageUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(Icons.store),
                                )
                              : const Icon(Icons.store, size: 100),
                          const SizedBox(height: 8),
                          Text(brand.name),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}


