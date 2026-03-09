import 'package:flutter/material.dart';
import '../category.dart';
import 'category_card.dart';

class CategoriesCarousel extends StatefulWidget {
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
  State<CategoriesCarousel> createState() => _CategoriesCarouselState();
}

class _CategoriesCarouselState extends State<CategoriesCarousel> {
  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.error != null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Text(widget.error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (widget.categories.isEmpty) {
      return const SizedBox.shrink();
    }

    // Calculate number of pages (3 columns x 2 rows = 6 categories per page)
    final pageCount = (widget.categories.length / 6).ceil();

    return SizedBox(
      height: 302, // Reduced height for 2 rows
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(12, 6, 14, 6),
        itemCount: pageCount,
        itemBuilder: (context, pageIndex) {
          final startIndex = pageIndex * 6;
          final endIndex = (startIndex + 6).clamp(0, widget.categories.length);
          final pageCategories = widget.categories.sublist(startIndex, endIndex);

          return SizedBox(
            width: MediaQuery.of(context).size.width - 28, // Full width minus padding
            height: 300, // Explicit height for the grid to show both rows
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: GridView.builder(
                padding: EdgeInsets.zero,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3, // 3 columns
                  mainAxisSpacing: 6,
                  crossAxisSpacing: 6,
                  childAspectRatio: 0.85, // Card shape
                ),
                itemCount: pageCategories.length,
                itemBuilder: (context, index) {
                  final category = pageCategories[index];
                  return CategoryCard(
                    categoryName: category.name,
                    productImages: category.productImages,
                    productCount: category.productCount,
                    backgroundColor: Colors.white,
                    categoryImageUrl: category.imageUrl,
                    onTap: widget.onCategoryTap != null
                        ? () => widget.onCategoryTap!(category)
                        : null,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
