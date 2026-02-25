import 'package:flutter/material.dart';
import '../catalog/product.dart';
import '../catalog/brand.dart';
import '../catalog/product_details_page.dart';
import '../../main.dart';

class UnifiedProductsPage extends StatefulWidget {
  final int? brandId;
  final String? brandName;
  final int? categoryId;
  final String? categoryName;
  final bool showSearchBar;
  final bool showFilterRow;

  const UnifiedProductsPage({
    this.brandId,
    this.brandName,
    this.categoryId,
    this.categoryName,
    this.showSearchBar = false,
    this.showFilterRow = false,
    Key? key,
  }) : super(key: key);

  @override
  State<UnifiedProductsPage> createState() => _UnifiedProductsPageState();
}

class _UnifiedProductsPageState extends State<UnifiedProductsPage> {
      void _loadBrands() async {
        try {
          final brandList = await catalogApi.listBrands();
          setState(() {
            brandsList = brandList.map((b) => Brand.fromJson(b)).toList();
          });
        } catch (_) {}
      }
    String filterType = 'Product';
    List<Brand> brandsList = [];
  bool loading = true;
  String? error;
  List<Product> products = [];
  List<Product> filteredProducts = [];
  final TextEditingController searchCtrl = TextEditingController();
  late bool showSearchBar;
  late bool showFilterRow;

  @override
  void initState() {
      _loadBrands();
    super.initState();
    showSearchBar = widget.showSearchBar;
    showFilterRow = widget.showFilterRow;
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
      products = all.where((p) {
        bool matches = true;
        if (widget.brandId != null) {
          // Compare brand as string, since Product.brand is a string
          matches = matches && (p.brand != null && p.brand!.isNotEmpty && int.tryParse(p.brand!) == widget.brandId);
        }
        if (widget.categoryId != null) {
          matches = matches && (p.categoryId == widget.categoryId);
        }
        return matches;
      }).toList();
      _applyFilters();
    } catch (e) {
      error = "Failed to load products";
    } finally {
      setState(() => loading = false);
    }
  }

  void _applyFilters() {
      void _loadBrands() async {
        try {
          final brandList = await catalogApi.listBrands();
          setState(() {
            brandsList = brandList.map((b) => Brand.fromJson(b)).toList();
          });
        } catch (_) {}
      }
    final query = searchCtrl.text.toLowerCase();
    setState(() {
      filteredProducts = products.where((p) {
        final matchesSearch = query.isEmpty || p.name.toLowerCase().contains(query);
        return matchesSearch;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: AppBar(
          backgroundColor: Colors.white,
          title: showSearchBar
              ? Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: TextField(
                    controller: searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search here ?',
                      border: InputBorder.none,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          setState(() {
                            showSearchBar = false;
                            searchCtrl.clear();
                            _applyFilters();
                          });
                        },
                      ),
                    ),
                    onChanged: (_) => _applyFilters(),
                  ),
                )
              : Text(
                  widget.categoryName ?? widget.brandName ?? 'Products',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
                ),
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            if (!showSearchBar)
              IconButton(
                icon: const Icon(Icons.search),
                onPressed: () {
                  setState(() {
                    showSearchBar = true;
                  });
                },
              ),
          ],
          elevation: 0.5,
        ),
      ),
      body: Column(
        children: [
          if (showFilterRow)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: DropdownButton<String>(
                      value: filterType,
                      items: const [
                        DropdownMenuItem(value: 'Product', child: Text('Product')),
                        DropdownMenuItem(value: 'Brand', child: Text('Brand')),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => filterType = v);
                      },
                      isExpanded: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.filter_alt_outlined),
                    label: const Text('Filter'),
                    onPressed: () {},
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    icon: const Icon(Icons.sort),
                    label: const Text('Sort'),
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          Expanded(
            child: filterType == 'Product'
                ? (loading
                    ? const Center(child: CircularProgressIndicator())
                    : error != null
                        ? Center(child: Text(error!))
                        : filteredProducts.isEmpty
                            ? const Center(child: Text("No products found"))
                            : GridView.builder(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: filteredProducts.length,
                                itemBuilder: (context, i) {
                                  final p = filteredProducts[i];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProductDetailsPage(product: p),
                                        ),
                                      );
                                    },
                                    child: Card(
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      elevation: 2,
                                      child: Padding(
                                        padding: const EdgeInsets.all(10),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            // Product image
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(12),
                                              child: Container(
                                                color: Colors.grey.shade100,
                                                height: 120,
                                                width: double.infinity,
                                                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                                    ? Image.network(
                                                        p.imageUrl!,
                                                        fit: BoxFit.cover,
                                                      )
                                                    : const Icon(Icons.image, size: 48, color: Colors.grey),
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            // Product name
                                            Text(
                                              p.name,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 6),
                                            // Product price
                                            Text(
                                              'Rs. ${p.sellingPrice.toStringAsFixed(2)}',
                                              style: const TextStyle(
                                                color: Colors.deepOrange,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ))
                : GridView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    itemCount: brandsList.length,
                    itemBuilder: (context, i) {
                      final b = brandsList[i];
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => UnifiedProductsPage(
                                brandId: b.id,
                                brandName: b.name,
                                showSearchBar: true,
                                showFilterRow: false,
                              ),
                            ),
                          );
                        },
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 2,
                          child: Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    color: Colors.grey.shade100,
                                    height: 80,
                                    width: double.infinity,
                                    child: b.imageUrl != null && b.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            b.imageUrl!,
                                            fit: BoxFit.contain,
                                          )
                                        : const Icon(Icons.image, size: 48, color: Colors.grey),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  b.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
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