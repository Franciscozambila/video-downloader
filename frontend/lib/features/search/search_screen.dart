import 'package:flutter/material.dart';

import '../../core/network/api_client.dart';
import '../../shared/models/media_info.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _controller = TextEditingController();
  final ApiClient _client = ApiClient();
  bool _loading = false;
  String? _error;
  MediaInfo? _info;

  Future<void> _loadMetadata() async {
    final url = _controller.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Informe uma URL válida.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final result = await _client.getMediaInfo(url);
      setState(() {
        _info = result;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Descobrir')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Cole uma URL ou pesquise',
                prefixIcon: const Icon(Icons.search_rounded),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                suffixIcon: IconButton(
                  onPressed: _loading ? null : _loadMetadata,
                  icon: const Icon(Icons.search_rounded),
                ),
              ),
              onSubmitted: (_) => _loadMetadata(),
            ),
            const SizedBox(height: 20),
            if (_loading)
              const Expanded(child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Expanded(
                child: Center(
                  child: Text(_error!, textAlign: TextAlign.center),
                ),
              )
            else if (_info == null)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.link_rounded, size: 72),
                      SizedBox(height: 16),
                      Text(
                        'Sem resultado ainda',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8),
                      Text('Use uma URL suportada pelo backend Python para obter metadados.'),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_info!.thumbnail != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _info!.thumbnail!,
                                width: double.infinity,
                                height: 180,
                                fit: BoxFit.cover,
                              ),
                            ),
                          const SizedBox(height: 12),
                          Text(
                            _info!.title,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 12),
                          ListTile(
                            leading: const Icon(Icons.timer_rounded),
                            title: const Text('Duração'),
                            subtitle: Text(_info!.duration ?? '—'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.video_library_rounded),
                            title: const Text('Plataforma'),
                            subtitle: Text(_info!.platform ?? '—'),
                          ),
                          ListTile(
                            leading: const Icon(Icons.format_list_bulleted_rounded),
                            title: const Text('Formatos'),
                            subtitle: Text(_info!.availableFormats.join(', ')),
                          ),
                          ListTile(
                            leading: const Icon(Icons.hd_rounded),
                            title: const Text('Qualidades'),
                            subtitle: Text(_info!.availableQualities.join(', ')),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
