import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';

/// Progressive image widget: shimmer -> blurred low-res -> full image
class ProgressiveImage extends StatelessWidget {
  final String imageUrl;
  final String? lowResUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProgressiveImage({
    Key? key,
    required this.imageUrl,
    this.lowResUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  }) : super(key: key);

  Widget _shimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        width: width ?? double.infinity,
        height: height ?? 200,
        decoration: BoxDecoration(
          color: Colors.grey[300],
          borderRadius: borderRadius,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget imageWidget = CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      placeholder: (context, url) {
        if (lowResUrl != null) {
          return CachedNetworkImage(
            imageUrl: lowResUrl!,
            width: width,
            height: height,
            fit: fit,
            imageBuilder: (context, imageProvider) => ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: imageProvider,
                    fit: fit,
                  ),
                  borderRadius: borderRadius,
                ),
              ),
            ),
            placeholder: (context, url) => _shimmerPlaceholder(),
            errorWidget: (context, url, error) => _shimmerPlaceholder(),
          );
        }
        return _shimmerPlaceholder();
      },
      errorWidget: (context, url, error) => Icon(Icons.broken_image, size: 40, color: Colors.grey),
    );

    if (borderRadius != null) {
      return ClipRRect(
        borderRadius: borderRadius!,
        child: imageWidget,
      );
    }
    return imageWidget;
  }
}
