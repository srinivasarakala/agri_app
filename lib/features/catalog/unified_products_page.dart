import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/widgets/progressive_image.dart';
import '../catalog/product.dart';
import '../catalog/brand.dart';
import '../catalog/product_details_page.dart';
import '../../main.dart';
import '../../core/cart/cart_state.dart';

class UnifiedProductsPage extends StatefulWidget {
  final int? brandId;
  final String? brandName;
  final int? categoryId;
  final String? categoryName;
  final bool showSearchBar;
  final bool showFilterRow;
  final bool showOnlySpareParts;
  final bool showOnlyFavorites;

  const UnifiedProductsPage({
    this.brandId,
    this.brandName,
    this.categoryId,
    this.categoryName,
    this.showSearchBar = false,
    this.showFilterRow = false,
    this.showOnlySpareParts = false,
    this.showOnlyFavorites = false,
    Key? key,
  }) : super(key: key);

  @override
  State<UnifiedProductsPage> createState() => _UnifiedProductsPageState();
}

class _UnifiedProductsPageState extends State<UnifiedProductsPage> {
    void _toggleFavorite(int productId) {
      setState(() {
        toggleFavorite(productId);
      });
    }
  String filterType = 'Product';
  List<Brand> brandsList = [];
  bool loading = true;
  String? error;
  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<Product> sparePartsProducts = [];
  final TextEditingController searchCtrl = TextEditingController();
  late bool showSearchBar;
  late bool showFilterRow;

  @override
  void initState() {
    super.initState();
      // For favorites, search bar is collapsed by default but can be expanded
      // For favorites, search bar should be collapsed by default
      showSearchBar = widget.showOnlyFavorites ? false : widget.showSearchBar;
      showFilterRow = widget.showFilterRow;
    _loadBrands();
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
      // Filter products based on showOnlySpareParts or showOnlyFavorites flag
      if (widget.showOnlyFavorites) {
        final favSet = favorites.value;
        products = all.where((p) => favSet.contains(p.id)).toList();
      } else {
        products = all.where((p) {
          bool matches = widget.showOnlySpareParts ? p.isSparePart : !p.isSparePart;
          if (widget.brandName != null) {
            matches = matches && (p.brand == widget.brandName);
          }
          if (widget.categoryId != null) {
            matches = matches && (p.categoryId == widget.categoryId);
          }
          return matches;
        }).toList();
      }
      // Load spare parts separately
      sparePartsProducts = all.where((p) => p.isSparePart).toList();
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
        return matchesSearch;
      }).toList();
    });
  }

  void _loadBrands() async {
    try {
      final brandList = await catalogApi.listBrands();
      setState(() {
        brandsList = brandList.map((b) => Brand.fromJson(b)).toList();
      });
    } catch (_) {}
  }

  Widget _buildRefreshState(Widget child) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        const SizedBox(height: 140),
        Center(child: child),
      ],
    );
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
                  widget.showOnlyFavorites
                      ? 'Favorites'
                      : widget.categoryName ?? widget.brandName ?? 'Products',
                  textAlign: TextAlign.center,
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
                        DropdownMenuItem(value: 'Spare Part', child: Text('Spare Part')),
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
            child: RefreshIndicator(
              onRefresh: _load,
              child: filterType == 'Spare Part'
                ? (loading
                ? _buildRefreshState(const CircularProgressIndicator())
                    : error != null
                  ? _buildRefreshState(Text(error!))
                        : sparePartsProducts.isEmpty
                    ? _buildRefreshState(const Text("No spare parts found"))
                            : GridView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  mainAxisSpacing: 12,
                                  crossAxisSpacing: 12,
                                  childAspectRatio: 0.78,
                                ),
                                itemCount: sparePartsProducts.length,
                                itemBuilder: (context, i) {
                                  final p = sparePartsProducts[i];
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
                                      elevation: 0,
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            flex: 3,
                                            child: Container(
                                              width: double.infinity,
                                              decoration: BoxDecoration(
                                                color: Color(0xFFF5F7FA),
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(16),
                                                  topRight: Radius.circular(16),
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: const BorderRadius.only(
                                                  topLeft: Radius.circular(16),
                                                  topRight: Radius.circular(16),
                                                ),
                                                child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                                    ? ProgressiveImage(
                                                        imageUrl: p.imageUrl!,
                                                        width: double.infinity,
                                                        height: double.infinity,
                                                        fit: BoxFit.cover,
                                                        borderRadius: const BorderRadius.only(
                                                          topLeft: Radius.circular(16),
                                                          topRight: Radius.circular(16),
                                                        ),
                                                      )
                                                    : const Icon(
                                                        Icons.image,
                                                        size: 50,
                                                        color: Colors.grey,
                                                      ),
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(
                                                  p.name,
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Text(
                                                  p.categoryName ?? 'General',
                                                  maxLines: 2,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                Text(
                                                  '₹ ${p.sellingPrice.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ))
                : filterType == 'Product'
                ? (loading
                  ? _buildRefreshState(const CircularProgressIndicator())
                    : error != null
                    ? _buildRefreshState(Text(error!))
                        : filteredProducts.isEmpty
                      ? _buildRefreshState(const Text("No products found"))
                            : GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                                      elevation: 0,
                                      color: Colors.white,
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Product image with light gray background and favorite icon
                                          Expanded(
                                            flex: 3,
                                            child: Stack(
                                              children: [
                                                Container(
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: Color(0xFFF5F7FA),
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(16),
                                                      topRight: Radius.circular(16),
                                                    ),
                                                  ),
                                                  child: ClipRRect(
                                                    borderRadius: const BorderRadius.only(
                                                      topLeft: Radius.circular(16),
                                                      topRight: Radius.circular(16),
                                                    ),
                                                    child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                                                        ? ProgressiveImage(
                                                            imageUrl: p.imageUrl!,
                                                            width: double.infinity,
                                                            height: double.infinity,
                                                            fit: BoxFit.cover,
                                                            borderRadius: const BorderRadius.only(
                                                              topLeft: Radius.circular(16),
                                                              topRight: Radius.circular(16),
                                                            ),
                                                          )
                                                        : const Icon(
                                                            Icons.image,
                                                            size: 50,
                                                            color: Colors.grey,
                                                          ),
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 8,
                                                  right: 8,
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      _toggleFavorite(p.id);
                                                    },
                                                    child: Icon(
                                                      favorites.value.contains(p.id)
                                                          ? Icons.favorite
                                                          : Icons.favorite_border,
                                                      color: favorites.value.contains(p.id)
                                                          ? Colors.red
                                                          : Colors.grey,
                                                      size: 28,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Product details
                                          Container(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                // Product SKU/Model
                                                Text(
                                                  p.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                // Product name as subtitle
                                                Text(
                                                  p.categoryName ?? 'General',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    color: Colors.grey.shade600,
                                                  ),
                                                ),
                                                const SizedBox(height: 8),
                                                // Product price
                                                Text(
                                                  '₹ ${p.sellingPrice.toStringAsFixed(2)}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ))
                : GridView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 16),
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
                                        ? ProgressiveImage(
                                            imageUrl: b.imageUrl!,
                                            width: double.infinity,
                                            height: 80,
                                            fit: BoxFit.fill,
                                            borderRadius: BorderRadius.circular(12),
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
          ),
        ],
      ),
    );
  }
}