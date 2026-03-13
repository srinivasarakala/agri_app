import 'dart:io';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/widgets/progressive_image.dart';
import 'product.dart';
import '../../main.dart';
import '../../services/analytics_service.dart';
import '../../core/cart/cart_state.dart';

class ProductDetailsPage extends StatefulWidget {
  final Product product;

  const ProductDetailsPage({super.key, required this.product});

  @override
  State<ProductDetailsPage> createState() => _ProductDetailsPageState();
}

class _ProductDetailsPageState extends State<ProductDetailsPage> {
  late int currentQty;
  bool isFavorite = false;
  bool favoriteLoading = false;

  @override
  void initState() {
    super.initState();
    currentQty = (cartQty.value[widget.product.id] ?? 0).toInt();
    isFavorite = favorites.value.contains(widget.product.id);
    // Log product view event
    AnalyticsService(analytics).logProductView(
      widget.product.id.toString(),
      widget.product.name,
    );
  }

  void _updateQuantity(int newQty) {
    setState(() {
      currentQty = newQty;
    });
  }

  void _addToCart() {
    if (currentQty > 0) {
      cartSetQty(widget.product.id, currentQty);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added ${currentQty} ${widget.product.unit} to cart'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _shareProduct() async {
    final p = widget.product;
    final msg = StringBuffer();
    msg.writeln('🌾 *${p.name}*');
    if (p.brand != null && p.brand!.isNotEmpty) msg.writeln('Brand: ${p.brand}');
    msg.writeln('💰 ₹${p.sellingPrice.toStringAsFixed(2)} per ${p.unit}');
    if (p.mrp > p.sellingPrice) {
      final disc = ((p.mrp - p.sellingPrice) / p.mrp * 100).toStringAsFixed(0);
      msg.writeln('🏷 MRP ₹${p.mrp.toStringAsFixed(2)} ($disc% OFF)');
    }
    if (p.description != null && p.description!.isNotEmpty) {
      msg.writeln('\n${p.description}');
    }
    msg.writeln('\n📦 Pavan HiTech Agro');

    if (p.imageUrl != null && p.imageUrl!.isNotEmpty) {
      try {
        final response = await Dio().get<List<int>>(
          p.imageUrl!,
          options: Options(responseType: ResponseType.bytes),
        );
        final dir = await getTemporaryDirectory();
        final ext = p.imageUrl!.toLowerCase().endsWith('.png') ? 'png' : 'jpg';
        final file = File('${dir.path}/share_product_${p.id}.$ext');
        await file.writeAsBytes(response.data!);
        await Share.shareXFiles([XFile(file.path)], text: msg.toString());
        return;
      } catch (_) {}
    }
    await Share.share(msg.toString());
  }

  void _showFullScreenImage() {
    final imageUrl = widget.product.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) return;
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (ctx) => Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 6.0,
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  ),
                  errorWidget: (context, url, error) => const Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 80,
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(ctx).padding.top + 8,
              right: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleFavorite() async {
    if (favoriteLoading) return;
    setState(() { favoriteLoading = true; });
    final prevFavorite = isFavorite;
    final prevFavorites = Set<int>.from(favorites.value);
    // Optimistic update
    setState(() { isFavorite = !isFavorite; });
    toggleFavorite(widget.product.id);
    try {
      await catalogApi.toggleFavorite(widget.product.id);
      await syncFavorites(); // Ensure backend sync
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isFavorite ? "Added to favorites" : "Removed from favorites",
          ),
          duration: const Duration(seconds: 1),
        ),
      );
    } catch (e) {
      // Revert UI and local state
      setState(() { isFavorite = prevFavorite; });
      favorites.value = prevFavorites;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to update favorite. Please try again."),
          duration: const Duration(seconds: 2),
        ),
      );
    } finally {
      if (mounted) setState(() { favoriteLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final inStock = widget.product.globalStock > 0;
    final discount = widget.product.mrp > widget.product.sellingPrice
        ? ((widget.product.mrp - widget.product.sellingPrice) /
                  widget.product.mrp *
                  100)
              .toStringAsFixed(0)
        : null;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // White top header with back button and favorite
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(8, 48, 8, 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text(
                        'Product Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share_rounded),
                    tooltip: 'Share',
                    onPressed: _shareProduct,
                  ),
                  IconButton(
                    icon: favoriteLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_outline,
                            color: isFavorite ? Colors.red : null,
                          ),
                    onPressed: favoriteLoading ? null : _toggleFavorite,
                  ),
                ],
              ),
            ),
            
            // Product Image
            GestureDetector(
              onTap: (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty)
                  ? _showFullScreenImage
                  : null,
              child: Container(
                width: double.infinity,
                height: 350,
                color: Colors.grey.shade100,
                child: (widget.product.imageUrl != null && widget.product.imageUrl!.isNotEmpty)
                    ? Stack(
                        fit: StackFit.expand,
                        children: [
                          ProgressiveImage(
                            imageUrl: widget.product.imageUrl!,
                            width: double.infinity,
                            height: 350,
                            fit: BoxFit.contain,
                            borderRadius: BorderRadius.circular(0),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black38,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(
                                Icons.zoom_in,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                        ],
                      )
                    : const Center(
                        child: Icon(Icons.image, size: 80, color: Colors.grey),
                      ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Name
                  Text(
                    widget.product.name,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // SKU
                  Text(
                    'SKU: ${widget.product.sku}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),

                  // Stock Status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: inStock
                          ? Colors.green.withValues(alpha: 0.12)
                          : Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          inStock ? Icons.check_circle : Icons.cancel,
                          color: inStock
                              ? Colors.green.shade800
                              : Colors.red.shade800,
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          inStock
                              ? "In Stock (${widget.product.globalStock.toInt()} ${widget.product.unit})"
                              : "Out of Stock",
                          style: TextStyle(
                            color: inStock
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Price Section
                  Row(
                    children: [
                      Text(
                        "₹${widget.product.sellingPrice.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      if (discount != null) ...[
                        const SizedBox(width: 12),
                        Text(
                          "₹${widget.product.mrp.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade600,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            "$discount% OFF",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Unit
                  Text(
                    'per ${widget.product.unit}',
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 20),

                  // Brand
                  if (widget.product.brand != null &&
                      widget.product.brand!.isNotEmpty) ...[
                    _buildInfoRow('Brand', widget.product.brand!, Icons.label),
                    const SizedBox(height: 16),
                  ],

                  // Category
                  if (widget.product.categoryName != null &&
                      widget.product.categoryName!.isNotEmpty) ...[
                    _buildInfoRow(
                      'Category',
                      widget.product.categoryName!,
                      Icons.category,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Minimum Quantity
                  if (widget.product.minQty > 1) ...[
                    _buildInfoRow(
                      'Minimum Order',
                      '${widget.product.minQty.toInt()} ${widget.product.unit}',
                      Icons.shopping_basket,
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Tags
                  if (widget.product.tags != null &&
                      widget.product.tags!.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.product.tags!
                          .split(',')
                          .map(
                            (tag) => Chip(
                              label: Text(
                                tag.trim(),
                                style: const TextStyle(fontSize: 12),
                              ),
                              backgroundColor: Colors.grey.shade200,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  if (widget.product.description != null &&
                      widget.product.description!.isNotEmpty) ...[
                    const Text(
                      'Description',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.product.description!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade700,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const Divider(),
                  const SizedBox(height: 20),

                  // Quantity Selector
                  const Text(
                    'Select Quantity',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      IconButton(
                        onPressed: currentQty > 0
                            ? () {
                                final minQty = widget.product.minQty.toInt();
                                _updateQuantity(
                                  (currentQty - minQty).clamp(0, 999999),
                                );
                              }
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                        iconSize: 32,
                        color: Colors.green,
                      ),
                      Container(
                        width: 80,
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 16,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          currentQty.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          final minQty = widget.product.minQty.toInt();
                          _updateQuantity(currentQty + minQty);
                        },
                        icon: const Icon(Icons.add_circle_outline),
                        iconSize: 32,
                        color: Colors.green,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        widget.product.unit,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),

                  // Add to Cart Section
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey,
                                ),
                              ),
                              Text(
                                '₹${(widget.product.sellingPrice * currentQty).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: currentQty > 0 ? _addToCart : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Add to Cart',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20), // Space for bottom navigation
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
          ),
        ),
      ],
    );
  }
}
