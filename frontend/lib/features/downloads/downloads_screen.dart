import 'package:flutter/material.dart';

import 'services/download_manager.dart';

class DownloadsScreen extends StatefulWidget {
  const DownloadsScreen({super.key});

  @override
  State<DownloadsScreen> createState() => _DownloadsScreenState();
}

class _DownloadsScreenState extends State<DownloadsScreen> {
  final DownloadManager _manager = DownloadManager.instance;

  @override
  Widget build(BuildContext context) {
    final downloads = _manager.downloads;

    if (downloads.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Downloads')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.downloading_rounded, size: 72),
                SizedBox(height: 16),
                Text(
                  'Sem downloads ativos',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'Os downloads em andamento e o histórico aparecerão aqui.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: downloads.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = downloads[index];
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(item.status.toUpperCase()),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text('${item.type} • ${item.format} • ${item.quality}'),
                  const SizedBox(height: 12),
                  LinearProgressIndicator(value: item.progress <= 0 ? null : item.progress.clamp(0.0, 1.0)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('${item.bytesDownloaded} bytes'),
                      Text('${(item.progress * 100).toStringAsFixed(0)}%'),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
