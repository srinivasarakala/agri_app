import 'dart:async';
import 'package:flutter/material.dart';
import '../category.dart';
import 'category_card.dart';

class SparePartsCarousel extends StatefulWidget {
  final List<Category> categories;
  final void Function(Category)? onCategoryTap;
  final bool isLoading;
  final String? error;

  const SparePartsCarousel({
    super.key,
    required this.categories,
    this.onCategoryTap,
    this.isLoading = false,
    this.error,
  });

  @override
  State<SparePartsCarousel> createState() => _SparePartsCarouselState();
}

class _SparePartsCarouselState extends State<SparePartsCarousel> {
  // Warm mechanical color palette for spare parts
  static const List<Color> _sparePartsColors = [
    Color(0xFFE8EAF6), // Indigo 50
    Color(0xFFECEFF1), // Blue Grey 50
    Color(0xFFFFF8E1), // Amber 50
    Color(0xFFE1F5FE), // Light Blue 50
    Color(0xFFF3E5F5), // Purple 50
    Color(0xFFE0F2F1), // Teal 50
    Color(0xFFFBE9E7), // Deep Orange 50
  ];

  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    // Start auto-scroll after initial frame and if categories exist
    if (widget.categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoScroll();
      });
    }
  }

  @override
  void didUpdateWidget(SparePartsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start auto-scroll when categories are loaded
    if (oldWidget.categories.isEmpty && widget.categories.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoScroll();
      });
    }
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  void _startAutoScroll() {
    if (widget.categories.length <= 1 || !_scrollController.hasClients) {
      return;
    }

    // Auto-scroll every 3 seconds
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!_scrollController.hasClients || _userInteracting) {
        return;
      }

      final maxScroll = _scrollController.position.maxScrollExtent;
      final currentScroll = _scrollController.offset;

      // If at the end, jump back to start
      if (currentScroll >= maxScroll - 10) {
        _scrollController.jumpTo(0);
      } else {
        // Scroll forward smoothly
        _scrollController.animateTo(
          currentScroll + 150, // Scroll by ~1 card width
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  void _onUserInteractionStart() {
    setState(() => _userInteracting = true);
  }

  void _onUserInteractionEnd() {
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _userInteracting = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 220,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (widget.error != null) {
      return Padding(
        padding: const EdgeInsets.all(14),
        child: Text(
          widget.error!,
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (widget.categories.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(14),
        child: Text(
          "No spare parts categories available",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    return SizedBox(
      height: 220,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            _onUserInteractionStart();
          } else if (notification is ScrollEndNotification) {
            _onUserInteractionEnd();
          }
          return false;
        },
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: widget.categories.length,
          itemBuilder: (context, index) {
            final category = widget.categories[index];
            final color = _sparePartsColors[index % _sparePartsColors.length];

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: CategoryCard(
                categoryName: category.name,
                productImages: category.productImages,
                productCount: category.productCount,
                backgroundColor: color,
                categoryImageUrl: category.imageUrl,
                onTap: widget.onCategoryTap != null
                    ? () => widget.onCategoryTap!(category)
                    : null,
              ),
            );
          },
        ),
      ),
    );
  }
}
