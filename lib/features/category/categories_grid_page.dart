import 'package:flutter/material.dart';
import '../catalog/category.dart';
import '../catalog/widgets/category_card.dart';

class CategoriesGridPage extends StatelessWidget {
  final List<Category> categories;
  final bool isLoading;
  final String? error;
  final void Function(Category)? onCategoryTap;

  const CategoriesGridPage({
    Key? key,
    required this.categories,
    this.isLoading = false,
    this.error,
    this.onCategoryTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Categories'),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        body: Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
      );
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Categories'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 1.1,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return CategoryCard(
              categoryName: category.name,
              productImages: category.productImages,
              productCount: category.productCount,
              onTap: onCategoryTap != null ? () => onCategoryTap!(category) : null,
            );
          },
        ),
      ),
    );
  }
}
