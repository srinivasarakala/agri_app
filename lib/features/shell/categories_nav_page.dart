import 'package:flutter/material.dart';
import '../catalog/category.dart';
import '../category/categories_grid_page.dart';
import '../catalog/unified_products_page.dart';
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
      final cats = await catalogApi.listCategories();
      categories = cats.where((cat) => cat.productCount > 0).toList();
    } catch (e) {
      error = "Failed to load categories";
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CategoriesGridPage(
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
            ),
          ),
        );
      },
      onRefresh: _loadCategories,
    );
  }
}
