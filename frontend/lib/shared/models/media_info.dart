class MediaInfo {
  final String title;
  final String? thumbnail;
  final String? duration;
  final String? platform;
  final List<String> availableFormats;
  final List<String> availableQualities;

  MediaInfo({
    required this.title,
    this.thumbnail,
    this.duration,
    this.platform,
    this.availableFormats = const ['mp4', 'mp3'],
    this.availableQualities = const ['best', '720p', '480p', '360p', 'audio_only'],
  });

  factory MediaInfo.fromJson(Map<String, dynamic> json) {
    return MediaInfo(
      title: json['title'] ?? json['name'] ?? 'Mídia sem título',
      thumbnail: json['thumbnail'] ?? json['thumb'],
      duration: json['duration']?.toString(),
      platform: json['platform'] ?? json['extractor'],
      availableFormats: (json['formats'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['mp4', 'mp3'],
      availableQualities: (json['qualities'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          ['best', 'audio_only'],
    );
  }
}
