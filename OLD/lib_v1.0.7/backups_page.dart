import 'dart:io';
import 'package:flutter/material.dart';
import 'storage.dart';

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

  // Charge la liste des fichiers depuis le dossier /KM_CSF_Backups
  Future<void> _refresh() async {
    setState(() => _loading = true);
    final files = await AppStorage.listAllBackups();
    setState(() {
      _files = files;
      _loading = false;
    });
  }

  // Crée une nouvelle sauvegarde manuelle
  Future<void> _createNewBackup() async {
    final cfg = await AppStorage.loadConfig();
    final data = await AppStorage.loadDeplacements();

    if (cfg == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text("Configurez d'abord votre profil dans les réglages.")));
      return;
    }

    await AppStorage.createAutoBackup(cfg, data);
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Sauvegarde créée avec succès !")));
    _refresh();
  }

  // Confirmation avant restauration
  Future<void> _confirmRestore(File file) async {
    final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Restaurer ?'),
            content: Text(
                'Voulez-vous écraser les données actuelles par celles de ce fichier ?\n\n${file.path.split('/').last}'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('ANNULER')),
              TextButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('RESTAURER',
                      style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await AppStorage.import(file);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Restauration terminée !")));
        Navigator.pop(
            context, true); // Retour à l'accueil pour rafraîchir les trajets
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Gestion des Sauvegardes"),
        actions: [
          IconButton(onPressed: _refresh, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Column(
        children: [
          // Section du haut : Bouton pour créer une sauvegarde
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            color: Colors.blue.withOpacity(0.1),
            child: ElevatedButton.icon(
              onPressed: _createNewBackup,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                backgroundColor: Colors.blue.shade700,
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.save_as),
              label: const Text("SAUVEGARDER MAINTENANT",
                  style: TextStyle(fontSize: 16)),
            ),
          ),

          const Divider(height: 1),

          // Liste des fichiers trouvés
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _files.isEmpty
                    ? const Center(
                        child: Text(
                            "Aucune sauvegarde trouvée dans le dossier\n/KM_CSF_Backups",
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey)))
                    : ListView.builder(
                        itemCount: _files.length,
                        itemBuilder: (context, i) {
                          final f = _files[i];
                          final fileName = f.path.split('/').last;
                          return ListTile(
                            leading:
                                const Icon(Icons.history, color: Colors.blue),
                            title: Text(fileName,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: Text(
                                "Modifié le : ${f.lastModifiedSync().toString().split('.')[0]}"),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Bouton Restaurer (Icône flèche vers le bas ou Cloud)
                                IconButton(
                                  icon: const Icon(
                                      Icons.settings_backup_restore,
                                      color: Colors.green),
                                  onPressed: () => _confirmRestore(f),
                                  tooltip: 'Restaurer ce fichier',
                                ),
                                // Bouton Supprimer
                                IconButton(
                                  icon: const Icon(Icons.delete_outline,
                                      color: Colors.red),
                                  onPressed: () async {
                                    await AppStorage.deleteBackup(f);
                                    _refresh();
                                  },
                                ),
                              ],
                            ),
                            onTap: () => _confirmRestore(f),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}
