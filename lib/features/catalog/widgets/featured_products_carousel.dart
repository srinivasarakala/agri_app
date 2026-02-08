import 'package:flutter/material.dart';
import '../product.dart';

class FeaturedProductsCarousel extends StatelessWidget {
  final List<Product> products;
  final void Function(Product)? onProductTap;
  final bool isLoading;
  final String? error;

  const FeaturedProductsCarousel({
    super.key,
    required this.products,
    this.onProductTap,
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

    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Text("No featured products available"),
      );
    }

    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: SizedBox(
              width: 140,
              child: InkWell(
                onTap: onProductTap != null ? () => onProductTap!(product) : null,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: (product.imageUrl != null && product.imageUrl!.isNotEmpty)
                            ? Image.network(
                                product.imageUrl!,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey.shade100,
                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                ),
                              )
                            : Container(
                                color: Colors.grey.shade100,
                                child: const Icon(Icons.image, size: 40, color: Colors.grey),
                              ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Product Name
                    Expanded(
                      child: Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

