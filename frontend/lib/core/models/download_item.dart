class DownloadItem {
  final String id;
  final String url;
  final String title;
  final String filename;
  final String type;
  final String quality;
  final String format;
  final String status;
  final double progress;
  final int bytesDownloaded;
  final int totalBytes;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? error;

  const DownloadItem({
    required this.id,
    required this.url,
    required this.title,
    required this.filename,
    required this.type,
    required this.quality,
    required this.format,
    required this.status,
    this.progress = 0,
    this.bytesDownloaded = 0,
    this.totalBytes = 0,
    required this.createdAt,
    this.completedAt,
    this.error,
  });

  DownloadItem copyWith({
    String? id,
    String? url,
    String? title,
    String? filename,
    String? type,
    String? quality,
    String? format,
    String? status,
    double? progress,
    int? bytesDownloaded,
    int? totalBytes,
    DateTime? createdAt,
    DateTime? completedAt,
    String? error,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      url: url ?? this.url,
      title: title ?? this.title,
      filename: filename ?? this.filename,
      type: type ?? this.type,
      quality: quality ?? this.quality,
      format: format ?? this.format,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesDownloaded: bytesDownloaded ?? this.bytesDownloaded,
      totalBytes: totalBytes ?? this.totalBytes,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      error: error ?? this.error,
    );
  }
}
