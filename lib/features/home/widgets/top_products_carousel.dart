import 'dart:async';
import 'package:flutter/material.dart';
import '../../../main.dart';

class TopProductsCarousel extends StatefulWidget {
  const TopProductsCarousel({super.key});

  @override
  State<TopProductsCarousel> createState() => _TopProductsCarouselState();
}

class _TopProductsCarouselState extends State<TopProductsCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _autoScrollTimer;
  List<String> featuredImages = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(viewportFraction: 0.92, initialPage: 0);
    _loadImages();
  }

  Future<void> _loadImages() async {
    try {
      final images = await catalogApi.getTopProductImages();
      setState(() {
        featuredImages = images;
        loading = false;
      });

      // Auto-scroll disabled
      // if (mounted && featuredImages.isNotEmpty) {
      //   WidgetsBinding.instance.addPostFrameCallback((_) {
      //     _startAutoScroll();
      //   });
      // }
    } catch (e) {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Don't show the section if there are no images
    if (!loading && featuredImages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section header with background
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Our Top Products",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                "Hand-picked items you'll love",
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),

        // Carousel section with teal background
        Container(
          color: const Color(0xFFB2EBF2), // Light teal/cyan color
          padding: const EdgeInsets.symmetric(vertical: 30),
          child: loading
              ? const SizedBox(
                  height: 320,
                  child: Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                )
              : Column(
                  children: [
                    // Image carousel
                    SizedBox(
                      height: 320,
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() {
                            _currentPage = index;
                          });
                        },
                        itemCount: featuredImages.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: _ImageCard(imageUrl: featuredImages[index]),
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Dot indicators
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        featuredImages.length,
                        (index) => Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: _currentPage == index
                                ? Colors.white
                                : Colors.white.withOpacity(0.5),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}

class _ImageCard extends StatelessWidget {
  final String imageUrl;

  const _ImageCard({required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          width: double.infinity,
          height: double.infinity,
          cacheWidth: 800,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                    : null,
              ),
            );
          },
          errorBuilder: (_, __, ___) => Container(
            color: Colors.grey.shade200,
            child: Center(
              child: Icon(
                Icons.image_outlined,
                size: 80,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
