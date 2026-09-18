class LibraryEntry {
  final String id;
  final String title;
  final String path;
  final String mediaType;
  final String? thumbnail;
  final String? sourceUrl;
  final String? platform;
  final String? duration;
  final bool favorite;
  final DateTime createdAt;

  const LibraryEntry({
    required this.id,
    required this.title,
    required this.path,
    required this.mediaType,
    this.thumbnail,
    this.sourceUrl,
    this.platform,
    this.duration,
    this.favorite = false,
    required this.createdAt,
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
        'favorite': favorite,
        'createdAt': createdAt.toIso8601String(),
      };

  factory LibraryEntry.fromJson(Map<String, dynamic> json) => LibraryEntry(
        id: json['id'] ?? '',
        title: json['title'] ?? 'Sem título',
        path: json['path'] ?? '',
        mediaType: json['mediaType'] ?? 'video',
        thumbnail: json['thumbnail'],
        sourceUrl: json['sourceUrl'],
        platform: json['platform'],
        duration: json['duration'],
        favorite: json['favorite'] == true,
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      );
}
