import 'package:flutter/material.dart';
import '../../main.dart';
import '../../core/cart/cart_state.dart';
import '../catalog/product.dart';
import '../catalog/category.dart';
import '../catalog/product_video.dart';
import '../catalog/widgets/featured_products_carousel.dart';
import '../catalog/widgets/categories_carousel.dart';
import '../catalog/widgets/product_videos_carousel.dart';
import '../subdealer/pages/sd_catalog_page.dart'; // reuse your existing catalog page

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
  List<Category> categories = [];
  bool categoriesLoading = true;
  String? categoriesError;
  List<ProductVideo> videos = [];
  bool videosLoading = true;
  String? videosError;

  @override
  void initState() {
    super.initState();
    _loadUserCartIfNeeded();
    _load();
    _loadCategories();
    _loadVideos();
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
    setState(() { loading = true; error = null; });
    try {
      final all = await catalogApi.listProducts();
      // Sort by date (newest first)
      all.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      featured = all.take(8).toList();
    } catch (e) {
      error = "Failed to load products";
    } finally {
      setState(() => loading = false);
    }
  }

  Future<void> _loadCategories() async {
    setState(() { categoriesLoading = true; categoriesError = null; });
    try {
      // Load manual categories (better grouping than tag-based)
      final cats = await catalogApi.listCategories();
      categories = cats;
    } catch (e) {
      categoriesError = "Failed to load categories";
    } finally {
      setState(() => categoriesLoading = false);
    }
  }

  Future<void> _loadVideos() async {
    setState(() { videosLoading = true; videosError = null; });
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
    ]);
  }

  void openCatalog({String initialQuery = "", int? categoryId, String? tag}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          body: SdCatalogPage(
            initialQuery: initialQuery, 
            categoryId: categoryId,
            tag: tag,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshAll,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          // Top banner with search bar overlay
          Stack(
            clipBehavior: Clip.none,
            children: [
              // Banner image
              Container(
                width: double.infinity,
                height: 200,
                child: Image.asset(
                  'assets/images/top_banner.png',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to gradient if image not found
                    print('Error loading banner: $error');
                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.green.shade800, Colors.green.shade500],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Banner image not found',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Search bar overlay
              Positioned(
                bottom: 16,
                left: 14,
                right: 14,
                child: _SearchPill(
                  onTap: () => openCatalog(initialQuery: ""),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Text("Shop by Category", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
          ),

          const SizedBox(height: 12),

          CategoriesCarousel(
            categories: categories,
            isLoading: categoriesLoading,
            error: categoriesError,
            onCategoryTap: (category) {
              // For dynamic categories, pass the tag name; for manual categories, pass the category ID
              if (category.isDynamic) {
                openCatalog(tag: category.name);
              } else {
                openCatalog(categoryId: category.id);
              }
            },
          ),

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
                    const SnackBar(content: Text("Download catalogue feature coming soon")),
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
            child: Row(
              children: [
                const Text("New Arrivals", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
                const Spacer(),
                TextButton(
                  onPressed: () => openCatalog(initialQuery: ""),
                  child: const Text("See all"),
                ),
              ],
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
              onProductTap: (product) => openCatalog(initialQuery: product.name),
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
                  style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600),
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
