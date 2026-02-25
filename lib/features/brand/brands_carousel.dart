import 'package:flutter/material.dart';
import '../catalog/brand.dart';

class BrandsCarousel extends StatelessWidget {
  final List<Brand> brands;
  final void Function(Brand)? onBrandTap;
  final bool isLoading;
  final String? error;

  const BrandsCarousel({
    super.key,
    required this.brands,
    this.onBrandTap,
    this.isLoading = false,
    this.error,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const SizedBox(
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (error != null) {
      return SizedBox(
        height: 120,
        child: Center(child: Text(error!, style: const TextStyle(color: Colors.red))),
      );
    }
    if (brands.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No brands found.')),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: brands.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final brand = brands[index];
          return GestureDetector(
            onTap: () => onBrandTap?.call(brand),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 36,
                  backgroundImage: brand.imageUrl != null ? NetworkImage(brand.imageUrl!) : null,
                  child: brand.imageUrl == null ? Text(brand.name[0]) : null,
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: 72,
                  child: Text(
                    brand.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
