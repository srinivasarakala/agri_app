import 'package:flutter/material.dart';
import '../category.dart';
import 'category_card.dart';

class CategoriesCarousel extends StatelessWidget {
  // Soft, rich color palette for category cards
  static const List<Color> _categoryColors = [
    Color(0xFFE3F2FD), // Light Blue
    Color(0xFFF1F8E9), // Light Green
    Color(0xFFFFF3E0), // Light Orange
    Color(0xFFF3E5F5), // Light Purple
    Color(0xFFFFEBEE), // Light Pink
    Color(0xFFE0F2F1), // Light Teal
    Color(0xFFFFF9C4), // Light Yellow
  ];

  final List<Category> categories;
  final void Function(Category)? onCategoryTap;
  final bool isLoading;
  final String? error;

  const CategoriesCarousel({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (error != null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Text(error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 220,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final backgroundColor = _categoryColors[index % _categoryColors.length];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CategoryCard(
              categoryName: category.name,
              productImages: category.productImages,
              backgroundColor: backgroundColor,
              onTap: onCategoryTap != null ? () => onCategoryTap!(category) : null,
            ),
          );
        },
      ),
    );
  }
}
