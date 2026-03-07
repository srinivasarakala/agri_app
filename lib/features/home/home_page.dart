import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
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
import '../catalog/widgets/spare_parts_carousel.dart';
import '../catalog/widgets/product_videos_carousel.dart';
import '../catalog/unified_products_page.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'widgets/top_products_carousel.dart';
import '../shell/app_shell.dart'; // for appTabIndex

class HomePage extends StatefulWidget {
  final String role; // "Admin" or "Dealer"
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
  List<Category> sparePartsCategories = [];
  bool sparePartsCategoriesLoading = true;
  String? sparePartsCategoriesError;
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
    _loadSparePartsCategories();
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
    if (currentSession?.phone != null) {
      try {
        await loadUserCart(currentSession!.phone!);
      } catch (e) {
        // Ignore cart loading errors - not critical
      }
    } else {
    }
  }

  Future<void> _load() async {
    setState(() {
      loading = true;
      error = null;
    });
    try {
      final all = await catalogApi.listProducts();
      // Filter out spare parts from regular product listings
      final regularProducts = all.where((p) => !p.isSparePart).toList();
      // Sort by date (newest first)
      regularProducts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      allProducts = regularProducts;
      featured = regularProducts.take(8).toList();
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

  Future<void> _loadSparePartsCategories() async {
    setState(() {
      sparePartsCategoriesLoading = true;
      sparePartsCategoriesError = null;
    });
    try {
      // Load all products and filter spare parts
      final allProducts = await catalogApi.listProducts();
      final spareParts = allProducts.where((p) => p.isSparePart).toList();
      
      // Group spare parts by category
      final categoryMap = <int, List<Product>>{};
      for (final part in spareParts) {
        if (part.categoryId != null) {
          categoryMap.putIfAbsent(part.categoryId!, () => []).add(part);
        }
      }
      
      // Load all categories and create new category objects with spare parts counts/images
      final allCategories = await catalogApi.listCategories();
      sparePartsCategories = allCategories
          .where((cat) => categoryMap.containsKey(cat.id))
          .map((cat) {
            final sparePartsInCategory = categoryMap[cat.id]!;
            final sparePartImages = sparePartsInCategory
                .where((p) => p.imageUrl != null && p.imageUrl!.isNotEmpty)
                .take(4)
                .map((p) => p.imageUrl!)
                .toList();
            
            
            // Create a new category with spare parts count and images
            return Category(
              id: cat.id,
              name: cat.name,
              description: cat.description,
              imageUrl: cat.imageUrl,
              productCount: sparePartsInCategory.length,
              productImages: sparePartImages,
              is_active: cat.is_active,
              isDynamic: cat.isDynamic,
            );
          })
          .toList();
    } catch (e) {
      sparePartsCategoriesError = "Failed to load spare parts categories";
    } finally {
      setState(() => sparePartsCategoriesLoading = false);
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
    } finally {
      setState(() => videosLoading = false);
    }
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _load(),
      _loadCategories(),
      _loadSparePartsCategories(),
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

        /// 🔎 Search Bar
        Container(
          color: AppTheme.backgroundColor,
          padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
          child: _SearchPill(
            onTap: () {
              Navigator.of(context).push(
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

        /// 🏷 Shop by Brands
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

        const SizedBox(height: 24),

        /// 🗂 Shop by Category
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

        /// � Shop Spare Parts
        if (sparePartsCategoriesLoading || sparePartsCategoriesError != null || sparePartsCategories.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                const Icon(Icons.build, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                const Text(
                  "Shop by Spare Parts",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SparePartsCarousel(
            categories: sparePartsCategories,
            isLoading: sparePartsCategoriesLoading,
            error: sparePartsCategoriesError,
            onCategoryTap: (category) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => UnifiedProductsPage(
                    categoryId: category.id,
                    categoryName: category.name,
                    showOnlySpareParts: true,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],

        /// �🔥 Top Products
        TopProductsCarousel(key: ValueKey(_topProductsKey)),

        const SizedBox(height: 24),

        /// 🎥 Product Videos
        if (videosLoading || videosError != null || videos.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: const Text(
              "Product Videos",
              style:
                  TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
            ),
          ),
          const SizedBox(height: 16),
          ProductVideosCarousel(
            videos: videos,
            isLoading: videosLoading,
            error: videosError,
          ),
          const SizedBox(height: 24),
        ],
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
            color: AppTheme.backgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppTheme.textColor.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.search, size: 22, color: AppTheme.textColor),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  "Search products…",
                  style: TextStyle(
                    color: AppTheme.textColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.mic_none, size: 20, color: AppTheme.textColor.withOpacity(0.6)),
            ],
          ),
        ),
      ),
    );
  }
}
