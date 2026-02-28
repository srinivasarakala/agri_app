import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../catalog/category.dart';
import '../catalog/widgets/category_card.dart';


class CategoriesGridPage extends StatefulWidget {
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final void Function(Category)? onCategoryTap;
  final Future<void> Function()? onRefresh;

  const CategoriesGridPage({
    Key? key,
    required this.categories,
    this.isLoading = false,
    this.error,
    this.onCategoryTap,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<CategoriesGridPage> createState() => _CategoriesGridPageState();
}

class _CategoriesGridPageState extends State<CategoriesGridPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textColor,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          backgroundColor: AppTheme.backgroundColor,
          foregroundColor: AppTheme.textColor,
          elevation: 1,
        ),
        body: Center(child: Text(widget.error!, style: TextStyle(color: AppTheme.errorColor))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: AppTheme.backgroundColor,
        foregroundColor: AppTheme.textColor,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: RefreshIndicator(
          onRefresh: widget.onRefresh ?? () async {},
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.1,
            ),
            itemCount: widget.categories.length,
            itemBuilder: (context, index) {
              final category = widget.categories[index];
              return CategoryCard(
                categoryName: category.name,
                productImages: category.productImages,
                productCount: category.productCount,
                onTap: widget.onCategoryTap != null ? () => widget.onCategoryTap!(category) : null,
              );
            },
          ),
        ),
      ),
    );
  }
}
