// FICHIER : lib/backups_page.dart

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'storage.dart';

class BackupsPage extends StatefulWidget {
  const BackupsPage({super.key});

  @override
  State<BackupsPage> createState() => _BackupsPageState();
}

class _BackupsPageState extends State<BackupsPage> {
  bool _isSavingNow = false;
  bool _isLoadingList = false;
  List<File> _backups = [];

  @override
  void initState() {
    super.initState();
    _loadBackups();
  }

  Future<void> _loadBackups() async {
    setState(() => _isLoadingList = true);
    try {
      final list = await AppStorage.listBackups();
      setState(() {
        _backups = list;
      });
    } finally {
      if (mounted) {
        setState(() => _isLoadingList = false);
      }
    }
  }

  Future<void> _saveNow() async {
    if (_isSavingNow) return;
    setState(() => _isSavingNow = true);
    try {
      final cfg = await AppStorage.loadConfig();
      final deplacements = await AppStorage.loadDeplacements();
      if (cfg == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Aucune configuration à sauvegarder'),
            ),
          );
        }
        return;
      }

      final file = await AppStorage.exportBackupToPublicDocuments(
        config: cfg,
        deplacements: deplacements,
      );
      if (file == null) {
        throw Exception('Impossible de créer le fichier de sauvegarde');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Sauvegarde créée',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        );
      }

      await _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la sauvegarde : $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingNow = false);
      }
    }
  }

  Future<void> _restoreFromBackup(File file) async {
    try {
      final content = await file.readAsString();
      await AppStorage.importBackupFromJsonString(content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sauvegarde restaurée')),
        );
        // on signale au SettingsPage / HomePage qu'il faut recharger
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la restauration : $e')),
        );
      }
    }
  }

  Future<void> _deleteBackup(File file) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Supprimer la sauvegarde'),
            content: const Text(
              'Voulez-vous vraiment supprimer ce fichier de sauvegarde ?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Annuler'),
              ),
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Supprimer'),
              ),
            ],
          ),
        ) ??
        false;

    if (!confirm) return;

    try {
      if (await file.exists()) {
        await file.delete();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Sauvegarde supprimée')),
        );
      }
      await _loadBackups();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors de la suppression : $e')),
        );
      }
    }
  }

  Future<void> _shareBackup(File file) async {
    try {
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Sauvegarde km_csf',
        subject: 'Sauvegarde km_csf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du partage : $e')),
        );
      }
    }
  }

  String _shortName(File file) {
    final name = file.path.split(Platform.pathSeparator).last;
    if (name.startsWith('km_csf_backup_')) {
      final core = name
          .replaceFirst('km_csf_backup_', '')
          .replaceAll('.json', '')
          .replaceAll('T', ' ');
      return core;
    }
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sauvegardes'),
      ),
      body: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isSavingNow ? null : _saveNow,
                icon: const Icon(Icons.cloud_upload),
                label: Text(
                  _isSavingNow
                      ? 'Sauvegarde en cours...'
                      : 'Sauvegarder maintenant',
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: Text(
              'Astuce : touchez une sauvegarde pour la restaurer.\n'
              'Utilisez les icônes à droite pour partager ou supprimer.',
              style: TextStyle(
                color: scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: _isLoadingList
                ? const Center(child: CircularProgressIndicator())
                : _backups.isEmpty
                    ? Center(
                        child: Text(
                          'Aucune sauvegarde.\nCréez-en une avec le bouton ci-dessus.',
                          style: TextStyle(color: scheme.onSurfaceVariant),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : ListView.builder(
                        itemCount: _backups.length,
                        itemBuilder: (context, index) {
                          final file = _backups[index];
                          final name = _shortName(file);
                          return ListTile(
                            leading: const Icon(Icons.insert_drive_file),
                            title: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              file.path,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                            ),
                            onTap: () => _restoreFromBackup(file),
                            trailing: Wrap(
                              spacing: 4,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.ios_share),
                                  tooltip: 'Partager',
                                  onPressed: () => _shareBackup(file),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  tooltip: 'Supprimer',
                                  onPressed: () => _deleteBackup(file),
                                ),
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
