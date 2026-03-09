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
  final String title;

  const CategoriesGridPage({
    Key? key,
    required this.categories,
    this.isLoading = false,
    this.error,
    this.onCategoryTap,
    this.onRefresh,
    this.title = 'Categories',
  }) : super(key: key);

  @override
  State<CategoriesGridPage> createState() => _CategoriesGridPageState();
}

class _CategoriesGridPageState extends State<CategoriesGridPage> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return Scaffold(
        body: Column(
          children: [
            if (widget.title.isNotEmpty)
              Container(
                //width: double.infinity,
                //padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                color: Colors.transparent,
                child: Text(
                  textAlign: TextAlign.center,
                  widget.title,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      );
    }
    if (widget.error != null) {
      return Scaffold(
        body: Column(
          children: [
            if (widget.title.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                color: Colors.transparent,
                child: Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
            Expanded(child: Center(child: Text(widget.error!, style: TextStyle(color: AppTheme.errorColor)))),          
          ],
        ),
      );
    }
    return Scaffold(
      body: Column(
        children: [
          if (widget.title.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              color: Colors.transparent,
              child: Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: RefreshIndicator(
                onRefresh: widget.onRefresh ?? () async {},
                child: GridView.builder(
                  padding: EdgeInsets.zero,
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
                      backgroundColor: Colors.white,
                      categoryImageUrl: category.imageUrl,
                      onTap: widget.onCategoryTap != null ? () => widget.onCategoryTap!(category) : null,
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
