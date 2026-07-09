class GalleryItem {
  final int id;
  final String title;
  final String imageUrl;
  final String mediaType; // 'image', 'video', etc.

  GalleryItem({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.mediaType,
  });

  factory GalleryItem.fromJson(Map<String, dynamic> json) {
    return GalleryItem(
      id: json['id'],
      title: json['title'] ?? 'Untitled Media',
      imageUrl: json['image_url'] ?? '',
      mediaType: json['media_type'] ?? 'image',
    );
  }
}
