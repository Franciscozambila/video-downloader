class LibraryItem {
  final String id;
  final String title;
  final String path;
  final String mediaType;
  final String? thumbnail;
  final String? sourceUrl;
  final String? platform;
  final String? duration;
  final DateTime createdAt;
  final bool favorite;

  const LibraryItem({
    required this.id,
    required this.title,
    required this.path,
    required this.mediaType,
    this.thumbnail,
    this.sourceUrl,
    this.platform,
    this.duration,
    required this.createdAt,
    this.favorite = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'path': path,
        'mediaType': mediaType,
        'thumbnail': thumbnail,
        'sourceUrl': sourceUrl,
        'platform': platform,
        'duration': duration,
        'createdAt': createdAt.toIso8601String(),
        'favorite': favorite,
      };

  factory LibraryItem.fromJson(Map<String, dynamic> json) => LibraryItem(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Sem título',
        path: json['path'] ?? '',
        mediaType: json['mediaType'] ?? 'video',
        thumbnail: json['thumbnail'],
        sourceUrl: json['sourceUrl'],
        platform: json['platform'],
        duration: json['duration'],
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        favorite: json['favorite'] == true,
      );
}
