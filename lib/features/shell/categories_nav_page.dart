import 'package:flutter/material.dart';
import 'package:pavan_agro/core/theme/app_theme.dart';
import '../catalog/category.dart';
import '../category/categories_grid_page.dart';
import '../catalog/unified_products_page.dart';
import '../catalog/product.dart';
import '../../main.dart';

class CategoriesNavPage extends StatefulWidget {
  const CategoriesNavPage({Key? key}) : super(key: key);

  @override
  State<CategoriesNavPage> createState() => _CategoriesNavPageState();
}

class _CategoriesNavPageState extends State<CategoriesNavPage> {
  List<Category> categories = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      loading = true;
      error = null;
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
      
      // Load all categories and create new category objects with spare parts counts
      final allCategories = await catalogApi.listCategories();
      categories = allCategories
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
      error = "Failed to load spare parts categories";
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Sticky Top Banner with Title
        SliverAppBar(
          pinned: true,
          floating: false,
          backgroundColor: AppTheme.backgroundColor,
          elevation: 0,
          toolbarHeight: 100, // Adjusted height for banner (55) + title (45)
          automaticallyImplyLeading: false,
          flexibleSpace: SafeArea(
            child: Container(
              color: AppTheme.backgroundColor,
              child: Column(
                mainAxisSize: MainAxisSize.min,
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
                  Container(
                    height: 45,
                    alignment: Alignment.center,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: const Text(
                      'Spare Parts',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Scrollable Content
        SliverFillRemaining(
          child: CategoriesGridPage(
            title: '',
            categories: categories,
            isLoading: loading,
            error: error,
            onCategoryTap: (category) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => UnifiedProductsPage(
              categoryId: category.id,
              categoryName: category.name,
              showOnlySpareParts: true,
            ),
          ),
        );
      },
      onRefresh: _loadCategories,
          ),
        ),
      ],
    );
  }
}
