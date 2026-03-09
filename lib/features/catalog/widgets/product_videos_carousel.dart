import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../product_video.dart';

class ProductVideosCarousel extends StatefulWidget {
  final List<ProductVideo> videos;
  final bool isLoading;
  final String? error;

  const ProductVideosCarousel({
    super.key,
    required this.videos,
    this.isLoading = false,
    this.error,
  });

  @override
  State<ProductVideosCarousel> createState() => _ProductVideosCarouselState();
}

class _ProductVideosCarouselState extends State<ProductVideosCarousel> {
  YoutubePlayerController? _ytController;

  void _showEmbeddedVideo(BuildContext context, String youtubeUrl) {
    // Try multiple methods to extract video ID
    String? videoId = YoutubePlayer.convertUrlToId(youtubeUrl);
    
    // If convertUrlToId fails, try manual extraction for Shorts URLs
    if (videoId == null) {
      final shortsPattern = RegExp(r'(?:youtube\.com|youtu\.be)/shorts/([0-9A-Za-z_-]{11})');
      final match = shortsPattern.firstMatch(youtubeUrl);
      if (match != null) {
        videoId = match.group(1);
      }
    }
    
    if (videoId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Invalid YouTube URL')),
      );
      return;
    }
    _ytController = YoutubePlayerController(
      initialVideoId: videoId,
      flags: const YoutubePlayerFlags(
        autoPlay: true,
        mute: false,
      ),
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        contentPadding: EdgeInsets.zero,
        content: YoutubePlayer(
          controller: _ytController!,
          showVideoProgressIndicator: true,
        ),
      ),
    ).then((_) {
      _ytController?.pause();
      _ytController?.dispose();
      _ytController = null;
    });
  }

  @override
  void dispose() {
    _ytController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 280,
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

    if (widget.videos.isEmpty) {
      return const SizedBox.shrink();
    }

    // For fewer than 3 videos, show larger thumbnails
    if (widget.videos.length < 3) {
      return SizedBox(
        height: 280,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          itemCount: widget.videos.length,
          itemBuilder: (context, index) {
            return SizedBox(
              width: MediaQuery.of(context).size.width * 0.85, // Larger width for fewer videos
              child: Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _VideoCard(
                  video: widget.videos[index],
                  onTap: () => _showEmbeddedVideo(context, widget.videos[index].youtubeUrl),
                ),
              ),
            );
          },
        ),
      );
    }

    // Calculate the number of columns needed (2 videos per column, so we need ceil(videos.length / 2) columns)
    final columnCount = (widget.videos.length / 2).ceil();

    return SizedBox(
      height: 280, // Height for 2 rows of videos
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: columnCount,
        itemBuilder: (context, columnIndex) {
          final firstVideoIndex = columnIndex * 2;
          final secondVideoIndex = firstVideoIndex + 1;
          final hasSecondVideo = secondVideoIndex < widget.videos.length;

          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.45, // Each column takes 40% of screen width
            child: Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  // First video (top row)
                  Expanded(
                    child: _VideoCard(
                      video: widget.videos[firstVideoIndex],
                      onTap: () => _showEmbeddedVideo(context, widget.videos[firstVideoIndex].youtubeUrl),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Second video (bottom row) if available
                  if (hasSecondVideo)
                    Expanded(
                      child: _VideoCard(
                        video: widget.videos[secondVideoIndex],
                        onTap: () => _showEmbeddedVideo(context, widget.videos[secondVideoIndex].youtubeUrl),
                      ),
                    )
                  else
                    Expanded(child: Container()), // Empty space if no second video
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _VideoCard extends StatelessWidget {
  final ProductVideo video;
  final VoidCallback onTap;

  const _VideoCard({
    required this.video,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.transparent,
            boxShadow: [
              BoxShadow(
                //Fix below issue
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Video thumbnail
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedNetworkImage(
                        imageUrl: video.thumbnailUrl,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(
                              Icons.play_circle_outline,
                              size: 48,
                             // color: Colors.grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Play button overlay
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.play_circle_filled,
                            size: 56,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Video title and description at the bottom
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      video.title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (video.description != null &&
                        video.description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        video.description!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
