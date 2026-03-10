import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../main.dart';
import '../../core/cart/cart_state.dart';
import '../brand/brands_carousel.dart';
import '../catalog/brand.dart';
import '../catalog/product.dart';
import '../catalog/category.dart';
import '../catalog/product_video.dart';
import '../../core/widgets/progressive_image.dart';
import '../catalog/widgets/categories_carousel.dart';
import '../catalog/widgets/product_videos_carousel.dart';
import '../catalog/unified_products_page.dart';
import 'package:dio/dio.dart';
import 'package:go_router/go_router.dart';
import 'widgets/top_products_carousel.dart';
import '../shell/app_shell.dart'; // for appTabIndex
import '../profile/profile_page.dart';
import '../profile/user_profile.dart';

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

  Future<void> _showProfileInfo(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        minChildSize: 0.3,
        maxChildSize: 0.8,
        expand: false,
        builder: (context, scrollController) => FutureBuilder<UserProfile>(
          future: profileApi.getProfile(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: Colors.red),
                    const SizedBox(height: 16),
                    Text('Error loading profile',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            }
            final profile = snapshot.data!;
            return ListView(
              controller: scrollController,
              padding: const EdgeInsets.all(24),
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Profile Information',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ProfilePage(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      tooltip: 'Edit Profile',
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _ProfileInfoTile(
                  icon: Icons.person,
                  label: 'Name',
                  value: profile.fullName.isNotEmpty
                      ? profile.fullName
                      : 'Not set',
                ),
                const SizedBox(height: 16),
                _ProfileInfoTile(
                  icon: Icons.phone,
                  label: 'Phone',
                  value: profile.phone,
                ),
                const SizedBox(height: 16),
                _ProfileInfoTile(
                  icon: Icons.badge,
                  label: 'Role',
                  value: profile.role,
                ),
                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  return RefreshIndicator(
    onRefresh: _refreshAll,
    child: CustomScrollView(
      slivers: [
        // Sticky Top Banner
        SliverAppBar(
          pinned: true,
          floating: false,
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          toolbarHeight: 60, // Height for banner only
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Container(
              color: AppTheme.backgroundColor,
              child: Stack(
                children: [
                  Container(
                    height: 55,
                    alignment: Alignment.center,
                    child: FractionallySizedBox(
                      widthFactor: 0.5,
                      child: Image.asset(
                      'assets/images/top_banner.png',
                      height: 55,
                      fit: BoxFit.contain,
                      alignment: Alignment.center,
                    ),
                  ),
                  ),
                  Positioned(
                    right: 16,
                    top: 4,
                    child: Material(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => _showProfileInfo(context),
                        child: Container(
                          height: 52,
                          width: 52,
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.account_circle,
                            size: 32,
                            color: Color(0xFF2E7D32),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Scrollable Content
        SliverToBoxAdapter(
          child: Column(
            children: [
              /// 🔎 Search Bar
              Container(
                color: AppTheme.backgroundColor,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
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

              const SizedBox(height: 20),

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

              const SizedBox(height: 20),

              /// 🗂 Shop by Category
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Shop by Category",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              const SizedBox(height: 20),

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

              const SizedBox(height: 20),

              /// 🔥 Top Products
              TopProductsCarousel(key: ValueKey(_topProductsKey)),

              const SizedBox(height: 20),

              /// 🎥 Product Videos
              if (videosLoading || videosError != null || videos.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      "Product Videos",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                ProductVideosCarousel(
                  videos: videos,
                  isLoading: videosLoading,
                  error: videosError,
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),
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

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF2E7D32).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF2E7D32),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
