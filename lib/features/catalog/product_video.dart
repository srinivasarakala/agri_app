class ProductVideo {
  final int id;
  final String title;
  final String youtubeUrl;
  final String youtubeId;
  final String? description;
  final int order;
  final bool isActive;
  final String thumbnailUrl;
  final DateTime createdAt;

  ProductVideo({
    required this.id,
    required this.title,
    required this.youtubeUrl,
    required this.youtubeId,
    this.description,
    required this.order,
    required this.isActive,
    required this.thumbnailUrl,
    required this.createdAt,
  });

  factory ProductVideo.fromJson(Map<String, dynamic> json) {
    return ProductVideo(
      id: json['id'] as int,
      title: json['title'] as String,
      youtubeUrl: json['youtube_url'] as String,
      youtubeId: json['youtube_id'] as String,
      description: json['description'] as String?,
      order: json['order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'youtube_url': youtubeUrl,
      'youtube_id': youtubeId,
      'description': description,
      'order': order,
      'is_active': isActive,
      'thumbnail_url': thumbnailUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
