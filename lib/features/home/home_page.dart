import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/cart/cart_state.dart';
import '../brand/brands_page.dart';
import '../brand/brand_products_page.dart';
import '../brand/brands_carousel.dart';
import '../catalog/brand.dart';
import '../catalog/product.dart';
import '../catalog/category.dart';
import '../catalog/product_video.dart';
import '../catalog/product_details_page.dart';
import '../catalog/widgets/featured_products_carousel.dart';
import '../catalog/widgets/categories_carousel.dart';
import '../catalog/widgets/product_videos_carousel.dart';
import '../catalog/unified_products_page.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'widgets/top_products_carousel.dart';
import '../shell/app_shell.dart'; // for appTabIndex

class HomePage extends StatefulWidget {
  final String role; // "DEALER_ADMIN" or "SUBDEALER"
  const HomePage({super.key, required this.role});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool loading = true;
  String? error;
  List<Product> featured = [];
  List<Product> allProducts = [];
  List<Category> categories = [];
  bool categoriesLoading = true;
  String? categoriesError;
  List<ProductVideo> videos = [];
  bool videosLoading = true;
  String? videosError;
  int _topProductsKey = 0; // Key to force TopProductsCarousel refresh

  List<Brand> brands = [];
  bool brandsLoading = true;
  String? brandsError;

  @override
  void initState() {
    super.initState();
    _loadUserCartIfNeeded();
    _load();
    _loadCategories();
    _loadVideos();
    _loadBrands();
  }

  Future<void> _loadBrands() async {
    setState(() {
      brandsLoading = true;
      brandsError = null;
    });
    try {
      final brandList = await catalogApi.listBrands();
      brands = brandList.map((b) => Brand.fromJson(b)).toList();
    } catch (e) {
      brandsError = "Failed to load brands";
    } finally {
      setState(() => brandsLoading = false);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadUserCartIfNeeded() async {
    // Load cart if user has existing session with phone
    print('Checking for existing session to load cart...');
    print('currentSession: ${currentSession?.phone}');
    if (currentSession?.phone != null) {
      try {
        print('Loading cart for existing session: ${currentSession!.phone}');
        await loadUserCart(currentSession!.phone!);
      } catch (e) {
        print('Error loading user cart: $e');
        // Ignore cart loading errors - not critical
      }
    } else {
      print('No existing session found');
    }
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final all = await catalogApi.listProducts();
      // Sort by date (newest first)
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      allProducts = all;
      featured = all.take(8).toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 && mounted) {
        // Session expired, redirect to login
        currentSession = null;
        if (mounted) context.go('/login');
      } else {
        error = "Failed to load products";
      }
    } catch (e) {
      error = "Failed to load products";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      categoriesLoading = true;
      categoriesError = null;
    });
    try {
      // Load manual categories (better grouping than tag-based)
      final cats = await catalogApi.listCategories();
      // Filter out categories with no products
      categories = cats.where((cat) => cat.productCount > 0).toList();
    } catch (e) {
      categoriesError = "Failed to load categories";
    } finally {
      setState(() => categoriesLoading = false);
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      videosLoading = true;
      videosError = null;
    });
    try {
      final vids = await catalogApi.listProductVideos();
      videos = vids;
    } catch (e) {
      videosError = "Failed to load videos";
      debugPrint("Error loading videos: $e");
    } finally {
      setState(() => videosLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _load(),
      _loadCategories(),
      _loadVideos(),
      _loadBrands(),
    ]);
    // Force TopProductsCarousel to reload
    if (mounted) {
      setState(() {
        _topProductsKey++;
      });
    }
  }

  void openCatalog({String initialQuery = "", int? categoryId, String? tag}) {
    // Switch to hidden catalog page (index 4 in AppShell)
    appTabIndex.value = 4;
    
    // Pass the filter parameters via catalog search bus after frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (initialQuery.isNotEmpty) {
        catalogSearchBus.openCatalogWithSearch(initialQuery);
      } else if (categoryId != null || tag != null) {
        catalogSearchBus.openCatalogWithCategory(categoryId: categoryId, tag: tag);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // White header with search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: _SearchPill(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UnifiedProductsPage(
                      showSearchBar: true,
                      showFilterRow: true,
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 12),

          // Shop by Brands Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Text(
              "Shop by Brand",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),

          const SizedBox(height: 12),

          BrandsCarousel(
            brands: brands,
            isLoading: brandsLoading,
            error: brandsError,
            onBrandTap: (brand) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnifiedProductsPage(
                    brandId: brand.id,
                    brandName: brand.name,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 16),

          // New Arrivals Section
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Text(
              "New Arrivals",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 12),
          if (loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          else
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: featured.length,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                itemBuilder: (context, i) {
                  final product = featured[i];
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProductDetailsPage(product: product),
                        ),
                      );
                    },
                    child: Container(
                      width: 170,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.green.shade100),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                color: Colors.grey.shade100,
                                height: 90,
                                width: double.infinity,
                                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                                    ? Image.network(product.imageUrl!, fit: BoxFit.cover)
                                    : const Icon(Icons.image, size: 48, color: Colors.grey),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              product.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Rs. ${product.sellingPrice.toStringAsFixed(2)}',
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
              ),
            ),

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Text(
              "Shop by Category",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),

          const SizedBox(height: 12),

          CategoriesCarousel(
            categories: categories,
            isLoading: categoriesLoading,
            error: categoriesError,
            onCategoryTap: (category) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnifiedProductsPage(
                    categoryId: category.id,
                    categoryName: category.name,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Top Products Section
          TopProductsCarousel(key: ValueKey(_topProductsKey)),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  // TODO: Implement download catalogue functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Download catalogue feature coming soon"),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green.shade400, Colors.green.shade600],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.download, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              "Download Catalogue",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Get the complete product list in PDF",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Text(
              "New Arrivals",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),

          if (loading)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (error != null)
            Padding(
              padding: const EdgeInsets.all(14),
              child: Text(error!, style: const TextStyle(color: Colors.red)),
            )
          else
            FeaturedProductsCarousel(
              products: featured,
              onProductTap: (product) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailsPage(product: product),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),

          // Product Videos Section
          if (videosLoading || videosError != null || videos.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: const Text(
                "Product Videos",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
              ),
            ),

            const SizedBox(height: 16),

            ProductVideosCarousel(
              videos: videos,
              isLoading: videosLoading,
              error: videosError,
            ),

            const SizedBox(height: 20),
          ],

          if (videos.isEmpty && !videosLoading && videosError == null)
            const SizedBox(height: 18),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _SearchPill extends StatelessWidget {
  final VoidCallback onTap;
  const _SearchPill({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: Colors.black.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 10,
                color: Colors.black.withOpacity(0.08),
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 22, color: Colors.grey),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Search products…",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.mic_none, size: 20, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );
  }
}
