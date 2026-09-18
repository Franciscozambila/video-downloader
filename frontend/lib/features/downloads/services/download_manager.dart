import '../models/download_model.dart';

class DownloadManager {
  DownloadManager._();

  static final DownloadManager instance = DownloadManager._();

  final List<DownloadModel> _downloads = <DownloadModel>[];

  List<DownloadModel> get downloads => List.unmodifiable(_downloads);

  void enqueue(DownloadModel item) {
    _downloads.insert(0, item);
  }

  void queueDownload({
    required String url,
    required String title,
    required String filename,
    required String type,
    required String quality,
    required String format,
  }) {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    final item = DownloadModel(
      id: id,
      url: url,
      title: title,
      filename: filename,
      type: type,
      quality: quality,
      format: format,
      createdAt: DateTime.now(),
      status: 'queued',
    );
    enqueue(item);
  }

  void updateStatus(
    String id, {
    String? status,
    double? progress,
    int? bytesDownloaded,
    int? totalBytes,
    String? error,
  }) {
    final index = _downloads.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = _downloads[index];
    _downloads[index] = current.copyWith(
      status: status ?? current.status,
      progress: progress ?? current.progress,
      bytesDownloaded: bytesDownloaded ?? current.bytesDownloaded,
      totalBytes: totalBytes ?? current.totalBytes,
      error: error ?? current.error,
    );
  }

  void remove(String id) {
    _downloads.removeWhere((item) => item.id == id);
  }

  List<DownloadModel> get active => _downloads.where((item) => item.status == 'downloading').toList();

  List<DownloadModel> get completed => _downloads.where((item) => item.status == 'completed').toList();

  List<DownloadModel> get failed => _downloads.where((item) => item.status == 'failed').toList();
}
