import 'package:flutter/material.dart';
import '../catalog/product.dart';
import '../catalog/product_details_page.dart';
import '../../main.dart';

class BrandProductsPage extends StatefulWidget {
  final int brandId;
  final String brandName;

  const BrandProductsPage({required this.brandId, required this.brandName, Key? key}) : super(key: key);

  @override
  State<BrandProductsPage> createState() => _BrandProductsPageState();
}

class _BrandProductsPageState extends State<BrandProductsPage> {
  bool loading = true;
  String? error;
  List<Product> products = [];
  List<Product> filteredProducts = [];
  final TextEditingController searchCtrl = TextEditingController();
  RangeValues priceRange = const RangeValues(0, 10000);
  List<String> allBrands = [];
  String? selectedBrand;

  @override
  void initState() {
    super.initState();
    _load();
    searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final all = await catalogApi.listProducts();
      products = all.where((p) => p.brand != null && p.brand!.isNotEmpty && int.tryParse(p.brand!) == widget.brandId).toList();
      allBrands = all.map((p) => p.brand ?? '').where((b) => b.isNotEmpty).toSet().toList();
      _applyFilters();
    } catch (e) {
      error = "Failed to load products";
    } finally {
      setState(() => loading = false);
    }
  }

  void _applyFilters() {
    final query = searchCtrl.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((p) {
        final matchesSearch = query.isEmpty || p.name.toLowerCase().contains(query);
        final matchesBrand = selectedBrand == null || p.brand == selectedBrand;
        final matchesPrice = p.sellingPrice >= priceRange.start && p.sellingPrice <= priceRange.end;
        return matchesSearch && matchesBrand && matchesPrice;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.brandName} Products')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
              ? Center(child: Text(error!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: const InputDecoration(
                          hintText: 'Search products...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        children: [
                          const Text('Brand:'),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedBrand,
                            hint: const Text('All'),
                            items: [null, ...allBrands].map((b) {
                              return DropdownMenuItem<String>(
                                value: b,
                                child: Text(b ?? 'All'),
                              );
                            }).toList(),
                            onChanged: (v) {
                              setState(() => selectedBrand = v);
                              _applyFilters();
                            },
                          ),
                          const SizedBox(width: 16),
                          const Text('Price:'),
                          Expanded(
                            child: RangeSlider(
                              values: priceRange,
                              min: 0,
                              max: 10000,
                              divisions: 100,
                              labels: RangeLabels(
                                priceRange.start.toStringAsFixed(0),
                                priceRange.end.toStringAsFixed(0),
                              ),
                              onChanged: (values) {
                                setState(() => priceRange = values);
                                _applyFilters();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: filteredProducts.isEmpty
                          ? const Center(child: Text('No products found.'))
                          : GridView.builder(
                              padding: const EdgeInsets.all(16),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio: 0.7,
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                              itemCount: filteredProducts.length,
                              itemBuilder: (context, index) {
                                final product = filteredProducts[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ProductDetailsPage(product: product),
                                      ),
                                    );
                                  },
                                  child: Card(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                              ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                              : const Icon(Icons.shopping_bag, size: 60),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: Text(
                                            product.name,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                          child: Text('₹${product.sellingPrice.toStringAsFixed(2)}'),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}
