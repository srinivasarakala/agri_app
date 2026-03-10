import 'dart:async';
import 'package:flutter/material.dart';
import '../catalog/brand.dart';
import '../../core/widgets/progressive_image.dart';

class BrandsCarousel extends StatefulWidget {
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
  State<BrandsCarousel> createState() => _BrandsCarouselState();
}

class _BrandsCarouselState extends State<BrandsCarousel> {
  final ScrollController _scrollController = ScrollController();
  Timer? _autoScrollTimer;
  bool _userInteracting = false;

  @override
  void initState() {
    super.initState();
    // Start auto-scroll after initial frame and if brands exist
    if (widget.brands.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startAutoScroll();
      });
    }
  }

  @override
  void didUpdateWidget(BrandsCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Start auto-scroll when brands are loaded
    if (oldWidget.brands.isEmpty && widget.brands.isNotEmpty) {
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
    if (widget.brands.length <= 1 || !_scrollController.hasClients) {
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
          currentScroll + 100, // Scroll by ~1 brand width
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
        height: 120,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (widget.error != null) {
      return SizedBox(
        height: 120,
        child: Center(child: Text(widget.error!, style: const TextStyle(color: Colors.red))),
      );
    }
    if (widget.brands.isEmpty) {
      return const SizedBox(
        height: 120,
        child: Center(child: Text('No brands found.')),
      );
    }
    return SizedBox(
      height: 120,
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification is ScrollStartNotification) {
            _onUserInteractionStart();
          } else if (notification is ScrollEndNotification) {
            _onUserInteractionEnd();
          }
          return false;
        },
        child: ListView.separated(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: widget.brands.length,
          separatorBuilder: (_, __) => const SizedBox(width: 12),
          itemBuilder: (context, index) {
            final brand = widget.brands[index];
            return GestureDetector(
              onTap: () => widget.onBrandTap?.call(brand),
              child: Column(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey.shade100,
                    ),
                    child: brand.imageUrl != null && brand.imageUrl!.isNotEmpty
                        ? ProgressiveImage(
                            imageUrl: brand.imageUrl!,
                            width: 72,
                            height: 72,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(36),
                          )
                        : Center(
                            child: Text(
                              brand.name.isNotEmpty ? brand.name[0] : '',
                              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                          ),
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
      ),
    );
  }
}
