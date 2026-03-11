import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/widgets/progressive_image.dart';

class CategoryCard extends StatelessWidget {
  final String categoryName;
  final List<String> productImages;
  final int productCount;
  final VoidCallback? onTap;
  final Color backgroundColor;
  final String? categoryImageUrl; // Optional category image

  const CategoryCard({
    super.key,
    required this.categoryName,
    required this.productImages,
    required this.productCount,
    this.onTap,
    this.backgroundColor = Colors.white,
    this.categoryImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 1,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Image Display - Category image if available, else product collage
            Expanded(
              flex: 65,
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                child: Container(
                  width: double.infinity,
                  color: const Color(0xFFF5F5F7),
                  child: _buildCategoryImage(),
                ),
              ),
            ),
            // Category Name at bottom center
            Expanded(
              flex: 35,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                width: double.infinity,
                alignment: Alignment.center,
                child: Text(
                  categoryName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    height: 1.2,
                    color: Color(0xFF1C1C1E),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Display single category image
  Widget _buildCategoryImage() {
    return ProgressiveImage(
      imageUrl: categoryImageUrl!,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(20),
        topRight: Radius.circular(20),
      ),
    );
  }

  
}
