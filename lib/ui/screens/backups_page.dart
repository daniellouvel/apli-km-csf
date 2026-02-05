import 'dart:io';
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/storage.dart';

class BackupsPage extends StatefulWidget {
  const BackupsPage({super.key});
  @override
  State<BackupsPage> createState() => _BackupsPageState();
}

class _BackupsPageState extends State<BackupsPage> {
  List<File> _files = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final files = await AppStorage.listAllBackups();
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Fichiers de sauvegarde")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: ElevatedButton.icon(
              onPressed: () async {
                final cfg = await AppStorage.loadConfig();
                final data = await AppStorage.loadDeplacements();
                if (cfg != null) await AppStorage.createBackup(cfg, data);
                _refresh();
              },
              icon: const Icon(Icons.add_circle),
              label: const Text("CRÉER UNE NOUVELLE SAUVEGARDE"),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: _files.length,
                    itemBuilder: (ctx, i) {
                      final f = _files[i];
                      return ListTile(
                        leading: const Icon(Icons.insert_drive_file),
                        title: Text(f.path.split('/').last,
                            style: const TextStyle(fontSize: 12)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon:
                                    const Icon(Icons.send, color: Colors.blue),
                                onPressed: () =>
                                    Share.shareXFiles([XFile(f.path)])),
                            IconButton(
                                icon: const Icon(Icons.settings_backup_restore,
                                    color: Colors.green),
                                onPressed: () async {
                                  await AppStorage.import(f);
                                  Navigator.pop(context, true);
                                }),
                            IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  await AppStorage.deleteBackup(f);
                                  _refresh();
                                }),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
