import 'package:flutter/material.dart';

import '../../core/config/api_config.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _controller = TextEditingController(text: ApiConfig.baseUrl);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _saveBackendUrl() async {
    final value = _controller.text.trim();
    if (value.isEmpty) return;
    await ApiConfig.setBaseUrl(value);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('URL do backend atualizada.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ListTile(
            leading: const Icon(Icons.smartphone_rounded),
            title: const Text('Servidor'),
            subtitle: Text(ApiConfig.baseUrl),
          ),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              labelText: 'URL do backend',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _saveBackendUrl,
            icon: const Icon(Icons.save_rounded),
            label: const Text('Salvar backend'),
          ),
          const Divider(height: 24),
          const ListTile(
            leading: Icon(Icons.notifications_rounded),
            title: Text('Notificações'),
            subtitle: Text('Ativadas'),
          ),
          const ListTile(
            leading: Icon(Icons.info_rounded),
            title: Text('Sobre'),
            subtitle: Text('Versão 1.0.0'),
          ),
        ],
      ),
    );
  }
}
