import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String categoryName;
  final List<String> productImages;
  final int productCount;
  final VoidCallback? onTap;
  final Color backgroundColor;

  const CategoryCard({
    super.key,
    required this.categoryName,
    required this.productImages,
    required this.productCount,
    this.onTap,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      color: backgroundColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: 160,
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Category Name at top
              Text(
                categoryName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              // Product count
              Text(
                '$productCount products',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              // Image Collage (2x2 grid)
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    width: double.infinity,
                    color: Colors.grey.shade100,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 2,
                            mainAxisSpacing: 2,
                          ),
                      itemCount: 4,
                      itemBuilder: (context, index) {
                        final hasImage =
                            index < productImages.length &&
                            productImages[index].isNotEmpty;
                        return Container(
                          color: Colors.grey.shade200,
                          child: hasImage
                              ? Image.network(
                                  productImages[index],
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.category,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                )
                              : Icon(
                                  Icons.image_outlined,
                                  size: 28,
                                  color: Colors.grey.shade400,
                                ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
